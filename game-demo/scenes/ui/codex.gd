extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")

enum Tab {CARDS, RELICS, ENEMIES, STATUSES}

@onready var cards_tab: Button = %CardsTab
@onready var relics_tab: Button = %RelicsTab
@onready var enemies_tab: Button = %EnemiesTab
@onready var statuses_tab: Button = %StatusesTab
@onready var class_filter_bar: HBoxContainer = %ClassFilterBar
@onready var content_grid: GridContainer = %ContentGrid
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_text: RichTextLabel = %DetailText
@onready var back_button: Button = %BackButton
@onready var detail_close_button: Button = %DetailCloseButton

var current_tab = Tab.CARDS
var current_class_filter = "全部"
var cards_by_class = {}
var all_relics: Array = []
var all_enemies = []
var all_statuses = []


func _ready():
	cards_tab.pressed.connect(_show_tab.bind(Tab.CARDS))
	relics_tab.pressed.connect(_show_tab.bind(Tab.RELICS))
	enemies_tab.pressed.connect(_show_tab.bind(Tab.ENEMIES))
	statuses_tab.pressed.connect(_show_tab.bind(Tab.STATUSES))
	back_button.pressed.connect(_on_back_pressed)
	detail_close_button.pressed.connect(_hide_detail)

	_setup_class_filters()
	_collect_all_data()
	_show_tab(Tab.CARDS)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if detail_panel.visible:
			_hide_detail()
		else:
			_on_back_pressed()


func _setup_class_filters():
	for child in class_filter_bar.get_children():
		var btn = child as Button
		if btn:
			btn.pressed.connect(_on_class_filter_pressed.bind(btn.text))


func _on_class_filter_pressed(filter_name):
	current_class_filter = filter_name
	_update_class_filter_buttons()
	_clear_content()
	_hide_detail()
	_populate_cards()


func _update_class_filter_buttons():
	for child in class_filter_bar.get_children():
		var btn = child as Button
		if btn:
			btn.button_pressed = btn.text == current_class_filter


func _collect_all_data():
	_collect_cards()
	all_relics = _collect_relics()
	all_enemies = _collect_enemies()
	all_statuses = _collect_statuses()


func _collect_cards():
	cards_by_class.clear()
	var char_dirs = {
		"体修": "body_cultivator",
		"剑修": "sword_cultivator",
		"魔修": "demonic_cultivator",
		"驭兽": "beastmaster",
	}
	for cls_name in char_dirs.keys():
		var dir = char_dirs[cls_name]
		var cards = _load_resources_in_dir("res://characters/%s/cards/" % dir)
		cards_by_class[cls_name] = cards
	cards_by_class["通用"] = _load_resources_in_dir("res://common_cards/")


func _collect_relics() -> Array:
	var result: Array = []
	var seen_ids := {}

	for relic in RELIC_REWARD_POOL.relics:
		_append_codex_relic(relic, result, seen_ids)

	var starter_relic_paths := [
		"res://characters/body_cultivator/body_cultivator.tres",
		"res://characters/sword_cultivator/sword_cultivator.tres",
		"res://characters/demonic_cultivator/demonic_cultivator.tres",
		"res://characters/beastmaster/beastmaster.tres",
	]
	for path: String in starter_relic_paths:
		var character := load(path) as CharacterStats
		if character and character.starting_relic:
			_append_codex_relic(character.starting_relic, result, seen_ids)

	return result


func _append_codex_relic(relic, result: Array, seen_ids: Dictionary) -> void:
	if not relic or seen_ids.has(relic.id):
		return

	seen_ids[relic.id] = true
	result.append(relic)


func _collect_enemies():
	var result = []
	var enemy_paths = [
		"res://enemies/bat/bat_enemy.tres",
		"res://enemies/crab/crab_enemy.tres",
		"res://enemies/bull_demon/bull_demon.tres",
		"res://enemies/toxic_ghost/toxic_ghost.tres",
	]
	for path in enemy_paths:
		var res = load(path)
		if res is EnemyStats:
			result.append(res)
	return result


func _collect_statuses():
	var result = []
	var status_names = ["exposed", "muscle", "qi_flow", "true_strength_form",
						"bleed", "sword_intent", "energy_charge", "sword_guard", "true_essence",
						"forge_sword", "gold_body", "soul_mark", "spirit_beast", "beast_pack"]
	for status_id in status_names:
		var res = load("res://statuses/%s.tres" % status_id)
		if res is Status:
			result.append(res)
	return result


func _load_resources_in_dir(path):
	var result = []
	var dir = DirAccess.open(path)
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var resource_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			result.append_array(_load_resources_in_dir(resource_path))
		elif file_name.ends_with(".tres"):
			var res = load(resource_path)
			if res is Card:
				result.append(res)
		file_name = dir.get_next()
	return result


func _show_tab(tab):
	current_tab = tab
	_update_tab_buttons()
	_clear_content()
	_hide_detail()
	class_filter_bar.visible = tab == Tab.CARDS

	match tab:
		Tab.CARDS:
			_populate_cards()
		Tab.RELICS:
			_populate_relics()
		Tab.ENEMIES:
			_populate_enemies()
		Tab.STATUSES:
			_populate_statuses()


func _update_tab_buttons():
	cards_tab.button_pressed = current_tab == Tab.CARDS
	relics_tab.button_pressed = current_tab == Tab.RELICS
	enemies_tab.button_pressed = current_tab == Tab.ENEMIES
	statuses_tab.button_pressed = current_tab == Tab.STATUSES


func _clear_content():
	for child in content_grid.get_children():
		child.queue_free()


func _populate_cards():
	content_grid.columns = 5
	var cards_to_show = []

	if current_class_filter == "全部":
		for cls_name in cards_by_class.keys():
			cards_to_show.append_array(cards_by_class[cls_name])
	else:
		var filtered = cards_by_class.get(current_class_filter, [])
		cards_to_show.append_array(filtered)

	for card in cards_to_show:
		if not card:
			continue

		var menu_ui = CARD_MENU_UI_SCENE.instantiate()
		content_grid.add_child(menu_ui)
		menu_ui.card = card
		menu_ui.tooltip_requested.connect(_show_card_detail.bind(card))


func _populate_enemies():
	content_grid.columns = 4
	for enemy_stats in all_enemies:
		var enemy_name = _enemy_display_name(enemy_stats)
		var entry = _create_entry(enemy_stats.art, enemy_name)
		entry.gui_input.connect(_on_enemy_entry_input.bind(enemy_stats))
		content_grid.add_child(entry)


func _populate_relics():
	content_grid.columns = 5
	for relic in all_relics:
		if not relic:
			continue

		var entry = _create_entry(relic.icon, relic.relic_name)
		entry.gui_input.connect(_on_relic_entry_input.bind(relic))
		content_grid.add_child(entry)


func _populate_statuses():
	content_grid.columns = 4
	for status in all_statuses:
		var entry = _create_entry(status.icon, _status_display_name(status.id))
		entry.gui_input.connect(_on_status_entry_input.bind(status))
		content_grid.add_child(entry)


func _create_entry(icon, title):
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 140)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.mouse_filter = Control.MOUSE_FILTER_PASS

	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = icon
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(texture_rect)

	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	return container


func _status_display_name(id):
	match id:
		"exposed": return "破绽"
		"muscle": return "劲气"
		"qi_flow": return "灵息"
		"true_strength_form": return "真武形"
		"bleed": return "流血"
		"sword_intent": return "剑意"
		"energy_charge": return "凝气"
		"sword_guard": return "剑阵"
		"true_essence": return "真元"
		"forge_sword": return "铸剑"
		"gold_body": return "金身"
		"soul_mark": return "魂印"
		"spirit_beast": return "灵兽"
		"beast_pack": return "兽群"
		_: return id


func _show_card_detail(card):
	detail_icon.texture = card.icon
	detail_title.text = card.get_display_name()
	detail_text.text = _format_card_detail(card)
	detail_panel.show()


func _on_relic_entry_input(event, relic):
	if event.is_action_pressed("left_mouse"):
		_show_relic_detail(relic)


func _show_relic_detail(relic):
	detail_icon.texture = relic.icon
	detail_title.text = relic.relic_name
	detail_text.text = "[center]%s[/center]" % relic.get_tooltip()
	detail_panel.show()


func _format_card_detail(card):
	var text = ""
	match card.type:
		Card.Type.ATTACK: text += "[color=#ff6666]攻击[/color]"
		Card.Type.SKILL: text += "[color=#66ccff]技能[/color]"
		Card.Type.POWER: text += "[color=#ffcc66]能力[/color]"

	match card.rarity:
		Card.Rarity.COMMON: text += "  |  普通"
		Card.Rarity.UNCOMMON: text += "  |  稀有"
		Card.Rarity.RARE: text += "  |  传说"
		Card.Rarity.MYTHIC: text += "  |  暗金"

	text += "  |  %s 费 | 元素：%s\n\n" % [card.cost, card.get_element_name()]

	if card is CultivationCard:
		text += card.get_default_tooltip()
	else:
		text += card.tooltip_text

	return text


func _on_enemy_entry_input(event, enemy_stats):
	if event.is_action_pressed("left_mouse"):
		_show_enemy_detail(enemy_stats)


func _show_enemy_detail(enemy_stats):
	detail_icon.texture = enemy_stats.art
	detail_title.text = _enemy_display_name(enemy_stats)
	detail_text.text = "[center]生命: %s\n\n%s[/center]" % [enemy_stats.max_health, _enemy_description(enemy_stats)]
	detail_panel.show()


func _enemy_display_name(enemy_stats):
	if enemy_stats.display_name:
		return enemy_stats.display_name
	return "未知怪物"


func _enemy_description(enemy_stats):
	return enemy_stats.description


func _on_status_entry_input(event, status):
	if event.is_action_pressed("left_mouse"):
		_show_status_detail(status)


func _show_status_detail(status):
	detail_icon.texture = status.icon
	detail_title.text = _status_display_name(status.id)
	var desc = status.get_tooltip()
	if desc.is_empty():
		desc = status.tooltip % status.stacks
	detail_text.text = "[center]%s[/center]" % desc
	detail_panel.show()


func _hide_detail():
	detail_panel.hide()


func _on_back_pressed():
	hide()
	get_tree().paused = false
