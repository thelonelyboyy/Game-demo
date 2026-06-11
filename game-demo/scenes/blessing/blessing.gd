class_name Blessing
extends Control

const BACKGROUND := preload("res://art/blessing_cavern_bg.png")

const GODS := [
	{
		"name": "太上玄尊",
		"description": "玄门祖炁垂照，为入山者稳住根基。",
		"blessings": [
			{"name": "玄门护命", "description": "最大生命 +8，并回复 8 点生命。", "effect": "max_health"},
			{"name": "灵石启程", "description": "获得 80 灵石。", "effect": "gold"},
			{"name": "点化旧术", "description": "随机突破牌组中一张可突破卡牌。", "effect": "upgrade"},
			{"name": "气海初开", "description": "最大法力 +1。", "effect": "max_mana"},
		],
	},
	{
		"name": "斗姥元君",
		"description": "星斗归位，照见此行凶吉。",
		"blessings": [
			{"name": "星辉满身", "description": "回复至满生命。", "effect": "full_heal"},
			{"name": "星盘赐财", "description": "获得 100 灵石。", "effect": "big_gold"},
			{"name": "观星悟法", "description": "每回合抽牌数 +1。", "effect": "draw"},
			{"name": "星火破障", "description": "随机突破牌组中一张可突破卡牌。", "effect": "upgrade"},
		],
	},
	{
		"name": "伏羲道君",
		"description": "先天八卦流转，替修士推演一线生机。",
		"blessings": [
			{"name": "卦象聚财", "description": "获得 80 灵石。", "effect": "gold"},
			{"name": "先天强身", "description": "最大生命 +8，并回复 8 点生命。", "effect": "max_health"},
			{"name": "八卦明心", "description": "每回合抽牌数 +1。", "effect": "draw"},
			{"name": "开窍聚气", "description": "最大法力 +1。", "effect": "max_mana"},
		],
	},
]

const EFFECT_ICONS := {
	"max_health": preload("res://art/heart.png"),
	"full_heal": preload("res://art/heart.png"),
	"gold": preload("res://art/gold.png"),
	"big_gold": preload("res://art/gold.png"),
	"upgrade": preload("res://art/deck.png"),
	"draw": preload("res://art/draw.png"),
	"max_mana": preload("res://art/map/nodes/map_node_blessing.png"),
}

@export var character_stats: CharacterStats
@export var run_stats: RunStats
@export var chapter := 1

var god: Dictionary
var choices: Array
var choice_buttons: Array[Button] = []
var choice_rows: Array[Dictionary] = []


func _ready() -> void:
	_build_ui()

	if character_stats and run_stats:
		_roll_blessings()


func setup(new_character_stats: CharacterStats, new_run_stats: RunStats, new_chapter: int) -> void:
	character_stats = new_character_stats
	run_stats = new_run_stats
	chapter = new_chapter

	if is_node_ready():
		_roll_blessings()


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.00, 0.03, 0.06, 0.14)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -360
	title.offset_top = 330
	title.offset_right = 360
	title.offset_bottom = 410
	title.add_theme_color_override("font_color", Color("f2c94f"))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.05, 0.07, 0.94))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_font_size_override("font_size", 58)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Description"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.offset_left = -420
	subtitle.offset_top = 402
	subtitle.offset_right = 420
	subtitle.offset_bottom = 452
	subtitle.add_theme_color_override("font_color", Color("d7eef4"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0.01, 0.03, 0.05, 0.88))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 3)
	subtitle.add_theme_font_size_override("font_size", 25)
	add_child(subtitle)

	var dialogue := PanelContainer.new()
	dialogue.name = "Dialogue"
	dialogue.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dialogue.offset_left = -420
	dialogue.offset_top = 650
	dialogue.offset_right = 420
	dialogue.offset_bottom = 700
	dialogue.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.15, 0.18, 0.92), Color(0.15, 0.78, 0.95, 0.32), 2, 18))
	add_child(dialogue)

	var dialogue_label := Label.new()
	dialogue_label.name = "DialogueText"
	dialogue_label.text = "聆听先古回响，择其一而行。"
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_color_override("font_color", Color("f2efe2"))
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	dialogue_label.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_label.add_theme_font_size_override("font_size", 25)
	dialogue.add_child(dialogue_label)

	var list := VBoxContainer.new()
	list.name = "Choices"
	list.set_anchors_preset(Control.PRESET_CENTER_TOP)
	list.offset_left = -470
	list.offset_top = 718
	list.offset_right = 470
	list.offset_bottom = 980
	list.add_theme_constant_override("separation", 12)
	add_child(list)

	for i in 3:
		var row := _create_choice_row(i)
		list.add_child(row["button"])
		choice_buttons.append(row["button"])
		choice_rows.append(row)


func _create_choice_row(index: int) -> Dictionary:
	var button := Button.new()
	button.custom_minimum_size = Vector2(940, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.pressed.connect(_on_choice_pressed.bind(index))
	_apply_choice_button_style(button)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 22
	content.offset_top = 8
	content.offset_right = -22
	content.offset_bottom = -8
	content.add_theme_constant_override("separation", 18)
	button.add_child(content)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(58, 58)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	content.add_child(text_box)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", Color("f2c94f"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.add_theme_font_size_override("font_size", 24)
	text_box.add_child(name_label)

	var description_label := Label.new()
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color("f4efe4"))
	description_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	description_label.add_theme_constant_override("shadow_offset_x", 2)
	description_label.add_theme_constant_override("shadow_offset_y", 2)
	description_label.add_theme_font_size_override("font_size", 22)
	text_box.add_child(description_label)

	return {
		"button": button,
		"icon": icon,
		"name": name_label,
		"description": description_label,
	}


func _roll_blessings() -> void:
	god = RNG.array_pick_random(GODS) as Dictionary
	var blessing_pool: Array = (god.get("blessings", []) as Array).duplicate()
	RNG.array_shuffle(blessing_pool)
	choices = blessing_pool.slice(0, mini(3, blessing_pool.size()))

	var title := $Title as Label
	var description := $Description as Label
	title.text = god.get("name", "先古神明")
	description.text = "第 %s 章之前，%s" % [chapter, god.get("description", "")]

	for i in choice_rows.size():
		var row := choice_rows[i]
		var button := row["button"] as Button
		if i >= choices.size():
			button.hide()
			continue

		var blessing := choices[i] as Dictionary
		var effect := blessing.get("effect", "") as String
		(row["icon"] as TextureRect).texture = EFFECT_ICONS.get(effect, EFFECT_ICONS["max_mana"])
		(row["name"] as Label).text = blessing.get("name", "未知祝福")
		(row["description"] as Label).text = blessing.get("description", "")
		button.show()


func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= choices.size():
		return

	_apply_blessing(choices[index])
	Events.blessing_exited.emit()
	queue_free()


func _apply_blessing(blessing: Dictionary) -> void:
	match blessing.get("effect", ""):
		"max_health":
			character_stats.max_health += 8
		"gold":
			run_stats.gold += 80
		"big_gold":
			run_stats.gold += 100
		"upgrade":
			_upgrade_random_card()
		"draw":
			character_stats.cards_per_turn += 1
			character_stats.stats_changed.emit()
		"max_mana":
			character_stats.max_mana += 1
			character_stats.reset_mana()
			character_stats.stats_changed.emit()
		"full_heal":
			character_stats.heal(character_stats.max_health)


func _upgrade_random_card() -> void:
	if not character_stats or not character_stats.deck:
		return

	var candidates: Array[Card] = []
	for card: Card in character_stats.deck.cards:
		if card and card.can_upgrade():
			candidates.append(card)

	var picked := RNG.array_pick_random(candidates) as Card
	if picked:
		picked.upgrade()


func _apply_choice_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.03, 0.22, 0.29, 0.70), Color(0.08, 0.72, 0.92, 0.32), 1, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.05, 0.34, 0.42, 0.86), Color(0.45, 0.94, 1.0, 0.70), 2, 8, Color(0.20, 0.86, 1.0, 0.18), 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.02, 0.18, 0.22, 0.88), Color(0.94, 0.74, 0.25, 0.78), 2, 8))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)


func _make_panel_style(bg: Color, border: Color, border_width := 1, radius := 8, shadow := Color(0, 0, 0, 0.38), shadow_size := 8) -> StyleBoxFlat:
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
