class_name FlameWheelUI
extends PanelContainer

## 战斗内焰轮显示：7 色色珠，本回合点亮的颜色高亮，其余暗淡。

const WHEEL_FRAME := preload("res://assets/ui/generated/battle/battle_element_wheel_base.png")
const SLOT_FRAME := preload("res://assets/ui/generated/battle/battle_element_slot_empty.png")
const SLOT_GLOW_TEXTURES := [
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_purple.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_blue.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_green.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_blue.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_orange.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_yellow.png"),
	preload("res://assets/ui/generated/battle/battle_element_slot_glow_red.png"),
]
const PANEL_SIZE := Vector2(300, 236)
const SLOT_SIZE := Vector2(54, 54)
const GLOW_SIZE := Vector2(72, 72)
const CORE_SIZE := Vector2(42, 42)
const INACTIVE_GLOW_MODULATE := Color(1, 1, 1, 0.62)
const INACTIVE_CORE_MODULATE := Color(1, 1, 1, 0.78)
const ACTIVE_GLOW_MODULATE := Color(1.08, 1.04, 1.0, 1.0)
const COLORS := [
	Color("a05cd6"),  # 紫
	Color("e8e8f0"),  # 白
	Color("4fc77a"),  # 绿
	Color("5a9bf0"),  # 蓝
	Color("403848"),  # 黑
	Color("f0cc4d"),  # 黄
	Color("e05050"),  # 红
]
const PIP_POSITIONS := [
	Vector2(50, 154),
	Vector2(80, 107),
	Vector2(122, 82),
	Vector2(150, 74),
	Vector2(178, 82),
	Vector2(220, 107),
	Vector2(250, 154),
]
var _pips: Array[TextureRect] = []
var _active := false   # 魔修战斗：从开局起常显（即使焰轮为空）


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "焰轮：本回合已打出的魔焰颜色。共鸣按已有的其它颜色数结算，回合结束清空。"
	custom_minimum_size = PANEL_SIZE
	z_index = -2
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
	frame.modulate = Color(1, 1, 1, 1)
	stage.add_child(frame)

	var title := Label.new()
	title.name = "Title"
	title.text = "焰轮"
	title.position = Vector2(114, 184)
	title.size = Vector2(72, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("f4d389"))
	title.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(title)

	for i in COLORS.size():
		var slot := Control.new()
		slot.position = PIP_POSITIONS[i] - GLOW_SIZE * 0.5
		slot.size = GLOW_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(slot)

		var glow := TextureRect.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.texture = SLOT_GLOW_TEXTURES[i]
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.modulate = INACTIVE_GLOW_MODULATE
		slot.add_child(glow)

		var slot_frame := TextureRect.new()
		slot_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_frame.position = (GLOW_SIZE - SLOT_SIZE) * 0.5
		slot_frame.size = SLOT_SIZE
		slot_frame.texture = SLOT_FRAME
		slot_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_frame.modulate = Color(1.0, 0.88, 0.62, 0.96)
		slot.add_child(slot_frame)

		var core := TextureRect.new()
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		core.position = (GLOW_SIZE - CORE_SIZE) * 0.5
		core.size = CORE_SIZE
		core.texture = SLOT_GLOW_TEXTURES[i]
		core.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		core.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		core.modulate = INACTIVE_CORE_MODULATE
		slot.add_child(core)

		_pips.append(core)

	if not Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.connect(_on_flame_wheel_changed)
	# 按 _active 决定初始可见性，避免 activate() 早于 _ready 时被这里盖掉。
	visible = _active


## 魔修战斗开始时调用：焰轮常显（空时全暗）。
func activate() -> void:
	_active = true
	show()


func _on_flame_wheel_changed(colors: Array) -> void:
	for i in _pips.size():
		_pips[i].modulate = _lit_color(COLORS[i]) if colors.has(i) else INACTIVE_CORE_MODULATE
	visible = _active


func _lit_color(_color: Color) -> Color:
	return ACTIVE_GLOW_MODULATE


func _dim_color(color: Color) -> Color:
	return Color(color.r * 0.48, color.g * 0.48, color.b * 0.48, 0.26)


func _exit_tree() -> void:
	if Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.disconnect(_on_flame_wheel_changed)
