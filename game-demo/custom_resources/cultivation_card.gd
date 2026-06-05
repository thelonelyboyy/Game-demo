class_name CultivationCard
extends Card

const EXPOSED_STATUS = preload("res://statuses/exposed.tres")
const MUSCLE_STATUS = preload("res://statuses/muscle.tres")
const QI_FLOW_STATUS = preload("res://statuses/qi_flow.tres")
const FORGE_SWORD_STATUS = preload("res://statuses/forge_sword.tres")
const GOLD_BODY_STATUS = preload("res://statuses/gold_body.tres")
const SOUL_MARK_STATUS = preload("res://statuses/soul_mark.tres")
const SPIRIT_BEAST_STATUS = preload("res://statuses/spirit_beast.tres")
const BEAST_PACK_STATUS = preload("res://statuses/beast_pack.tres")

@export_group("Cultivation Effects")
@export var base_damage := 0
@export var base_block := 0
@export var cards_to_draw := 0
@export var muscle_stacks := 0
@export var qi_flow_stacks := 0
@export var exposed_duration := 0
@export var self_damage := 0
@export var forge_sword_stacks := 0
@export var consume_forge_for_damage := false
@export var gold_body_stacks := 0
@export var blood_refine_bonus_damage := 0
@export var soul_mark_stacks := 0
@export var spirit_beast_stacks := 0
@export var beast_pack_stacks := 0
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

	var player_targets: Array[Node] = tree.get_nodes_in_group("player")

	if self_damage > 0:
		var self_damage_effect := DamageEffect.new()
		self_damage_effect.amount = self_damage
		self_damage_effect.execute(player_targets)

	var effective_damage := get_spirit_root_modified_value(base_damage)
	effective_damage += _get_blood_refine_bonus(player_targets)
	effective_damage += _consume_forge_damage(player_targets)
	if effective_damage > 0:
		var damage_effect := DamageEffect.new()
		damage_effect.amount = modifiers.get_modified_value(effective_damage, Modifier.Type.DMG_DEALT)
		damage_effect.sound = sound
		damage_effect.execute(targets)

	var effective_exposed_duration := get_spirit_root_modified_value(exposed_duration)
	if effective_exposed_duration > 0:
		var exposed_effect := StatusEffect.new()
		var exposed := EXPOSED_STATUS.duplicate() as Status
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

	var effective_forge_stacks := get_spirit_root_modified_value(forge_sword_stacks)
	if effective_forge_stacks > 0:
		_apply_status_to_player(player_targets, FORGE_SWORD_STATUS, effective_forge_stacks)

	var effective_gold_body_stacks := get_spirit_root_modified_value(gold_body_stacks)
	if effective_gold_body_stacks > 0:
		_apply_status_to_player(player_targets, GOLD_BODY_STATUS, effective_gold_body_stacks)

	var effective_spirit_beast_stacks := get_spirit_root_modified_value(spirit_beast_stacks)
	if effective_spirit_beast_stacks > 0:
		_apply_status_to_player(player_targets, SPIRIT_BEAST_STATUS, effective_spirit_beast_stacks)

	var effective_beast_pack_stacks := get_spirit_root_modified_value(beast_pack_stacks)
	if effective_beast_pack_stacks > 0:
		_apply_status_to_player(player_targets, BEAST_PACK_STATUS, effective_beast_pack_stacks)

	var effective_soul_mark_stacks := get_spirit_root_modified_value(soul_mark_stacks)
	if effective_soul_mark_stacks > 0:
		_apply_status_to_targets(targets, SOUL_MARK_STATUS, effective_soul_mark_stacks)


func _build_tooltip(damage: int) -> String:
	var text := effect_text
	text = text.replace("{damage}", str(damage))
	text = text.replace("{block}", str(get_spirit_root_modified_value(base_block)))
	text = text.replace("{draw}", str(get_spirit_root_modified_value(cards_to_draw)))
	text = text.replace("{muscle}", str(get_spirit_root_modified_value(muscle_stacks)))
	text = text.replace("{qi}", str(get_spirit_root_modified_value(qi_flow_stacks)))
	text = text.replace("{exposed}", str(get_spirit_root_modified_value(exposed_duration)))
	text = text.replace("{self_damage}", str(self_damage))
	text = text.replace("{forge}", str(get_spirit_root_modified_value(forge_sword_stacks)))
	text = text.replace("{gold_body}", str(get_spirit_root_modified_value(gold_body_stacks)))
	text = text.replace("{blood_bonus}", str(blood_refine_bonus_damage))
	text = text.replace("{soul_mark}", str(get_spirit_root_modified_value(soul_mark_stacks)))
	text = text.replace("{spirit_beast}", str(get_spirit_root_modified_value(spirit_beast_stacks)))
	text = text.replace("{beast_pack}", str(get_spirit_root_modified_value(beast_pack_stacks)))
	return "[center][b]%s[/b]\n%s[/center]" % [get_display_name(), text]


func _get_tree_from_targets(targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	var scene_tree := Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null

	var player := scene_tree.get_first_node_in_group("player") as Node
	return player.get_tree() if player else scene_tree


func _apply_status_to_player(player_targets: Array[Node], status_resource: Status, stacks: int) -> void:
	var status_effect := StatusEffect.new()
	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	status_effect.status = status
	status_effect.execute(player_targets)


func _apply_status_to_targets(targets: Array[Node], status_resource: Status, stacks: int) -> void:
	var status_effect := StatusEffect.new()
	var status := status_resource.duplicate() as Status
	status.stacks = stacks
	status_effect.status = status
	status_effect.execute(targets)


func _get_blood_refine_bonus(player_targets: Array[Node]) -> int:
	if blood_refine_bonus_damage <= 0 or player_targets.is_empty():
		return 0

	var player := player_targets[0] as Player
	if not player or not player.stats:
		return 0

	if player.stats.health <= ceili(player.stats.max_health * 0.5):
		return blood_refine_bonus_damage
	return 0


func _consume_forge_damage(player_targets: Array[Node]) -> int:
	if not consume_forge_for_damage or player_targets.is_empty():
		return 0

	var player := player_targets[0] as Player
	if not player or not player.status_handler:
		return 0

	var forge_status := player.status_handler.get_status("forge_sword") as Status
	if not forge_status:
		return 0

	var bonus: int = forge_status.stacks
	forge_status.stacks = 0
	return bonus


func _upgrade_values() -> void:
	base_damage = _upgrade_number(base_damage)
	base_block = _upgrade_number(base_block)
	cards_to_draw = _upgrade_number(cards_to_draw)
	muscle_stacks = _upgrade_number(muscle_stacks)
	qi_flow_stacks = _upgrade_number(qi_flow_stacks)
	exposed_duration = _upgrade_number(exposed_duration)
	forge_sword_stacks = _upgrade_number(forge_sword_stacks)
	gold_body_stacks = _upgrade_number(gold_body_stacks)
	blood_refine_bonus_damage = _upgrade_number(blood_refine_bonus_damage)
	soul_mark_stacks = _upgrade_number(soul_mark_stacks)
	spirit_beast_stacks = _upgrade_number(spirit_beast_stacks)
	beast_pack_stacks = _upgrade_number(beast_pack_stacks)


func get_spirit_root_primary_value() -> int:
	var values := [
		get_spirit_root_modified_value(base_damage),
		get_spirit_root_modified_value(base_block),
		get_spirit_root_modified_value(cards_to_draw),
		get_spirit_root_modified_value(muscle_stacks),
		get_spirit_root_modified_value(qi_flow_stacks),
		get_spirit_root_modified_value(exposed_duration),
		get_spirit_root_modified_value(forge_sword_stacks),
		get_spirit_root_modified_value(gold_body_stacks),
		get_spirit_root_modified_value(soul_mark_stacks),
		get_spirit_root_modified_value(spirit_beast_stacks),
		get_spirit_root_modified_value(beast_pack_stacks),
	]
	var result := 0
	for value: int in values:
		result = maxi(result, value)
	return result
