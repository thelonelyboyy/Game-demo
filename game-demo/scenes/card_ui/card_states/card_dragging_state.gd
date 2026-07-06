extends CardState

const DRAG_MINIMUM_THRESHOLD := 0.05
const TARGETING_PREVIEW_SCALE := 1.22
const TARGETING_PREVIEW_Y := 18.0
# 拖拽惯性：卡牌跟随鼠标横向速度轻微倾斜，停下后回正。
const DRAG_TILT_PER_PIXEL := 0.14
const DRAG_TILT_MAX := 9.0
const DRAG_TILT_RECOVER_DURATION := 0.40

var minimum_drag_time_elapsed := false
var single_targeted := false
var _tilt_tween: Tween


func enter() -> void:
	single_targeted = card_ui.card.is_single_targeted()
	var hand := card_ui.parent
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)

	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()
	card_ui.rotation_degrees = 0.0
	card_ui.scale = Vector2.ONE
	
	card_ui.card_visuals.apply_drag_style()
	Events.card_drag_started.emit(card_ui)
	if single_targeted:
		card_ui.targets.clear()
		card_ui.scale = Vector2.ONE * TARGETING_PREVIEW_SCALE
		if hand:
			card_ui.animate_to_position(_get_targeting_preview_position(hand), 0.12)
		Events.card_aim_started.emit(card_ui)
	
	minimum_drag_time_elapsed = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(_on_drag_threshold_timeout)


func exit() -> void:
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	if single_targeted:
		Events.card_aim_ended.emit(card_ui)
	Events.card_drag_ended.emit(card_ui)


func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var cancel = event.is_action_pressed("right_mouse")
	var confirm = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")

	if mouse_motion and not single_targeted:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
		_apply_drag_tilt(event as InputEventMouseMotion)

	if cancel:
		card_ui.targets.clear()
		transition_requested.emit(self, CardState.State.BASE)
	elif minimum_drag_time_elapsed and confirm:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)


func _get_targeting_preview_position(hand: Control) -> Vector2:
	return hand.global_position + Vector2(
		(hand.size.x - card_ui.size.x * TARGETING_PREVIEW_SCALE) * 0.5,
		TARGETING_PREVIEW_Y
	)


func _on_drag_threshold_timeout() -> void:
	minimum_drag_time_elapsed = true


func _apply_drag_tilt(motion: InputEventMouseMotion) -> void:
	var tilt := clampf(
		card_ui.rotation_degrees + motion.relative.x * DRAG_TILT_PER_PIXEL,
		-DRAG_TILT_MAX,
		DRAG_TILT_MAX
	)
	card_ui.rotation_degrees = tilt

	# 每次移动重置回正补间：鼠标停下后卡牌自然摆回竖直。
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = card_ui.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tilt_tween.tween_property(card_ui, "rotation_degrees", 0.0, DRAG_TILT_RECOVER_DURATION)
