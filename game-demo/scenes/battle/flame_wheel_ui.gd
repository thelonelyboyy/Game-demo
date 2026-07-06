class_name FlameWheelUI
extends PanelContainer

const WHEEL_FRAME := preload("res://assets/ui/generated/battle/battle_element_wheel_aligned.png")
const SLOT_GLOW_TEXTURES := [
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_purple.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_yellow.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_green.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_blue.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_purple.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_yellow.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_red.png"),
]

const PANEL_SIZE := Vector2(300, 236)
const GLOW_SIZE := Vector2(66, 66)
const ACTIVE_MODULATES := [
	Color(1.08, 1.0, 1.0, 0.92),
	Color(0.82, 0.9, 1.0, 0.72),
	Color(1.0, 1.05, 1.0, 0.88),
	Color(1.0, 1.0, 1.0, 0.88),
	Color(0.24, 0.18, 0.32, 0.74),
	Color(1.08, 1.0, 0.86, 0.9),
	Color(1.08, 0.9, 0.86, 0.9),
]
const PIP_POSITIONS := [
	Vector2(72, 136),
	Vector2(74, 88),
	Vector2(150, 50),
	Vector2(226, 88),
	Vector2(150, 118),
	Vector2(226, 136),
	Vector2(150, 171),
]

var _pips: Array[TextureRect] = []
var _active := false
var _lit_colors := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "焰轮：本回合已打出的魔焰颜色。共鸣按已有的其它颜色数结算，回合结束清空。"
	custom_minimum_size = PANEL_SIZE
	z_index = 2
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var stage := Control.new()
	stage.name = "FlameWheelStage"
	stage.custom_minimum_size = PANEL_SIZE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	var frame := TextureRect.new()
	frame.name = "WheelFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.texture = WHEEL_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.add_child(frame)

	for i in PIP_POSITIONS.size():
		var glow := TextureRect.new()
		glow.name = "ActiveGlow%s" % i
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.position = PIP_POSITIONS[i] - GLOW_SIZE * 0.5
		glow.size = GLOW_SIZE
		glow.texture = SLOT_GLOW_TEXTURES[i]
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.modulate = Color(1, 1, 1, 0)
		glow.visible = false
		stage.add_child(glow)
		_pips.append(glow)

	var title := Label.new()
	title.name = "Title"
	title.text = "焰轮"
	title.position = Vector2(114, 202)
	title.size = Vector2(72, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("f4d389"))
	title.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(title)

	if not Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.connect(_on_flame_wheel_changed)
	visible = _active


func activate() -> void:
	_active = true
	show()


func _on_flame_wheel_changed(colors: Array) -> void:
	for i in _pips.size():
		var lit := colors.has(i)
		var was_lit: bool = _lit_colors.has(i)
		_pips[i].visible = lit
		if lit and not was_lit:
			_flash_pip(i)
		elif lit:
			_pips[i].modulate = ACTIVE_MODULATES[i]
		else:
			_pips[i].modulate = Color(1, 1, 1, 0)

	_lit_colors.clear()
	for color in colors:
		_lit_colors[color] = true
	visible = _active


# 新点亮的色珠：放大回落 + 从高亮闪到常态，让"这张魔焰加了色"看得见。
func _flash_pip(index: int) -> void:
	var pip := _pips[index]
	var target: Color = ACTIVE_MODULATES[index]
	pip.pivot_offset = GLOW_SIZE * 0.5
	pip.scale = Vector2.ONE * 1.7
	pip.modulate = Color(
		minf(target.r * 2.2 + 0.4, 3.0),
		minf(target.g * 2.2 + 0.4, 3.0),
		minf(target.b * 2.2 + 0.4, 3.0),
		1.0
	)
	var tween := pip.create_tween().set_parallel(true)
	tween.tween_property(pip, "scale", Vector2.ONE, 0.46) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pip, "modulate", target, 0.55) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _exit_tree() -> void:
	if Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.disconnect(_on_flame_wheel_changed)
