class_name Map
extends Node2D

const MAP_VISUAL_SCALE := 3.35
const SCROLL_SPEED := 15
const SCROLL_FLOOR_CAPACITY := 17
const SCROLL_SIDE_PADDING := 74.0
const SCROLL_VERTICAL_PADDING := 64.0
const SCROLL_VIEWPORT_WIDTH_RATIO := 1.02
const MAP_ROOM = preload("res://scenes/map/map_room.tscn")
const MAP_LINE = preload("res://scenes/map/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var scroll_board: Sprite2D = $Visuals/ScrollBoard
@onready var camera_2d: Camera2D = $Camera2D

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float
var camera_min_y := 0.0
var camera_max_y := 0.0
# 测试地图（非 ROGUELIKE）下解锁全部节点，想点哪个点哪个，方便调试各类房间
var free_navigation := false


func _ready() -> void:
	free_navigation = map_generator.map_mode != MapGenerator.MapMode.ROGUELIKE
	InkTheme.add_backdrop($MapBackground, "map")
	var scroll_background := $MapBackground/Background as TextureRect
	scroll_background.hide()
	scroll_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals.scale = Vector2.ONE * MAP_VISUAL_SCALE
	camera_2d.offset = get_viewport_rect().size / 2.0
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_camera_limits()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("scroll_up"):
		camera_2d.position.y -= SCROLL_SPEED * MAP_VISUAL_SCALE
	elif event.is_action_pressed("scroll_down"):
		camera_2d.position.y += SCROLL_SPEED * MAP_VISUAL_SCALE

	_clamp_camera_position()


func generate_new_map(chapter: int = 1) -> void:
	floors_climbed = 0
	last_room = null
	camera_2d.position = Vector2.ZERO
	map_generator.current_chapter = chapter
	map_data = map_generator.generate_map()
	create_map()
	_update_camera_limits()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed
	create_map()
	_update_camera_limits()
	_clamp_camera_position()
	
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

	var content_width := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	var content_height := MapGenerator.Y_DIST * maxi(_get_scroll_floor_slots() - 1, 0)
	_layout_map_visuals(content_width, content_height)


func unlock_floor(which_floor: int = floors_climbed) -> void:
	if free_navigation:
		_unlock_all_rooms()
		return

	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true

	_update_line_states()


func unlock_next_rooms() -> void:
	if free_navigation:
		_unlock_all_rooms()
		return

	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true

	_update_line_states()


func _unlock_all_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
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
	# 自由导航下按节点所在层定位，确保直接点 Boss 也能正确触发通关/进章
	if free_navigation:
		floors_climbed = room.row + 1
	else:
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
	camera_min_y = -MapGenerator.Y_DIST * maxi(_get_scroll_floor_slots() - 1, 0) * MAP_VISUAL_SCALE
	camera_max_y = 0.0

	if scroll_board and scroll_board.texture:
		var texture_size := scroll_board.texture.get_size()
		var board_height := texture_size.y * scroll_board.scale.y
		var scroll_top := visuals.position.y + (scroll_board.position.y - board_height * 0.5) * visuals.scale.y
		var scroll_bottom := visuals.position.y + (scroll_board.position.y + board_height * 0.5) * visuals.scale.y
		var viewport_height := get_viewport_rect().size.y
		var next_camera_max_y := minf(0.0, scroll_bottom - viewport_height)
		camera_min_y = minf(next_camera_max_y, scroll_top)
		camera_max_y = next_camera_max_y

	camera_edge_y = -camera_min_y


func _clamp_camera_position() -> void:
	camera_2d.position.y = clamp(camera_2d.position.y, camera_min_y, camera_max_y)


func _on_viewport_size_changed() -> void:
	camera_2d.offset = get_viewport_rect().size / 2.0
	if map_data.is_empty():
		return

	var content_width := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	var content_height := MapGenerator.Y_DIST * maxi(_get_scroll_floor_slots() - 1, 0)
	_layout_map_visuals(content_width, content_height)


func _get_scroll_floor_slots() -> int:
	return maxi(SCROLL_FLOOR_CAPACITY, get_floor_count())


func _layout_map_visuals(content_width: float, content_height: float) -> void:
	var viewport_size := get_viewport_rect().size
	var map_width_pixels: float = content_width * MAP_VISUAL_SCALE
	var map_height_pixels: float = content_height * MAP_VISUAL_SCALE
	visuals.position.x = (viewport_size.x - map_width_pixels) / 2
	visuals.position.y = minf(
		viewport_size.y * 0.84,
		(viewport_size.y + map_height_pixels) / 2.0
	)
	_layout_scroll_board(content_width, content_height, viewport_size)
	_update_camera_limits()
	_clamp_camera_position()


func _layout_scroll_board(content_width: float, content_height: float, viewport_size: Vector2) -> void:
	if not scroll_board or not scroll_board.texture:
		return

	var texture_size := scroll_board.texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	var content_scroll_width := content_width + SCROLL_SIDE_PADDING * 2.0
	var viewport_scroll_width := viewport_size.x * SCROLL_VIEWPORT_WIDTH_RATIO / MAP_VISUAL_SCALE
	var scroll_width := maxf(content_scroll_width, viewport_scroll_width)
	var scroll_height := content_height + SCROLL_VERTICAL_PADDING * 2.0
	scroll_board.centered = true
	scroll_board.position = Vector2(content_width * 0.5, content_height * -0.5)
	scroll_board.scale = Vector2(scroll_width / texture_size.x, scroll_height / texture_size.y)


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
			line.width = 4.0
			line.default_color = Color(0.22, 0.16, 0.10, 0.96)
		"available":
			line.width = 3.8
			line.default_color = Color(0.15, 0.13, 0.23, 0.92)
		_:
			line.width = 3.4
			line.default_color = Color(0.13, 0.12, 0.18, 0.78)


func _is_room_available(room_to_check: Room) -> bool:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room == room_to_check:
			return map_room.available
	return false
