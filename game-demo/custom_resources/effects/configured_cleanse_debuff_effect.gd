class_name ConfiguredCleanseDebuffEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var player := final_targets[0] as Player
	if not player or not player.status_handler:
		return

	var removed := player.status_handler.remove_debuffs(maxi(amount, 0))
	if removed.is_empty():
		return
	Events.ui_notice_requested.emit("净化了 %s 项负面状态" % removed.size())


func get_description(card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if amount <= 0:
		return "移除自身所有负面状态。"
	return "移除自身至多 %s 项负面状态。" % get_modified_amount(card)
