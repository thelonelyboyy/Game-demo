class_name InkTheme
extends RefCounted

const TEXT := Color("eee7d2")
const TEXT_DIM := Color("b8ad8e")
const PAPER := Color("24251e")
const PAPER_DARK := Color("151715")
const GOLD := Color("b89648")
const RED := Color("8b2f2a")


static func add_backdrop(parent: Node, variant: String) -> InkBackdrop:
	var backdrop := InkBackdrop.new()
	backdrop.name = "InkBackdrop"
	backdrop.variant = variant
	parent.add_child(backdrop)
	parent.move_child(backdrop, 0)
	return backdrop


static func apply_button(button: Button, large := false) -> void:
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color("fff5d9"))
	button.add_theme_color_override("font_pressed_color", Color("d2bd82"))
	button.add_theme_color_override("font_disabled_color", Color(0.64, 0.60, 0.50, 0.42))
	button.add_theme_font_size_override("font_size", 24 if large else 20)
	button.add_theme_stylebox_override("normal", make_style(PAPER, GOLD, 2, 4, Color(0, 0, 0, 0.32), 8))
	button.add_theme_stylebox_override("hover", make_style(Color("303027"), Color("d0ad55"), 2, 4, Color(0.75, 0.55, 0.25, 0.38), 14))
	button.add_theme_stylebox_override("pressed", make_style(Color("171915"), Color("8f753c"), 2, 4, Color(0, 0, 0, 0.28), 4))
	button.add_theme_stylebox_override("disabled", make_style(Color(0.12, 0.13, 0.12, 0.55), Color(0.38, 0.35, 0.28, 0.45), 1, 4))


static func apply_buttons(root: Node, large := false) -> void:
	if root is Button:
		apply_button(root, large)
	for child in root.get_children():
		apply_buttons(child, large)


static func apply_title(label: Label, size := 58) -> void:
	label.add_theme_color_override("font_color", Color("f4ead1"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.66))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_font_size_override("font_size", size)


static func apply_body_label(label: Label, size := 24) -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func apply_panel(panel: Control) -> void:
	panel.add_theme_stylebox_override("panel", make_style(Color(0.10, 0.11, 0.10, 0.82), Color(0.63, 0.52, 0.30, 0.72), 2, 6, Color(0, 0, 0, 0.42), 12))


static func make_style(bg: Color, border: Color, border_width := 1, radius := 4, shadow := Color(0, 0, 0, 0), shadow_size := 0) -> StyleBoxFlat:
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
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
