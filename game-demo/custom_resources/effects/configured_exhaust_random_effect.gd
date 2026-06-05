class_name ConfiguredExhaustRandomEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return

	var exhaust_count := get_modified_amount(card)
	if exhaust_count <= 0:
		return

	var exhaust_effect := ExhaustRandomEffect.new()
	exhaust_effect.amount = exhaust_count
	exhaust_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "弃掉 %s 张随机手牌。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
