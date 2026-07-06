class_name ConfiguredXCostDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var target_mode := TargetMode.CARD_TARGETS
@export var damage_per_mana := 1


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var x_paid := card.get_x_cost_paid() if card else 0
	var damage := x_paid * damage_per_mana
	if affected_by_spirit_root and card:
		damage = card.get_spirit_root_modified_value(damage)
	if damage <= 0:
		return

	execute_damage(card, get_targets(card, targets, target_mode), damage, modifiers)


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return description_template
	var target_text := "全体敌人" if target_mode == TargetMode.ALL_ENEMIES else "目标"
	return "消耗所有灵气，每点对%s造成 %d 点伤害。" % [target_text, damage_per_mana]


func get_primary_value(_card: CultivationCard) -> int:
	return damage_per_mana
