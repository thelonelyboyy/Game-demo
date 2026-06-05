class_name ConfiguredDrawEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return

	var draw_count := get_modified_amount(card)
	if draw_count <= 0:
		return

	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = draw_count
	draw_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "抽 %s 张牌。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
