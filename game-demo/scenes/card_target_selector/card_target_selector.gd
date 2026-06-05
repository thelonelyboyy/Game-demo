extends Node2D

const ARC_POINTS := 8
const ARROW_COLOR := Color(0.88, 0.04, 0.02, 0.88)
const ARROW_SHADOW_COLOR := Color(0.12, 0, 0, 0.58)

@onready var area_2d: Area2D = $Area2D
@onready var card_arc: Line2D = $CanvasLayer/CardArc

var current_card: CardUI
var targeting := false
var arrow_shadow: Line2D
var arrow_head: Polygon2D


func _ready() -> void:
	_setup_arrow_visuals()
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)


func _process(_delta: float) -> void:
	if not targeting:
		return

	area_2d.position = get_local_mouse_position()
	var points := _get_points()
	arrow_shadow.points = points
	card_arc.points = points
	_update_arrow_head(points)


func _get_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var start := _get_card_anchor_position()
	var target := _get_target_position()
	var distance := (target - start)
	
	for i in range(ARC_POINTS):
		var t := (1.0 / ARC_POINTS) * i
		var x := start.x + (distance.x / ARC_POINTS) * i
		var y := start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x, y))
	
	points.append(target)
	
	return points


func _get_card_anchor_position() -> Vector2:
	var card_size := current_card.size * current_card.scale
	return current_card.global_position + Vector2(card_size.x * 0.5, card_size.y * 0.22)


func _get_target_position() -> Vector2:
	var enemy := _get_current_enemy_target()
	if enemy:
		if enemy.has_method("get_target_anchor_global_position"):
			return enemy.get_target_anchor_global_position()
		return enemy.global_position

	return get_local_mouse_position()


func _get_current_enemy_target() -> Enemy:
	if not current_card:
		return null

	for target in current_card.targets:
		if target is Enemy:
			return target
	return null


func ease_out_cubic(number : float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)


func _on_card_aim_started(card: CardUI) -> void:
	if not card.card.is_single_targeted():
		return
	
	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true
	current_card = card
	current_card.targets.clear()
	arrow_shadow.show()
	card_arc.show()
	arrow_head.show()


func _on_card_aim_ended(_card: CardUI) -> void:
	targeting = false
	arrow_shadow.clear_points()
	card_arc.clear_points()
	arrow_shadow.hide()
	card_arc.hide()
	arrow_head.hide()
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_card = null


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	
	if not current_card.targets.has(area):
		current_card.targets.append(area)
		current_card.request_tooltip()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	
	current_card.targets.erase(area)
	current_card.request_tooltip()


func _setup_arrow_visuals() -> void:
	card_arc.width = 22.0
	card_arc.default_color = ARROW_COLOR
	card_arc.antialiased = true
	card_arc.hide()

	arrow_shadow = Line2D.new()
	arrow_shadow.name = "ArrowShadow"
	arrow_shadow.width = 30.0
	arrow_shadow.default_color = ARROW_SHADOW_COLOR
	arrow_shadow.antialiased = true
	arrow_shadow.width_curve = card_arc.width_curve
	arrow_shadow.hide()
	card_arc.get_parent().add_child(arrow_shadow)
	card_arc.get_parent().move_child(arrow_shadow, card_arc.get_index())

	arrow_head = Polygon2D.new()
	arrow_head.name = "ArrowHead"
	arrow_head.color = ARROW_COLOR
	arrow_head.polygon = PackedVector2Array([
		Vector2(0.0, -25.0),
		Vector2(62.0, 0.0),
		Vector2(0.0, 25.0),
		Vector2(14.0, 0.0),
	])
	arrow_head.hide()
	card_arc.get_parent().add_child(arrow_head)


func _update_arrow_head(points: PackedVector2Array) -> void:
	if points.size() < 2:
		arrow_head.hide()
		return

	var target := points[points.size() - 1]
	var previous := points[points.size() - 2]
	var direction := target - previous
	if direction.length_squared() <= 0.01:
		arrow_head.hide()
		return

	arrow_head.show()
	arrow_head.position = target
	arrow_head.rotation = direction.angle()
