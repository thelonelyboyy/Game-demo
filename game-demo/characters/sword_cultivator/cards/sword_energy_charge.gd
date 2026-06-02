extends Card

const ENERGY_CHARGE_STATUS := preload("res://statuses/energy_charge.tres")

@export var base_block := 4
@export var charge_stacks := 1


func get_default_tooltip() -> String:
	return tooltip_text % [get_spirit_root_modified_value(base_block), get_spirit_root_modified_value(charge_stacks)]


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % [get_spirit_root_modified_value(base_block), get_spirit_root_modified_value(charge_stacks)]


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var tree := _get_tree_from_targets(targets)
	var player_targets := tree.get_nodes_in_group("player")

	var block_effect := BlockEffect.new()
	block_effect.amount = get_spirit_root_modified_value(base_block)
	block_effect.sound = sound
	block_effect.execute(player_targets)

	var status_effect := StatusEffect.new()
	var charge := ENERGY_CHARGE_STATUS.duplicate()
	charge.stacks = get_spirit_root_modified_value(charge_stacks)
	status_effect.status = charge
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
	base_block = _upgrade_number(base_block)
	charge_stacks = _upgrade_number(charge_stacks)


func get_spirit_root_primary_value() -> int:
	return maxi(get_spirit_root_modified_value(base_block), get_spirit_root_modified_value(charge_stacks))
