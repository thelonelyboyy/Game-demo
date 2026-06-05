class_name PlayerStatusDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var status_id := "muscle"
@export var value_per_stack := 1
@export var target_mode := TargetMode.CARD_TARGETS


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, target_mode)
	if final_targets.is_empty():
		return

	var damage := _get_total_damage(card)
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
		text = text.replace("{bonus}", str(_get_modified_value_per_stack(card)))
		text = text.replace("{total}", str(_get_preview_damage(card, player_modifiers, enemy_modifiers)))
		text = text.replace("{status}", status_id)
		return text

	return "造成 %s 点伤害，每层 %s 额外造成 %s 点伤害。" % [
		_get_modified_base_amount(card, player_modifiers, enemy_modifiers),
		status_id,
		_get_modified_value_per_stack(card)
	]


func get_primary_value(card: CultivationCard) -> int:
	return _get_total_damage(card)


func upgrade_values() -> void:
	amount = _upgrade_number(amount)
	value_per_stack = _upgrade_number(value_per_stack)


func _get_total_damage(card: CultivationCard) -> int:
	return get_modified_amount(card) + (_get_player_status_stacks(card) * _get_modified_value_per_stack(card))


func _get_preview_damage(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> int:
	var value := _get_total_damage(card)
	if player_modifiers:
		value = player_modifiers.get_modified_value(value, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		value = enemy_modifiers.get_modified_value(value, Modifier.Type.DMG_TAKEN)
	return value


func _get_modified_base_amount(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> int:
	var value := get_modified_amount(card)
	if player_modifiers:
		value = player_modifiers.get_modified_value(value, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		value = enemy_modifiers.get_modified_value(value, Modifier.Type.DMG_TAKEN)
	return value


func _get_modified_value_per_stack(card: CultivationCard) -> int:
	if affected_by_spirit_root and card:
		return card.get_spirit_root_modified_value(value_per_stack)
	return value_per_stack


func _get_player_status_stacks(card: CultivationCard) -> int:
	var player := _get_player(card)
	if not player or not player.status_handler:
		return 0

	var status := player.status_handler.get_status(status_id) as Status
	return status.stacks if status else 0
