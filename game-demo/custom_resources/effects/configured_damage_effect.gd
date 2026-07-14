class_name ConfiguredDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var target_mode := TargetMode.CARD_TARGETS


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, target_mode)
	if final_targets.is_empty():
		return

	var damage := get_modified_amount(card, modifiers)
	if damage <= 0:
		return

	execute_damage(card, final_targets, damage, modifiers)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var value := get_preview_damage_amount(
		get_modified_amount(card, player_modifiers, enemy_modifiers),
		player_modifiers,
		enemy_modifiers
	)
	if not description_template.is_empty():
		return description_template.replace("{amount}", str(value)).replace("{bonus}", str(bonus_amount)).replace("{condition}", get_condition_description())

	if target_mode == TargetMode.ALL_ENEMIES:
		return "对所有敌人造成 %s 点伤害。" % value
	return "造成 %s 点伤害。" % value
