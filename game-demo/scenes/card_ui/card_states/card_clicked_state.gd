extends CardState


func enter() -> void:
	if card_ui.parent and card_ui.parent.has_method("clear_card_focus"):
		card_ui.parent.clear_card_focus(card_ui)
	card_ui.drop_point_detector.monitoring = true
	card_ui.original_index = card_ui.get_index()
	card_ui.refresh_runtime_values()


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, CardState.State.DRAGGING)
