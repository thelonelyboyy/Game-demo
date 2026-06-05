class_name ConfiguredManaEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	var mana_amount := get_modified_amount(card)
	if final_targets.is_empty() or mana_amount <= 0:
		return

	var player := final_targets[0] as Player
	if player and player.stats is CharacterStats:
		player.stats.mana += mana_amount


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "获得 %s 点灵力。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
