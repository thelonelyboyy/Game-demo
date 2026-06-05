extends CardState


func enter() -> void:
	var can_play_without_explicit_target := false
	if card_ui.targets.is_empty() and card_ui.can_auto_release_without_target():
		can_play_without_explicit_target = card_ui.prepare_auto_release_targets()
		if not can_play_without_explicit_target:
			return

	if card_ui.targets.is_empty() and not can_play_without_explicit_target:
		return

	var single_targeted := card_ui.card.is_single_targeted()
	var first_target_is_enemy := not card_ui.targets.is_empty() and card_ui.targets[0] is Enemy
	
	if single_targeted and not first_target_is_enemy:
		return
		
	Events.tooltip_hide_requested.emit()
	card_ui.play()


func post_enter() -> void:
	transition_requested.emit(self, CardState.State.BASE)
