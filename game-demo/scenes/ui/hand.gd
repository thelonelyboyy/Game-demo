class_name Hand
extends Control

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")
const CARD_SIZE := Vector2(224.0, 322.0)
const MAX_CARD_GAP := 172.0
const MIN_CARD_GAP := 92.0
const SIDE_SAFE_AREA := 720.0
const FAN_ROTATION := 7.0
const FAN_DROP := 38.0
const CENTER_LIFT := 62.0
const HOVER_SCALE := 1.38
const HOVER_LIFT := 54.0
const HOVER_Z_INDEX := 1000
const LAYOUT_DURATION := 0.18

@export var player: Player
@export var char_stats: CharacterStats

var focused_card: CardUI


func _ready() -> void:
	resized.connect(_layout_cards)


func add_card(card: Card) -> void:
	var new_card_ui := CARD_UI_SCENE.instantiate() as CardUI
	add_child(new_card_ui)
	_prepare_card(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.player_modifiers = player.modifier_handler
	_layout_cards()


func discard_card(card: CardUI) -> void:
	if focused_card == card:
		focused_card = null
	card.queue_free()
	_layout_cards.call_deferred()


func enable_hand() -> void:
	for card: CardUI in get_children():
		card.disabled = false
		if card.is_hovered():
			card.card_state_machine.on_mouse_entered()


func disable_hand() -> void:
	focused_card = null
	for card: CardUI in get_children():
		card.disabled = true
	_layout_cards()


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	child.reparent(self)
	_prepare_card(child)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)
	_layout_cards.call_deferred()


func focus_card(card_ui: CardUI) -> void:
	if focused_card == card_ui:
		return

	focused_card = card_ui
	_layout_cards()


func clear_card_focus(card_ui: CardUI) -> void:
	if focused_card != card_ui:
		return

	focused_card = null
	_layout_cards()


func _prepare_card(card_ui: CardUI) -> void:
	card_ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card_ui.size = CARD_SIZE
	card_ui.custom_minimum_size = CARD_SIZE
	card_ui.pivot_offset = Vector2(CARD_SIZE.x * 0.5, CARD_SIZE.y)
	card_ui.parent = self


func _layout_cards() -> void:
	var cards := _get_card_uis()
	var card_count := cards.size()
	if card_count == 0:
		return

	var available_width := maxf(360.0, size.x - SIDE_SAFE_AREA)
	var card_gap := MAX_CARD_GAP
	if card_count > 1:
		card_gap = clampf((available_width - CARD_SIZE.x) / float(card_count - 1), MIN_CARD_GAP, MAX_CARD_GAP)

	var total_width := CARD_SIZE.x + card_gap * float(card_count - 1)
	var start_x := (size.x - total_width) * 0.5
	var base_y := size.y - CARD_SIZE.y + 4.0
	var middle := float(card_count - 1) * 0.5
	var divisor := maxf(middle, 1.0)

	for card_index in range(card_count):
		var card_ui := cards[card_index]
		var normalized_position := (float(card_index) - middle) / divisor
		var arc_drop := absf(normalized_position) * FAN_DROP
		var target_position := Vector2(
			start_x + card_gap * float(card_index),
			base_y + arc_drop - CENTER_LIFT
		)
		var target_rotation := normalized_position * FAN_ROTATION
		var target_scale := Vector2.ONE

		if card_ui == focused_card:
			target_position.y -= HOVER_LIFT
			target_rotation = 0.0
			target_scale = Vector2.ONE * HOVER_SCALE
			card_ui.z_index = HOVER_Z_INDEX
		else:
			card_ui.z_index = card_index

		card_ui.pivot_offset = Vector2(CARD_SIZE.x * 0.5, CARD_SIZE.y)
		if card_ui.tween and card_ui.tween.is_running():
			card_ui.tween.kill()
		card_ui.tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card_ui.tween.tween_property(card_ui, "position", target_position, LAYOUT_DURATION)
		card_ui.tween.tween_property(card_ui, "rotation_degrees", target_rotation, LAYOUT_DURATION)
		card_ui.tween.tween_property(card_ui, "scale", target_scale, LAYOUT_DURATION)


func _get_card_uis() -> Array[CardUI]:
	var cards: Array[CardUI] = []
	for child in get_children():
		if child is CardUI:
			cards.append(child)
	return cards
