class_name ClassMechanicHandler
extends Node

const FORGE_SWORD_STATUS = preload("res://statuses/forge_sword.tres")
const BEAST_PACK_STATUS = preload("res://statuses/beast_pack.tres")
const GOLD_BODY_STATUS = preload("res://statuses/gold_body.tres")
const MUSCLE_STATUS = preload("res://statuses/muscle.tres")
const SHA_QI_STATUS = preload("res://statuses/sha_qi.tres")

const SOUL_MARK_HEAL_PER_STACK := 1

# 煞气阈值与天魔降世
const SHA_QI_ON_HIT := 1
const SHA_QI_FLAT_THRESHOLD := 3
const SHA_QI_DOUBLE_THRESHOLD := 6
const SHA_QI_HEAVENLY_THRESHOLD := 10
const SHA_QI_AFTER_HEAVENLY := 5

var character: CharacterStats
var player: Player
var player_handler: PlayerHandler
var enemy_handler: EnemyHandler

var _sha_qi_connected := false
var _heavenly_active := false           # 本回合处于天魔降世（×3）
var _heavenly_penalty_pending := false  # 下回合开始结算代价
# 一次性创建、原地更新的 modifier 值（避免 remove_value 的 queue_free 延迟问题）
var _mv_dealt_flat: ModifierValue
var _mv_dealt_mult: ModifierValue
var _mv_taken_mult: ModifierValue


func setup(
	char_stats: CharacterStats,
	battle_player: Player,
	battle_player_handler: PlayerHandler,
	battle_enemy_handler: EnemyHandler
) -> void:
	character = char_stats
	player = battle_player
	player_handler = battle_player_handler
	enemy_handler = battle_enemy_handler

	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)
	if not Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.connect(_on_player_hit)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)
	if not Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.connect(_on_player_turn_ended)


func _exit_tree() -> void:
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)
	if Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.disconnect(_on_player_hit)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
	if Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.disconnect(_on_player_turn_ended)


func _on_card_played(card: Card) -> void:
	if not card or not player:
		return

	if _has_tag(card, "兽群") or _has_tag(card, "兽系"):
		_add_status_to_player(BEAST_PACK_STATUS, 1)

	if _has_tag(card, "铸剑"):
		_add_status_to_player(FORGE_SWORD_STATUS, 1)

	if _has_tag(card, "金身"):
		_add_status_to_player(GOLD_BODY_STATUS, 1)

	if _has_tag(card, "血炼") and player.stats.health <= ceili(player.stats.max_health * 0.5):
		_add_status_to_player(MUSCLE_STATUS, 1)

	# 卡牌可能通过 ConfiguredStatusEffect(sha_qi) 叠煞气，延迟一帧确保已应用后再接管。
	if _is_demonic():
		_ensure_sha_qi_connected.call_deferred()


func _on_enemy_died(enemy: Enemy) -> void:
	if not enemy or not enemy.status_handler or not character:
		return

	var soul_mark_stacks := enemy.status_handler.get_status_stacks("soul_mark")
	if soul_mark_stacks <= 0:
		return

	character.heal(soul_mark_stacks * SOUL_MARK_HEAL_PER_STACK)


func _add_status_to_player(status_resource: Status, stacks: int) -> void:
	if not player or not player.status_handler or stacks <= 0:
		return

	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	player.status_handler.add_status(status)


func _has_tag(card: Card, tag: String) -> bool:
	return card.mechanic_tags.has(tag)


# ----------------------------- 煞气 / 天魔降世 -----------------------------

func _is_demonic() -> bool:
	if not character:
		return false
	# 战斗中的 character 是 duplicate()，resource_path 可能为空，回退到牌组路径判断。
	var path := character.resource_path
	if path.is_empty() and character.starting_deck:
		path = character.starting_deck.resource_path
	if path.is_empty() and character.draftable_cards:
		path = character.draftable_cards.resource_path
	return path.contains("demonic_cultivator")


func _on_player_hit() -> void:
	# 受到伤害（实际掉血）获得煞气。
	if not _is_demonic():
		return
	_add_status_to_player(SHA_QI_STATUS, SHA_QI_ON_HIT)
	_ensure_sha_qi_connected()


func _sha_qi_status() -> Status:
	if not player or not player.status_handler:
		return null
	return player.status_handler.get_status("sha_qi")


func _sha_qi_stacks() -> int:
	var status := _sha_qi_status()
	return status.stacks if status else 0


func _ensure_sha_qi_connected() -> void:
	# 卡牌给玩家叠煞气（ConfiguredStatusEffect）后，确保监听其变化以刷新阈值。
	var status := _sha_qi_status()
	if status and not status.status_changed.is_connected(_update_sha_qi_modifiers):
		status.status_changed.connect(_update_sha_qi_modifiers)
		_sha_qi_connected = true
	_update_sha_qi_modifiers()


func _ensure_modifier_values() -> void:
	if _mv_dealt_flat:
		return
	if not player or not player.modifier_handler:
		return
	var dealt := player.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var taken := player.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	if not dealt or not taken:
		return
	_mv_dealt_flat = ModifierValue.create_new_modifier("sha_qi_flat", ModifierValue.Type.FLAT)
	dealt.add_new_value(_mv_dealt_flat)
	_mv_dealt_mult = ModifierValue.create_new_modifier("sha_qi_mult", ModifierValue.Type.PERCENT_BASED)
	dealt.add_new_value(_mv_dealt_mult)
	_mv_taken_mult = ModifierValue.create_new_modifier("sha_qi_taken", ModifierValue.Type.PERCENT_BASED)
	taken.add_new_value(_mv_taken_mult)


func _update_sha_qi_modifiers() -> void:
	if not _is_demonic() or not player or not player.modifier_handler:
		return

	_ensure_modifier_values()
	if not _mv_dealt_flat:
		return

	var sha := _sha_qi_stacks()

	# 触发天魔降世（同一代价周期内只进入一次）
	if sha >= SHA_QI_HEAVENLY_THRESHOLD and not _heavenly_penalty_pending:
		_heavenly_active = true
		_heavenly_penalty_pending = true

	_mv_dealt_flat.flat_value = 1 if sha >= SHA_QI_FLAT_THRESHOLD else 0

	var mult := 0.0
	if _heavenly_active:
		mult = 2.0  # ×3
	elif sha >= SHA_QI_DOUBLE_THRESHOLD:
		mult = 1.0  # ×2
	_mv_dealt_mult.percent_value = mult
	_mv_taken_mult.percent_value = mult


func _on_player_turn_started() -> void:
	if not _is_demonic():
		return
	if _heavenly_penalty_pending:
		# 天魔降世代价：失去 50% 最大生命，煞气降至 5。
		var loss := floori(player.stats.max_health * 0.5)
		player.stats.health = maxi(player.stats.health - loss, 0)
		var status := _sha_qi_status()
		if status:
			status.stacks = SHA_QI_AFTER_HEAVENLY
		_heavenly_penalty_pending = false
		_heavenly_active = false
		_update_sha_qi_modifiers()
		if player.stats.health <= 0:
			Events.player_died.emit()


func _on_player_turn_ended() -> void:
	# 天魔降世的 ×3 仅持续本回合。
	if _heavenly_active:
		_heavenly_active = false
		_update_sha_qi_modifiers()
