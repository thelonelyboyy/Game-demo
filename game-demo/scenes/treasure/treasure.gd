class_name Treasure
extends Control

const TREASURE_BACKGROUND := preload("res://art/treasure/treasure_room_bg.png")
const CHEST_CLOSED := preload("res://art/treasure/treasure_chest_closed.png")
const CHEST_OPENING := preload("res://art/treasure/treasure_chest_opening.png")
const CHEST_OPEN := preload("res://art/treasure/treasure_chest_open.png")

@export var treasure_relic_pool: Array[Relic]
@export var relic_reward_pool: RelicRewardPool
@export var relic_handler: RelicHandler
@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var background: TextureRect = $Background
@onready var dimmer: ColorRect = $BackgroundDimmer
@onready var title: Label = $Label
@onready var treasure_chest: TextureRect = $TreasureChest
@onready var particles: GPUParticles2D = $TreasureChest/GPUParticles2D

var found_relic: Relic
var found_relics: Array[Relic] = []
var opening_started := false
var burst_progress := 0.0


func _ready() -> void:
	# 正式流程已直接进入法宝二选一；保留场景仅兼容调试入口，不再播放开箱演出。
	animation_player.stop()
	particles.emitting = false
	treasure_chest.hide()


func generate_relic() -> void:
	generate_relic_choices(1)


func generate_relic_choices(count := 2, chapter := 1) -> void:
	found_relics.clear()
	if relic_reward_pool:
		found_relics = relic_reward_pool.get_random_available_choices(
		char_stats, relic_handler, count, chapter, RelicRewardPool.RewardContext.TREASURE
		)
		found_relic = found_relics[0] if not found_relics.is_empty() else null
		_on_treasure_opened.call_deferred()
		return

	var available_relics := treasure_relic_pool.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(char_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)
	RNG.array_shuffle(available_relics)
	found_relics.assign(available_relics.slice(0, mini(count, available_relics.size())))
	found_relic = found_relics[0] if not found_relics.is_empty() else null
	_on_treasure_opened.call_deferred()


# Called from the AnimationPlayer, at the
# end of the 'open' animation.
func _on_treasure_opened() -> void:
	Events.treasure_room_exited.emit(found_relics)


func _on_treasure_chest_gui_input(_event: InputEvent) -> void:
	# 旧场景连接保留以兼容资源加载；宝箱节点已不再等待点击。
	pass


func _apply_visuals() -> void:
	background.texture = TREASURE_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dimmer.color = Color(0.03, 0.00, 0.00, 0.26)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	title.text = "秘藏宝匣"
	title.offset_top = -350.0
	title.offset_bottom = -286.0
	InkTheme.apply_screen_title(title, 56)

	_add_subtitle()
	_add_stage_panel()
	_add_hint_label()
	_style_chest()
	queue_redraw()


func _add_subtitle() -> void:
	if has_node("Subtitle"):
		return

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "洞府灵机汇于此匣，开启后从两件法宝中择其一。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -520.0
	subtitle.offset_top = -292.0
	subtitle.offset_right = 520.0
	subtitle.offset_bottom = -250.0
	InkTheme.apply_subtitle(subtitle, 23)
	add_child(subtitle)


func _add_stage_panel() -> void:
	if has_node("TreasureStage"):
		return

	var stage := PanelContainer.new()
	stage.name = "TreasureStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -260.0
	stage.offset_top = -106.0
	stage.offset_right = 260.0
	stage.offset_bottom = 258.0
	stage.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.045, 0.030, 0.028, 0.50),
		Color(0.70, 0.48, 0.24, 0.64),
		2,
		8,
		Color(0, 0, 0, 0.42),
		16
	))
	add_child(stage)
	move_child(stage, treasure_chest.get_index())


func _add_hint_label() -> void:
	if has_node("OpenHint"):
		return

	var hint := Label.new()
	hint.name = "OpenHint"
	hint.text = "点击宝匣"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER)
	hint.offset_left = -200.0
	hint.offset_top = 222.0
	hint.offset_right = 200.0
	hint.offset_bottom = 268.0
	hint.add_theme_color_override("font_color", Color("f7e6b4"))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 3)
	hint.add_theme_font_size_override("font_size", 24)
	add_child(hint)


func _style_chest() -> void:
	treasure_chest.texture = CHEST_CLOSED
	treasure_chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	treasure_chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	treasure_chest.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	treasure_chest.offset_left = -170.0
	treasure_chest.offset_top = -42.0
	treasure_chest.offset_right = 170.0
	treasure_chest.offset_bottom = 298.0
	treasure_chest.pivot_offset = Vector2(170, 170)

	particles.position = Vector2(170, 150)
	particles.amount = 48
	particles.lifetime = 1.35
	particles.explosiveness = 0.96


func _begin_open_effects() -> void:
	var hint := get_node_or_null("OpenHint") as Label
	if hint:
		hint.text = "灵光涌现..."
		hint.add_theme_color_override("font_color", Color("fff1c8"))

	treasure_chest.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(treasure_chest, "scale", Vector2(1.10, 1.10), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(treasure_chest, "scale", Vector2(1.0, 1.0), 0.22).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_burst_progress, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_burst_progress(value: float) -> void:
	burst_progress = value
	queue_redraw()


func _draw() -> void:
	var center := size * Vector2(0.5, 0.57)
	draw_circle(center, 165.0, Color(0.54, 0.08, 0.05, 0.10))
	draw_arc(center, 142.0, -0.22, TAU - 0.22, 96, Color(0.77, 0.58, 0.25, 0.42), 2.0, true)
	draw_arc(center, 102.0, 0.42, TAU + 0.42, 96, Color(0.66, 0.24, 0.84, 0.24), 1.6, true)

	if burst_progress <= 0.0:
		return

	draw_circle(center, 130.0 + 80.0 * burst_progress, Color(0.98, 0.78, 0.25, 0.20 * (1.0 - burst_progress)))
	draw_arc(center, 118.0 + 96.0 * burst_progress, 0.0, TAU, 120, Color(1.0, 0.74, 0.42, 0.58 * (1.0 - burst_progress)), 3.0, true)


func _make_panel_style(bg: Color, border: Color, border_width := 1, radius := 8, shadow := Color(0, 0, 0, 0.34), shadow_size := 8) -> StyleBoxFlat:
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
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
