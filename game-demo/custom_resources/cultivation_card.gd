class_name CultivationCard
extends Card

const EXPOSED_STATUS = preload("res://statuses/exposed.tres")
const MUSCLE_STATUS = preload("res://statuses/muscle.tres")
const QI_FLOW_STATUS = preload("res://statuses/qi_flow.tres")

@export_group("Cultivation Effects")
@export var base_damage := 0
@export var base_block := 0
@export var cards_to_draw := 0
@export var muscle_stacks := 0
@export var qi_flow_stacks := 0
@export var exposed_duration := 0
@export var self_damage := 0
@export_multiline var effect_text := ""


func get_default_tooltip() -> String:
	return _build_tooltip(get_spirit_root_modified_value(base_damage))


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var modified_damage := get_spirit_root_modified_value(base_damage)
	if base_damage > 0 and player_modifiers:
		modified_damage = player_modifiers.get_modified_value(modified_damage, Modifier.Type.DMG_DEALT)

	if modified_damage > 0 and enemy_modifiers:
		modified_damage = enemy_modifiers.get_modified_value(modified_damage, Modifier.Type.DMG_TAKEN)

	return _build_tooltip(modified_damage)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var tree := _get_tree_from_targets(targets)
	if not tree:
		return

	var player_targets := tree.get_nodes_in_group("player")

	if self_damage > 0:
		var self_damage_effect := DamageEffect.new()
		self_damage_effect.amount = self_damage
		self_damage_effect.execute(player_targets)

	var effective_damage := get_spirit_root_modified_value(base_damage)
	if effective_damage > 0:
		var damage_effect := DamageEffect.new()
		damage_effect.amount = modifiers.get_modified_value(effective_damage, Modifier.Type.DMG_DEALT)
		damage_effect.sound = sound
		damage_effect.execute(targets)

	var effective_exposed_duration := get_spirit_root_modified_value(exposed_duration)
	if effective_exposed_duration > 0:
		var exposed_effect := StatusEffect.new()
		var exposed := EXPOSED_STATUS.duplicate()
		exposed.duration = effective_exposed_duration
		exposed_effect.status = exposed
		exposed_effect.execute(targets)

	var effective_block := get_spirit_root_modified_value(base_block)
	if effective_block > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = effective_block
		block_effect.sound = sound
		block_effect.execute(player_targets)

	var effective_cards_to_draw := get_spirit_root_modified_value(cards_to_draw)
	if effective_cards_to_draw > 0:
		var draw_effect := CardDrawEffect.new()
		draw_effect.cards_to_draw = effective_cards_to_draw
		draw_effect.execute(player_targets)

	var effective_muscle_stacks := get_spirit_root_modified_value(muscle_stacks)
	if effective_muscle_stacks > 0:
		_apply_status_to_player(player_targets, MUSCLE_STATUS, effective_muscle_stacks)

	var effective_qi_flow_stacks := get_spirit_root_modified_value(qi_flow_stacks)
	if effective_qi_flow_stacks > 0:
		_apply_status_to_player(player_targets, QI_FLOW_STATUS, effective_qi_flow_stacks)


func _build_tooltip(damage: int) -> String:
	var text := effect_text
	text = text.replace("{damage}", str(damage))
	text = text.replace("{block}", str(get_spirit_root_modified_value(base_block)))
	text = text.replace("{draw}", str(get_spirit_root_modified_value(cards_to_draw)))
	text = text.replace("{muscle}", str(get_spirit_root_modified_value(muscle_stacks)))
	text = text.replace("{qi}", str(get_spirit_root_modified_value(qi_flow_stacks)))
	text = text.replace("{exposed}", str(get_spirit_root_modified_value(exposed_duration)))
	text = text.replace("{self_damage}", str(self_damage))
	return "[center][b]%s[/b]\n%s[/center]" % [get_display_name(), text]


func _get_tree_from_targets(targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var player := scene_tree.get_first_node_in_group("player")
	return player.get_tree() if player else scene_tree


func _apply_status_to_player(player_targets: Array[Node], status_resource: Status, stacks: int) -> void:
	var status_effect := StatusEffect.new()
	var status := status_resource.duplicate()
	status.stacks = stacks
	status_effect.status = status
	status_effect.execute(player_targets)


func _upgrade_values() -> void:
	base_damage = _upgrade_number(base_damage)
	base_block = _upgrade_number(base_block)
	cards_to_draw = _upgrade_number(cards_to_draw)
	muscle_stacks = _upgrade_number(muscle_stacks)
	qi_flow_stacks = _upgrade_number(qi_flow_stacks)
	exposed_duration = _upgrade_number(exposed_duration)


func get_spirit_root_primary_value() -> int:
	var values := [
		get_spirit_root_modified_value(base_damage),
		get_spirit_root_modified_value(base_block),
		get_spirit_root_modified_value(cards_to_draw),
		get_spirit_root_modified_value(muscle_stacks),
		get_spirit_root_modified_value(qi_flow_stacks),
		get_spirit_root_modified_value(exposed_duration),
	]
	var result := 0
	for value: int in values:
		result = maxi(result, value)
	return result
