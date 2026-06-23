extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const MENU_BACKGROUND := preload("res://art/backgrounds/background1.png")

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var codex_panel: Control = $CodexPanel
@onready var menu_panel: PanelContainer = %MenuPanel
@onready var panel_title: Label = %PanelTitle
@onready var panel_rule: ColorRect = %PanelRule
@onready var subtitle: Label = %Subtitle
@onready var footer_hint: Label = %FooterHint
@onready var settings_toast: Label = %SettingsToast

func _ready() -> void:
	get_tree().paused = false
	_polish_scene()
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
	_apply_layout()
	_apply_custom_background()
	_apply_title_style()
	_apply_menu_panel_style()
	_apply_menu_button_style()
	_apply_toast_style()
	_spawn_spirit_motes()
	_animate_breathing_glow()


func _spawn_spirit_motes() -> void:
	## 飘浮灵光粒子（暖金色光点，加色发光），叠在背景之上、墨色遮罩之下。
	if has_node("SpiritMotes"):
		return
	var view_size := get_viewport_rect().size
	var p := GPUParticles2D.new()
	p.name = "SpiritMotes"
	p.amount = 160
	p.lifetime = 10.0
	p.preprocess = 10.0         # 进场即铺满全屏，不用等粒子升上来
	p.position = Vector2(view_size.x * 0.5, view_size.y + 8.0)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(view_size.x * 0.75, 12.0, 1.0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 18.0
	mat.gravity = Vector3.ZERO
	# 上升速度 + 寿命让粒子覆盖整屏高度
	mat.initial_velocity_min = 45.0
	mat.initial_velocity_max = 110.0
	mat.scale_min = 0.7
	mat.scale_max = 2.4
	# 整段生命周期内淡入淡出，呈赤红灵光
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.28, 0.2, 0.0))
	grad.set_color(1, Color(1.0, 0.35, 0.24, 0.0))
	grad.add_point(0.5, Color(1.0, 0.3, 0.2, 0.9))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	p.process_material = mat

	var cmat := CanvasItemMaterial.new()
	cmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # 发光叠加
	p.material = cmat

	add_child(p)
	move_child(p, 1)            # Background(0) 之上、墨色遮罩之下
	p.emitting = true


func _animate_breathing_glow() -> void:
	## 呼吸辉光：背景亮度极缓慢明暗脉动，画框不动，只有光在变化。
	var background := $Background as TextureRect
	var dim := Color(0.76, 0.76, 0.80)
	var bright := Color(1.20, 1.20, 1.24)
	background.modulate = dim
	var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(background, "modulate", bright, 5.0)
	t.tween_property(background, "modulate", dim, 5.0)


func _apply_layout() -> void:
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)
	subtitle.offset_left = 42.0
	subtitle.offset_top = -92.0
	subtitle.offset_right = 620.0
	subtitle.offset_bottom = -52.0

	footer_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, false)
	footer_hint.offset_left = 42.0
	footer_hint.offset_top = -48.0
	footer_hint.offset_right = 540.0
	footer_hint.offset_bottom = -18.0

	menu_panel.anchor_left = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -240.0
	menu_panel.offset_top = 8.0
	menu_panel.offset_right = 240.0
	menu_panel.offset_bottom = 368.0


func _apply_custom_background() -> void:
	var background := $Background as TextureRect
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()


func _apply_title_style() -> void:
	subtitle.text = "修仙卡牌 · 肉鸽构筑"
	footer_hint.text = "万劫残卷已启"
	subtitle.add_theme_color_override("font_color", Color("d9c089"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", 24)
	footer_hint.add_theme_color_override("font_color", Color(0.82, 0.74, 0.58, 0.68))
	footer_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.68))
	footer_hint.add_theme_constant_override("shadow_offset_x", 2)
	footer_hint.add_theme_constant_override("shadow_offset_y", 2)
	footer_hint.add_theme_font_size_override("font_size", 18)


func _apply_menu_panel_style() -> void:
	menu_panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.025, 0.021, 0.018, 0.08),
		Color(0.72, 0.52, 0.22, 0.42),
		1,
		8,
		Color(0, 0, 0, 0.18),
		8
	))
	panel_title.hide()
	panel_title.add_theme_color_override("font_color", Color("ead093"))
	panel_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	panel_title.add_theme_constant_override("shadow_offset_x", 2)
	panel_title.add_theme_constant_override("shadow_offset_y", 2)
	panel_title.add_theme_font_size_override("font_size", 27)
	panel_rule.color = Color(0.78, 0.55, 0.23, 0.42)


func _apply_menu_button_style() -> void:
	for child: Node in $MenuPanel/MenuMargin/MenuVBox.get_children():
		if not child is Button:
			continue
		var button := child as Button
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _make_transparent_button_style(Color.TRANSPARENT))
		button.add_theme_stylebox_override("hover", _make_transparent_button_style(Color(0.96, 0.72, 0.32, 0.82), 2, 9, Color(0.95, 0.66, 0.24, 0.22), 10))
		button.add_theme_stylebox_override("pressed", _make_transparent_button_style(Color("f2c94f"), 2, 9, Color(0.95, 0.66, 0.24, 0.16), 6))
		button.add_theme_stylebox_override("disabled", _make_transparent_button_style(Color(0.34, 0.30, 0.22, 0.28)))
		button.add_theme_color_override("font_color", Color("f7ead2"))
		button.add_theme_color_override("font_hover_color", Color("ffe38a"))
		button.add_theme_color_override("font_pressed_color", Color("f2c94f"))
		button.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.60, 0.42))
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.03, 0.9))
		button.add_theme_constant_override("outline_size", 3)
		button.add_theme_font_size_override("font_size", 32)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _apply_toast_style() -> void:
	settings_toast.add_theme_color_override("font_color", Color("f4efe4"))
	settings_toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	settings_toast.add_theme_constant_override("shadow_offset_x", 2)
	settings_toast.add_theme_constant_override("shadow_offset_y", 2)
	settings_toast.add_theme_font_size_override("font_size", 18)


func _make_panel_style(
	bg: Color,
	border: Color,
	border_width := 1,
	radius := 6,
	shadow := Color(0, 0, 0, 0.0),
	shadow_size := 0
) -> StyleBoxFlat:
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
	style.content_margin_left = 14
	style.content_margin_top = 8
	style.content_margin_right = 14
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style


func _make_transparent_button_style(
	border: Color,
	border_width := 0,
	radius := 6,
	shadow := Color(0, 0, 0, 0.0),
	shadow_size := 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_top = 8
	style.content_margin_right = 14
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
