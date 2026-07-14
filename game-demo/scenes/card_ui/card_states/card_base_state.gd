extends CardState

var mouse_over_card := false


func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready

	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()

	card_ui.card_visuals.apply_normal_style()
	card_ui.reset_runtime_values()
	card_ui.reparent_requested.emit(card_ui)
	Events.tooltip_hide_requested.emit()


func on_gui_input(event: InputEvent) -> void:
	if card_ui.disabled:
		return

	if not card_ui.playable:
		# 费用不够时点牌：摇头 + 费用闪红，代替无反应。
		if mouse_over_card and event.is_action_pressed("left_mouse"):
			card_ui.shake_unplayable()
		return

	if mouse_over_card and event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)


func on_mouse_entered() -> void:
	mouse_over_card = true
	
	if not card_ui.playable or card_ui.disabled:
		return

	card_ui.card_visuals.apply_hover_style()
	if card_ui.parent and card_ui.parent.has_method("focus_card"):
		card_ui.parent.focus_card(card_ui)


func on_mouse_exited() -> void:
	mouse_over_card = false
	
	if not card_ui.playable or card_ui.disabled:
		return

	card_ui.card_visuals.apply_normal_style()
	if card_ui.parent and card_ui.parent.has_method("clear_card_focus"):
		card_ui.parent.clear_card_focus(card_ui)
	Events.tooltip_hide_requested.emit()
