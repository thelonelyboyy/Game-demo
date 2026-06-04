class_name Blessing
extends Control

const BACKGROUND := preload("res://test1.png")

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
		"name": "斗姆元君",
		"description": "星斗归位，照见此行凶吉。",
		"blessings": [
			{"name": "星辉满身", "description": "回复至满生命。", "effect": "full_heal"},
			{"name": "星盘赠财", "description": "获得 100 灵石。", "effect": "big_gold"},
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

@export var character_stats: CharacterStats
@export var run_stats: RunStats
@export var chapter := 1

var god: Dictionary
var choices: Array
var choice_buttons: Array[Button] = []


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
	dimmer.color = Color(0.03, 0.035, 0.035, 0.62)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.custom_minimum_size = Vector2(960, 620)
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -480
	content.offset_top = -310
	content.offset_right = 480
	content.offset_bottom = 310
	content.add_theme_constant_override("separation", 18)
	add_child(content)

	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InkTheme.apply_title(title, 52)
	content.add_child(title)

	var description := Label.new()
	description.name = "Description"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.custom_minimum_size = Vector2(960, 72)
	InkTheme.apply_body_label(description, 24)
	content.add_child(description)

	var choices_row := HBoxContainer.new()
	choices_row.name = "Choices"
	choices_row.custom_minimum_size = Vector2(960, 340)
	choices_row.add_theme_constant_override("separation", 20)
	content.add_child(choices_row)

	for i in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(300, 330)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		InkTheme.apply_button(button, true)
		button.pressed.connect(_on_choice_pressed.bind(i))
		choices_row.add_child(button)
		choice_buttons.append(button)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "选择一项祝福后将直接进入本章地图。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InkTheme.apply_body_label(hint, 20)
	content.add_child(hint)


func _roll_blessings() -> void:
	god = RNG.array_pick_random(GODS) as Dictionary
	var blessing_pool: Array = (god.get("blessings", []) as Array).duplicate()
	RNG.array_shuffle(blessing_pool)
	choices = blessing_pool.slice(0, mini(3, blessing_pool.size()))

	var title := $Content/Title as Label
	var description := $Content/Description as Label
	title.text = "第%s章之前  %s降下祝福" % [chapter, god.get("name", "未知神明")]
	description.text = god.get("description", "")

	for i in choice_buttons.size():
		var button := choice_buttons[i]
		if i >= choices.size():
			button.hide()
			continue

		var blessing := choices[i] as Dictionary
		button.text = "%s\n\n%s" % [
			blessing.get("name", "未知祝福"),
			blessing.get("description", "")
		]


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
