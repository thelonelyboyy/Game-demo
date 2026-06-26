extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const MENU_BACKGROUND := preload("res://art/backgrounds/background1.png")

const OUTER_FRAME_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_outer_frame_9slice.png")
const CENTER_PANEL_TEXTURE := preload("res://assets/ui/generated/panels/main_menu_center_panel_9slice.png")
const VERSION_PLATE_TEXTURE := preload("res://assets/ui/generated/panels/main_menu_version_plate_9slice.png")
const BUTTON_NORMAL_TEXTURE := preload("res://assets/ui/generated/buttons/main_menu_button_normal_9slice.png")
const BUTTON_HOVER_TEXTURE := preload("res://assets/ui/generated/buttons/main_menu_button_hover_9slice.png")
const BUTTON_PRESSED_TEXTURE := preload("res://assets/ui/generated/buttons/main_menu_button_pressed_9slice.png")
const BUTTON_DISABLED_TEXTURE := preload("res://assets/ui/generated/buttons/main_menu_button_disabled_9slice.png")
const TOP_DRAGON_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_top_dragon_ornament.png")
const HANGING_TAG_LEFT_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_hanging_tag_left.png")
const HANGING_TAG_RIGHT_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_hanging_tag_right.png")
const CORNER_TL_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_corner_ornament_tl.png")
const CORNER_TR_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_corner_ornament_tr.png")
const CORNER_BL_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_corner_ornament_bl.png")
const CORNER_BR_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_corner_ornament_br.png")
const BOTTOM_ORNAMENT_TEXTURE := preload("res://assets/ui/generated/decorations/main_menu_bottom_center_ornament.png")

const REFERENCE_SIZE := Vector2(1672.0, 941.0)
const PANEL_TEXTURE_MARGINS := Vector4(48.0, 48.0, 48.0, 48.0)
const BUTTON_TEXTURE_MARGINS := Vector4(32.0, 22.0, 32.0, 22.0)
const BUTTON_SELECTED_EXPAND_MARGINS := Vector4(12.0, 0.0, 12.0, 0.0)
const VERSION_TEXTURE_MARGINS := Vector4(28.0, 18.0, 28.0, 18.0)
const OUTER_FRAME_MARGINS := Vector4(72.0, 72.0, 72.0, 72.0)
const MENU_PANEL_Y_OFFSET := 26.0

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var codex_panel: Control = $CodexPanel
@onready var menu_panel: PanelContainer = %MenuPanel
@onready var menu_margin: MarginContainer = $MenuPanel/MenuMargin
@onready var menu_vbox: VBoxContainer = $MenuPanel/MenuMargin/MenuVBox
@onready var panel_title: Label = %PanelTitle
@onready var panel_rule: ColorRect = %PanelRule
@onready var subtitle: Label = %Subtitle
@onready var footer_hint: Label = %FooterHint
@onready var settings_toast: Label = %SettingsToast


func _ready() -> void:
	get_tree().paused = false
	_polish_scene()
	get_viewport().size_changed.connect(_apply_layout)
	var has_save := SaveGame.load_data() != null
	continue_button.disabled = not has_save


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_codex_pressed() -> void:
	codex_panel.show()


func _on_settings_pressed() -> void:
	settings_toast.show()
	settings_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(settings_toast, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(settings_toast, "hide"))


func _on_exit_pressed() -> void:
	get_tree().quit()


func _polish_scene() -> void:
	_apply_custom_background()
	_apply_decorations()
	_apply_layout()
	_apply_title_style()
	_apply_menu_panel_style()
	_apply_menu_button_style()
	_apply_toast_style()
	_spawn_spirit_motes()
	_animate_breathing_glow()


func _spawn_spirit_motes() -> void:
	if has_node("SpiritMotes"):
		return
	var view_size := get_viewport_rect().size
	var p := GPUParticles2D.new()
	p.name = "SpiritMotes"
	p.amount = 160
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.position = Vector2(view_size.x * 0.5, view_size.y + 8.0)
	p.z_index = -80

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(view_size.x * 0.75, 12.0, 1.0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 18.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 45.0
	mat.initial_velocity_max = 110.0
	mat.scale_min = 0.7
	mat.scale_max = 2.4

	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.28, 0.2, 0.0))
	grad.set_color(1, Color(1.0, 0.35, 0.24, 0.0))
	grad.add_point(0.5, Color(1.0, 0.3, 0.2, 0.9))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	p.process_material = mat

	var cmat := CanvasItemMaterial.new()
	cmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = cmat

	add_child(p)
	p.emitting = true


func _animate_breathing_glow() -> void:
	var background := $Background as TextureRect
	var dim := Color(0.90, 0.90, 0.94)
	var bright := Color(1.18, 1.16, 1.18)
	background.modulate = dim
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "modulate", bright, 5.0)
	tween.tween_property(background, "modulate", dim, 5.0)


func _apply_layout() -> void:
	var view_size := get_viewport_rect().size
	var scale := _ui_scale(view_size)

	_layout_screen_decorations(view_size, scale)

	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)
	subtitle.offset_left = 56.0 * scale
	subtitle.offset_top = -78.0 * scale
	subtitle.offset_right = 560.0 * scale
	subtitle.offset_bottom = -48.0 * scale

	footer_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)
	footer_hint.offset_left = 56.0 * scale
	footer_hint.offset_top = -46.0 * scale
	footer_hint.offset_right = 420.0 * scale
	footer_hint.offset_bottom = -18.0 * scale

	var panel_size := Vector2(380.0, 410.0) * scale
	menu_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	menu_panel.position = Vector2((view_size.x - panel_size.x) * 0.5, view_size.y * 0.462 + MENU_PANEL_Y_OFFSET * scale)
	menu_panel.size = panel_size
	menu_panel.custom_minimum_size = panel_size

	menu_margin.add_theme_constant_override("margin_left", int(28.0 * scale))
	menu_margin.add_theme_constant_override("margin_top", int(36.0 * scale))
	menu_margin.add_theme_constant_override("margin_right", int(28.0 * scale))
	menu_margin.add_theme_constant_override("margin_bottom", int(34.0 * scale))
	menu_vbox.add_theme_constant_override("separation", int(9.0 * scale))

	for child: Node in menu_vbox.get_children():
		if not child is Button:
			continue
		var button := child as Button
		button.custom_minimum_size = Vector2(322.0, 56.0) * scale
		button.add_theme_font_size_override("font_size", int(round(27.0 * scale)))

	settings_toast.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	settings_toast.size = Vector2(520.0, 42.0) * scale
	settings_toast.position = Vector2(
		(view_size.x - settings_toast.size.x) * 0.5,
		min(view_size.y - 98.0 * scale, menu_panel.position.y + panel_size.y + 18.0 * scale)
	)


func _apply_custom_background() -> void:
	var background := $Background as TextureRect
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -100
	background.show()

	var atmosphere := $Atmosphere as ColorRect
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.color = Color(0.016, 0.011, 0.008, 0.04)
	atmosphere.z_index = -70


func _apply_title_style() -> void:
	var scale := _ui_scale(get_viewport_rect().size)
	subtitle.text = "暗黑修仙 · Roguelike 卡牌"
	subtitle.add_theme_color_override("font_color", Color("d9c089"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", int(round(19.0 * scale)))
	subtitle.z_index = 10

	footer_hint.text = "版本号：v1.0.0"
	footer_hint.add_theme_color_override("font_color", Color(0.82, 0.74, 0.58, 0.76))
	footer_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	footer_hint.add_theme_constant_override("shadow_offset_x", 2)
	footer_hint.add_theme_constant_override("shadow_offset_y", 2)
	footer_hint.add_theme_font_size_override("font_size", int(round(16.0 * scale)))
	footer_hint.z_index = 10


func _apply_menu_panel_style() -> void:
	menu_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	menu_panel.z_index = 5
	panel_title.hide()
	panel_rule.hide()


func _apply_menu_button_style() -> void:
	var labels := {
		"Continue": "继续游戏",
		"NewRun": "新的轮回",
		"Codex": "图鉴大全",
		"Settings": "设置",
		"Exit": "退出",
	}
	for child: Node in menu_vbox.get_children():
		if not child is Button:
			continue
		var button := child as Button
		button.text = labels.get(button.name, button.text)
		button.flat = false
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _make_texture_style(BUTTON_NORMAL_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(18, 6, 18, 6), Color(0.94, 0.92, 0.86, 0.94)))
		button.add_theme_stylebox_override("hover", _make_texture_style(BUTTON_HOVER_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(18, 6, 18, 6), Color.WHITE, BUTTON_SELECTED_EXPAND_MARGINS))
		button.add_theme_stylebox_override("pressed", _make_texture_style(BUTTON_PRESSED_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(18, 6, 18, 6), Color(0.96, 0.88, 0.72, 0.98), BUTTON_SELECTED_EXPAND_MARGINS))
		button.add_theme_stylebox_override("disabled", _make_texture_style(BUTTON_DISABLED_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(18, 6, 18, 6), Color(0.72, 0.68, 0.58, 0.62)))
		button.add_theme_stylebox_override("focus", _make_texture_style(BUTTON_HOVER_TEXTURE, BUTTON_TEXTURE_MARGINS, Vector4(18, 6, 18, 6), Color(1.0, 0.96, 0.82, 0.92), BUTTON_SELECTED_EXPAND_MARGINS))
		button.add_theme_color_override("font_color", Color("e8d2a0"))
		button.add_theme_color_override("font_hover_color", Color("ffe38a"))
		button.add_theme_color_override("font_pressed_color", Color("f2c94f"))
		button.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.60, 0.42))
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.03, 0.9))
		button.add_theme_constant_override("outline_size", 3)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _apply_toast_style() -> void:
	settings_toast.text = "设置功能暂未开放"
	settings_toast.add_theme_color_override("font_color", Color("f4e2bd"))
	settings_toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	settings_toast.add_theme_constant_override("shadow_offset_x", 2)
	settings_toast.add_theme_constant_override("shadow_offset_y", 2)
	settings_toast.add_theme_font_size_override("font_size", int(round(18.0 * _ui_scale(get_viewport_rect().size))))
	settings_toast.z_index = 20


func _apply_decorations() -> void:
	_ensure_nine_patch("OuterFrame", OUTER_FRAME_TEXTURE, OUTER_FRAME_MARGINS, false, -35)
	_ensure_nine_patch("VersionPlate", VERSION_PLATE_TEXTURE, VERSION_TEXTURE_MARGINS, true, -20)
	_ensure_texture_rect("TopDragonOrnament", TOP_DRAGON_TEXTURE, -25)
	_ensure_texture_rect("BottomCenterOrnament", BOTTOM_ORNAMENT_TEXTURE, -20)
	_ensure_texture_rect("HangingTagLeft", HANGING_TAG_LEFT_TEXTURE, -30)
	_ensure_texture_rect("HangingTagRight", HANGING_TAG_RIGHT_TEXTURE, -30)
	_ensure_texture_rect("CornerTopLeft", CORNER_TL_TEXTURE, -18)
	_ensure_texture_rect("CornerTopRight", CORNER_TR_TEXTURE, -18)
	_ensure_texture_rect("CornerBottomLeft", CORNER_BL_TEXTURE, -18)
	_ensure_texture_rect("CornerBottomRight", CORNER_BR_TEXTURE, -18)
	codex_panel.z_index = 100


func _layout_screen_decorations(view_size: Vector2, scale: float) -> void:
	var outer := get_node_or_null("OuterFrame") as NinePatchRect
	if outer:
		_set_control_rect(outer, Vector2.ZERO, view_size)
		outer.modulate = Color(1.0, 0.92, 0.76, 0.82)

	var dragon := get_node_or_null("TopDragonOrnament") as TextureRect
	if dragon:
		var dragon_size := Vector2(310.0, 164.0) * scale
		_set_control_rect(dragon, Vector2((view_size.x - dragon_size.x) * 0.5, 4.0 * scale), dragon_size)
		dragon.modulate = Color(1.0, 0.91, 0.78, 0.78)

	var bottom := get_node_or_null("BottomCenterOrnament") as TextureRect
	if bottom:
		var bottom_size := Vector2(230.0, 92.0) * scale
		_set_control_rect(bottom, Vector2((view_size.x - bottom_size.x) * 0.5, view_size.y - 74.0 * scale), bottom_size)
		bottom.modulate = Color(1.0, 0.92, 0.78, 0.82)

	var left_tag := get_node_or_null("HangingTagLeft") as TextureRect
	if left_tag:
		var tag_size := Vector2(88.0, 212.0) * scale
		_set_control_rect(left_tag, Vector2(128.0 * scale, 72.0 * scale), tag_size)
		left_tag.modulate = Color(1.0, 0.87, 0.68, 0.66)

	var right_tag := get_node_or_null("HangingTagRight") as TextureRect
	if right_tag:
		var tag_size := Vector2(88.0, 212.0) * scale
		_set_control_rect(right_tag, Vector2(view_size.x - 216.0 * scale, 72.0 * scale), tag_size)
		right_tag.modulate = Color(1.0, 0.87, 0.68, 0.66)

	var corner_size := Vector2(164.0, 164.0) * scale
	_set_named_rect("CornerTopLeft", Vector2(10.0 * scale, 8.0 * scale), corner_size, Color(1.0, 0.88, 0.66, 0.72))
	_set_named_rect("CornerTopRight", Vector2(view_size.x - corner_size.x - 10.0 * scale, 8.0 * scale), corner_size, Color(1.0, 0.88, 0.66, 0.72))
	_set_named_rect("CornerBottomLeft", Vector2(10.0 * scale, view_size.y - corner_size.y - 8.0 * scale), corner_size, Color(1.0, 0.88, 0.66, 0.68))
	_set_named_rect("CornerBottomRight", Vector2(view_size.x - corner_size.x - 10.0 * scale, view_size.y - corner_size.y - 8.0 * scale), corner_size, Color(1.0, 0.88, 0.66, 0.68))

	var version_plate := get_node_or_null("VersionPlate") as NinePatchRect
	if version_plate:
		var plate_size := Vector2(370.0, 76.0) * scale
		_set_control_rect(version_plate, Vector2(34.0 * scale, view_size.y - 94.0 * scale), plate_size)
		version_plate.modulate = Color(1.0, 0.9, 0.68, 0.42)


func _set_named_rect(node_name: String, position: Vector2, size: Vector2, color: Color) -> void:
	var node := get_node_or_null(node_name) as TextureRect
	if not node:
		return
	_set_control_rect(node, position, size)
	node.modulate = color


func _ensure_texture_rect(node_name: String, texture: Texture2D, z: int = 0) -> TextureRect:
	var rect := get_node_or_null(node_name) as TextureRect
	if rect == null:
		rect = TextureRect.new()
		rect.name = node_name
		add_child(rect)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	return rect


func _ensure_nine_patch(node_name: String, texture: Texture2D, margins: Vector4, draw_center: bool, z: int = 0) -> NinePatchRect:
	var rect := get_node_or_null(node_name) as NinePatchRect
	if rect == null:
		rect = NinePatchRect.new()
		rect.name = node_name
		add_child(rect)
	rect.texture = texture
	rect.patch_margin_left = int(margins.x)
	rect.patch_margin_top = int(margins.y)
	rect.patch_margin_right = int(margins.z)
	rect.patch_margin_bottom = int(margins.w)
	rect.draw_center = draw_center
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	return rect


func _set_control_rect(control: Control, position: Vector2, size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	control.position = position
	control.size = size


func _make_texture_style(
	texture: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4 = Vector4(12.0, 8.0, 12.0, 8.0),
	tint: Color = Color.WHITE,
	expand_margins: Vector4 = Vector4.ZERO,
	draw_center: bool = true
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = draw_center
	style.expand_margin_left = expand_margins.x
	style.expand_margin_top = expand_margins.y
	style.expand_margin_right = expand_margins.z
	style.expand_margin_bottom = expand_margins.w
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


func _ui_scale(view_size: Vector2) -> float:
	var width_scale: float = view_size.x / REFERENCE_SIZE.x
	var height_scale: float = view_size.y / REFERENCE_SIZE.y
	var raw_scale: float = width_scale if width_scale < height_scale else height_scale
	return clampf(raw_scale, 0.84, 1.15)
