class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/tile_0103.png"), Vector2.ONE],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2.ONE],
	Room.Type.CAMPFIRE: [preload("res://art/player_heart.png"), Vector2(0.6, 0.6)],
	Room.Type.SHOP: [preload("res://art/gold.png"), Vector2(0.6, 0.6)],
	Room.Type.BOSS: [preload("res://art/tile_0105.png"), Vector2(1.25, 1.25)],
	Room.Type.EVENT: [preload("res://art/rarity.png"), Vector2(0.9, 0.9)],
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room


func set_available(new_value: bool) -> void:
	available = new_value
	queue_redraw()
	
	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]
	sprite_2d.hide()
	line_2d.hide()
	queue_redraw()


func show_selected() -> void:
	queue_redraw()


func _draw() -> void:
	if not room:
		return

	var fill := Color(0.07, 0.065, 0.055, 0.98)
	var border := Color(0.68, 0.56, 0.30, 0.92)
	var icon := Color(1.0, 0.92, 0.70, 1.0)

	if available:
		fill = Color(0.22, 0.15, 0.07, 1.0)
		border = Color(1.0, 0.78, 0.24, 1.0)
	elif room.selected:
		fill = Color(0.18, 0.16, 0.11, 1.0)
		border = Color(0.84, 0.68, 0.36, 1.0)

	draw_circle(Vector2(2, 3), 13.0, Color(0, 0, 0, 0.42))
	draw_circle(Vector2.ZERO, 10.0, fill)
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 48, Color(0, 0, 0, 0.55), 2.8, true)
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 48, border, 1.9, true)

	match room.type:
		Room.Type.MONSTER:
			_draw_sword_icon(icon)
		Room.Type.TREASURE:
			_draw_box_icon(icon)
		Room.Type.CAMPFIRE:
			_draw_fire_icon(icon)
		Room.Type.SHOP:
			_draw_coin_icon(icon)
		Room.Type.BOSS:
			_draw_boss_icon(icon)
		Room.Type.EVENT:
			_draw_event_icon(icon)


func _draw_sword_icon(color: Color) -> void:
	draw_line(Vector2(0, -7), Vector2(0, 6), color, 2.0, true)
	draw_line(Vector2(-4, 1), Vector2(4, 1), color, 1.6, true)
	draw_line(Vector2(0, -7), Vector2(3, -3), color, 1.3, true)
	draw_line(Vector2(0, -7), Vector2(-3, -3), color, 1.3, true)


func _draw_box_icon(color: Color) -> void:
	draw_rect(Rect2(Vector2(-6, -4), Vector2(12, 10)), Color(color.r, color.g, color.b, 0.22))
	draw_line(Vector2(-6, -4), Vector2(6, -4), color, 1.4, true)
	draw_line(Vector2(-6, 0), Vector2(6, 0), color, 1.2, true)
	draw_line(Vector2(-6, 6), Vector2(6, 6), color, 1.4, true)
	draw_line(Vector2(-6, -4), Vector2(-6, 6), color, 1.4, true)
	draw_line(Vector2(6, -4), Vector2(6, 6), color, 1.4, true)


func _draw_fire_icon(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -7),
		Vector2(5, 2),
		Vector2(2, 7),
		Vector2(-4, 7),
		Vector2(-6, 2),
	]), Color(0.80, 0.23, 0.15, 0.86))
	draw_line(Vector2(0, -7), Vector2(2, 7), color, 1.2, true)


func _draw_coin_icon(color: Color) -> void:
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 32, color, 1.6, true)
	draw_line(Vector2(-4, 0), Vector2(4, 0), color, 1.3, true)
	draw_line(Vector2(0, -4), Vector2(0, 4), color, 1.3, true)


func _draw_boss_icon(color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7, 6),
		Vector2(-5, -5),
		Vector2(0, -1),
		Vector2(5, -7),
		Vector2(7, 6),
	]), Color(0.55, 0.12, 0.12, 0.92))
	draw_line(Vector2(-7, 6), Vector2(7, 6), color, 1.4, true)
	draw_arc(Vector2.ZERO, 5.0, 0.15, PI - 0.15, 24, color, 1.1, true)


func _draw_event_icon(color: Color) -> void:
	draw_arc(Vector2(0, -2), 5.0, -1.2, 1.9, 24, color, 1.8, true)
	draw_line(Vector2(1, 3), Vector2(1, 6), color, 1.8, true)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	room.selected = true
	clicked.emit(room)
	queue_redraw()
	animation_player.play("select")


# Called by the AnimationPLayer when the 
# "select" animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
