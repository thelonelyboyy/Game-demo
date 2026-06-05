class_name RepeatCardEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var times := 2
@export var effects: Array[Resource] = []


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	for i in range(maxi(times, 0)):
		for effect in effects:
			if effect:
				effect.execute(card, targets, modifiers)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)

	var descriptions: PackedStringArray = []
	for effect in effects:
		if effect:
			var line := effect.get_description(card, player_modifiers, enemy_modifiers)
			if not line.is_empty():
				descriptions.append(line)
	return "重复 %s 次：%s" % [times, " ".join(descriptions)]


func upgrade_values() -> void:
	for effect in effects:
		if effect:
			effect.upgrade_values()
