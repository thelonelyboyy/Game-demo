extends Control

const SPIRIT_ROOT_SELECTOR_SCENE = preload("res://scenes/ui/spirit_root_selector.tscn")
const BODY_CULTIVATOR_STATS := preload("res://characters/body_cultivator/body_cultivator.tres")
const SWORD_CULTIVATOR_STATS := preload("res://characters/sword_cultivator/sword_cultivator.tres")
const DEMONIC_CULTIVATOR_STATS := preload("res://characters/demonic_cultivator/demonic_cultivator.tres")
const BEASTMASTER_STATS := preload("res://characters/beastmaster/beastmaster.tres")
const SELECTOR_BACKGROUND := preload("res://test1.png")
const INFO_PANEL_FRAME := preload("res://assets/ui/generated/panels/character_select_info_panel_9slice.png")
const STAT_ROW_FRAME := preload("res://assets/ui/generated/panels/character_select_stat_row_9slice.png")
const SKILL_ROW_FRAME := preload("res://assets/ui/generated/panels/character_select_skill_row_9slice.png")
const CLASS_BADGE_FRAME := preload("res://assets/ui/generated/icons/character_class_badge_frame.png")
const SKILL_ICON_FRAME := preload("res://assets/ui/generated/icons/character_skill_icon_frame.png")
const CARD_FRAME_NORMAL := preload("res://assets/ui/generated/cards/character_card_frame_normal.png")
const CARD_FRAME_HOVER := preload("res://assets/ui/generated/cards/character_card_frame_hover.png")
const CARD_FRAME_SELECTED := preload("res://assets/ui/generated/cards/character_card_frame_selected.png")
const CARD_FRAME_DISABLED := preload("res://assets/ui/generated/cards/character_card_frame_disabled.png")
const CARD_PORTRAIT_MASK := preload("res://assets/ui/generated/cards/character_card_portrait_mask_frame.png")
const CARD_SELECTED_GLOW := preload("res://assets/ui/generated/decorations/character_select_card_selected_glow.png")
const ENTER_BUTTON_NORMAL := preload("res://assets/ui/generated/buttons/character_select_enter_button_normal_9slice.png")
const ENTER_BUTTON_HOVER := preload("res://assets/ui/generated/buttons/character_select_enter_button_hover_9slice.png")
const ENTER_BUTTON_PRESSED := preload("res://assets/ui/generated/buttons/character_select_enter_button_pressed_9slice.png")
const ENTER_BUTTON_DISABLED := preload("res://assets/ui/generated/buttons/character_select_enter_button_disabled_9slice.png")
const BACK_BUTTON_NORMAL := preload("res://assets/ui/generated/buttons/character_select_back_button_normal_9slice.png")
const BACK_BUTTON_HOVER := preload("res://assets/ui/generated/buttons/character_select_back_button_hover_9slice.png")
const BACK_BUTTON_PRESSED := preload("res://assets/ui/generated/buttons/character_select_back_button_pressed_9slice.png")

# 与 run_stats.gd 的实际初始灵石保持一致（此前显示 99、实际 70，不一致）。
const STARTING_GOLD := 70
const ANIMATED_BACKGROUND_FPS := 18.0
const REFERENCE_SIZE := Vector2(1672.0, 941.0)
const INFO_PANEL_POS := Vector2(48.0, 82.0)
const INFO_PANEL_SIZE := Vector2(430.0, 690.0)
const CARD_ROW_POS := Vector2(488.0, 618.0)
const CARD_ROW_SIZE := Vector2(696.0, 292.0)
const BACK_BUTTON_POS := Vector2(58.0, 834.0)
const START_BUTTON_POS := Vector2(1292.0, 806.0)
const CARD_SIZE := Vector2(150.0, 260.0)
const CARD_SELECTED_SIZE := Vector2(168.0, 290.0)
const INFO_PANEL_MARGINS := Vector4(56.0, 56.0, 56.0, 56.0)
const STAT_ROW_MARGINS := Vector4(24.0, 14.0, 24.0, 14.0)
const SKILL_ROW_MARGINS := Vector4(32.0, 24.0, 32.0, 24.0)
const ENTER_BUTTON_MARGINS := Vector4(44.0, 30.0, 44.0, 30.0)
const BACK_BUTTON_MARGINS := Vector4(36.0, 24.0, 36.0, 24.0)
const CARD_FRAME_MARGINS := Vector4(22.0, 30.0, 22.0, 42.0)

@export var run_startup: RunStartup

@onready var background: TextureRect = $Background
@onready var animated_background: TextureRect = %AnimatedBackground
@onready var accent_tint: ColorRect = %AccentTint
@onready var vignette: ColorRect = %Vignette
@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var description: Label = %Description
@onready var health_value: Label = %HealthValue
@onready var gold_value: Label = %GoldValue
@onready var relic_icon: TextureRect = %RelicIcon
@onready var relic_name: Label = %RelicName
@onready var relic_description: Label = %RelicDescription
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var info_panel: PanelContainer = %InfoPanel
@onready var character_text: VBoxContainer = $InfoPanel/CharacterText
@onready var stats_row: HBoxContainer = $InfoPanel/CharacterText/StatsRow
@onready var relic_row: HBoxContainer = $InfoPanel/CharacterText/RelicRow
@onready var health_icon: TextureRect = $InfoPanel/CharacterText/StatsRow/HealthBox/HealthIcon
@onready var gold_icon: TextureRect = $InfoPanel/CharacterText/StatsRow/GoldBox/GoldIcon
@onready var bottom_band: Panel = $BottomBand
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var character_buttons: HBoxContainer = %CharacterButtons

var current_character: CharacterStats : set = set_current_character
var selected_index := 0
var character_entries: Array[Dictionary] = []
var animated_background_frames: Array[Texture2D] = []
var animated_background_time := 0.0
var animated_background_index := 0
var animated_background_playing := false
var animated_background_fps := ANIMATED_BACKGROUND_FPS
# 帧集缓存：目录 -> Array[Texture2D]，切换职业不再重新加载。
var _frame_cache := {}
# 异步加载状态（单飞），避免进入/切换时同步加载几十张大图卡住主线程。
var _loading_dir := ""
var _loading_paths: Array[String] = []
var _loading_collected := {}
var _pending_apply_dir := ""
var _ui_scale := 1.0
var _stats_frame: PanelContainer
var _relic_frame: PanelContainer
var _class_badge: Control
var _class_badge_glyph: Label
var _info_swap_tween: Tween
var _last_punched_index := -1
var _difficulty_selector: OptionButton
var _difficulty_profile: DifficultyProfile


func _ready() -> void:
	InkTheme.animate_screen_entrance(self, 0.4)
	_build_character_entries()
	_polish_scene()
	_setup_difficulty_selector()
	_wire_button_sounds()
	get_viewport().size_changed.connect(_layout_scene)
	set_current_character(_default_character())
	_layout_scene()


func _wire_button_sounds() -> void:
	InkTheme.wire_button_sfx(start_button)
	InkTheme.wire_button_sfx(back_button)
	if _difficulty_selector:
		InkTheme.wire_button_sfx(_difficulty_selector)
	for entry in character_entries:
		var button := entry.get("button") as Button
		if button:
			InkTheme.wire_button_sfx(button)


func set_current_character(new_character: CharacterStats) -> void:
	if character_entries.is_empty():
		current_character = new_character
		return

	selected_index = _get_character_index(new_character)
	var entry := character_entries[selected_index]
	current_character = entry.stats

	title.text = entry.name
	subtitle.text = entry.subtitle
	description.text = entry.description
	health_value.text = "%s/%s" % [current_character.max_health, current_character.max_health]
	gold_value.text = str(STARTING_GOLD)
	background.texture = _resolve_background(entry)
	_apply_animated_background(entry)
	_update_class_badge(entry)

	if current_character.starting_relic:
		relic_icon.texture = current_character.starting_relic.icon
		relic_name.text = entry.relic_name
		relic_description.text = entry.relic_description

	_animate_info_swap()
	_update_character_buttons()


# 切换角色时信息面板淡入，信息更替不再硬切。
func _animate_info_swap() -> void:
	if not info_panel:
		return
	if _info_swap_tween and _info_swap_tween.is_running():
		_info_swap_tween.kill()
	info_panel.modulate = Color(1, 1, 1, 0.0)
	_info_swap_tween = info_panel.create_tween()
	_info_swap_tween.tween_property(info_panel, "modulate:a", 1.0, 0.24) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_start_button_pressed() -> void:
	print("Start new Run with %s" % current_character.character_name)
	# 踏上旅途的仪式感：一记锣。
	GameSfx.play(GameSfx.GONG, -4.0)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.picked_character = current_character
	run_startup.difficulty_level = _difficulty_profile.selected_level if _difficulty_profile else 0
	get_tree().change_scene_to_packed(SPIRIT_ROOT_SELECTOR_SCENE)


func _setup_difficulty_selector() -> void:
	_difficulty_profile = DifficultyProfile.load_data()
	_difficulty_selector = OptionButton.new()
	_difficulty_selector.name = "DifficultySelector"
	_difficulty_selector.focus_mode = Control.FOCUS_ALL
	_difficulty_selector.tooltip_text = "通关当前最高心魔难度可解锁下一阶。"
	add_child(_difficulty_selector)
	for level in _difficulty_profile.unlocked_level + 1:
		var label := "难度 · 凡境" if level == 0 else "难度 · 心魔 %s" % level
		_difficulty_selector.add_item(label, level)
		_difficulty_selector.set_item_tooltip(level, RunStats.get_difficulty_rule(level))
	_difficulty_selector.select(_difficulty_profile.selected_level)
	_difficulty_selector.item_selected.connect(_on_difficulty_selected)
	InkTheme.apply_screen_button(_difficulty_selector)
	_difficulty_selector.add_theme_font_size_override("font_size", 22)


func _on_difficulty_selected(index: int) -> void:
	if not _difficulty_profile or not _difficulty_selector:
		return
	var level := _difficulty_selector.get_item_id(index)
	_difficulty_profile.select_level(level)
	var error := _difficulty_profile.save_data()
	if error != OK:
		push_warning("无法保存心魔难度选择：%s" % error)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_body_cultivator_button_pressed() -> void:
	current_character = BODY_CULTIVATOR_STATS


func _on_sword_cultivator_button_pressed() -> void:
	current_character = SWORD_CULTIVATOR_STATS


func _on_demonic_cultivator_button_pressed() -> void:
	current_character = DEMONIC_CULTIVATOR_STATS


func _on_beastmaster_button_pressed() -> void:
	current_character = BEASTMASTER_STATS


func _build_character_entries() -> void:
	character_entries = [
		{
			"stats": BODY_CULTIVATOR_STATS,
			"button": $CharacterButtons/BodyCultivatorButton,
			"enabled": false,
			"name": "体修",
			"subtitle": "金身炼体 · 稳扎稳打",
			"description": "以血肉为炉，拳掌破山。擅长护体、回血与承伤反击，越战越硬。",
			"relic_name": "玄骨符",
			"relic_description": "战斗开始时稳住护体根基，让你能放心吃下第一波攻势。",
			"tint": Color(0.55, 0.22, 0.06, 0.28),
			"vignette": Color(0.09, 0.05, 0.02, 0.34),
			"hero_modulate": Color(1.0, 0.90, 0.72, 0.95),
		},
		{
			"stats": SWORD_CULTIVATOR_STATS,
			"button": $CharacterButtons/SwordCultivatorButton,
			"enabled": false,
			"background": "res://art/backgrounds/sw.png",
			"animated_background": "res://art/backgrounds/sw_selector_bg_frames",
			"animated_background_fps": 16.0,
			"name": "剑修",
			"subtitle": "一念起剑 · 轻灵迅捷",
			"description": "擅长过牌与铸剑，出手频率高。越打越锋利，适合追求连招节奏。",
			"relic_name": "清风剑匣",
			"relic_description": "开局便藏一缕剑气，帮助你更快找到关键剑招。",
			"tint": Color(0.06, 0.32, 0.52, 0.30),
			"vignette": Color(0.02, 0.05, 0.10, 0.38),
			"hero_modulate": Color(0.90, 0.98, 1.0, 0.96),
		},
		{
			"stats": DEMONIC_CULTIVATOR_STATS,
			"button": $CharacterButtons/DemonicCultivatorButton,
			"enabled": true,
			"background": "res://art/backgrounds/demonic_selector_bg.png",
			"animated_background": "res://art/backgrounds/demonic_selector_bg_frames",
			"name": "魔修",
			"subtitle": "血契燃魂 · 高风险爆发",
			"description": "以伤换势，用生命换取爆发。会献祭、吸魂与叠印，打得狠也要算得准。",
			"relic_name": "魂灯",
			"relic_description": "黑焰护住命魂，让献祭后的反扑更凶险。",
			"tint": Color(0.52, 0.04, 0.26, 0.34),
			"vignette": Color(0.10, 0.01, 0.05, 0.42),
			"hero_modulate": Color(1.0, 0.74, 0.95, 0.96),
		},
		{
			"stats": BEASTMASTER_STATS,
			"button": $CharacterButtons/BeastmasterButton,
			"enabled": false,
			"name": "驭兽师",
			"subtitle": "百兽同心 · 召唤协同",
			"description": "灵兽相伴，攻守轮转。依靠兽群、召唤与连携压制敌人。",
			"relic_name": "百兽铃",
			"relic_description": "每场战斗唤醒兽灵，让你的兽群更早进入战局。",
			"tint": Color(0.08, 0.40, 0.20, 0.32),
			"vignette": Color(0.02, 0.08, 0.04, 0.40),
			"hero_modulate": Color(0.82, 1.0, 0.78, 0.95),
		},
	]
	character_entries.sort_custom(_sort_character_entries)


func _sort_character_entries(a: Dictionary, b: Dictionary) -> bool:
	return _character_entry_order(a) < _character_entry_order(b)


func _character_entry_order(entry: Dictionary) -> int:
	var stats := entry.stats as CharacterStats
	if stats == DEMONIC_CULTIVATOR_STATS:
		return 0
	if stats == SWORD_CULTIVATOR_STATS:
		return 1
	if stats == BODY_CULTIVATOR_STATS:
		return 2
	if stats == BEASTMASTER_STATS:
		return 3
	return 99


func _polish_scene() -> void:
	_apply_custom_background()
	_ensure_info_panel_frames()
	_apply_info_panel_style()
	_apply_action_button_style(start_button, true)
	_apply_action_button_style(back_button, false)
	InkTheme.apply_title(title, 74)
	InkTheme.apply_body_label(subtitle, 23)
	InkTheme.apply_body_label(description, 23)
	InkTheme.apply_body_label(health_value, 23)
	InkTheme.apply_body_label(gold_value, 23)
	InkTheme.apply_body_label(relic_name, 24)
	InkTheme.apply_body_label(relic_description, 19)

	title.add_theme_color_override("font_color", Color("f5d06b"))
	subtitle.add_theme_color_override("font_color", Color("e8c79d"))
	description.add_theme_color_override("font_color", Color("e9dcc8"))
	relic_name.add_theme_color_override("font_color", Color("f0c85b"))
	relic_description.add_theme_color_override("font_color", Color("d8c6a8"))
	health_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_portrait.hide()
	character_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 不再给背景图盖色罩/暗角，保持背景原图。
	accent_tint.hide()
	vignette.hide()
	bottom_band.hide()

	character_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	for order_index in character_entries.size():
		var ordered_button := character_entries[order_index].button as Button
		if ordered_button and ordered_button.get_parent() == character_buttons:
			character_buttons.move_child(ordered_button, order_index)

	for entry in character_entries:
		var button := entry.button as Button
		button.visible = true
		button.disabled = not entry.get("enabled", true)
		button.text = ""
		button.tooltip_text = entry.name
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.clip_contents = false
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover_pressed", _make_texture_style(CARD_FRAME_SELECTED, CARD_FRAME_MARGINS, Vector4.ZERO))
		_ensure_card_decoration(button)
		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.texture = entry.stats.portrait
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := button.get_node_or_null("Name") as Label
		if label:
			label.text = entry.name
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			InkTheme.apply_body_label(label, 20)


func _apply_info_panel_style() -> void:
	var style := _make_texture_style(
		INFO_PANEL_FRAME,
		INFO_PANEL_MARGINS,
		Vector4(46.0, 36.0, 38.0, 34.0),
		Color(1.0, 0.93, 0.82, 0.96)
	)
	info_panel.add_theme_stylebox_override("panel", style)
	character_text.add_theme_constant_override("separation", 13)

	if _stats_frame:
		_stats_frame.add_theme_stylebox_override(
			"panel",
			_make_texture_style(STAT_ROW_FRAME, STAT_ROW_MARGINS, Vector4(22.0, 8.0, 22.0, 8.0))
		)
	if _relic_frame:
		_relic_frame.add_theme_stylebox_override(
			"panel",
			_make_texture_style(SKILL_ROW_FRAME, SKILL_ROW_MARGINS, Vector4(18.0, 16.0, 18.0, 14.0))
		)


func _ensure_info_panel_frames() -> void:
	_class_badge = character_text.get_node_or_null("ClassBadge") as Control
	if not _class_badge:
		_class_badge = Control.new()
		_class_badge.name = "ClassBadge"
		_class_badge.custom_minimum_size = Vector2(104.0, 104.0)
		_class_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_class_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_text.add_child(_class_badge)
		character_text.move_child(_class_badge, 0)

		var badge_frame := TextureRect.new()
		badge_frame.name = "Frame"
		badge_frame.texture = CLASS_BADGE_FRAME
		badge_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_frame.stretch_mode = TextureRect.STRETCH_SCALE
		badge_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_class_badge.add_child(badge_frame)
		_fill_parent(badge_frame)

		_class_badge_glyph = Label.new()
		_class_badge_glyph.name = "Glyph"
		_class_badge_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_class_badge_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_class_badge_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_class_badge_glyph.add_theme_color_override("font_color", Color("f5d06b"))
		_class_badge_glyph.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
		_class_badge_glyph.add_theme_constant_override("shadow_offset_x", 3)
		_class_badge_glyph.add_theme_constant_override("shadow_offset_y", 3)
		_class_badge_glyph.add_theme_font_size_override("font_size", 43)
		_class_badge.add_child(_class_badge_glyph)
		_fill_parent(_class_badge_glyph)
	else:
		_class_badge_glyph = _class_badge.get_node_or_null("Glyph") as Label

	_stats_frame = _wrap_panel_row(stats_row, "StatsFrame", Vector2(350.0, 54.0))
	_relic_frame = _wrap_panel_row(relic_row, "RelicFrame", Vector2(380.0, 112.0))

	if health_icon:
		health_icon.custom_minimum_size = Vector2(28.0, 28.0)
	if gold_icon:
		gold_icon.custom_minimum_size = Vector2(28.0, 28.0)

	var relic_icon_slot := relic_row.get_node_or_null("RelicIconSlot") as Control
	if not relic_icon_slot:
		relic_icon_slot = Control.new()
		relic_icon_slot.name = "RelicIconSlot"
		relic_icon_slot.custom_minimum_size = Vector2(72.0, 72.0)
		relic_icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_index := relic_icon.get_index()
		relic_row.remove_child(relic_icon)
		relic_row.add_child(relic_icon_slot)
		relic_row.move_child(relic_icon_slot, icon_index)

		var relic_icon_frame := TextureRect.new()
		relic_icon_frame.name = "Frame"
		relic_icon_frame.texture = SKILL_ICON_FRAME
		relic_icon_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		relic_icon_frame.stretch_mode = TextureRect.STRETCH_SCALE
		relic_icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		relic_icon_slot.add_child(relic_icon_frame)
		_fill_parent(relic_icon_frame)

		relic_icon_slot.add_child(relic_icon)
	relic_icon_slot.custom_minimum_size = Vector2(72.0, 72.0)

	if relic_icon:
		relic_icon.custom_minimum_size = Vector2.ZERO
		relic_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		relic_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		relic_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		relic_icon.anchor_left = 0.0
		relic_icon.anchor_top = 0.0
		relic_icon.anchor_right = 1.0
		relic_icon.anchor_bottom = 1.0
		relic_icon.offset_left = 10.0
		relic_icon.offset_top = 10.0
		relic_icon.offset_right = -10.0
		relic_icon.offset_bottom = -10.0


func _wrap_panel_row(row: Control, wrapper_name: String, minimum_size: Vector2) -> PanelContainer:
	var existing := character_text.get_node_or_null(wrapper_name) as PanelContainer
	if existing:
		existing.custom_minimum_size = minimum_size
		return existing

	var previous_parent := row.get_parent()
	var row_index := row.get_index()
	previous_parent.remove_child(row)

	var wrapper := PanelContainer.new()
	wrapper.name = wrapper_name
	wrapper.custom_minimum_size = minimum_size
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	character_text.add_child(wrapper)
	character_text.move_child(wrapper, row_index)
	wrapper.add_child(row)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return wrapper


func _update_class_badge(entry: Dictionary) -> void:
	if _class_badge_glyph:
		var display_name := String(entry.name)
		_class_badge_glyph.text = display_name.substr(0, 1)


func _ensure_card_decoration(button: Button) -> void:
	var glow := button.get_node_or_null("SelectedGlow") as TextureRect
	if not glow:
		glow = TextureRect.new()
		glow.name = "SelectedGlow"
		glow.texture = CARD_SELECTED_GLOW
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.z_index = -1
		button.add_child(glow)
		button.move_child(glow, 0)

	var mask := button.get_node_or_null("PortraitMaskFrame") as TextureRect
	if not mask:
		mask = TextureRect.new()
		mask.name = "PortraitMaskFrame"
		mask.texture = CARD_PORTRAIT_MASK
		mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mask.stretch_mode = TextureRect.STRETCH_SCALE
		mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(mask)


func _apply_action_button_style(button: Button, is_primary: bool) -> void:
	button.add_theme_color_override("font_color", Color("fff0c2"))
	button.add_theme_color_override("font_hover_color", Color("fff7dc"))
	button.add_theme_color_override("font_pressed_color", Color("d8a75e"))
	button.add_theme_color_override("font_disabled_color", Color(0.68, 0.55, 0.44, 0.52))
	button.add_theme_color_override("font_shadow_color", Color(0.08, 0.0, 0.0, 0.92))
	button.add_theme_constant_override("shadow_offset_x", 3)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.add_theme_font_size_override("font_size", 31 if is_primary else 25)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if is_primary:
		button.add_theme_stylebox_override("normal", _make_texture_style(ENTER_BUTTON_NORMAL, ENTER_BUTTON_MARGINS, Vector4(26.0, 18.0, 26.0, 18.0)))
		button.add_theme_stylebox_override("hover", _make_texture_style(ENTER_BUTTON_HOVER, ENTER_BUTTON_MARGINS, Vector4(26.0, 18.0, 26.0, 18.0)))
		button.add_theme_stylebox_override("pressed", _make_texture_style(ENTER_BUTTON_PRESSED, ENTER_BUTTON_MARGINS, Vector4(26.0, 18.0, 26.0, 18.0)))
		button.add_theme_stylebox_override("disabled", _make_texture_style(ENTER_BUTTON_DISABLED, ENTER_BUTTON_MARGINS, Vector4(26.0, 18.0, 26.0, 18.0), Color(0.58, 0.52, 0.48, 0.66)))
	else:
		button.add_theme_stylebox_override("normal", _make_texture_style(BACK_BUTTON_NORMAL, BACK_BUTTON_MARGINS, Vector4(20.0, 12.0, 20.0, 12.0)))
		button.add_theme_stylebox_override("hover", _make_texture_style(BACK_BUTTON_HOVER, BACK_BUTTON_MARGINS, Vector4(20.0, 12.0, 20.0, 12.0)))
		button.add_theme_stylebox_override("pressed", _make_texture_style(BACK_BUTTON_PRESSED, BACK_BUTTON_MARGINS, Vector4(20.0, 12.0, 20.0, 12.0)))
		button.add_theme_stylebox_override("disabled", _make_texture_style(BACK_BUTTON_NORMAL, BACK_BUTTON_MARGINS, Vector4(20.0, 12.0, 20.0, 12.0), Color(0.58, 0.52, 0.48, 0.66)))


func _make_texture_style(
	texture: Texture2D,
	texture_margins: Vector4,
	content_margins: Vector4 = Vector4(12.0, 8.0, 12.0, 8.0),
	modulate_color: Color = Color.WHITE
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.modulate_color = modulate_color
	style.set_texture_margin(SIDE_LEFT, texture_margins.x)
	style.set_texture_margin(SIDE_TOP, texture_margins.y)
	style.set_texture_margin(SIDE_RIGHT, texture_margins.z)
	style.set_texture_margin(SIDE_BOTTOM, texture_margins.w)
	style.set_content_margin(SIDE_LEFT, content_margins.x)
	style.set_content_margin(SIDE_TOP, content_margins.y)
	style.set_content_margin(SIDE_RIGHT, content_margins.z)
	style.set_content_margin(SIDE_BOTTOM, content_margins.w)
	return style


func _fill_parent(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _layout_scene() -> void:
	if not is_inside_tree():
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_x := viewport_size.x / REFERENCE_SIZE.x
	var scale_y := viewport_size.y / REFERENCE_SIZE.y
	_ui_scale = scale_x
	if scale_y < _ui_scale:
		_ui_scale = scale_y
	_ui_scale = clampf(_ui_scale, 0.72, 1.18)

	var origin := Vector2(
		(viewport_size.x - REFERENCE_SIZE.x * _ui_scale) * 0.5,
		(viewport_size.y - REFERENCE_SIZE.y * _ui_scale) * 0.5
	)

	_place_reference_rect(info_panel, INFO_PANEL_POS, INFO_PANEL_SIZE, origin, _ui_scale)
	_place_reference_rect(character_buttons, CARD_ROW_POS, CARD_ROW_SIZE, origin, _ui_scale)
	_place_reference_rect(back_button, BACK_BUTTON_POS, Vector2(260.0, 74.0), origin, _ui_scale)
	_place_reference_rect(start_button, START_BUTTON_POS, Vector2(320.0, 104.0), origin, _ui_scale)
	if _difficulty_selector:
		_place_reference_rect(_difficulty_selector, START_BUTTON_POS - Vector2(0.0, 72.0), Vector2(320.0, 58.0), origin, _ui_scale)

	character_text.add_theme_constant_override("separation", roundi(13.0 * _ui_scale))
	character_buttons.add_theme_constant_override("separation", roundi(22.0 * _ui_scale))
	start_button.add_theme_font_size_override("font_size", roundi(31.0 * _ui_scale))
	back_button.add_theme_font_size_override("font_size", roundi(25.0 * _ui_scale))
	_refresh_character_card_metrics()


func _place_reference_rect(control: Control, position: Vector2, rect_size: Vector2, origin: Vector2, scale: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = origin.x + position.x * scale
	control.offset_top = origin.y + position.y * scale
	control.offset_right = control.offset_left + rect_size.x * scale
	control.offset_bottom = control.offset_top + rect_size.y * scale


func _apply_custom_background() -> void:
	background.texture = SELECTOR_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()
	animated_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animated_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	animated_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stop_animated_background()


func _process(delta: float) -> void:
	_poll_threaded_load()

	if not animated_background_playing or animated_background_frames.is_empty():
		return

	animated_background_time += delta
	var frame_duration := 1.0 / animated_background_fps
	while animated_background_time >= frame_duration:
		animated_background_time -= frame_duration
		animated_background_index = (animated_background_index + 1) % animated_background_frames.size()
		animated_background.texture = animated_background_frames[animated_background_index]


func _apply_animated_background(entry: Dictionary) -> void:
	var frame_dir: String = entry.get("animated_background", "")
	# 每个角色可单独覆盖动画帧率，缺省回退全局值。
	animated_background_fps = entry.get("animated_background_fps", ANIMATED_BACKGROUND_FPS)
	_pending_apply_dir = frame_dir
	# Headless smoke 会在首帧立即退出；此时启动后台纹理加载会与渲染器销毁竞态。
	if DisplayServer.get_name() == "headless":
		_stop_animated_background()
		return

	if frame_dir.is_empty():
		_stop_animated_background()
		return

	# 命中缓存：立即播放，零卡顿。
	if _frame_cache.has(frame_dir):
		_start_animated_background(_frame_cache[frame_dir])
		return

	# 未缓存：先显示静态背景，后台异步加载该目录帧。
	_stop_animated_background()
	_begin_threaded_load(frame_dir)


func _start_animated_background(frames: Array[Texture2D]) -> void:
	if frames.is_empty():
		_stop_animated_background()
		return
	animated_background_frames = frames
	animated_background_index = 0
	animated_background_time = 0.0
	animated_background.texture = frames[0]
	animated_background.show()
	animated_background_playing = true


func _begin_threaded_load(frame_dir: String) -> void:
	if _loading_dir == frame_dir:
		return
	_loading_dir = frame_dir
	_loading_paths.clear()
	_loading_collected.clear()
	var files := DirAccess.get_files_at(frame_dir)
	files.sort()
	for file_name in files:
		var lower_name := file_name.to_lower()
		if lower_name.ends_with(".png") or lower_name.ends_with(".jpg") or lower_name.ends_with(".jpeg") or lower_name.ends_with(".webp"):
			var path := "%s/%s" % [frame_dir, file_name]
			_loading_paths.append(path)
			ResourceLoader.load_threaded_request(path)


func _poll_threaded_load() -> void:
	if _loading_dir.is_empty():
		return

	for path in _loading_paths:
		if _loading_collected.has(path):
			continue
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loading_collected[path] = ResourceLoader.load_threaded_get(path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_loading_collected[path] = null  # 跳过坏帧

	if _loading_collected.size() < _loading_paths.size():
		return

	# 全部就绪：按文件名顺序组装并缓存。
	var frames: Array[Texture2D] = []
	for path in _loading_paths:
		var tex := _loading_collected.get(path) as Texture2D
		if tex:
			frames.append(tex)

	var done_dir := _loading_dir
	_frame_cache[done_dir] = frames
	_loading_dir = ""
	_loading_paths.clear()
	_loading_collected.clear()

	# 若该目录仍是当前选中职业，立即开始播放。
	if _pending_apply_dir == done_dir:
		_start_animated_background(frames)

	# 顺手后台预热其余职业的帧集，让后续切换瞬时完成。
	_preload_next_uncached()


func _preload_next_uncached() -> void:
	if not _loading_dir.is_empty():
		return
	for entry in character_entries:
		var dir: String = entry.get("animated_background", "")
		if dir.is_empty() or _frame_cache.has(dir):
			continue
		_begin_threaded_load(dir)
		return


func _stop_animated_background() -> void:
	animated_background_playing = false
	animated_background_time = 0.0
	animated_background_index = 0
	animated_background.texture = null
	animated_background.hide()


func _update_character_buttons() -> void:
	for index in character_entries.size():
		var entry := character_entries[index]
		var button := entry.button as Button
		var selected := index == selected_index
		var enabled: bool = entry.get("enabled", true)
		button.button_pressed = selected
		button.disabled = not enabled
		button.visible = true
		button.modulate = Color.WHITE if enabled or selected else Color(0.52, 0.50, 0.48, 0.72)
		_apply_character_button_style(button, selected, enabled)

		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon:
			if selected:
				icon.modulate = Color.WHITE
			elif enabled:
				icon.modulate = Color(0.78, 0.74, 0.68, 0.92)
			else:
				icon.modulate = Color(0.48, 0.46, 0.44, 0.62)
		var label := button.get_node_or_null("Name") as Label
		if label:
			label.visible = true
			label.add_theme_font_size_override("font_size", roundi((22.0 if selected else 19.0) * _ui_scale))
			label.add_theme_color_override("font_color", Color("ffe7ad") if selected else Color("d4c2a0"))
			if not enabled and not selected:
				label.add_theme_color_override("font_color", Color(0.58, 0.54, 0.47, 0.78))

		# 新选中的角色卡 punch 一下（布局刷新重进本函数时不重复弹）。
		if selected and index != _last_punched_index:
			_last_punched_index = index
			button.pivot_offset = button.size * 0.5
			button.scale = Vector2.ONE * 1.08
			var tween := button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "scale", Vector2.ONE, 0.3)

	_refresh_character_card_metrics()


func _apply_character_button_style(button: Button, selected: bool, enabled: bool) -> void:
	var normal_texture := CARD_FRAME_SELECTED if selected else CARD_FRAME_NORMAL
	if not enabled and not selected:
		normal_texture = CARD_FRAME_DISABLED

	button.add_theme_stylebox_override("normal", _make_texture_style(normal_texture, CARD_FRAME_MARGINS, Vector4.ZERO))
	button.add_theme_stylebox_override("hover", _make_texture_style(CARD_FRAME_HOVER if enabled else CARD_FRAME_DISABLED, CARD_FRAME_MARGINS, Vector4.ZERO))
	button.add_theme_stylebox_override("pressed", _make_texture_style(CARD_FRAME_SELECTED, CARD_FRAME_MARGINS, Vector4.ZERO))
	button.add_theme_stylebox_override("disabled", _make_texture_style(CARD_FRAME_DISABLED, CARD_FRAME_MARGINS, Vector4.ZERO, Color(0.72, 0.68, 0.62, 0.84)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _refresh_character_card_metrics() -> void:
	if character_entries.is_empty():
		return

	for index in character_entries.size():
		var entry := character_entries[index]
		var button := entry.button as Button
		if not button:
			continue

		var selected := index == selected_index
		var card_size := CARD_SELECTED_SIZE if selected else CARD_SIZE
		button.custom_minimum_size = card_size * _ui_scale

		var glow := button.get_node_or_null("SelectedGlow") as TextureRect
		if glow:
			glow.visible = selected
			glow.offset_left = -15.0 * _ui_scale
			glow.offset_top = -15.0 * _ui_scale
			glow.offset_right = 15.0 * _ui_scale
			glow.offset_bottom = 15.0 * _ui_scale
			glow.anchor_left = 0.0
			glow.anchor_top = 0.0
			glow.anchor_right = 1.0
			glow.anchor_bottom = 1.0

		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.anchor_left = 0.0
			icon.anchor_top = 0.0
			icon.anchor_right = 1.0
			icon.anchor_bottom = 1.0
			icon.offset_left = 17.0 * _ui_scale
			icon.offset_top = 24.0 * _ui_scale
			icon.offset_right = -17.0 * _ui_scale
			icon.offset_bottom = -68.0 * _ui_scale
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

		var mask := button.get_node_or_null("PortraitMaskFrame") as TextureRect
		if mask:
			mask.anchor_left = 0.0
			mask.anchor_top = 0.0
			mask.anchor_right = 1.0
			mask.anchor_bottom = 1.0
			mask.offset_left = 9.0 * _ui_scale
			mask.offset_top = 14.0 * _ui_scale
			mask.offset_right = -9.0 * _ui_scale
			mask.offset_bottom = -53.0 * _ui_scale

		var label := button.get_node_or_null("Name") as Label
		if label:
			label.anchor_left = 0.0
			label.anchor_top = 1.0
			label.anchor_right = 1.0
			label.anchor_bottom = 1.0
			label.offset_left = 10.0 * _ui_scale
			label.offset_top = -58.0 * _ui_scale
			label.offset_right = -10.0 * _ui_scale
			label.offset_bottom = -15.0 * _ui_scale


func _resolve_background(entry: Dictionary) -> Texture2D:
	var path: String = entry.get("background", "")
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return SELECTOR_BACKGROUND


func _default_character() -> CharacterStats:
	for entry in character_entries:
		if entry.get("enabled", true):
			return entry.stats
	return character_entries[0].stats


func _get_character_index(character: CharacterStats) -> int:
	for index in character_entries.size():
		if character_entries[index].stats == character:
			return index
	return 0
