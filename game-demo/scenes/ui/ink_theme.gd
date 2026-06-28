class_name InkTheme
extends RefCounted

const TEXT := Color("eee7d2")
const TEXT_DIM := Color("b8ad8e")
const PAPER := Color("24251e")
const PAPER_DARK := Color("151715")
const GOLD := Color("b89648")
const RED := Color("8b2f2a")

const HUD_PANEL_FRAME := preload("res://art/ui/battle_hud/demonic_red/panel_frame.png")
const HUD_END_TURN_PLATE := preload("res://art/ui/battle_hud/demonic_red/end_turn_plate.png")
const HUD_BLUE_PANEL_FRAME := preload("res://art/ui/battle_hud/demonic_blue/panel_frame.png")
const HUD_BLUE_CLASS_EMBLEM := preload("res://art/ui/battle_hud/demonic_blue/top_class_emblem.png")
const HUD_BATTLE_TOP_BAR := preload("res://assets/ui/generated/battle/battle_top_hud_bar_9slice.png")
const HUD_BLUE_END_TURN_PLATE := preload("res://assets/ui/generated/battle/battle_end_turn_button_normal_9slice.png")
const HUD_BATTLE_END_TURN_HOVER := preload("res://assets/ui/generated/battle/battle_end_turn_button_hover_9slice.png")
const HUD_BATTLE_END_TURN_PRESSED := preload("res://assets/ui/generated/battle/battle_end_turn_button_pressed_9slice.png")
const HUD_BATTLE_END_TURN_DISABLED := preload("res://assets/ui/generated/battle/battle_end_turn_button_disabled_9slice.png")
const HUD_BLUE_TURN_BADGE := preload("res://assets/ui/generated/battle/battle_round_banner_9slice.png")
const HUD_BLUE_PILE_PANEL := preload("res://assets/ui/generated/battle/battle_draw_pile_panel_9slice.png")
const HUD_BATTLE_DISCARD_PILE_PANEL := preload("res://assets/ui/generated/battle/battle_discard_pile_panel_9slice.png")
const HUD_BLUE_DECK_PANEL := preload("res://assets/ui/generated/battle/battle_deck_button_normal_9slice.png")
const HUD_BATTLE_DECK_HOVER := preload("res://assets/ui/generated/battle/battle_deck_button_hover_9slice.png")
const HUD_BATTLE_DECK_PRESSED := preload("res://assets/ui/generated/battle/battle_deck_button_pressed_9slice.png")
const HUD_BLUE_TOP_LEFT_PANEL := preload("res://assets/ui/generated/battle/battle_player_identity_plate_9slice.png")
const HUD_BATTLE_SETTINGS_NORMAL := preload("res://assets/ui/generated/battle/battle_settings_button_normal.png")
const HUD_BATTLE_SETTINGS_HOVER := preload("res://assets/ui/generated/battle/battle_settings_button_hover.png")
const HUD_BATTLE_SETTINGS_PRESSED := preload("res://assets/ui/generated/battle/battle_settings_button_pressed.png")
const HUD_BATTLE_SETTINGS_ICON := preload("res://assets/ui/generated/icons/icon_settings_gear.png")
const HUD_BATTLE_DECK_ICON := preload("res://assets/ui/generated/icons/icon_card_deck_stack.png")


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


static func apply_demonic_panel(panel: Control) -> void:
	var style := make_style(
		Color(0.055, 0.035, 0.032, 0.86),
		Color(0.56, 0.29, 0.18, 0.88),
		2,
		6,
		Color(0, 0, 0, 0.45),
		8
	)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)


static func apply_demonic_button(button: Button, large := false) -> void:
	button.add_theme_color_override("font_color", Color("f8e5c0"))
	button.add_theme_color_override("font_hover_color", Color("fff1d0"))
	button.add_theme_color_override("font_pressed_color", Color("d7a85f"))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.54, 0.44, 0.42))
	button.add_theme_color_override("font_shadow_color", Color(0.08, 0, 0, 0.9))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_font_size_override("font_size", 25 if large else 21)
	button.add_theme_stylebox_override("normal", make_texture_style(HUD_END_TURN_PLATE, 42, 18, Color(1, 1, 1, 0.94)))
	button.add_theme_stylebox_override("hover", make_texture_style(HUD_END_TURN_PLATE, 42, 18, Color(1.16, 1.08, 0.92, 1.0)))
	button.add_theme_stylebox_override("pressed", make_texture_style(HUD_END_TURN_PLATE, 42, 18, Color(0.72, 0.62, 0.58, 0.96)))
	button.add_theme_stylebox_override("disabled", make_texture_style(HUD_END_TURN_PLATE, 42, 18, Color(0.42, 0.38, 0.36, 0.45)))


static func apply_battle_blue_panel(panel: Control) -> void:
	var style := make_texture_style(HUD_BLUE_PANEL_FRAME, 42, 18, Color(1, 1, 1, 0.96))
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


static func apply_battle_blue_button(button: Button, large := false) -> void:
	button.add_theme_color_override("font_color", Color("fff0c2"))
	button.add_theme_color_override("font_hover_color", Color("fff7d8"))
	button.add_theme_color_override("font_pressed_color", Color("d6b16e"))
	button.add_theme_color_override("font_disabled_color", Color(0.76, 0.60, 0.48, 0.45))
	button.add_theme_color_override("font_shadow_color", Color(0.04, 0, 0, 0.95))
	button.add_theme_constant_override("shadow_offset_x", 3)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.add_theme_font_size_override("font_size", 34 if large else 24)
	button.add_theme_stylebox_override("normal", make_texture_style(HUD_BLUE_END_TURN_PLATE, 42, 28, Color(1, 1, 1, 0.98)))
	button.add_theme_stylebox_override("hover", make_texture_style(HUD_BATTLE_END_TURN_HOVER, 42, 28, Color(1.08, 1.04, 0.98, 1.0)))
	button.add_theme_stylebox_override("pressed", make_texture_style(HUD_BATTLE_END_TURN_PRESSED, 42, 28, Color(0.82, 0.72, 0.66, 0.98)))
	button.add_theme_stylebox_override("disabled", make_texture_style(HUD_BATTLE_END_TURN_DISABLED, 42, 28, Color(0.62, 0.56, 0.52, 0.58)))


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


static func make_texture_style(texture: Texture2D, margin_x := 24, margin_y := 16, modulate := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin_x
	style.texture_margin_right = margin_x
	style.texture_margin_top = margin_y
	style.texture_margin_bottom = margin_y
	style.content_margin_left = 14
	style.content_margin_top = 8
	style.content_margin_right = 14
	style.content_margin_bottom = 8
	style.draw_center = true
	style.modulate_color = modulate
	return style
