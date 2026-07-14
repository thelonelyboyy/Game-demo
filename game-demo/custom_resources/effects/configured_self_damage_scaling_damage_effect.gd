class_name ConfiguredSelfDamageScalingDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var damage_per_life := 1
@export var max_bonus := 15
@export var target_mode := TargetMode.CARD_TARGETS


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var handler := _get_class_mechanic_handler()
	var self_damage := 0
	if handler and handler.has_method("get_self_damage_this_turn"):
		self_damage = handler.get_self_damage_this_turn()
	var bonus := mini(self_damage * damage_per_life, max_bonus)
	execute_damage(card, get_targets(card, targets, target_mode), get_modified_amount(card) + bonus, modifiers)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var handler := _get_class_mechanic_handler()
	var self_damage: int = 0
	if handler and handler.has_method("get_self_damage_this_turn"):
		self_damage = handler.get_self_damage_this_turn()
	var raw_total := get_modified_amount(card) + mini(self_damage * damage_per_life, max_bonus)
	var total := get_preview_damage_amount(raw_total, player_modifiers, enemy_modifiers)
	return "造成 %s 点伤害。本回合自损已提供 +%d 基础伤害（最多 +%d）。" % [
		total,
		mini(self_damage * damage_per_life, max_bonus),
		max_bonus,
	]


func upgrade_values() -> void:
	amount = _upgrade_number(amount)
	max_bonus = _upgrade_number(max_bonus)
