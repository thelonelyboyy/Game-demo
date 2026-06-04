class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const ICON_SIZE := 20.0
const BOSS_ICON_SIZE := 23.0
const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, ICON_SIZE],
	Room.Type.MONSTER: [preload("res://art/map/map_monster.png"), ICON_SIZE],
	Room.Type.TREASURE: [preload("res://art/map/map_treasure.png"), ICON_SIZE],
	Room.Type.CAMPFIRE: [preload("res://art/map/map_campfire.png"), ICON_SIZE],
	Room.Type.SHOP: [preload("res://art/map/map_shop.png"), ICON_SIZE],
	Room.Type.BOSS: [preload("res://art/map/map_boss.png"), BOSS_ICON_SIZE],
	Room.Type.EVENT: [preload("res://art/map/map_event.png"), ICON_SIZE],
	Room.Type.ELITE: [preload("res://art/map/map_elite.png"), BOSS_ICON_SIZE],
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
	_apply_room_icon()
	line_2d.hide()
	queue_redraw()


func show_selected() -> void:
	queue_redraw()


func _apply_room_icon() -> void:
	var icon_data: Array = ICONS.get(room.type, ICONS[Room.Type.NOT_ASSIGNED])
	var texture := icon_data[0] as Texture2D
	var target_size: float = icon_data[1]

	sprite_2d.texture = texture
	sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite_2d.visible = texture != null
	sprite_2d.modulate = Color(1.0, 0.92, 0.72, 0.96)

	if not texture:
		return

	var texture_size := texture.get_size()
	var max_edge := maxf(texture_size.x, texture_size.y)
	sprite_2d.scale = Vector2.ONE * (target_size / max_edge)


func _draw() -> void:
	if not room:
		return

	var fill := Color("15120d")
	var inner := Color("2a2114")
	var border := Color("a58a4c")
	var glow := Color(0.78, 0.58, 0.24, 0.20)

	if room.type == Room.Type.ELITE:
		fill = Color("21100f")
		inner = Color("4a1a16")
		border = Color("c99242")
		glow = Color(0.86, 0.24, 0.13, 0.28)

	if available:
		fill = Color("2b1d0e")
		inner = Color("4b3212")
		border = Color("ffd35a")
		glow = Color(1.0, 0.68, 0.20, 0.36)
		if room.type == Room.Type.ELITE:
			inner = Color("6b2218")
			glow = Color(1.0, 0.33, 0.18, 0.38)
	elif room.selected:
		fill = Color("201b11")
		inner = Color("3b3018")
		border = Color("dfbd67")
		glow = Color(0.86, 0.68, 0.35, 0.28)

	draw_circle(Vector2(3, 4), 18.5, Color(0, 0, 0, 0.48))
	draw_circle(Vector2.ZERO, 17.0, glow)
	draw_circle(Vector2.ZERO, 14.0, fill)
	draw_arc(Vector2.ZERO, 14.5, 0.0, TAU, 64, Color(0, 0, 0, 0.58), 3.2, true)
	draw_arc(Vector2.ZERO, 13.2, 0.0, TAU, 64, border, 2.1, true)
	draw_arc(Vector2.ZERO, 9.8, 0.0, TAU, 64, Color(inner.r, inner.g, inner.b, 0.78), 2.0, true)

	if available:
		draw_arc(Vector2.ZERO, 18.5, -0.45, PI + 0.35, 40, Color(1.0, 0.86, 0.42, 0.58), 1.5, true)
	elif room.selected:
		draw_line(Vector2(-6, 12), Vector2(6, 12), Color(0.93, 0.77, 0.40, 0.82), 1.8, true)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	room.selected = true
	clicked.emit(room)
	queue_redraw()
	animation_player.play("select")


# Called by the AnimationPlayer when the select animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
