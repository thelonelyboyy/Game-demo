class_name Map
extends Node2D

const MAP_VISUAL_SCALE := 3.35
const SCROLL_SPEED := 15
const MAP_ROOM = preload("res://scenes/map/map_room.tscn")
const MAP_LINE = preload("res://scenes/map/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float


func _ready() -> void:
	InkTheme.add_backdrop($MapBackground, "map")
	$MapBackground/Background.hide()
	visuals.scale = Vector2.ONE * MAP_VISUAL_SCALE
	camera_2d.offset = get_viewport_rect().size / 2.0
	_update_camera_limits()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("scroll_up"):
		camera_2d.position.y -= SCROLL_SPEED * MAP_VISUAL_SCALE
	elif event.is_action_pressed("scroll_down"):
		camera_2d.position.y += SCROLL_SPEED * MAP_VISUAL_SCALE

	camera_2d.position.y = clamp(camera_2d.position.y, -camera_edge_y, 0)


func generate_new_map() -> void:
	floors_climbed = 0
	last_room = null
	camera_2d.position = Vector2.ZERO
	map_data = map_generator.generate_map()
	create_map()
	_update_camera_limits()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed
	create_map()
	_update_camera_limits()
	camera_2d.position.y = clamp(camera_2d.position.y, -camera_edge_y, 0)
	
	if floors_climbed > 0:
		unlock_next_rooms()
	else:
		unlock_floor()


func create_map() -> void:
	_clear_map_visuals()

	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	# Boss room has no next room but we need to spawn it
	var last_floor := map_data.size() - 1
	var middle := floori(map_data[last_floor].size() * 0.5)
	_spawn_room(map_data[last_floor][middle])

	var map_width_pixels: float = MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1) * MAP_VISUAL_SCALE
	var map_height_pixels: float = MapGenerator.Y_DIST * maxi(get_floor_count() - 1, 0) * MAP_VISUAL_SCALE
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = minf(
		get_viewport_rect().size.y * 0.84,
		(get_viewport_rect().size.y + map_height_pixels) / 2.0
	)


func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true

	_update_line_states()


func unlock_next_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true

	_update_line_states()


func show_map() -> void:
	show()
	camera_2d.enabled = true


func hide_map() -> void:
	hide()
	camera_2d.enabled = false


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)
	
	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
		
	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position)
		new_map_line.add_point(next.position)
		new_map_line.texture = null
		new_map_line.antialiased = true
		new_map_line.set_meta("from_room", room)
		new_map_line.set_meta("to_room", next)
		lines.add_child(new_map_line)
		_style_map_line(new_map_line, "normal")


func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false

	_update_line_states()


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	floors_climbed += 1
	_update_line_states()
	Events.map_exited.emit(room)


func get_floor_count() -> int:
	if map_data:
		return map_data.size()
	return MapGenerator.FLOORS


func _clear_map_visuals() -> void:
	for child: Node in rooms.get_children():
		child.free()
	for child: Node in lines.get_children():
		child.free()


func is_final_floor_reached() -> bool:
	return floors_climbed >= get_floor_count()


func _update_camera_limits() -> void:
	camera_edge_y = MapGenerator.Y_DIST * maxi(get_floor_count() - 1, 0) * MAP_VISUAL_SCALE


func _update_line_states() -> void:
	for line: Line2D in lines.get_children():
		var from_room := line.get_meta("from_room") as Room
		var to_room := line.get_meta("to_room") as Room

		if from_room and to_room and from_room.selected and to_room.selected:
			_style_map_line(line, "selected")
		elif last_room and from_room == last_room and last_room.next_rooms.has(to_room):
			_style_map_line(line, "available")
		elif _is_room_available(from_room):
			_style_map_line(line, "available")
		else:
			_style_map_line(line, "normal")


func _style_map_line(line: Line2D, state: String) -> void:
	match state:
		"selected":
			line.width = 3.2
			line.default_color = Color(1.0, 0.82, 0.32, 0.92)
		"available":
			line.width = 2.8
			line.default_color = Color(0.95, 0.75, 0.36, 0.78)
		_:
			line.width = 1.75
			line.default_color = Color(0.66, 0.56, 0.34, 0.42)


func _is_room_available(room_to_check: Room) -> bool:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room == room_to_check:
			return map_room.available
	return false
