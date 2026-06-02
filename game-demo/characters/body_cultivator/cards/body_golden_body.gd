extends Card

@export var base_block := 5
@export var bonus_per_muscle := 2


func get_default_tooltip() -> String:
	var total := _calculate_total_block()
	return tooltip_text % [get_spirit_root_modified_value(base_block), total]


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	var total := _calculate_total_block()
	return tooltip_text % [get_spirit_root_modified_value(base_block), total]


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var tree := _get_tree_from_targets(targets)
	var player_targets := tree.get_nodes_in_group("player")

	var total_block := _calculate_total_block()
	var block_effect := BlockEffect.new()
	block_effect.amount = total_block
	block_effect.sound = sound
	block_effect.execute(player_targets)


func _calculate_total_block() -> int:
	var muscle_stacks := _get_muscle_stacks()
	return get_spirit_root_modified_value(base_block) + (muscle_stacks * get_spirit_root_modified_value(bonus_per_muscle))


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


func _get_tree_from_targets(targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var player := scene_tree.get_first_node_in_group("player")
	return player.get_tree() if player else scene_tree


func _upgrade_values() -> void:
	base_block = _upgrade_number(base_block)
	bonus_per_muscle = _upgrade_number(bonus_per_muscle)


func get_spirit_root_primary_value() -> int:
	return _calculate_total_block()
