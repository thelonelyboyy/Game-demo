class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target
## 固定行为序列：非空时按回合循环执行子节点索引（确定性套路），忽略条件/权重。
@export var fixed_sequence: Array[int] = []

@onready var total_weight := 0.0

var _sequence_index := 0


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	setup_chances()


func get_action() -> EnemyAction:
	if not fixed_sequence.is_empty():
		return _get_fixed_sequence_action()

	var action := get_first_conditional_action()
	if action:
		return action

	return get_chance_based_action()


func _get_fixed_sequence_action() -> EnemyAction:
	var child_index: int = fixed_sequence[_sequence_index % fixed_sequence.size()]
	_sequence_index += 1
	if child_index < 0 or child_index >= get_child_count():
		return null
	return get_child(child_index) as EnemyAction


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
	var roll := RNG.instance.randf_range(0.0, total_weight)
	
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		
		if action.accumulated_weight > roll:
			return action
	
	return null


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
