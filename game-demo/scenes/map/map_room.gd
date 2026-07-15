class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)
signal hovered(map_room: MapRoom)
signal hover_cleared(map_room: MapRoom)

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
var focused := false : set = set_focused
var room: Room : set = set_room
var _hover_tween: Tween
var _boss_pulse := 0.0
var legend_highlighted := false
var _legend_highlight_time := 0.0


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)


# 仅 Boss 节点开启 _process：红光缓慢脉冲，隔着半张地图也能感到威慑。
func _process(delta: float) -> void:
	if room and room.type == Room.Type.BOSS:
		_boss_pulse += delta
	if legend_highlighted:
		_legend_highlight_time += delta
		# 使用 Visuals 的局部位移，不干扰地图入场缩放、可选节点呼吸或鼠标 hover。
		$Visuals.position.y = -absf(sin(_legend_highlight_time * 5.6)) * 4.2
	queue_redraw()


func set_available(new_value: bool) -> void:
	available = new_value
	_refresh_visual_state()
	queue_redraw()

	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")


func set_focused(new_value: bool) -> void:
	focused = new_value
	queue_redraw()


func set_legend_highlighted(new_value: bool) -> void:
	if legend_highlighted == new_value:
		return
	legend_highlighted = new_value
	_legend_highlight_time = 0.0
	if not legend_highlighted and is_node_ready():
		$Visuals.position = Vector2.ZERO
	set_process(legend_highlighted or (room and room.type == Room.Type.BOSS))
	queue_redraw()


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	_apply_room_icon()
	line_2d.hide()
	set_process(room.type == Room.Type.BOSS)
	_refresh_visual_state()
	queue_redraw()


func show_selected() -> void:
	_refresh_visual_state()
	queue_redraw()


func _apply_room_icon() -> void:
	var texture := ICONS.get(room.type, ICONS[Room.Type.NOT_ASSIGNED]) as Texture2D
	sprite_2d.texture = texture
	sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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

	if room.type == Room.Type.BOSS:
		var pulse := 0.5 + 0.5 * sin(_boss_pulse * 2.2)
		draw_circle(Vector2.ZERO, 27.0 + pulse * 3.0, Color(0.80, 0.16, 0.12, 0.08 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, 24.5 + pulse * 2.0, 0.0, TAU, 72, Color(1.0, 0.34, 0.24, 0.26 + 0.24 * pulse), 1.8, true)

	if legend_highlighted:
		var legend_pulse := 0.5 + 0.5 * sin(_legend_highlight_time * 7.2)
		var ring_radius := 26.0 + legend_pulse * 3.0
		draw_circle(Vector2.ZERO, ring_radius + 2.0, Color(1.0, 0.04, 0.03, 0.13 + 0.09 * legend_pulse))
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 96, Color(1.0, 0.12, 0.08, 0.88), 3.0, true)
		draw_arc(Vector2.ZERO, ring_radius + 4.0, 0.0, TAU, 96, Color(1.0, 0.32, 0.18, 0.30 + 0.24 * legend_pulse), 1.4, true)

	if available:
		draw_circle(Vector2.ZERO, 22.5, Color(0.74, 0.94, 1.0, 0.20))
		draw_arc(Vector2.ZERO, 20.0, -0.25, TAU - 0.25, 80, Color(0.86, 0.96, 1.0, 0.72), 2.0, true)
	elif room.selected:
		draw_circle(Vector2.ZERO, 20.0, Color(0.86, 0.70, 0.34, 0.16))
		draw_arc(Vector2.ZERO, 17.5, 0.0, TAU, 72, Color(0.95, 0.80, 0.42, 0.55), 1.6, true)

	if focused:
		draw_arc(Vector2.ZERO, 25.5, 0.0, TAU, 96, Color(1.0, 0.90, 0.52, 0.86), 2.6, true)


func _is_large_room() -> bool:
	return room.type == Room.Type.BOSS or room.type == Room.Type.ELITE or room.type == Room.Type.BLESSING


func activate() -> void:
	if not available or not room:
		return

	room.selected = true
	GameSfx.play(GameSfx.MAP_SELECT, -4.0)
	clicked.emit(room)
	_refresh_visual_state()
	queue_redraw()
	animation_player.play("select")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event.is_action_pressed("left_mouse"):
		return

	activate()


func _on_mouse_entered() -> void:
	if room:
		hovered.emit(self)
		if available:
			GameSfx.play(GameSfx.UI_HOVER, -16.0)
			_animate_hover(1.18)


func _on_mouse_exited() -> void:
	if room:
		hover_cleared.emit(self)
		_animate_hover(1.0)


func _animate_hover(target: float) -> void:
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween() \
			.set_trans(Tween.TRANS_BACK if target > 1.0 else Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE * target, 0.18)


# Called by the AnimationPlayer when the select animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
