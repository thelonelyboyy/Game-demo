class_name ClassMechanicHandler
extends Node

const FORGE_SWORD_STATUS = preload("res://statuses/forge_sword.tres")
const BEAST_PACK_STATUS = preload("res://statuses/beast_pack.tres")

const SOUL_MARK_HEAL_PER_STACK := 1

var character: CharacterStats
var player: Player
var player_handler: PlayerHandler
var enemy_handler: EnemyHandler


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


func _exit_tree() -> void:
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)


func _on_card_played(card: Card) -> void:
	if not card or not player:
		return

	if _has_tag(card, "兽群") or _has_tag(card, "兽系"):
		_add_status_to_player(BEAST_PACK_STATUS, 1)

	if _has_tag(card, "铸剑"):
		_add_status_to_player(FORGE_SWORD_STATUS, 1)


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
