class_name ClassMechanicHandler
extends Node

const FORGE_SWORD_STATUS = preload("res://statuses/forge_sword.tres")
const BEAST_PACK_STATUS = preload("res://statuses/beast_pack.tres")
const GOLD_BODY_STATUS = preload("res://statuses/gold_body.tres")
const MUSCLE_STATUS = preload("res://statuses/muscle.tres")
const SHA_QI_STATUS = preload("res://statuses/sha_qi.tres")
const SOUL_MARK_STATUS = preload("res://statuses/soul_mark.tres")
const DEBUG_CONSOLE_STATE := preload("res://custom_resources/debug_console_state.gd")

const SOUL_MARK_HEAL_PER_STACK := 1
const FLAME_DETONATE_DAMAGE_PER_STACK := 3   # 红·焚界引爆：每层魂印伤害（与主动引爆一致）

# 煞气阈值与天魔降世
const SHA_QI_ON_HIT := 1
const SHA_QI_FLAT_THRESHOLD := 3
const SHA_QI_DOUBLE_THRESHOLD := 6
const SHA_QI_HEAVENLY_THRESHOLD := 10
const SHA_QI_AFTER_HEAVENLY := 5

enum DemonicEngine {
	BLOOD_QI_GUARD,
	BLOODTHIRST,
	BLOOD_RECOMPENSE,
	SOUL_MARK_SENSE,
	SOUL_RITE,
	SOUL_FLAME_CYCLE,
	SOUL_ECHO,
	FLAME_CONTINUITY,
	FLAME_REFINING,
	SHA_NURTURE,
}

var character: CharacterStats
var player: Player
var player_handler: PlayerHandler
var enemy_handler: EnemyHandler

var _sha_qi_connected := false
var _heavenly_active := false           # 本回合处于天魔降世（×3）
var _heavenly_penalty_pending := false  # 下回合开始结算代价
var _flame_wheel := {}                  # 本回合焰轮里的魔焰颜色集合
var _flame_damage_bonus := 0            # 本回合魔焰共鸣伤害加成（黄·狂烬累加，回合切换清空）
var _last_flame_color := -1
var _demonic_engines := {}
var _self_damage_this_turn := 0
var _blood_recompense_triggered := false
var _bloodthirst_turn_bonus := 0
# 一次性创建、原地更新的 modifier 值（避免 remove_value 的 queue_free 延迟问题）
var _mv_dealt_flat: ModifierValue
var _mv_dealt_mult: ModifierValue
var _mv_taken_mult: ModifierValue
var _mv_bloodthirst_flat: ModifierValue


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

	# 让魔焰效果能通过组找到本处理器读取/更新焰轮
	if not is_in_group("class_mechanic"):
		add_to_group("class_mechanic")

	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)
	if not Events.player_hit.is_connected(_on_player_hit):
		Events.player_hit.connect(_on_player_hit)
	if not Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.connect(_on_player_self_damaged)
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
	if Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.disconnect(_on_player_self_damaged)
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
		if _engine_value(DemonicEngine.FLAME_REFINING) > 0 and _is_flame_card(card):
			reduce_flame_card_costs(_engine_value(DemonicEngine.FLAME_REFINING), card)
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


func _add_status_to_enemy(enemy: Enemy, status_resource: Status, stacks: int) -> void:
	if not enemy or not enemy.status_handler or stacks <= 0:
		return

	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	enemy.status_handler.add_status(status)


func _has_tag(card: Card, tag: String) -> bool:
	return card.mechanic_tags.has(tag)


func add_demonic_engine(engine: int, value: int = 1, threshold: int = 0) -> void:
	if not _is_demonic():
		return

	var state: Dictionary = _demonic_engines.get(engine, {"value": 0, "threshold": 0})
	state["value"] = int(state.get("value", 0)) + maxi(value, 0)
	if threshold > 0:
		state["threshold"] = threshold
	_demonic_engines[engine] = state


func modify_attack_damage(card: Card, target: Node, damage: int) -> int:
	if not _is_demonic() or not card or card.type != Card.Type.ATTACK:
		return damage

	var bonus := _engine_value(DemonicEngine.SOUL_MARK_SENSE)
	if bonus <= 0 or not target is Enemy:
		return damage

	var enemy := target as Enemy
	if enemy.status_handler and enemy.status_handler.get_status_stacks("soul_mark") > 0:
		return damage + bonus
	return damage


func notify_soul_mark_detonated(_card: Card, enemy: Enemy, consumed: int, modifiers: ModifierHandler) -> void:
	if not _is_demonic() or consumed <= 0:
		return

	var draw_count := _engine_value(DemonicEngine.SOUL_FLAME_CYCLE)
	if draw_count > 0 and player_handler:
		player_handler.draw_cards(draw_count)
	_apply_soul_echo(enemy, consumed, modifiers)


func notify_soul_mark_consumed(_card: Card, enemy: Enemy, consumed: int, modifiers: ModifierHandler) -> void:
	if not _is_demonic() or consumed <= 0:
		return
	_apply_soul_echo(enemy, consumed, modifiers)


func flame_color_count() -> int:
	return _flame_wheel.size()


func _engine_value(engine: int) -> int:
	var state: Dictionary = _demonic_engines.get(engine, {})
	return int(state.get("value", 0))


func _engine_threshold(engine: int, fallback: int = 0) -> int:
	var state: Dictionary = _demonic_engines.get(engine, {})
	return int(state.get("threshold", fallback))


func _apply_soul_echo(enemy: Enemy, consumed: int, modifiers: ModifierHandler) -> void:
	var per_stack := _engine_value(DemonicEngine.SOUL_ECHO)
	if per_stack <= 0 or consumed <= 0 or not is_instance_valid(enemy):
		return

	var damage := per_stack * consumed
	if modifiers:
		damage = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT)
	damage = DEBUG_CONSOLE_STATE.apply_next_dealt(damage)
	if damage <= 0:
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.execute([enemy])


# ----------------------------- 煞气 / 天魔降世 -----------------------------

func is_demonic() -> bool:
	return _is_demonic()


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


func _on_player_self_damaged(amount: int) -> void:
	if not _is_demonic() or amount <= 0:
		return

	_self_damage_this_turn += amount

	var guard := _engine_value(DemonicEngine.BLOOD_QI_GUARD)
	if guard > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = guard
		block_effect.execute([player])

	var bloodthirst := _engine_value(DemonicEngine.BLOODTHIRST)
	if bloodthirst > 0:
		_bloodthirst_turn_bonus += bloodthirst
		_set_bloodthirst_bonus(_bloodthirst_turn_bonus)

	var recompense := _engine_value(DemonicEngine.BLOOD_RECOMPENSE)
	var threshold := _engine_threshold(DemonicEngine.BLOOD_RECOMPENSE, 7)
	if recompense > 0 and not _blood_recompense_triggered and _self_damage_this_turn >= threshold:
		_blood_recompense_triggered = true
		_deal_fixed_damage_to_all_enemies(_self_damage_this_turn * recompense)


func _set_bloodthirst_bonus(amount: int) -> void:
	if not player or not player.modifier_handler:
		return
	var dealt := player.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	if not dealt:
		return
	if not _mv_bloodthirst_flat:
		_mv_bloodthirst_flat = ModifierValue.create_new_modifier("demonic_bloodthirst_turn", ModifierValue.Type.FLAT)
		dealt.add_new_value(_mv_bloodthirst_flat)
	_mv_bloodthirst_flat.flat_value = amount


func _reset_blood_turn_state() -> void:
	_self_damage_this_turn = 0
	_blood_recompense_triggered = false
	_bloodthirst_turn_bonus = 0
	_set_bloodthirst_bonus(0)


func _deal_fixed_damage_to_all_enemies(amount: int) -> void:
	if amount <= 0:
		return
	var tree := get_tree()
	if not tree:
		return
	var targets: Array[Node] = []
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			targets.append(enemy)
	if targets.is_empty():
		return
	var damage_effect := DamageEffect.new()
	damage_effect.amount = DEBUG_CONSOLE_STATE.apply_next_dealt(amount)
	damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	damage_effect.execute(targets)


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


func flame_other_color_count(color: int) -> int:
	var count := 0
	for c in _flame_wheel:
		if c != color:
			count += 1
	return count


func flame_add_color(color: int) -> void:
	_last_flame_color = color
	_flame_wheel[color] = true
	Events.flame_wheel_changed.emit(_flame_wheel.keys())


func _clear_flame_wheel() -> void:
	if _flame_wheel.is_empty():
		return
	_flame_wheel.clear()
	Events.flame_wheel_changed.emit([])


# ----------------------------- 魔焰色卡 rider -----------------------------

## 黄·狂烬：累加本回合魔焰共鸣伤害加成。
func add_flame_damage_bonus(amount: int) -> void:
	if amount > 0:
		_flame_damage_bonus += amount


func flame_damage_bonus() -> int:
	return _flame_damage_bonus


## 绿·镇煞：若煞气足够则消耗 n 点，返回是否消耗成功。
func consume_sha_qi(n: int) -> bool:
	if n <= 0:
		return true
	var status := _sha_qi_status()
	if not status or status.stacks < n:
		return false
	status.stacks -= n
	_update_sha_qi_modifiers()
	return true


## 蓝·灵涌：手牌中最多 count 张魔焰卡费用-1（排除正在打出的本牌）。
func reduce_flame_card_costs(count: int, exclude_card: Card = null) -> void:
	if count <= 0 or not player_handler or not player_handler.hand:
		return
	var reduced := 0
	for card_ui in player_handler.hand.get_children():
		if reduced >= count:
			break
		if not card_ui is CardUI:
			continue
		var c: Card = card_ui.card
		if c and c != exclude_card and c.cost > 0 and _is_flame_card(c):
			c.reduce_cost_for_turn(1)
			card_ui.card = c   # 触发 CardUI 重新渲染费用
			reduced += 1


## 红·焚界：引爆所有敌人的魂印（消耗全部层数，每层 3 伤，走玩家增伤）。
func detonate_all_soul_marks(modifiers: ModifierHandler) -> void:
	var tree := get_tree()
	if not tree:
		return
	for enemy in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Enemy):
			continue
		var sh = enemy.status_handler
		if not sh:
			continue
		var status: Status = sh.get_status("soul_mark")
		if not status or status.stacks <= 0:
			continue
		var consumed := status.stacks
		status.stacks = 0
		var damage := FLAME_DETONATE_DAMAGE_PER_STACK * consumed
		if modifiers:
			damage = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT)
		if damage <= 0:
			continue
		var de := DamageEffect.new()
		de.amount = damage
		de.execute([enemy])


func _is_flame_card(card: Card) -> bool:
	if not card is CultivationCard:
		return false
	for e in (card as CultivationCard).configured_effects:
		if e is ConfiguredFlameEffect:
			return true
	return false


func _on_player_turn_started() -> void:
	_clear_flame_wheel()
	_flame_damage_bonus = 0
	_reset_blood_turn_state()
	if not _is_demonic():
		return
	_restore_retained_flame_color()
	_apply_soul_rite()
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
	# 回合结束清空焰轮与焰伤加成。
	_clear_flame_wheel()
	_flame_damage_bonus = 0
	var sha_nurture := _engine_value(DemonicEngine.SHA_NURTURE)
	if _is_demonic() and sha_nurture > 0:
		_add_status_to_player(SHA_QI_STATUS, sha_nurture)
		_ensure_sha_qi_connected()
	_reset_blood_turn_state()
	# 天魔降世的 ×3 仅持续本回合。
	if _heavenly_active:
		_heavenly_active = false
		_update_sha_qi_modifiers()


func _restore_retained_flame_color() -> void:
	if _engine_value(DemonicEngine.FLAME_CONTINUITY) <= 0 or _last_flame_color < 0:
		return
	_flame_wheel[_last_flame_color] = true
	Events.flame_wheel_changed.emit(_flame_wheel.keys())


func _apply_soul_rite() -> void:
	var stacks := _engine_value(DemonicEngine.SOUL_RITE)
	if stacks <= 0:
		return
	var tree := get_tree()
	if not tree:
		return
	var enemies: Array[Enemy] = []
	for node in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Enemy:
			enemies.append(node)
	var picked := RNG.array_pick_random(enemies) as Enemy
	if picked:
		_add_status_to_enemy(picked, SOUL_MARK_STATUS, stacks)
