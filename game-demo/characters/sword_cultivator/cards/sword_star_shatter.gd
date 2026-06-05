extends Card

const BLEED_STATUS := preload("res://statuses/bleed.tres")

@export var base_damage := 5
@export var bonus_damage := 5


func get_default_tooltip() -> String:
	return tooltip_text % [
		get_spirit_root_modified_value(base_damage),
		get_spirit_root_modified_value(bonus_damage)
	]


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(get_spirit_root_modified_value(base_damage), Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % [
		modified_dmg,
		get_spirit_root_modified_value(bonus_damage)
	]


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var total_damage := get_spirit_root_modified_value(base_damage)

	for hit_target in targets:
		if hit_target is Enemy and _has_bleed(hit_target):
			total_damage += get_spirit_root_modified_value(bonus_damage)
			break
	total_damage += _consume_forge_sword()

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(total_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)


func _has_bleed(enemy: Enemy) -> bool:
	for status_ui in enemy.status_handler.get_children():
		if status_ui.status.id == "bleed":
			return true
	return false


func _consume_forge_sword() -> int:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return 0

	var player := scene_tree.get_first_node_in_group("player") as Player
	if not player:
		return 0

	var forge_status := player.status_handler.get_status("forge_sword") as Status
	if not forge_status:
		return 0

	var bonus: int = forge_status.stacks
	forge_status.stacks = 0
	return bonus


func _upgrade_values() -> void:
	base_damage = _upgrade_number(base_damage)
	bonus_damage = _upgrade_number(bonus_damage)


func get_spirit_root_primary_value() -> int:
	return get_spirit_root_modified_value(base_damage)
