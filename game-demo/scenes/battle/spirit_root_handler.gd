class_name SpiritRootHandler
extends Node

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")
const TRUE_ESSENCE_STATUS := preload("res://statuses/true_essence.tres")

var character: CharacterStats
var player_handler: PlayerHandler
var player: Player
var enemy_handler: EnemyHandler
var water_discount_pending := 0
var earth_triggered_this_turn := false


func setup(
		new_character: CharacterStats,
		new_player_handler: PlayerHandler,
		new_player: Player,
		new_enemy_handler: EnemyHandler
) -> void:
	character = new_character
	player_handler = new_player_handler
	player = new_player
	enemy_handler = new_enemy_handler
	water_discount_pending = 0
	earth_triggered_this_turn = false

	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.card_drawn.is_connected(_on_card_drawn):
		Events.card_drawn.connect(_on_card_drawn)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)
	if not Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.connect(_on_player_turn_ended)


func _on_player_turn_started() -> void:
	earth_triggered_this_turn = false


func _on_card_played(card: Card) -> void:
	if not _can_trigger(card):
		return

	match character.spirit_root:
		Card.Element.FIRE:
			_trigger_fire(card)
		Card.Element.METAL:
			_apply_status_to_player(MUSCLE_STATUS, 1)
		Card.Element.WATER:
			water_discount_pending += 1
			player_handler.draw_cards(1)
		Card.Element.EARTH:
			if not earth_triggered_this_turn:
				earth_triggered_this_turn = true
				_apply_status_to_player(TRUE_ESSENCE_STATUS, 1)


func _on_card_drawn(card: Card) -> void:
	if water_discount_pending <= 0 or not card:
		return

	water_discount_pending -= 1
	card.reduce_cost_for_turn(1)
	_refresh_card_ui(card)


func _on_player_turn_ended() -> void:
	if not character or not character.is_spirit_root_complete():
		return
	if character.spirit_root != Card.Element.WOOD:
		return

	character.heal(character.count_cards_of_element(Card.Element.WOOD))


func _can_trigger(card: Card) -> bool:
	return (
		character
		and character.is_spirit_root_complete()
		and card
		and card.element == character.spirit_root
	)


func _trigger_fire(card: Card) -> void:
	var explosion_damage := ceili(card.get_spirit_root_primary_value() * 0.5)
	if explosion_damage <= 0:
		return

	var enemies: Array[Node] = []
	for enemy: Enemy in enemy_handler.get_children():
		enemies.append(enemy)

	var damage_effect := DamageEffect.new()
	damage_effect.amount = explosion_damage
	damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	damage_effect.execute(enemies)


func _apply_status_to_player(status_resource: Status, stacks: int) -> void:
	var status_effect := StatusEffect.new()
	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	status_effect.status = status
	status_effect.execute([player])


func _refresh_card_ui(card: Card) -> void:
	for card_ui: CardUI in player_handler.hand.get_children():
		if card_ui.card == card:
			card_ui.card = card
			return
