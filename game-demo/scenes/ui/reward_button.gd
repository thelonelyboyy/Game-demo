class_name RewardButton
extends Button

@export var reward_icon: Texture : set = set_reward_icon
@export var reward_text: String : set = set_reward_text
@export_multiline var reward_subtext: String : set = set_reward_subtext
@export var accent_color := Color("b89648") : set = set_accent_color
@export var auto_consume := true

@onready var custom_icon: TextureRect = %CustomIcon
@onready var custom_text: Label = %CustomText
@onready var custom_subtext: Label = %CustomSubtext
@onready var icon_frame: PanelContainer = %IconFrame


func _ready() -> void:
	_apply_visuals()
	set_reward_icon(reward_icon)
	set_reward_text(reward_text)
	set_reward_subtext(reward_subtext)


func set_reward_icon(new_icon: Texture) -> void:
	reward_icon = new_icon
	if not is_node_ready():
		await ready
	custom_icon.texture = reward_icon


func set_reward_text(new_text: String) -> void:
	reward_text = new_text
	if not is_node_ready():
		await ready
	custom_text.text = reward_text


func set_reward_subtext(new_text: String) -> void:
	reward_subtext = new_text
	if not is_node_ready():
		await ready
	custom_subtext.text = reward_subtext
	custom_subtext.visible = not reward_subtext.is_empty()


func set_accent_color(new_color: Color) -> void:
	accent_color = new_color
	if is_node_ready():
		_apply_visuals()


func _on_pressed() -> void:
	if not auto_consume:
		return

	queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(220, 236)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("normal", _make_style(Color(0.04, 0.13, 0.15, 0.88), accent_color.darkened(0.30), 2, Color(0, 0, 0, 0.42), 12))
	add_theme_stylebox_override("hover", _make_style(Color(0.07, 0.25, 0.30, 0.96), accent_color.lightened(0.18), 2, Color(accent_color.r, accent_color.g, accent_color.b, 0.24), 16))
	add_theme_stylebox_override("pressed", _make_style(Color(0.03, 0.10, 0.12, 0.98), Color("f2c94f"), 2, Color(0, 0, 0, 0.36), 8))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	icon_frame.add_theme_stylebox_override("panel", _make_style(Color(0.02, 0.08, 0.10, 0.78), accent_color, 2, Color(accent_color.r, accent_color.g, accent_color.b, 0.22), 10))
	custom_icon.custom_minimum_size = Vector2(92, 92)
	custom_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	custom_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	custom_text.add_theme_color_override("font_color", Color("f8e7ad"))
	custom_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	custom_text.add_theme_constant_override("shadow_offset_x", 2)
	custom_text.add_theme_constant_override("shadow_offset_y", 2)
	custom_text.add_theme_font_size_override("font_size", 24)

	custom_subtext.add_theme_color_override("font_color", Color("d7eef4"))
	custom_subtext.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.66))
	custom_subtext.add_theme_constant_override("shadow_offset_x", 1)
	custom_subtext.add_theme_constant_override("shadow_offset_y", 2)
	custom_subtext.add_theme_font_size_override("font_size", 17)
	custom_subtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 71.0)
	draw_circle(center, 54.0, Color(accent_color.r, accent_color.g, accent_color.b, 0.10))
	draw_arc(center, 72.0, -0.35, TAU - 0.35, 72, Color(accent_color.r, accent_color.g, accent_color.b, 0.28), 2.0, true)


func _make_style(bg: Color, border: Color, border_width := 1, shadow := Color(0, 0, 0, 0.34), shadow_size := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
