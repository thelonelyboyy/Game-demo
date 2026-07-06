class_name HitEffect
extends Node2D

## 命中冲击特效：代码绘制的放射状冲击线 + 中心闪光，随进度外扩淡出后自毁。
## 挂在战斗世界层（世界坐标系），受击者被震动/释放也不影响特效播完。

const LIFETIME := 0.55
const DEFAULT_COLOR := Color(1.0, 0.86, 0.5, 0.95)

var _color := DEFAULT_COLOR
var _radius := 20.0
var _progress := 0.0
var _spokes: Array[Dictionary] = []


static func spawn(world_node: Node2D, radius := 20.0, color := DEFAULT_COLOR) -> void:
	if not world_node or not world_node.is_inside_tree():
		return
	var parent := _get_effect_parent(world_node)
	if not parent:
		return

	var effect := HitEffect.new()
	effect._color = color
	effect._radius = maxf(radius, 8.0)
	effect.z_index = 30
	parent.add_child(effect)
	effect.global_position = world_node.global_position
	effect._start()


static func _get_effect_parent(world_node: Node2D) -> Node2D:
	var parent := world_node.get_parent() as Node2D
	if not parent:
		return null

	if parent is EnemyHandler:
		var world_parent := parent.get_parent() as Node2D
		if world_parent:
			return world_parent

	return parent


func _init() -> void:
	for i in range(7):
		_spokes.append({
			"angle": randf_range(0.0, TAU),
			"length": randf_range(0.65, 1.15),
			"width": randf_range(1.2, 2.6),
		})


func _start() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, LIFETIME)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _progress
	var color := Color(_color.r, _color.g, _color.b, _color.a * fade)

	# 中心闪光只在前半段出现。
	if _progress < 0.45:
		var flash_alpha := (1.0 - _progress / 0.45) * 0.55
		draw_circle(Vector2.ZERO, _radius * (0.28 + 0.30 * _progress), Color(1, 1, 1, flash_alpha))

	for spoke in _spokes:
		var direction := Vector2.RIGHT.rotated(spoke.angle)
		var max_len: float = _radius * spoke.length
		var inner: float = max_len * _progress
		var outer: float = max_len * minf(0.45 + 0.75 * _progress, 1.0)
		if outer - inner < 0.5:
			continue
		draw_line(direction * inner, direction * outer, color, spoke.width * fade + 0.4, true)
