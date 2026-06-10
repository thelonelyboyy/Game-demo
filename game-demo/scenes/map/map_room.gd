class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const NORMAL_TEXTURE_SIZE := 38.0
const LARGE_TEXTURE_SIZE := 44.0
const ICONS := {
	Room.Type.NOT_ASSIGNED: preload("res://art/map/nodes/map_node_unknown.png"),
	Room.Type.MONSTER: preload("res://art/map/nodes/map_node_monster.png"),
	Room.Type.TREASURE: preload("res://art/map/nodes/map_node_treasure.png"),
	Room.Type.CAMPFIRE: preload("res://art/map/nodes/map_node_campfire.png"),
	Room.Type.SHOP: preload("res://art/map/nodes/map_node_shop.png"),
	Room.Type.BOSS: preload("res://art/map/nodes/map_node_boss.png"),
	Room.Type.EVENT: preload("res://art/map/nodes/map_node_unknown.png"),
	Room.Type.ELITE: preload("res://art/map/nodes/map_node_elite.png"),
	Room.Type.BLESSING: preload("res://art/map/nodes/map_node_blessing.png"),
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room


func set_available(new_value: bool) -> void:
	available = new_value
	_refresh_visual_state()
	queue_redraw()

	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	_apply_room_icon()
	line_2d.hide()
	_refresh_visual_state()
	queue_redraw()


func show_selected() -> void:
	_refresh_visual_state()
	queue_redraw()


func _apply_room_icon() -> void:
	var texture := ICONS.get(room.type, ICONS[Room.Type.NOT_ASSIGNED]) as Texture2D
	sprite_2d.texture = texture
	sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite_2d.show()

	var target_size := LARGE_TEXTURE_SIZE if _is_large_room() else NORMAL_TEXTURE_SIZE
	var max_edge := maxf(texture.get_width(), texture.get_height())
	sprite_2d.scale = Vector2.ONE * (target_size / max_edge)


func _refresh_visual_state() -> void:
	if not room or not sprite_2d:
		return

	if available:
		sprite_2d.modulate = Color(1.08, 1.06, 0.96, 1.0)
	elif room.selected:
		sprite_2d.modulate = Color(0.96, 0.91, 0.80, 0.96)
	else:
		sprite_2d.modulate = Color(0.76, 0.70, 0.62, 0.95)


func _draw() -> void:
	if not room:
		return

	if available:
		draw_circle(Vector2.ZERO, 22.5, Color(0.74, 0.94, 1.0, 0.20))
		draw_arc(Vector2.ZERO, 20.0, -0.25, TAU - 0.25, 80, Color(0.86, 0.96, 1.0, 0.72), 2.0, true)
	elif room.selected:
		draw_circle(Vector2.ZERO, 20.0, Color(0.86, 0.70, 0.34, 0.16))
		draw_arc(Vector2.ZERO, 17.5, 0.0, TAU, 72, Color(0.95, 0.80, 0.42, 0.55), 1.6, true)


func _is_large_room() -> bool:
	return room.type == Room.Type.BOSS or room.type == Room.Type.ELITE or room.type == Room.Type.BLESSING


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	room.selected = true
	clicked.emit(room)
	_refresh_visual_state()
	queue_redraw()
	animation_player.play("select")


# Called by the AnimationPlayer when the select animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
