class_name Map
extends Node2D

const MAP_VISUAL_SCALE := 3.35
const SCROLL_SPEED := 15
const SCROLL_FLOOR_CAPACITY := 17
const SCROLL_SIDE_PADDING := 74.0
const SCROLL_VERTICAL_PADDING := 64.0
const SCROLL_VIEWPORT_WIDTH_RATIO := 1.02
const TOOLTIP_MARGIN := 24.0
const TOOLTIP_TOP_SAFE_Y := 92.0
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
var tooltip_layer: CanvasLayer
var tooltip_panel: PanelContainer
var tooltip_title: Label
var tooltip_description: Label
var tooltip_status: Label
var tooltip_target: MapRoom
var focused_map_room: MapRoom


func _ready() -> void:
	free_navigation = map_generator.map_mode != MapGenerator.MapMode.ROGUELIKE
	InkTheme.add_backdrop($MapBackground, "map")
	var scroll_background := $MapBackground/Background as TextureRect
	scroll_background.hide()
	scroll_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals.scale = Vector2.ONE * MAP_VISUAL_SCALE
	camera_2d.offset = get_viewport_rect().size / 2.0
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_create_tooltip()
	_update_camera_limits()


func _process(_delta: float) -> void:
	if tooltip_panel and tooltip_panel.visible and is_instance_valid(tooltip_target):
		_position_tooltip(tooltip_target)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if InputMap.has_action("ui_focus_next") and event.is_action_pressed("ui_focus_next"):
		_focus_next_available_room(1)
		get_viewport().set_input_as_handled()
		return
	elif InputMap.has_action("ui_focus_prev") and event.is_action_pressed("ui_focus_prev"):
		_focus_next_available_room(-1)
		get_viewport().set_input_as_handled()
		return
	elif InputMap.has_action("ui_accept") and event.is_action_pressed("ui_accept") and is_instance_valid(focused_map_room) and focused_map_room.available:
		focused_map_room.activate()
		get_viewport().set_input_as_handled()
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
	_hide_tooltip()
	_set_focused_map_room(null)


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	new_map_room.hovered.connect(_on_map_room_hovered)
	new_map_room.hover_cleared.connect(_on_map_room_hover_cleared)
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


func _on_map_room_hovered(map_room: MapRoom) -> void:
	if not map_room or not map_room.room:
		return

	_show_map_room_tooltip(map_room)


func _show_map_room_tooltip(map_room: MapRoom) -> void:
	tooltip_target = map_room
	tooltip_title.text = _room_tooltip_title(map_room.room)
	tooltip_description.text = _room_tooltip_description(map_room.room)
	tooltip_status.text = _room_tooltip_status(map_room)
	tooltip_status.add_theme_color_override("font_color", _room_tooltip_status_color(map_room))
	tooltip_panel.show()
	tooltip_panel.size = Vector2(280, 132)
	_position_tooltip(map_room)


func _on_map_room_hover_cleared(map_room: MapRoom) -> void:
	if map_room == tooltip_target:
		_hide_tooltip()


func get_floor_count() -> int:
	if map_data:
		return map_data.size()
	return MapGenerator.FLOORS


func _clear_map_visuals() -> void:
	_hide_tooltip()
	_set_focused_map_room(null)
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


func _focus_next_available_room(direction: int) -> void:
	var candidates: Array[MapRoom] = []
	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if map_room and map_room.available:
			candidates.append(map_room)

	if candidates.is_empty():
		return

	candidates.sort_custom(_sort_map_rooms_by_position)
	var current_index := candidates.find(focused_map_room) if is_instance_valid(focused_map_room) else -1
	var next_index := 0
	if current_index == -1:
		next_index = 0 if direction > 0 else candidates.size() - 1
	else:
		next_index = posmod(current_index + direction, candidates.size())
	_set_focused_map_room(candidates[next_index])
	_show_map_room_tooltip(focused_map_room)


func _sort_map_rooms_by_position(a: MapRoom, b: MapRoom) -> bool:
	if a.room.row == b.room.row:
		return a.room.column < b.room.column
	return a.room.row < b.room.row


func _set_focused_map_room(map_room: MapRoom) -> void:
	if is_instance_valid(focused_map_room):
		focused_map_room.focused = false

	focused_map_room = map_room

	if is_instance_valid(focused_map_room):
		focused_map_room.focused = true


func _create_tooltip() -> void:
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.name = "MapTooltipLayer"
	tooltip_layer.layer = 4
	add_child(tooltip_layer)

	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "MapTooltip"
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.custom_minimum_size = Vector2(280, 132)
	tooltip_panel.size = Vector2(280, 132)
	tooltip_panel.add_theme_stylebox_override("panel", _make_tooltip_style())
	tooltip_panel.hide()
	tooltip_layer.add_child(tooltip_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	tooltip_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	tooltip_title = Label.new()
	tooltip_title.add_theme_font_size_override("font_size", 24)
	tooltip_title.add_theme_color_override("font_color", Color("fff0c8"))
	tooltip_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	tooltip_title.add_theme_constant_override("shadow_offset_x", 2)
	tooltip_title.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(tooltip_title)

	tooltip_description = Label.new()
	tooltip_description.custom_minimum_size = Vector2(236, 0)
	tooltip_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_description.add_theme_font_size_override("font_size", 17)
	tooltip_description.add_theme_color_override("font_color", Color("f3dfb2"))
	tooltip_description.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	tooltip_description.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_description.add_theme_constant_override("shadow_offset_y", 1)
	content.add_child(tooltip_description)

	tooltip_status = Label.new()
	tooltip_status.add_theme_font_size_override("font_size", 16)
	tooltip_status.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	tooltip_status.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_status.add_theme_constant_override("shadow_offset_y", 1)
	content.add_child(tooltip_status)


func _position_tooltip(map_room: MapRoom) -> void:
	var viewport_size := get_viewport_rect().size
	var tooltip_size := tooltip_panel.size
	var anchor := map_room.get_global_transform_with_canvas().origin
	var tooltip_position := anchor + Vector2(28.0, -tooltip_size.y - 28.0)

	var max_x := maxf(TOOLTIP_MARGIN, viewport_size.x - tooltip_size.x - TOOLTIP_MARGIN)
	var max_y := maxf(TOOLTIP_TOP_SAFE_Y, viewport_size.y - tooltip_size.y - TOOLTIP_MARGIN)
	tooltip_position.x = clampf(tooltip_position.x, TOOLTIP_MARGIN, max_x)
	tooltip_position.y = clampf(tooltip_position.y, TOOLTIP_TOP_SAFE_Y, max_y)
	tooltip_panel.position = tooltip_position


func _hide_tooltip() -> void:
	tooltip_target = null
	if tooltip_panel:
		tooltip_panel.hide()


func _room_tooltip_title(room: Room) -> String:
	match room.type:
		Room.Type.MONSTER:
			return "战斗"
		Room.Type.TREASURE:
			return "宝箱"
		Room.Type.CAMPFIRE:
			return "营火"
		Room.Type.SHOP:
			return "商店"
		Room.Type.BOSS:
			return "终局首领"
		Room.Type.EVENT:
			return "机缘"
		Room.Type.ELITE:
			return "精英战"
		Room.Type.BLESSING:
			return "赐福"
		_:
			return "未知"


func _room_tooltip_description(room: Room) -> String:
	match room.type:
		Room.Type.MONSTER:
			return "遭遇妖邪，胜利后获得战利。"
		Room.Type.TREASURE:
			return "开启宝箱，获得遗物或资源。"
		Room.Type.CAMPFIRE:
			return "休整疗伤，准备下一段山路。"
		Room.Type.SHOP:
			return "购买卡牌、遗物和丹药符箓。"
		Room.Type.BOSS:
			return "本劫最终挑战，胜则入下一章。"
		Room.Type.EVENT:
			return "触发随机机缘，收益与代价并存。"
		Room.Type.ELITE:
			return "高风险强敌，奖励也更丰厚。"
		Room.Type.BLESSING:
			return "选择开局赐福，奠定本轮根基。"
		_:
			return "此处尚未显露真实去向。"


func _room_tooltip_status(map_room: MapRoom) -> String:
	if map_room.available:
		return "点击前往"
	if map_room.room and map_room.room.selected:
		return "已完成"
	return "未开放"


func _room_tooltip_status_color(map_room: MapRoom) -> Color:
	if map_room.available:
		return Color("dffcff")
	if map_room.room and map_room.room.selected:
		return Color("f2c94f")
	return Color(0.72, 0.68, 0.58, 0.72)


func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.028, 0.025, 0.022, 0.94)
	style.border_color = Color(0.82, 0.61, 0.27, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0, 0, 0, 0.46)
	style.shadow_size = 10
	return style
