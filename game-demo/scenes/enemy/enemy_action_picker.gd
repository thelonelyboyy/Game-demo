class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target
## 固定行为序列：非空时按回合循环执行子节点索引（确定性套路），忽略条件/权重。
@export var fixed_sequence: Array[int] = []

@onready var total_weight := 0.0

var _sequence_index := 0
var _last_chance_action: EnemyAction
var _chance_repeat_count := 0


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	setup_chances()


func get_action() -> EnemyAction:
	if not fixed_sequence.is_empty():
		return _get_fixed_sequence_action()

	var action := get_first_conditional_action()
	if action:
		_reset_chance_history()
		return action

	return get_chance_based_action()


func _get_fixed_sequence_action() -> EnemyAction:
	var child_index: int = fixed_sequence[_sequence_index % fixed_sequence.size()]
	_sequence_index += 1
	if child_index < 0 or child_index >= get_child_count():
		return null
	return get_child(child_index) as EnemyAction


func enter_phase_sequence(sequence: Array[int]) -> void:
	if sequence.is_empty():
		return
	fixed_sequence = sequence.duplicate()
	_sequence_index = 0
	_reset_chance_history()


func get_first_conditional_action() -> EnemyAction:
	# 固定序列敌人不走条件覆盖，保证套路确定。
	if not fixed_sequence.is_empty():
		return null
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CONDITIONAL:
			continue
			
		if action.is_performable():
			return action
	
	return null


func get_chance_based_action() -> EnemyAction:
	var all_actions: Array[EnemyAction] = []
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CHANCE_BASED or action.chance_weight <= 0.0:
			continue
		all_actions.append(action)
	if all_actions.is_empty():
		return null

	var eligible := all_actions.filter(
		func(action: EnemyAction):
			return action != _last_chance_action or _chance_repeat_count < action.max_consecutive_uses
	)
	if eligible.is_empty():
		eligible = all_actions

	var eligible_weight := 0.0
	for action: EnemyAction in eligible:
		eligible_weight += action.chance_weight
	var roll := RNG.instance.randf_range(0.0, eligible_weight)
	var selected := eligible.back() as EnemyAction
	for action: EnemyAction in eligible:
		roll -= action.chance_weight
		if roll <= 0.0:
			selected = action
			break
	_record_chance_action(selected)
	return selected


func _record_chance_action(action: EnemyAction) -> void:
	if action == _last_chance_action:
		_chance_repeat_count += 1
	else:
		_last_chance_action = action
		_chance_repeat_count = 1


func _reset_chance_history() -> void:
	_last_chance_action = null
	_chance_repeat_count = 0


func setup_chances() -> void:
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		
		total_weight += action.chance_weight
		action.accumulated_weight = total_weight


func _set_enemy(value: Enemy) -> void:
	enemy = value
	
	for action: EnemyAction in get_children():
		action.enemy = enemy


func _set_target(value: Node2D) -> void:
	target = value
	
	for action: EnemyAction in get_children():
		action.target = target
