class_name ConfiguredDelayedEffect
extends "res://custom_resources/effects/card_effect.gd"

@export_range(1, 9) var delay_turns := 1
@export var target_mode := TargetMode.PLAYER
@export var delayed_effects: Array[Resource] = []


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card) or delayed_effects.is_empty():
		return
	var handler := _get_class_mechanic_handler()
	if handler and handler.has_method("schedule_delayed_effects"):
		handler.schedule_delayed_effects(card, delayed_effects, delay_turns, target_mode, targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var lines := PackedStringArray()
	for effect: Resource in delayed_effects:
		if not effect or not effect.has_method("get_description"):
			continue
		var line: String = effect.get_description(card, player_modifiers, enemy_modifiers)
		if not line.is_empty():
			lines.append(line)
	var timing := "下个回合开始时" if delay_turns == 1 else "%s 回合后开始时" % delay_turns
	return "%s：%s" % [timing, " ".join(lines)]


func get_primary_value(card: CultivationCard) -> int:
	var result := 0
	for effect: Resource in delayed_effects:
		if effect and effect.has_method("get_primary_value"):
			result = maxi(result, effect.get_primary_value(card))
	return result


func upgrade_values() -> void:
	for effect: Resource in delayed_effects:
		if effect and effect.has_method("upgrade_values"):
			effect.upgrade_values()


func grow_values(growth_amount: int) -> void:
	if not affected_by_card_growth or growth_amount <= 0:
		return
	for effect: Resource in delayed_effects:
		if effect and effect.has_method("grow_values"):
			effect.grow_values(growth_amount)
