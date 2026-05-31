extends Card

const BLEED_STATUS := preload("res://statuses/bleed.tres")

@export var base_damage := 6
@export var self_damage := 3
@export var bleed_duration := 2


func get_default_tooltip() -> String:
	return tooltip_text % [self_damage, base_damage, bleed_duration]


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_dmg := player_modifiers.get_modified_value(base_damage, Modifier.Type.DMG_DEALT)
	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(modified_dmg, Modifier.Type.DMG_TAKEN)
	return tooltip_text % [self_damage, modified_dmg, bleed_duration]


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var tree := _get_tree_from_targets(targets)
	var player_targets := tree.get_nodes_in_group("player")

	if self_damage > 0:
		var self_dmg_effect := DamageEffect.new()
		self_dmg_effect.amount = self_damage
		self_dmg_effect.execute(player_targets)

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)

	var status_effect := StatusEffect.new()
	var bleed := BLEED_STATUS.duplicate()
	bleed.duration = bleed_duration
	status_effect.status = bleed
	status_effect.execute(targets)


func _get_tree_from_targets(targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var player := scene_tree.get_first_node_in_group("player")
	return player.get_tree() if player else scene_tree
