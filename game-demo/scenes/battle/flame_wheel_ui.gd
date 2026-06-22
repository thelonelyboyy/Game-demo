class_name FlameWheelUI
extends PanelContainer

## 战斗内焰轮显示：7 色色珠，本回合点亮的颜色高亮，其余暗淡。空焰轮时隐藏。

const COLORS := [
	Color("a05cd6"),  # 紫
	Color("e8e8f0"),  # 白
	Color("4fc77a"),  # 绿
	Color("5a9bf0"),  # 蓝
	Color("403848"),  # 黑
	Color("f0cc4d"),  # 黄
	Color("e05050"),  # 红
]
const DIM := 0.22

var _pips: Array[ColorRect] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "焰轮：本回合已打出的魔焰颜色。共鸣按已有的其它颜色数结算，回合结束清空。"
	InkTheme.apply_panel(self)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	add_child(row)

	var label := Label.new()
	label.text = "焰"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("f0cc4d"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	for i in COLORS.size():
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(16, 22)
		pip.color = COLORS[i]
		pip.modulate = Color(1, 1, 1, DIM)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
		_pips.append(pip)

	if not Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.connect(_on_flame_wheel_changed)
	hide()


func _on_flame_wheel_changed(colors: Array) -> void:
	for i in _pips.size():
		_pips[i].modulate = Color.WHITE if colors.has(i) else Color(1, 1, 1, DIM)
	visible = not colors.is_empty()


func _exit_tree() -> void:
	if Events.flame_wheel_changed.is_connected(_on_flame_wheel_changed):
		Events.flame_wheel_changed.disconnect(_on_flame_wheel_changed)
