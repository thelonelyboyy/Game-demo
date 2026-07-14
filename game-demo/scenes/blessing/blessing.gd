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
	"rare_card": preload("res://art/ui/icons/deck.png"),
	"draw": preload("res://art/ui/icons/draw.png"),
	"max_mana": preload("res://art/map/nodes/map_node_blessing.png"),
	"relic": preload("res://art/map/nodes/map_node_blessing.png"),
	"seal": preload("res://art/relics/icons/campfire_ember_seal.png"),
	"potion": preload("res://art/potions/icons/healing_pill.png"),
}

# 来源徽记颜色：一眼区分每个选项的"性格"。
const SOURCE_COLORS := {
	"灵脉余泽": Color("7cc47a"),
	"补天盟密阵": Color("6fb2d8"),
	"残仙遗蜕": Color("e06a5a"),
	"照命石审判": Color("f2c94f"),
	"命格共鸣": Color("b88ad8"),
}

const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
const BROKEN_SEAL_RELIC := preload("res://relics/blessing_broken_seal.tres")
const CHOICE_COUNT := 4

@export var character_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler
@export var chapter := 1

var source: Dictionary
var choices: Array
var choice_buttons: Array[Button] = []
var choice_rows: Array[Dictionary] = []


func _ready() -> void:
	InkTheme.animate_screen_entrance(self)
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
	dimmer.color = Color(0.03, 0.00, 0.00, 0.24)
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
	InkTheme.apply_screen_title(title, 58)
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
	InkTheme.apply_subtitle(subtitle, 25)
	add_child(subtitle)

	var dialogue := PanelContainer.new()
	dialogue.name = "Dialogue"
	dialogue.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dialogue.offset_left = -420
	dialogue.offset_top = 650
	dialogue.offset_right = 420
	dialogue.offset_bottom = 700
	dialogue.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.030, 0.028, 0.88), Color(0.70, 0.48, 0.24, 0.64), 2, 8, Color(0, 0, 0, 0.46), 12))
	add_child(dialogue)

	var dialogue_label := Label.new()
	dialogue_label.name = "DialogueText"
	dialogue_label.text = "聆听先古回响，择其一而行。"
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_color_override("font_color", Color("efe6d0"))
	dialogue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	dialogue_label.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_label.add_theme_font_size_override("font_size", 25)
	dialogue.add_child(dialogue_label)

	var list := VBoxContainer.new()
	list.name = "Choices"
	list.set_anchors_preset(Control.PRESET_CENTER_TOP)
	list.offset_left = -470
	list.offset_top = 712
	list.offset_right = 470
	list.offset_bottom = 1044
	list.add_theme_constant_override("separation", 10)
	add_child(list)

	for i in CHOICE_COUNT:
		var row := _create_choice_row(i)
		list.add_child(row["button"])
		InkTheme.wire_button_sfx(row["button"])
		InkTheme.animate_item_entrance(row["button"], 0.1)
		choice_buttons.append(row["button"])
		choice_rows.append(row)


func _create_choice_row(index: int) -> Dictionary:
	var button := Button.new()
	button.custom_minimum_size = Vector2(940, 72)
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

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 10)
	text_box.add_child(name_row)

	# 来源徽记：标明这个选项来自哪路"先古回响"。
	var tag_label := Label.new()
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	tag_label.add_theme_constant_override("shadow_offset_x", 2)
	tag_label.add_theme_constant_override("shadow_offset_y", 2)
	tag_label.add_theme_font_size_override("font_size", 18)
	name_row.add_child(tag_label)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", Color("f2c94f"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.add_theme_font_size_override("font_size", 24)
	name_row.add_child(name_label)

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
		"tag": tag_label,
		"name": name_label,
		"description": description_label,
	}


# 杀戮尖塔 Neow 式选择：不再"抽一个来源出三个同质选项"，
# 而是打乱来源、每个来源各出一条——稳妥/改牌/以劫换福/豪赌四种性格同台，必有取舍。
func _roll_blessings() -> void:
	_load_sources()
	if sources_data.is_empty():
		return

	var cls := _character_class()
	var shuffled_sources: Array = sources_data.duplicate()
	RNG.array_shuffle(shuffled_sources)

	choices = []
	for src in shuffled_sources:
		if choices.size() >= CHOICE_COUNT:
			break
		var pool: Array = []
		for b in ((src as Dictionary).get("blessings", []) as Array):
			var b_class: String = (b as Dictionary).get("class", "")
			if b_class.is_empty() or b_class == cls:
				pool.append(b)
		if pool.is_empty():
			continue
		choices.append({
			"blessing": RNG.array_pick_random(pool),
			"source_name": (src as Dictionary).get("name", ""),
		})

	var title := $Title as Label
	var description := $Description as Label
	title.text = "劫中遗赠"
	description.text = "第 %s 章之前，数道先古回响同时低语，只可应其一。" % chapter

	for i in choice_rows.size():
		var row := choice_rows[i]
		var button := row["button"] as Button
		if i >= choices.size():
			button.hide()
			continue

		var entry := choices[i] as Dictionary
		var blessing := entry["blessing"] as Dictionary
		var source_name := entry["source_name"] as String
		var icon_key := blessing.get("icon", "max_mana") as String
		(row["icon"] as TextureRect).texture = EFFECT_ICONS.get(icon_key, EFFECT_ICONS["max_mana"])
		var tag := row["tag"] as Label
		tag.text = "「%s」" % source_name
		tag.add_theme_color_override("font_color", SOURCE_COLORS.get(source_name, Color("d4c2a0")))
		(row["name"] as Label).text = blessing.get("name", "未知祝福")
		(row["description"] as Label).text = blessing.get("description", "")
		button.show()


func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= choices.size():
		return

	GameSfx.play(GameSfx.GONG, -6.0)
	_apply_blessing((choices[index] as Dictionary)["blessing"])
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
		"remove_strike_defend":
			_remove_basic_cards(maxi(amount, 1))
		"duplicate_card":
			_duplicate_random_cards(maxi(amount, 1))
		"add_random_cards":
			_add_random_draftable_cards(maxi(amount, 1), false)
		"add_random_rare_card":
			_add_random_draftable_cards(maxi(amount, 1), true)
		"transform_card":
			# 蜕变：移除 N 张打击/防御，换 N 张随机职业术法。
			_remove_basic_cards(maxi(amount, 1))
			_add_random_draftable_cards(maxi(amount, 1), false)
		"grant_relic":
			_grant_relics(maxi(amount, 1))
		"gain_potion":
			_grant_random_potions(maxi(amount, 1))
		"lose_all_gold":
			run_stats.gold = 0
		"weaken_next_battles":
			_grant_broken_seal(maxi(amount, 1))


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
	var picked_cards: Array[Card] = []
	for _i in count:
		var candidates: Array[Card] = []
		for card: Card in character_stats.deck.cards:
			if card and card.can_upgrade():
				candidates.append(card)
		var picked := RNG.array_pick_random(candidates) as Card
		if picked:
			picked.upgrade()
			picked_cards.append(picked)
	_notify_cards("突破卡牌", picked_cards, "卡牌已完成突破。")


func _remove_random_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	var picked_cards: Array[Card] = []
	for _i in count:
		if character_stats.deck.cards.size() <= 1:
			break
		var picked := RNG.array_pick_random(character_stats.deck.cards) as Card
		if picked:
			character_stats.deck.remove_card(picked)
			picked_cards.append(picked)
	_notify_cards("移除卡牌", picked_cards, "卡牌已从本次牌组中移除。")


func _duplicate_random_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	var copied_cards: Array[Card] = []
	for _i in count:
		if character_stats.deck.cards.is_empty():
			break
		var picked := RNG.array_pick_random(character_stats.deck.cards) as Card
		if picked:
			var copied_card := picked.duplicate(true) as Card
			character_stats.deck.add_card(copied_card)
			copied_cards.append(copied_card)
	_notify_cards("复制卡牌", copied_cards, "以下副本已加入牌组。")


func _grant_relics(count: int) -> void:
	if not relic_handler:
		return
	var picked_names: Array[String] = []
	for _i in count:
		var relic := RELIC_REWARD_POOL.get_random_available(
			character_stats,
			relic_handler,
			chapter,
			RelicRewardPool.RewardContext.STANDARD
		)
		if relic:
			relic_handler.add_relic(relic)
			picked_names.append(relic.relic_name)
	_notify("获得法宝", picked_names)


# 随机结果播报：让玩家看见"到底随机到了哪张"。
func _notify(prefix: String, names: Array[String]) -> void:
	if names.is_empty():
		return
	var joined := ""
	for n in names:
		joined += "「%s」" % n
	Events.ui_notice_requested.emit("%s：%s" % [prefix, joined])


func _notify_cards(title: String, cards: Array[Card], detail: String) -> void:
	if not cards.is_empty():
		Events.card_change_feedback_requested.emit(title, cards, detail)


# 移除打击/防御类起手牌（id 含 strike/defend，兼容魔修的 demon_strike 等专属版本）。
# 比"随机移除任意牌"安全——不会吃掉玩家的好牌。
func _remove_basic_cards(count: int) -> void:
	if not character_stats or not character_stats.deck:
		return
	var picked_cards: Array[Card] = []
	for _i in count:
		if character_stats.deck.cards.size() <= 1:
			break
		var candidates: Array[Card] = []
		for card: Card in character_stats.deck.cards:
			if card and (card.id.contains("strike") or card.id.contains("defend")):
				candidates.append(card)
		var picked := RNG.array_pick_random(candidates) as Card
		if picked:
			character_stats.deck.remove_card(picked)
			picked_cards.append(picked)
	_notify_cards("移除卡牌", picked_cards, "基础卡已从本次牌组中移除。")


# 从职业可抽卡池发随机卡；rare_only 时只发金卡（无金卡则退回全池）。
func _add_random_draftable_cards(count: int, rare_only: bool) -> void:
	if not character_stats or not character_stats.deck or not character_stats.draftable_cards:
		return
	var pool: Array[Card] = character_stats.draftable_cards.cards
	if pool.is_empty():
		return
	var added_cards: Array[Card] = []
	for _i in count:
		var candidates: Array[Card] = []
		for card: Card in pool:
			if card and (not rare_only or card.rarity == Card.Rarity.RARE):
				candidates.append(card)
		if candidates.is_empty():
			candidates = pool.duplicate()
		var picked := RNG.array_pick_random(candidates) as Card
		if picked:
			var copied_card := picked.duplicate(true) as Card
			character_stats.deck.add_card(copied_card)
			added_cards.append(copied_card)
	_notify_cards("获得卡牌", added_cards, "以下卡牌已加入牌组。")


# 借用 run 的丹药奖池发放（blessing 是 run 的子场景，经组拿 run 节点）。
func _grant_random_potions(count: int) -> void:
	var run: Node = get_tree().get_first_node_in_group("run")
	if not run or not ("potion_handler" in run) or not run.potion_handler:
		return
	var picked_names: Array[String] = []
	for _i in count:
		if run.potion_handler.is_full():
			break
		var potion: Potion = run._random_reward_potion()
		if potion:
			run.potion_handler.add_potion(potion)
			picked_names.append(potion.potion_name)
	_notify("获得丹药", picked_names)


# 破劫之印：接下来 N 场战斗敌人以七成气血入场（消耗性法宝，用尽自碎）。
func _grant_broken_seal(battle_count: int) -> void:
	if not relic_handler:
		return
	var seal := BROKEN_SEAL_RELIC.duplicate(true) as Relic
	seal.set("battles_left", battle_count)
	relic_handler.add_relic(seal)


func _apply_choice_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.045, 0.030, 0.028, 0.82), Color(0.58, 0.38, 0.20, 0.74), 1, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.090, 0.045, 0.038, 0.92), Color("f2c94f"), 2, 8, Color(0.72, 0.24, 0.10, 0.20), 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.030, 0.020, 0.020, 0.96), Color(0.86, 0.55, 0.25, 0.92), 2, 8))
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
