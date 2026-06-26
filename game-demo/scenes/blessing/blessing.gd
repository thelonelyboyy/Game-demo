class_name Blessing
extends Control

const BACKGROUND := preload("res://art/backgrounds/blessing_cavern_bg.png")

# 祝福数据外置在 data/blessings.json，可经 Excel 管线编辑后回写。
const BLESSINGS_DATA_PATH := "res://data/blessings.json"

var sources_data: Array = []

const EFFECT_ICONS := {
	"max_health": preload("res://art/ui/icons/heart.png"),
	"full_heal": preload("res://art/ui/icons/heart.png"),
	"gold": preload("res://art/ui/icons/gold.png"),
	"big_gold": preload("res://art/ui/icons/gold.png"),
	"upgrade": preload("res://art/ui/icons/deck.png"),
	"remove_card": preload("res://art/ui/icons/deck.png"),
	"duplicate_card": preload("res://art/ui/icons/deck.png"),
	"draw": preload("res://art/ui/icons/draw.png"),
	"max_mana": preload("res://art/map/nodes/map_node_blessing.png"),
	"relic": preload("res://art/map/nodes/map_node_blessing.png"),
}

const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")

@export var character_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler
@export var chapter := 1

var source: Dictionary
var choices: Array
var choice_buttons: Array[Button] = []
var choice_rows: Array[Dictionary] = []


func _ready() -> void:
	_load_sources()
	_build_ui()

	if character_stats and run_stats:
		_roll_blessings()


func _load_sources() -> void:
	if not sources_data.is_empty():
		return
	if not FileAccess.file_exists(BLESSINGS_DATA_PATH):
		push_error("祝福数据缺失：%s" % BLESSINGS_DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BLESSINGS_DATA_PATH))
	if parsed is Dictionary:
		sources_data = (parsed as Dictionary).get("sources", [])


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
	_load_sources()
	if sources_data.is_empty():
		return
	source = RNG.array_pick_random(sources_data) as Dictionary

	# 按角色命格过滤（仅命格共鸣带 class 标签；其余来源全部放行）。
	var cls := _character_class()
	var blessing_pool: Array = []
	for b in (source.get("blessings", []) as Array):
		var b_class: String = (b as Dictionary).get("class", "")
		if b_class.is_empty() or b_class == cls:
			blessing_pool.append(b)

	RNG.array_shuffle(blessing_pool)
	choices = blessing_pool.slice(0, mini(3, blessing_pool.size()))

	var title := $Title as Label
	var description := $Description as Label
	title.text = source.get("name", "劫中遗赠")
	description.text = "第 %s 章之前，%s" % [chapter, source.get("description", "")]

	for i in choice_rows.size():
		var row := choice_rows[i]
		var button := row["button"] as Button
		if i >= choices.size():
			button.hide()
			continue

		var blessing := choices[i] as Dictionary
		var icon_key := blessing.get("icon", "max_mana") as String
		(row["icon"] as TextureRect).texture = EFFECT_ICONS.get(icon_key, EFFECT_ICONS["max_mana"])
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
	for effect in blessing.get("effects", []):
		_apply_effect(effect.get("type", ""), int(effect.get("amount", 0)))
	character_stats.stats_changed.emit()


func _apply_effect(type: String, amount: int) -> void:
	match type:
		"max_health":
			# Stats.set_max_health 在增加上限时已自动回复同等生命，无需再 heal。
			character_stats.max_health += amount
		"lose_max_health":
			character_stats.max_health = maxi(1, character_stats.max_health - amount)
			character_stats.health = mini(character_stats.health, character_stats.max_health)
		"full_heal":
			character_stats.heal(character_stats.max_health)
		"gold":
			run_stats.gold += amount
		"lose_gold":
			run_stats.gold = maxi(0, run_stats.gold - amount)
		"max_mana":
			character_stats.max_mana += amount
			character_stats.reset_mana()
		"draw":
			character_stats.cards_per_turn += amount
		"upgrade":
			_upgrade_random_cards(maxi(amount, 1))
		"remove_card":
			_remove_random_cards(maxi(amount, 1))
		"duplicate_card":
			_duplicate_random_cards(maxi(amount, 1))
		"grant_relic":
			_grant_relics(maxi(amount, 1))


func _character_class() -> String:
	if not character_stats:
		return ""
	var path := character_stats.resource_path
	if path.is_empty() and character_stats.starting_deck:
		path = character_stats.starting_deck.resource_path
	if path.contains("demonic_cultivator"):
		return "demonic"
	if path.contains("sword_cultivator"):
		return "sword"
	if path.contains("body_cultivator"):
		return "body"
	if path.contains("beastmaster"):
		return "beastmaster"
	return ""


func _upgrade_random_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	for _i in count:
		var candidates: Array[Card] = []
		for card: Card in character_stats.deck.cards:
			if card and card.can_upgrade():
				candidates.append(card)
		var picked := RNG.array_pick_random(candidates) as Card
		if picked:
			picked.upgrade()


func _remove_random_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	for _i in count:
		if character_stats.deck.cards.size() <= 1:
			return
		var picked := RNG.array_pick_random(character_stats.deck.cards) as Card
		if picked:
			character_stats.deck.remove_card(picked)


func _duplicate_random_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	for _i in count:
		if character_stats.deck.cards.is_empty():
			return
		var picked := RNG.array_pick_random(character_stats.deck.cards) as Card
		if picked:
			character_stats.deck.add_card(picked.duplicate(true))


func _grant_relics(count: int) -> void:
	if not relic_handler:
		return
	for _i in count:
		var relic := RELIC_REWARD_POOL.get_random_available(character_stats, relic_handler)
		if relic:
			relic_handler.add_relic(relic)


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
