class_name ConfiguredBlockEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return

	var block := get_modified_amount(card)
	if block <= 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = card.sound if card else null
	block_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "获得 %s 点护体。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
