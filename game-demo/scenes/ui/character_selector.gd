extends Control

const SPIRIT_ROOT_SELECTOR_SCENE = preload("res://scenes/ui/spirit_root_selector.tscn")
const BODY_CULTIVATOR_STATS := preload("res://characters/body_cultivator/body_cultivator.tres")
const SWORD_CULTIVATOR_STATS := preload("res://characters/sword_cultivator/sword_cultivator.tres")
const DEMONIC_CULTIVATOR_STATS := preload("res://characters/demonic_cultivator/demonic_cultivator.tres")
const BEASTMASTER_STATS := preload("res://characters/beastmaster/beastmaster.tres")
const SELECTOR_BACKGROUND := preload("res://test1.png")

const STARTING_GOLD := 99

@export var run_startup: RunStartup

@onready var background: TextureRect = $Background
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
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var character_buttons: HBoxContainer = %CharacterButtons

var current_character: CharacterStats : set = set_current_character
var selected_index := 0
var character_entries: Array[Dictionary] = []


func _ready() -> void:
	_build_character_entries()
	_polish_scene()
	set_current_character(_default_character())


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

	if current_character.starting_relic:
		relic_icon.texture = current_character.starting_relic.icon
		relic_name.text = entry.relic_name
		relic_description.text = entry.relic_description

	_update_character_buttons()


func _on_start_button_pressed() -> void:
	print("Start new Run with %s" % current_character.character_name)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.picked_character = current_character
	get_tree().change_scene_to_packed(SPIRIT_ROOT_SELECTOR_SCENE)


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
			"enabled": true,
			"background": "res://art/backgrounds/sw.png",
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
			"name": "驭兽",
			"subtitle": "百兽同心 · 召唤协同",
			"description": "灵兽相伴，攻守轮转。依靠兽群、召唤与连携压制敌人。",
			"relic_name": "百兽铃",
			"relic_description": "每场战斗唤醒兽灵，让你的兽群更早进入战局。",
			"tint": Color(0.08, 0.40, 0.20, 0.32),
			"vignette": Color(0.02, 0.08, 0.04, 0.40),
			"hero_modulate": Color(0.82, 1.0, 0.78, 0.95),
		},
	]


func _polish_scene() -> void:
	_apply_custom_background()
	InkTheme.apply_panel(info_panel)
	InkTheme.apply_title(title, 76)
	InkTheme.apply_body_label(subtitle, 25)
	InkTheme.apply_body_label(description, 26)
	InkTheme.apply_body_label(health_value, 24)
	InkTheme.apply_body_label(gold_value, 24)
	InkTheme.apply_body_label(relic_name, 24)
	InkTheme.apply_body_label(relic_description, 22)
	InkTheme.apply_button(start_button, true)
	InkTheme.apply_button(back_button, true)

	title.add_theme_color_override("font_color", Color("f3c84b"))
	subtitle.add_theme_color_override("font_color", Color("f7ebd4"))
	relic_name.add_theme_color_override("font_color", Color("f0c85b"))
	health_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	character_portrait.hide()
	character_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 不再给背景图盖色罩/暗角，保持背景原图。
	accent_tint.hide()
	vignette.hide()

	# Keep the button row centered so hiding locked classes still looks balanced.
	character_buttons.alignment = BoxContainer.ALIGNMENT_CENTER

	for entry in character_entries:
		var button := entry.button as Button
		button.visible = entry.get("enabled", true)
		button.text = ""
		button.tooltip_text = entry.name
		button.custom_minimum_size = Vector2(92.0, 122.0)
		button.focus_mode = Control.FOCUS_NONE
		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.texture = entry.stats.portrait
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var label := button.get_node_or_null("Name") as Label
		if label:
			label.text = entry.name
			InkTheme.apply_body_label(label, 17)


func _apply_custom_background() -> void:
	background.texture = SELECTOR_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()


func _update_character_buttons() -> void:
	for index in character_entries.size():
		var entry := character_entries[index]
		var button := entry.button as Button
		var selected := index == selected_index
		button.button_pressed = selected
		button.modulate = Color.WHITE if selected else Color(0.62, 0.62, 0.58, 0.78)
		_apply_character_button_style(button, selected, entry.tint)

		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.modulate = Color.WHITE if selected else Color(0.62, 0.62, 0.62, 0.82)
		var label := button.get_node_or_null("Name") as Label
		if label:
			label.visible = selected


func _apply_character_button_style(button: Button, selected: bool, tint: Color) -> void:
	var accent := Color(tint.r + 0.30, tint.g + 0.28, tint.b + 0.18, 1.0)
	var normal_border := accent if selected else Color(0.46, 0.40, 0.28, 0.72)
	var bg := Color(0.04, 0.04, 0.035, 0.58) if selected else Color(0.03, 0.03, 0.03, 0.38)
	var border_width := 3 if selected else 1

	button.add_theme_stylebox_override("normal", InkTheme.make_style(bg, normal_border, border_width, 4, Color(0, 0, 0, 0.36), 10))
	button.add_theme_stylebox_override("hover", InkTheme.make_style(Color(0.12, 0.12, 0.09, 0.68), accent, 3, 4, Color(0.9, 0.72, 0.28, 0.32), 12))
	button.add_theme_stylebox_override("pressed", InkTheme.make_style(Color(0.11, 0.10, 0.07, 0.72), accent, 3, 4, Color(0.9, 0.72, 0.28, 0.34), 12))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


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
