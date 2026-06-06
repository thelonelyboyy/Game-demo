class_name LowHealthBonusDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var target_mode := TargetMode.CARD_TARGETS
@export_range(0.0, 1.0, 0.05) var health_ratio_threshold := 0.5


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, target_mode)
	if final_targets.is_empty():
		return

	var damage := get_modified_amount(card)
	if _is_player_at_low_health(card):
		damage += bonus_amount
	if damage <= 0:
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT) if modifiers else damage
	damage_effect.sound = card.sound if card else null
	damage_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		var text := description_template
		text = text.replace("{amount}", str(_get_modified_base_amount(card, player_modifiers, enemy_modifiers)))
		text = text.replace("{bonus}", str(bonus_amount))
		return text

	return "造成 %s 点伤害。半血以下额外造成 %s 点伤害。" % [
		_get_modified_base_amount(card, player_modifiers, enemy_modifiers),
		bonus_amount
	]


func get_primary_value(card: CultivationCard) -> int:
	return get_modified_amount(card) + bonus_amount


func upgrade_values() -> void:
	amount = _upgrade_number(amount)
	bonus_amount = _upgrade_number(bonus_amount)


func _get_modified_base_amount(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> int:
	var value := get_modified_amount(card)
	if player_modifiers:
		value = player_modifiers.get_modified_value(value, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		value = enemy_modifiers.get_modified_value(value, Modifier.Type.DMG_TAKEN)
	return value


func _is_player_at_low_health(card: CultivationCard) -> bool:
	var player := _get_player(card)
	if not player or not player.stats:
		return false
	return player.stats.health <= ceili(player.stats.max_health * health_ratio_threshold)
