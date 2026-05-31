extends Card

@export var base_damage := 6
@export var bonus_per_muscle := 2


func get_default_tooltip() -> String:
	var total := _calculate_total_damage()
	return tooltip_text % [base_damage, total]


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var total := _calculate_total_damage()
	total = player_modifiers.get_modified_value(total, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		total = enemy_modifiers.get_modified_value(total, Modifier.Type.DMG_TAKEN)
	return tooltip_text % [base_damage, total]


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var total_damage := _calculate_total_damage()
	total_damage = modifiers.get_modified_value(total_damage, Modifier.Type.DMG_DEALT)

	var damage_effect := DamageEffect.new()
	damage_effect.amount = total_damage
	damage_effect.sound = sound
	damage_effect.execute(targets)


func _calculate_total_damage() -> int:
	var muscle_stacks := _get_muscle_stacks()
	return base_damage + (muscle_stacks * bonus_per_muscle)


func _get_muscle_stacks() -> int:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return 0

	var player := scene_tree.get_first_node_in_group("player")
	if not player:
		return 0

	for status_ui in player.status_handler.get_children():
		if status_ui.status.id == "muscle":
			return status_ui.status.stacks

	return 0
