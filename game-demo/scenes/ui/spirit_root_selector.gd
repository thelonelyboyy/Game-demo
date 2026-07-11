extends Control

const RUN_SCENE := preload("res://scenes/run/run.tscn")
const SELECTOR_BACKGROUND := preload("res://art/backgrounds/blessing_cavern_bg.png")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var content: VBoxContainer = $Content
@onready var buttons: VBoxContainer = %Buttons

var offered_roots: Array = []


func _ready() -> void:
	InkTheme.animate_screen_entrance(self, 0.4)
	_polish_scene()
	_roll_spirit_roots()
	_setup_buttons()


func _roll_spirit_roots() -> void:
	offered_roots = [
		Card.Element.METAL,
		Card.Element.WOOD,
		Card.Element.WATER,
		Card.Element.FIRE,
		Card.Element.EARTH,
	]
	RNG.array_shuffle(offered_roots)
	offered_roots = offered_roots.slice(0, 3)


func _setup_buttons() -> void:
	title.text = "选择灵根"
	description.text = "从三种灵根中选择一种，开局会将一张打击或防御转化为所选元素，并获得一张对应元素的职业卡。"

	for child: Node in buttons.get_children():
		child.queue_free()

	for root in offered_roots:
		var row := _create_root_row(root)
		buttons.add_child(row)
		InkTheme.wire_button_sfx(row)
		InkTheme.animate_item_entrance(row, 0.12)


func _on_root_selected(root: Card.Element) -> void:
	# 定灵根的仪式感：与选人「开始修行」呼应的一记锣。
	GameSfx.play(GameSfx.GONG, -4.0)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.selected_spirit_root = root
	get_tree().change_scene_to_packed(RUN_SCENE)


func _polish_scene() -> void:
	_apply_custom_background()
	_apply_content_layout()
	_apply_title_style()
	_apply_description_style()


func _apply_custom_background() -> void:
	var background := $Background as TextureRect
	background.texture = SELECTOR_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()


func _apply_content_layout() -> void:
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -470.0
	content.offset_top = -108.0
	content.offset_right = 470.0
	content.offset_bottom = 360.0
	content.add_theme_constant_override("separation", 14)

	buttons.add_theme_constant_override("separation", 12)
	buttons.custom_minimum_size = Vector2(940, 264)


func _apply_title_style() -> void:
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	InkTheme.apply_screen_title(title, 58)


func _apply_description_style() -> void:
	description.custom_minimum_size = Vector2(940, 52)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	InkTheme.apply_subtitle(description, 24)


func _create_root_row(root: Card.Element) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(940, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.pressed.connect(_on_root_selected.bind(root))
	_apply_root_button_style(button, root)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 22
	row.offset_top = 8
	row.offset_right = -22
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 18)
	button.add_child(row)

	var icon := PanelContainer.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(58, 58)
	icon.add_theme_stylebox_override("panel", _make_round_style(
		SpiritRootText.element_color(root).darkened(0.45),
		SpiritRootText.element_color(root).lightened(0.20),
		2,
		29,
		Color(0, 0, 0, 0.52),
		8
	))
	row.add_child(icon)

	var glyph := Label.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.text = _element_glyph(root)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override("font_color", Color("f6efd8"))
	glyph.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	glyph.add_theme_constant_override("shadow_offset_x", 2)
	glyph.add_theme_constant_override("shadow_offset_y", 2)
	glyph.add_theme_font_size_override("font_size", 30)
	icon.add_child(glyph)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = "%s灵根" % SpiritRootText.element_name(root)
	name_label.add_theme_color_override("font_color", SpiritRootText.element_color(root).lightened(0.16))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.add_theme_font_size_override("font_size", 25)
	text_box.add_child(name_label)

	var effect := Label.new()
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.text = SpiritRootText.perfect_effect(root)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_color_override("font_color", Color("f4efe4"))
	effect.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	effect.add_theme_constant_override("shadow_offset_x", 2)
	effect.add_theme_constant_override("shadow_offset_y", 2)
	effect.add_theme_font_size_override("font_size", 21)
	text_box.add_child(effect)

	return button


func _apply_root_button_style(button: Button, root: Card.Element) -> void:
	var element_color := SpiritRootText.element_color(root)
	button.add_theme_stylebox_override("normal", _make_round_style(Color(0.045, 0.030, 0.028, 0.78), element_color.darkened(0.28), 1, 8))
	button.add_theme_stylebox_override("hover", _make_round_style(Color(0.090, 0.045, 0.038, 0.90), element_color.lightened(0.18), 2, 8, Color(element_color.r, element_color.g, element_color.b, 0.16), 10))
	button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.030, 0.020, 0.020, 0.96), Color("f2c94f"), 2, 8))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)


func _element_glyph(root: Card.Element) -> String:
	match root:
		Card.Element.METAL:
			return "金"
		Card.Element.WOOD:
			return "木"
		Card.Element.WATER:
			return "水"
		Card.Element.FIRE:
			return "火"
		Card.Element.EARTH:
			return "土"
		_:
			return "?"


func _make_round_style(bg: Color, border: Color, border_width := 1, radius := 8, shadow := Color(0, 0, 0, 0.38), shadow_size := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_top = 8
	style.content_margin_right = 16
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
