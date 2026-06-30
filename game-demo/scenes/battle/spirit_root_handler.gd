class_name SpiritRootHandler
extends Node

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")
const TRUE_ESSENCE_STATUS := preload("res://statuses/true_essence.tres")
const FIRE_CHOICE := preload("res://custom_resources/spirit_root_fire_choice.gd")

var character: CharacterStats
var player_handler: PlayerHandler
var player: Player
var enemy_handler: EnemyHandler
var water_discount_pending := 0
var fire_choice_layer: CanvasLayer


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
	if character:
		character.reset_spirit_root_turn_flags()

	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.card_drawn.is_connected(_on_card_drawn):
		Events.card_drawn.connect(_on_card_drawn)
	if not Events.spirit_root_fire_choice_requested.is_connected(_on_fire_choice_requested):
		Events.spirit_root_fire_choice_requested.connect(_on_fire_choice_requested)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)
	if not Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.connect(_on_player_turn_ended)


func _exit_tree() -> void:
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.card_drawn.is_connected(_on_card_drawn):
		Events.card_drawn.disconnect(_on_card_drawn)
	if Events.spirit_root_fire_choice_requested.is_connected(_on_fire_choice_requested):
		Events.spirit_root_fire_choice_requested.disconnect(_on_fire_choice_requested)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
	if Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.disconnect(_on_player_turn_ended)


func _on_player_turn_started() -> void:
	water_discount_pending = 0
	if character:
		character.reset_spirit_root_turn_flags()


func _on_card_played(card: Card) -> void:
	if not _can_trigger(card):
		return

	if character.spirit_root == Card.Element.WOOD:
		character.mark_spirit_root_wood_played()
		return

	if character.spirit_root_perfect_triggered_this_turn:
		return

	match character.spirit_root:
		Card.Element.METAL:
			_apply_status_to_player(MUSCLE_STATUS, 1)
			character.mark_spirit_root_perfect_triggered()
		Card.Element.WATER:
			character.mark_spirit_root_perfect_triggered()
			water_discount_pending += 1
			player_handler.draw_cards(1)
		Card.Element.EARTH:
			_apply_status_to_player(TRUE_ESSENCE_STATUS, 1)
			character.mark_spirit_root_perfect_triggered()


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
	if not character.spirit_root_wood_played_this_turn or character.spirit_root_perfect_triggered_this_turn:
		return

	if character.health >= character.max_health:
		_apply_block_to_player(3)
	else:
		character.heal(3)
	character.mark_spirit_root_perfect_triggered()


func _can_trigger(card: Card) -> bool:
	return (
		character
		and character.is_spirit_root_complete()
		and card
		and card.element == character.spirit_root
	)


func _on_fire_choice_requested(choice) -> void:
	if not choice:
		return
	if not _can_trigger(choice.card):
		choice.resolve(FIRE_CHOICE.CHOICE_NONE)
		return
	if character.spirit_root != Card.Element.FIRE or choice.card.type != Card.Type.ATTACK:
		choice.resolve(FIRE_CHOICE.CHOICE_NONE)
		return
	if character.spirit_root_perfect_triggered_this_turn:
		choice.resolve(FIRE_CHOICE.CHOICE_NONE)
		return

	_show_fire_choice(choice)


func _show_fire_choice(choice) -> void:
	if fire_choice_layer:
		fire_choice_layer.queue_free()

	fire_choice_layer = CanvasLayer.new()
	fire_choice_layer.layer = 120
	add_child(fire_choice_layer)

	var blocker := Control.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	fire_choice_layer.add_child(blocker)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 180)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -90
	panel.offset_bottom = 90
	blocker.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "炎爆余波"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "选择本回合第一张火属性攻击牌的圆满效果"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	box.add_child(hint)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	box.add_child(buttons)

	var amplify_button := Button.new()
	amplify_button.text = "伤害 ×1.5"
	amplify_button.custom_minimum_size = Vector2(200, 54)
	amplify_button.pressed.connect(_resolve_fire_choice.bind(choice, FIRE_CHOICE.CHOICE_AMPLIFY))
	buttons.add_child(amplify_button)

	var splash_button := Button.new()
	splash_button.text = "余波伤及其余敌人"
	splash_button.custom_minimum_size = Vector2(240, 54)
	splash_button.pressed.connect(_resolve_fire_choice.bind(choice, FIRE_CHOICE.CHOICE_SPLASH))
	buttons.add_child(splash_button)

	amplify_button.grab_focus()


func _resolve_fire_choice(choice, selected_choice: int) -> void:
	if fire_choice_layer:
		fire_choice_layer.queue_free()
		fire_choice_layer = null
	character.mark_spirit_root_perfect_triggered()
	choice.resolve(selected_choice)


func _apply_status_to_player(status_resource: Status, stacks: int) -> void:
	var status_effect := StatusEffect.new()
	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	status_effect.status = status
	status_effect.execute([player])


func _apply_block_to_player(amount: int) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = amount
	block_effect.execute([player])


func _refresh_card_ui(card: Card) -> void:
	for card_ui: CardUI in player_handler.hand.get_children():
		if card_ui.card == card:
			card_ui.card = card
			return
