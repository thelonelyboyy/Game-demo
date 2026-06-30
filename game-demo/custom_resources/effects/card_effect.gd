class_name CardEffect
extends Resource

const DEBUG_CONSOLE_STATE := preload("res://custom_resources/debug_console_state.gd")

enum TargetMode {CARD_TARGETS, PLAYER, ALL_ENEMIES, EVERYONE}
enum ConditionType {ALWAYS, SELECTED_SPIRIT_ROOT, HAS_MECHANIC_TAG, CARD_TYPE, PLAYER_HAS_STATUS}

@export_group("Value")
@export var amount := 0
@export var affected_by_spirit_root := true

@export_group("Condition")
@export var require_condition := false
@export var condition_type := ConditionType.ALWAYS
@export var condition_tag := ""
@export var condition_card_type := Card.Type.ATTACK
@export var condition_status_id := ""
@export var bonus_amount := 0

@export_group("Description")
@export_multiline var description_template := ""


func execute(_card: CultivationCard, _targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if description_template.is_empty():
		return ""

	var value := get_modified_amount(card, player_modifiers, enemy_modifiers)
	var text := description_template
	text = text.replace("{amount}", str(value))
	text = text.replace("{bonus}", str(bonus_amount))
	text = text.replace("{condition}", get_condition_description())
	return text


func get_primary_value(card: CultivationCard) -> int:
	return get_modified_amount(card)


func upgrade_values() -> void:
	amount = _upgrade_number(amount)
	bonus_amount = _upgrade_number(bonus_amount)


func get_modified_amount(card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> int:
	var value := amount
	if affected_by_spirit_root and card:
		value = card.get_spirit_root_modified_value(value)
	if _condition_matches(card):
		value += bonus_amount
	return value


func can_execute(card: CultivationCard) -> bool:
	return not require_condition or _condition_matches(card)


func get_targets(card: CultivationCard, original_targets: Array[Node], mode: TargetMode) -> Array[Node]:
	var tree := _get_tree(card, original_targets)
	if not tree:
		return original_targets

	match mode:
		TargetMode.PLAYER:
			return tree.get_nodes_in_group("player")
		TargetMode.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		TargetMode.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return original_targets


func execute_damage(card: CultivationCard, final_targets: Array[Node], damage: int, modifiers: ModifierHandler) -> void:
	if not card or final_targets.is_empty() or damage <= 0:
		return

	var fire_choice := card.consume_spirit_root_fire_choice()
	if fire_choice == Card.SPIRIT_ROOT_FIRE_CHOICE.CHOICE_AMPLIFY:
		damage = ceili(damage * 1.5)

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT) if modifiers else damage
	damage_effect.amount = DEBUG_CONSOLE_STATE.apply_next_dealt(damage_effect.amount)
	damage_effect.sound = card.sound
	var main_target := final_targets[0]
	var main_target_actual_damage := _preview_actual_damage(main_target, damage_effect.amount, damage_effect.receiver_modifier_type)
	damage_effect.execute(final_targets)
	if fire_choice == Card.SPIRIT_ROOT_FIRE_CHOICE.CHOICE_SPLASH:
		_execute_fire_splash(main_target, main_target_actual_damage)


func get_condition_description() -> String:
	match condition_type:
		ConditionType.SELECTED_SPIRIT_ROOT:
			return "本牌元素与所选灵根一致"
		ConditionType.HAS_MECHANIC_TAG:
			return "拥有机制标签：%s" % condition_tag
		ConditionType.CARD_TYPE:
			return "卡牌类型匹配"
		ConditionType.PLAYER_HAS_STATUS:
			return "拥有状态：%s" % condition_status_id
		_:
			return "无条件"


func _condition_matches(card: CultivationCard) -> bool:
	match condition_type:
		ConditionType.ALWAYS:
			return true
		ConditionType.SELECTED_SPIRIT_ROOT:
			return card and card.is_selected_spirit_root_element()
		ConditionType.HAS_MECHANIC_TAG:
			return card and card.mechanic_tags.has(condition_tag)
		ConditionType.CARD_TYPE:
			return card and card.type == condition_card_type
		ConditionType.PLAYER_HAS_STATUS:
			var player := _get_player(card)
			return player and player.status_handler and player.status_handler.get_status(condition_status_id)
		_:
			return false


func _get_tree(card: CultivationCard, targets: Array[Node]) -> SceneTree:
	if not targets.is_empty() and targets[0]:
		return targets[0].get_tree()

	if card:
		var scene_tree := Engine.get_main_loop() as SceneTree
		if scene_tree:
			return scene_tree

	return null


func _get_player(card: CultivationCard) -> Player:
	var tree := _get_tree(card, [])
	if not tree:
		return null
	return tree.get_first_node_in_group("player") as Player


func _execute_fire_splash(main_target: Node, main_target_actual_damage: int) -> void:
	if not main_target or main_target_actual_damage <= 0:
		return

	var splash_amount := ceili(main_target_actual_damage * 0.5)
	if splash_amount <= 0:
		return

	var tree := main_target.get_tree()
	if not tree:
		return

	var splash_targets: Array[Node] = []
	for enemy: Node in tree.get_nodes_in_group("enemies"):
		if enemy != main_target:
			splash_targets.append(enemy)
	if splash_targets.is_empty():
		return

	var splash_effect := DamageEffect.new()
	splash_effect.amount = splash_amount
	splash_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
	splash_effect.execute(splash_targets)


func _preview_actual_damage(target: Node, incoming_damage: int, receiver_modifier_type: Modifier.Type) -> int:
	if not target or incoming_damage <= 0:
		return 0

	var modified_damage := incoming_damage
	var target_modifiers = target.get("modifier_handler")
	if target_modifiers and receiver_modifier_type != Modifier.Type.NO_MODIFIER:
		modified_damage = target_modifiers.get_modified_value(incoming_damage, receiver_modifier_type)

	var target_stats = target.get("stats")
	if target_stats:
		return maxi(modified_damage - target_stats.block, 0)
	return modified_damage


func _upgrade_number(value: int) -> int:
	if value <= 0:
		return value
	return ceili(value * 1.5)
