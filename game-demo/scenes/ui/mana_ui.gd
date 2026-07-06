class_name ManaUI
extends Panel

const ENERGY_ORB_FRAME := preload("res://assets/ui/generated/battle/battle_energy_orb_frame.png")
const ENERGY_ORB_FILL := preload("res://assets/ui/generated/battle/battle_energy_orb_fill_mask.png")
const BATTLE_ENERGY_ORB := preload("res://art/ui/battle_widgets/battle_energy_orb.png")

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var mana_label: Label = $ManaLabel
@onready var frame: TextureRect = $Frame

var _active := true
var _fill: TextureRect


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.texture = BATTLE_ENERGY_ORB
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ensure_fill()
	queue_redraw()


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	
	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()


func _on_stats_changed() -> void:
	mana_label.text = str(char_stats.mana)
	_active = char_stats.mana > 0
	frame.modulate = Color.WHITE if _active else Color(0.55, 0.48, 0.48, 0.78)
	mana_label.modulate = Color.WHITE if _active else Color(0.68, 0.72, 0.75, 0.72)
	if _fill:
		var mana_ratio := clampf(float(char_stats.mana) / float(maxi(char_stats.max_mana, 1)), 0.0, 1.0)
		_fill.modulate = Color(0.56, 0.20, 1.0, 0.28 + 0.52 * mana_ratio) if _active else Color(0.28, 0.20, 0.38, 0.18)
		_fill.scale = Vector2.ONE * (0.86 + 0.10 * mana_ratio)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var glow := Color(0.46, 0.18, 1.0, 0.38 if _active else 0.12)
	var core := Color(0.008, 0.018, 0.055, 0.88)
	var rim := Color(0.46, 0.76, 1.0, 0.96 if _active else 0.34)

	draw_circle(center, radius + 14.0, Color(0.0, 0.0, 0.0, 0.34))
	draw_circle(center, radius + 7.0, glow)
	draw_circle(center, radius, core)
	draw_arc(center, radius + 2.0, -PI * 0.12, PI * 1.12, 64, rim, 2.0, true)
	draw_arc(center, radius * 0.72, PI * 0.64, PI * 1.94, 48, Color(0.58, 0.24, 1.0, 0.48), 1.5, true)


func _ensure_fill() -> void:
	_fill = get_node_or_null("EnergyFill") as TextureRect
	if not _fill:
		_fill = TextureRect.new()
		_fill.name = "EnergyFill"
		_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fill.texture = ENERGY_ORB_FILL
		_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_fill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_fill)
		move_child(_fill, 0)

	_fill.anchor_left = 0.0
	_fill.anchor_top = 0.0
	_fill.anchor_right = 1.0
	_fill.anchor_bottom = 1.0
	_fill.offset_left = 21.0
	_fill.offset_top = 21.0
	_fill.offset_right = -21.0
	_fill.offset_bottom = -21.0
	_fill.pivot_offset = _fill.size * 0.5
