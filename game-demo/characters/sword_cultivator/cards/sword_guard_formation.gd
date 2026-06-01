extends Card

const SWORD_GUARD_STATUS := preload("res://statuses/sword_guard.tres")

@export var guard_stacks := 2


func get_default_tooltip() -> String:
	return tooltip_text % guard_stacks


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % guard_stacks


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var tree := _get_tree_from_targets(targets)
	var player_targets := tree.get_nodes_in_group("player")

	var status_effect := StatusEffect.new()
	var guard := SWORD_GUARD_STATUS.duplicate()
	guard.stacks = guard_stacks
	status_effect.status = guard
	status_effect.execute(player_targets)


func _get_tree_from_targets(targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var player := scene_tree.get_first_node_in_group("player")
	return player.get_tree() if player else scene_tree


func _upgrade_values() -> void:
	guard_stacks = _upgrade_number(guard_stacks)
