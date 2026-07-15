class_name Map
extends Node2D

const MAP_VISUAL_SCALE := 3.35
const SCROLL_SPEED := 15
# 卷轴按 20 层节点的高度绘制，FLOORS 拉到 20 以内都放得下。
const SCROLL_FLOOR_CAPACITY := 20
const SCROLL_SIDE_PADDING := 74.0
# 卷轴上下留白以楼层间距为单位，修改 Y_DIST 时卷轴会同比例增减。
const SCROLL_VERTICAL_PADDING_FLOORS := 1.6
# 顶部需要额外覆盖顶栏安全位；只向上延长，不改变节点层距和卷轴底部位置。
const SCROLL_TOP_EXTRA_PADDING_FLOORS := 0.8
const SCROLL_VIEWPORT_WIDTH_RATIO := 1.02
const TOOLTIP_MARGIN := 24.0
const TOOLTIP_TOP_SAFE_Y := 92.0
# 最高节点中心的屏幕安全线。节点在 3.35 倍缩放下点击半径约 74px，
# 该值可让整个点击圈落在约 208px 高的运行顶栏下方。
const TOP_ROOM_SAFE_CENTER_Y := 296.0
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
var player_marker: PlayerMarker
var legend_panel: PanelContainer
var legend_rows: Dictionary = {}
var _legend_highlighted_type := Room.Type.NOT_ASSIGNED
# 平滑滚动：滚轮改目标值，_process 里插值逼近
var _scroll_target_y := 0.0
# 可选路径连线脉冲
var _pulse_lines: Array[Line2D] = []
var _pulse_time := 0.0
# 顶部章节/层数进度
var progress_panel: PanelContainer
var progress_label: Label
var progress_chapter_label: Label
var progress_remaining_label: Label


# 「当前位置」标记：金色脉冲光环，落在最后走过的节点上；选新节点时滑过去。
class PlayerMarker:
	extends Node2D

	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		var ring_radius := 8.5 + pulse * 1.8
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(1.0, 0.82, 0.35, 0.50 + 0.35 * pulse), 1.5, true)
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.75, 0.30, 0.30))
		draw_circle(Vector2.ZERO, 3.2, Color(1.0, 0.88, 0.52, 0.95))


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
	_create_progress_panel()
	_create_legend_panel()
	_update_camera_limits()
	_sync_map_overlay_visibility()


func _process(delta: float) -> void:
	if tooltip_panel and tooltip_panel.visible and is_instance_valid(tooltip_target):
		_position_tooltip(tooltip_target)

	if not visible:
		return

	# 平滑滚动：向目标值插值逼近。
	if absf(camera_2d.position.y - _scroll_target_y) > 0.5:
		camera_2d.position.y = lerpf(camera_2d.position.y, _scroll_target_y, minf(1.0, delta * 10.0))

	# 可选路径连线 + 可选节点的呼吸脉冲。
	_pulse_time += delta
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 3.0)
	for line in _pulse_lines:
		if is_instance_valid(line):
			var base_alpha: float = line.get_meta("base_alpha", 0.9)
			line.default_color.a = base_alpha * (0.62 + 0.38 * pulse)
	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if not map_room or not map_room.room:
			continue
		if map_room.legend_highlighted:
			# 图例筛选优先于不可达支线的整体变暗，保证红圈始终足够醒目。
			map_room.modulate = Color.WHITE
		elif map_room.available:
			var glow := 1.0 + 0.14 * pulse
			map_room.modulate = Color(glow, glow, glow * 0.97, 1.0)
		elif not map_room.room.selected and map_room.room.row < floors_climbed:
			# 已经走过这一层但没选它：这条支线永远到不了了，强变暗（杀戮尖塔式）。
			map_room.modulate = Color(0.5, 0.5, 0.5, 0.5)
		elif map_room.modulate != Color.WHITE:
			map_room.modulate = Color.WHITE


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
		_scroll_target_y -= SCROLL_SPEED * MAP_VISUAL_SCALE * 2.4
	elif event.is_action_pressed("scroll_down"):
		_scroll_target_y += SCROLL_SPEED * MAP_VISUAL_SCALE * 2.4

	_scroll_target_y = clampf(_scroll_target_y, camera_min_y, camera_max_y)


func generate_new_map(chapter: int = 1) -> void:
	floors_climbed = 0
	last_room = null
	camera_2d.position = Vector2.ZERO
	_scroll_target_y = 0.0
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
	_reflow_room_vertical_positions()
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
	var content_height := MapGenerator.get_floor_span(_get_scroll_floor_slots())
	_layout_map_visuals(content_width, content_height)
	_ensure_player_marker()
	_animate_map_entrance()
	_update_progress_label()
	_sync_map_overlay_visibility()


# Room.position 会随存档持久化。层距常量更新后，旧存档仍保留旧 Y 坐标，
# 因而出现“卷轴变高但节点没拉开”的错位。每次建图都按当前层距重排，且保持 X 抖动不变。
func _reflow_room_vertical_positions() -> void:
	if map_data.is_empty():
		return

	var last_row := map_data.size() - 1
	for row: Array in map_data:
		for room: Room in row:
			if not room:
				continue
			var visual_row := room.row
			# 生成器会把 Boss 放在末层之外的额外一个纵向槽位，继续保留这段终战间隔。
			if room.type == Room.Type.BOSS and room.row == last_row:
				visual_row += 1
			room.position.y = MapGenerator.get_row_y(visual_row)


# 开图演出：节点自下而上按层错落浮现，连线整体淡入。
# 只在 create_map（新章/读档）时触发，回到地图不重播。
func _animate_map_entrance() -> void:
	lines.modulate = Color(1, 1, 1, 0.0)
	var lines_tween := lines.create_tween()
	lines_tween.tween_property(lines, "modulate:a", 1.0, 0.7) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if not map_room or not map_room.room:
			continue
		var delay := 0.05 * map_room.room.row + 0.015 * map_room.room.column
		map_room.scale = Vector2.ZERO
		var tween := map_room.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(map_room, "scale", Vector2.ONE, 0.38) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ensure_player_marker() -> void:
	if is_instance_valid(player_marker):
		player_marker.queue_free()

	player_marker = PlayerMarker.new()
	player_marker.name = "PlayerMarker"
	player_marker.z_index = 25
	rooms.get_parent().add_child(player_marker)

	if last_room:
		player_marker.position = rooms.position + last_room.position
		player_marker.show()
	else:
		player_marker.hide()


func _move_player_marker(room: Room) -> void:
	if not is_instance_valid(player_marker) or not room:
		return

	var target := rooms.position + room.position
	if not player_marker.visible:
		# 本章第一次选点：原地弹出，没有旅程可走。
		player_marker.position = target
		player_marker.scale = Vector2.ONE * 1.7
		player_marker.show()
		var pop := player_marker.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(player_marker, "scale", Vector2.ONE, 0.4)
		return

	# 在节点 select 动画窗口内滑过去，带一个小跳跃感。
	var tween := player_marker.create_tween()
	tween.tween_property(player_marker, "position", target, 0.65) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var hop := player_marker.create_tween()
	hop.tween_property(player_marker, "scale", Vector2.ONE * 1.4, 0.33) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hop.tween_property(player_marker, "scale", Vector2.ONE, 0.33) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


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
	_update_progress_label()
	_sync_map_overlay_visibility()


func hide_map() -> void:
	hide()
	camera_2d.enabled = false
	_hide_tooltip()
	_set_focused_map_room(null)
	_clear_legend_room_highlight()
	_sync_map_overlay_visibility()


func _sync_map_overlay_visibility() -> void:
	if progress_panel:
		progress_panel.visible = visible
	if legend_panel:
		legend_panel.visible = visible


# 左侧登仙进度牌，与右侧图例共用现有暗金九宫格素材。
func _create_progress_panel() -> void:
	progress_panel = PanelContainer.new()
	progress_panel.name = "MapProgressPanel"
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# SIDE_PANEL 原图四周带约 42~49px 的透明装饰留白。面板过窄时，
	# 文字虽在 Control 内，却会跑到肉眼可见的金色边框外；加宽并按可见边框留边。
	progress_panel.custom_minimum_size = Vector2(260, 300)
	progress_panel.anchor_left = 0.0
	progress_panel.anchor_right = 0.0
	progress_panel.anchor_top = 0.60
	progress_panel.anchor_bottom = 0.60
	progress_panel.offset_left = 24.0
	progress_panel.offset_right = 284.0
	progress_panel.offset_top = -234.0
	progress_panel.offset_bottom = 66.0
	progress_panel.add_theme_stylebox_override("panel", _make_map_side_panel_style())
	progress_panel.hide()
	tooltip_layer.add_child(progress_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	progress_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	content.add_child(_make_map_panel_title("登仙路"))

	progress_chapter_label = Label.new()
	progress_chapter_label.name = "ChapterLabel"
	progress_chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_chapter_label.add_theme_font_size_override("font_size", 24)
	progress_chapter_label.add_theme_color_override("font_color", Color("f8df9b"))
	progress_chapter_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	progress_chapter_label.add_theme_constant_override("shadow_offset_x", 2)
	progress_chapter_label.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(progress_chapter_label)

	var caption := Label.new()
	caption.text = "当前进度"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color("a99a80"))
	content.add_child(caption)

	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 30)
	progress_label.add_theme_color_override("font_color", Color("fff0c2"))
	progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	progress_label.add_theme_constant_override("shadow_offset_x", 2)
	progress_label.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(progress_label)

	progress_remaining_label = Label.new()
	progress_remaining_label.name = "RemainingLabel"
	progress_remaining_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_remaining_label.add_theme_font_size_override("font_size", 13)
	progress_remaining_label.add_theme_color_override("font_color", Color("c4ad82"))
	content.add_child(progress_remaining_label)


func _update_progress_label() -> void:
	if not progress_label:
		return

	var chapter_names := ["一", "二", "三"]
	var chapter: int = clampi(map_generator.current_chapter, 1, chapter_names.size())
	var current_floor := clampi(floors_climbed, 0, get_floor_count())
	var floor_count := get_floor_count()
	progress_chapter_label.text = "第%s章" % chapter_names[chapter - 1]
	progress_label.text = "%d / %d 层" % [current_floor, floor_count]
	progress_remaining_label.text = "距本章终点 %d 层" % maxi(floor_count - current_floor, 0)


func _create_legend_panel() -> void:
	legend_panel = PanelContainer.new()
	legend_panel.name = "MapLegend"
	legend_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	legend_panel.custom_minimum_size = Vector2(260, 520)
	legend_panel.anchor_left = 1.0
	legend_panel.anchor_right = 1.0
	legend_panel.anchor_top = 0.60
	legend_panel.anchor_bottom = 0.60
	legend_panel.offset_left = -284.0
	legend_panel.offset_right = -24.0
	legend_panel.offset_top = -260.0
	legend_panel.offset_bottom = 260.0
	legend_panel.add_theme_stylebox_override("panel", _make_map_side_panel_style())
	legend_panel.hide()
	tooltip_layer.add_child(legend_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	legend_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	content.add_child(_make_map_panel_title("天路图例"))

	var entries := [
		[Room.Type.BLESSING, "赐福", "开局强化"],
		[Room.Type.MONSTER, "战斗", "普通敌人"],
		[Room.Type.ELITE, "精英", "高风险奖励"],
		[Room.Type.EVENT, "机缘", "随机事件"],
		[Room.Type.TREASURE, "宝箱", "获得奖励"],
		[Room.Type.CAMPFIRE, "营火", "休整疗伤"],
		[Room.Type.SHOP, "商店", "购买补给"],
		[Room.Type.BOSS, "首领", "章节终战"],
	]
	for entry in entries:
		var row := _make_legend_row(entry[0], entry[1], entry[2])
		legend_rows[entry[0]] = row
		content.add_child(row)


func _make_legend_row(room_type: int, title: String, description: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "LegendRow_%s" % room_type
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 35)
	row.add_theme_constant_override("separation", 8)
	row.set_meta("room_type", room_type)
	row.mouse_entered.connect(_on_legend_row_mouse_entered.bind(room_type, row))
	row.mouse_exited.connect(_on_legend_row_mouse_exited.bind(room_type, row))

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.texture = MapRoom.ICONS.get(room_type, MapRoom.ICONS[Room.Type.NOT_ASSIGNED])
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)

	var title_label := Label.new()
	title_label.text = title
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("f6dfaa"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	text_box.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.77, 0.70, 0.58, 0.90))
	desc_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.70))
	desc_label.add_theme_constant_override("shadow_offset_x", 1)
	desc_label.add_theme_constant_override("shadow_offset_y", 1)
	text_box.add_child(desc_label)

	return row


func _on_legend_row_mouse_entered(room_type: int, row: Control) -> void:
	if is_instance_valid(row):
		row.modulate = Color(1.24, 0.84, 0.78, 1.0)
	_set_legend_room_highlight(room_type)


func _on_legend_row_mouse_exited(room_type: int, row: Control) -> void:
	if is_instance_valid(row):
		row.modulate = Color.WHITE
	if _legend_highlighted_type == room_type:
		_clear_legend_room_highlight()


func _set_legend_room_highlight(room_type: int) -> void:
	_legend_highlighted_type = room_type
	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if map_room and map_room.room:
			map_room.set_legend_highlighted(map_room.room.type == room_type)


func _clear_legend_room_highlight() -> void:
	_legend_highlighted_type = Room.Type.NOT_ASSIGNED
	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if map_room:
			map_room.set_legend_highlighted(false)
	for row in legend_rows.values():
		if is_instance_valid(row):
			(row as Control).modulate = Color.WHITE


func _make_map_side_panel_style() -> StyleBoxTexture:
	var style := InkTheme.make_texture_style(
		InkTheme.SIDE_PANEL,
		48,
		48,
		Color(0.98, 0.90, 0.80, 0.98)
	)
	# 该素材的有效金框从原图约 x=42/y=49 才开始，内容边距必须跟随
	# 可见边框，而不是沿用通用九宫格的 14/8，否则两侧文字会越框。
	style.content_margin_left = 44
	style.content_margin_top = 48
	style.content_margin_right = 44
	style.content_margin_bottom = 48
	return style


func _make_map_panel_title(text: String) -> PanelContainer:
	var title_panel := PanelContainer.new()
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.custom_minimum_size = Vector2(0, 42)
	title_panel.add_theme_stylebox_override(
		"panel",
		InkTheme.make_texture_style(
			InkTheme.SECTION_TITLE_PLATE,
			48,
			18,
			Color(1.0, 0.92, 0.76, 0.98)
		)
	)

	var title_label := Label.new()
	title_label.text = text
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 19)
	title_label.add_theme_color_override("font_color", Color("ffe8ad"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_panel.add_child(title_label)
	return title_panel


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


# 杀戮尖塔式路径：虚线贴图 + 轻微弯曲的手绘感。
# 虚线纹理运行时生成一次；弯度由端点坐标决定（确定性，重建地图不变、不消耗 RNG）。
static var _dash_texture: ImageTexture


static func _get_dash_texture() -> ImageTexture:
	if _dash_texture:
		return _dash_texture
	var img := Image.create(20, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(2, 1, 9, 8), Color.WHITE)
	_dash_texture = ImageTexture.create_from_image(img)
	return _dash_texture


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return

	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		for point in _curved_line_points(room.position, next.position):
			new_map_line.add_point(point)
		new_map_line.antialiased = true
		new_map_line.texture = _get_dash_texture()
		new_map_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		new_map_line.set_meta("from_room", room)
		new_map_line.set_meta("to_room", next)
		lines.add_child(new_map_line)
		_style_map_line(new_map_line, "normal")


func _curved_line_points(from: Vector2, to: Vector2) -> PackedVector2Array:
	var mid := (from + to) * 0.5
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var seed_value := int(absf(from.x * 7.0 + from.y * 13.0 + to.x * 17.0 + to.y * 23.0))
	var bow := (float(seed_value % 100) / 100.0 - 0.5) * 12.0
	var control := mid + normal * bow

	var points := PackedVector2Array()
	var segments := 8
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points


func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false

	_move_player_marker(room)
	_update_line_states()


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	# 自由导航下按节点所在层定位，确保直接点 Boss 也能正确触发通关/进章
	if free_navigation:
		floors_climbed = room.row + 1
	else:
		floors_climbed += 1
	_update_line_states()
	_update_progress_label()
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
	_clear_legend_room_highlight()
	for child: Node in rooms.get_children():
		child.free()
	for child: Node in lines.get_children():
		child.free()


func is_final_floor_reached() -> bool:
	return floors_climbed >= get_floor_count()


func _update_camera_limits() -> void:
	camera_min_y = -MapGenerator.get_floor_span(_get_scroll_floor_slots()) * MAP_VISUAL_SCALE
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

	# 不允许最高层节点的点击圈滚入运行顶栏下面。
	var has_room := false
	var top_room_world_y := 0.0
	for child: Node in rooms.get_children():
		var map_room := child as MapRoom
		if not map_room:
			continue
		var room_world_y := visuals.position.y + (rooms.position.y + map_room.position.y) * visuals.scale.y
		if not has_room or room_world_y < top_room_world_y:
			has_room = true
			top_room_world_y = room_world_y
	if has_room:
		camera_min_y = minf(camera_min_y, top_room_world_y - TOP_ROOM_SAFE_CENTER_Y)

	camera_edge_y = -camera_min_y


func _clamp_camera_position() -> void:
	camera_2d.position.y = clamp(camera_2d.position.y, camera_min_y, camera_max_y)
	_scroll_target_y = clampf(_scroll_target_y, camera_min_y, camera_max_y)


func _on_viewport_size_changed() -> void:
	camera_2d.offset = get_viewport_rect().size / 2.0
	if map_data.is_empty():
		return

	var content_width := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	var content_height := MapGenerator.get_floor_span(_get_scroll_floor_slots())
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
	var scroll_vertical_padding := MapGenerator.Y_DIST * SCROLL_VERTICAL_PADDING_FLOORS
	var scroll_top_extra := MapGenerator.Y_DIST * SCROLL_TOP_EXTRA_PADDING_FLOORS
	var scroll_height := content_height + scroll_vertical_padding * 2.0 + scroll_top_extra
	scroll_board.centered = true
	# 高度增量全部放到顶部：底部卷轴和起点位置不动，最高处不再露出后备灰纸背景。
	scroll_board.position = Vector2(content_width * 0.5, content_height * -0.5 - scroll_top_extra * 0.5)
	scroll_board.scale = Vector2(scroll_width / texture_size.x, scroll_height / texture_size.y)


func _update_line_states() -> void:
	_pulse_lines.clear()
	for line: Line2D in lines.get_children():
		var from_room := line.get_meta("from_room") as Room
		var to_room := line.get_meta("to_room") as Room

		if from_room and to_room and from_room.selected and to_room.selected:
			_style_map_line(line, "selected")
		elif last_room and from_room == last_room and last_room.next_rooms.has(to_room):
			_style_map_line(line, "available")
			_pulse_lines.append(line)
		elif _is_room_available(from_room):
			_style_map_line(line, "available")
			_pulse_lines.append(line)
		elif from_room and from_room.row < floors_climbed:
			_style_map_line(line, "missed")
		else:
			_style_map_line(line, "normal")


func _style_map_line(line: Line2D, state: String) -> void:
	match state:
		"selected":
			# 走过的路：红色高亮，和未选择路径拉开对比。
			line.width = 4.6
			line.default_color = Color(0.86, 0.05, 0.04, 0.98)
		"available":
			# 可选去向：仍保持黑色基调，_process 里做轻微呼吸脉冲。
			line.width = 4.0
			line.default_color = Color(0.02, 0.018, 0.016, 0.92)
			line.set_meta("base_alpha", 0.92)
		"missed":
			# 已经错过的支线：压到几乎隐去。
			line.width = 3.0
			line.default_color = Color(0.0, 0.0, 0.0, 0.28)
		_:
			line.width = 3.4
			line.default_color = Color(0.0, 0.0, 0.0, 0.82)


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
