extends Card

const BLEED_STATUS := preload("res://statuses/bleed.tres")

@export var base_damage := 5
@export var bonus_damage := 5


func get_default_tooltip() -> String:
	return tooltip_text % base_damage


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(base_damage, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % modified_dmg


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var total_damage := base_damage

	for target in targets:
		if target is Enemy and _has_bleed(target):
			total_damage += bonus_damage
			break

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(total_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)


func _has_bleed(enemy: Enemy) -> bool:
	for status_ui in enemy.status_handler.get_children():
		if status_ui.status.id == "bleed":
			return true
	return false


func _upgrade_values() -> void:
	base_damage = _upgrade_number(base_damage)
	bonus_damage = _upgrade_number(bonus_damage)
