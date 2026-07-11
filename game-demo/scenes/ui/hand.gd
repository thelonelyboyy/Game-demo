class_name Hand
extends Control

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")
const MAX_HAND_SIZE := 10
const CARD_SIZE := Vector2(224.0, 322.0)
const MAX_CARD_GAP := 172.0
const MIN_CARD_GAP := 92.0
const SIDE_SAFE_AREA := 720.0
const FAN_ROTATION := 7.0
const FAN_DROP := 38.0
const CENTER_LIFT := 62.0
# 手牌下沉量：过大时卡底描述会被屏幕边缘裁切。
const HAND_Y_OFFSET := 26.0
const HOVER_SCALE := 1.38
const HOVER_LIFT := 54.0
const HOVER_Z_INDEX := 1000
const LAYOUT_DURATION := 0.24
# 牌数变化（抽牌/打出/弃牌）引起的补位用弹簧曲线，比 hover 重排慢一点、带回弹。
const REFLOW_DURATION := 0.48
# 聚焦卡响应要比整体重排更快，配合回弹曲线让 hover 有"跳出来"的手感。
const FOCUS_DURATION := 0.15
# 聚焦卡放大后会盖住邻牌，两侧卡牌按与聚焦卡的距离让位。
const NEIGHBOR_PUSH := 46.0
const NEIGHBOR_PUSH_FALLOFF := 0.45

@export var player: Player
@export var char_stats: CharacterStats

var focused_card: CardUI
# 抽牌飞入起点（抽牌堆按钮中心的全局坐标），由 battle_ui 布局时更新；为零时新卡直接出现在手牌位。
var draw_origin_global := Vector2.ZERO
var _last_layout_count := -1


func _ready() -> void:
	resized.connect(_layout_cards)


func add_card(card: Card, use_draw_origin := true, origin_global := Vector2.ZERO) -> bool:
	if not card or is_full():
		return false
	var new_card_ui := CARD_UI_SCENE.instantiate() as CardUI
	add_child(new_card_ui)
	_prepare_card(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.player_modifiers = player.modifier_handler

	var spawn_origin := draw_origin_global if use_draw_origin else origin_global
	if spawn_origin != Vector2.ZERO:
		new_card_ui.position = spawn_origin - global_position - CARD_SIZE * 0.5
		new_card_ui.scale = Vector2.ONE * 0.3
		new_card_ui.rotation_degrees = -14.0
		new_card_ui.modulate = Color(1, 1, 1, 0.0)
		var fade := new_card_ui.create_tween()
		fade.tween_property(new_card_ui, "modulate:a", 1.0, 0.18)

	_layout_cards()
	return true


func is_full() -> bool:
	return get_child_count() >= MAX_HAND_SIZE


func available_slots() -> int:
	return maxi(MAX_HAND_SIZE - get_child_count(), 0)


func discard_card(card: CardUI, play_discard_animation := true) -> void:
	if focused_card == card:
		focused_card = null
	if play_discard_animation and card.card:
		Events.card_discarded.emit(card.card, card.get_global_rect().get_center())
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
	var base_y := size.y - CARD_SIZE.y + 4.0 + HAND_Y_OFFSET
	var middle := float(card_count - 1) * 0.5
	var divisor := maxf(middle, 1.0)

	var focus_index := cards.find(focused_card) if focused_card else -1
	var reflow := card_count != _last_layout_count
	_last_layout_count = card_count

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
		var is_focused := card_ui == focused_card

		if focus_index >= 0 and not is_focused:
			var distance := card_index - focus_index
			var push := NEIGHBOR_PUSH * pow(NEIGHBOR_PUSH_FALLOFF, absf(distance) - 1.0)
			target_position.x += push * signf(distance)

		if is_focused:
			target_position.y -= HOVER_LIFT
			target_rotation = 0.0
			target_scale = Vector2.ONE * HOVER_SCALE
			card_ui.z_index = HOVER_Z_INDEX
		else:
			card_ui.z_index = card_index

		var springy := reflow and not is_focused
		var duration := FOCUS_DURATION if is_focused else (REFLOW_DURATION if springy else LAYOUT_DURATION)
		card_ui.pivot_offset = Vector2(CARD_SIZE.x * 0.5, CARD_SIZE.y)
		if card_ui.tween and card_ui.tween.is_running():
			card_ui.tween.kill()
		card_ui.tween = create_tween().set_parallel(true) \
				.set_trans(Tween.TRANS_SPRING if springy else Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)
		card_ui.tween.tween_property(card_ui, "position", target_position, duration)
		card_ui.tween.tween_property(card_ui, "rotation_degrees", target_rotation, duration)
		if is_focused:
			card_ui.tween.tween_property(card_ui, "scale", target_scale, duration) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			card_ui.tween.tween_property(card_ui, "scale", target_scale, duration)


func _get_card_uis() -> Array[CardUI]:
	var cards: Array[CardUI] = []
	for child in get_children():
		if child is CardUI:
			cards.append(child)
	return cards
