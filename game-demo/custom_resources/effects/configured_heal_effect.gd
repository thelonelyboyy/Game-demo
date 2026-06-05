class_name ConfiguredHealEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	var heal_amount := get_modified_amount(card)
	if final_targets.is_empty() or heal_amount <= 0:
		return

	for target: Node in final_targets:
		if target is Player:
			target.stats.heal(heal_amount)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "回复 %s 点生命。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
