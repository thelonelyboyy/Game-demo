class_name TargetStatusBonusDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var status_id := "bleed"
@export var target_mode := TargetMode.CARD_TARGETS
@export var consumed_status_id := ""
@export var consume_all := true
@export var max_stacks_to_consume := 1
@export var value_per_consumed_stack := 1


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, target_mode)
	if final_targets.is_empty():
		return

	var damage := get_modified_amount(card)
	if _any_target_has_status(final_targets):
		damage += _get_modified_bonus_amount(card)
	damage += _consume_status_value(card)
	if damage <= 0:
		return

	execute_damage(card, final_targets, damage, modifiers)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		var text := description_template
		text = text.replace("{amount}", str(_get_modified_base_amount(card, player_modifiers, enemy_modifiers)))
		text = text.replace("{bonus}", str(_get_modified_bonus_amount(card)))
		text = text.replace("{status}", status_id)
		text = text.replace("{consume_value}", str(value_per_consumed_stack))
		text = text.replace("{consumed_status}", consumed_status_id)
		return text

	return "造成 %s 点伤害。若目标有 %s，额外造成 %s 点伤害。" % [
		_get_modified_base_amount(card, player_modifiers, enemy_modifiers),
		status_id,
		_get_modified_bonus_amount(card)
	]


func get_primary_value(card: CultivationCard) -> int:
	return get_modified_amount(card)


func upgrade_values() -> void:
	amount = _upgrade_number(amount)
	bonus_amount = _upgrade_number(bonus_amount)


func _any_target_has_status(targets: Array[Node]) -> bool:
	for target: Node in targets:
		var status_handler: StatusHandler
		if target is Enemy:
			status_handler = (target as Enemy).status_handler
		elif target is Player:
			status_handler = (target as Player).status_handler

		if status_handler and status_handler.get_status(status_id):
			return true
	return false


func _get_modified_base_amount(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> int:
	var value := get_modified_amount(card)
	if player_modifiers:
		value = player_modifiers.get_modified_value(value, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		value = enemy_modifiers.get_modified_value(value, Modifier.Type.DMG_TAKEN)
	return value


func _get_modified_bonus_amount(card: CultivationCard) -> int:
	if affected_by_spirit_root and card:
		return card.get_spirit_root_modified_value(bonus_amount)
	return bonus_amount


func _consume_status_value(card: CultivationCard) -> int:
	if consumed_status_id.is_empty():
		return 0

	var player := _get_player(card)
	if not player or not player.status_handler:
		return 0

	var status := player.status_handler.get_status(consumed_status_id) as Status
	if not status or status.stacks <= 0:
		return 0

	var consumed := status.stacks if consume_all else mini(status.stacks, max_stacks_to_consume)
	status.stacks -= consumed
	return consumed * value_per_consumed_stack
