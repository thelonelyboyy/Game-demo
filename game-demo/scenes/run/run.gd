class_name Run
extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const BATTLE_REWARD_SCENE := preload("res://scenes/battle_reward/battle_reward.tscn")
const BLESSING_SCENE := preload("res://scenes/blessing/blessing.tscn")
const CAMPFIRE_SCENE := preload("res://scenes/campfire/campfire.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE = preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE := preload("res://scenes/win_screen/win_screen.tscn")
const SPIRIT_ROOT_BADGE_SCENE := preload("res://scenes/ui/spirit_root_badge.tscn")
const CARD_VISUALS_SCENE := preload("res://scenes/ui/card_visuals.tscn")
const CARD_CHANGE_FEEDBACK_SCRIPT := preload("res://scenes/ui/card_change_feedback.gd")
const DEBUG_CONSOLE := preload("res://scenes/debug/debug_console.gd")
const DEMONIC_HEAD_ICON := preload("res://art/characters/demonic_cultivator_head_icon.png")
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
const DEFEAT_LEGACY := preload("res://custom_resources/defeat_legacy.gd")
const POTION_REWARD_PATHS := PotionRewardPool.POTION_PATHS
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const TOTAL_CHAPTERS := 3
const MUSIC_EXPLORATION := preload("res://art/audio/collected_dark_roguelike/bgm/vampires_piano_tad_cc0.mp3")
const EXPLORATION_MUSIC_VOLUME_DB := -7.0

@export var run_startup: RunStartup

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var potion_handler: PotionHandler = %PotionHandler
@onready var relic_tooltip: RelicTooltip = %RelicTooltip
@onready var deck_button: CardPileOpener = %DeckButton
@onready var deck_view: CardPileView = %DeckView
@onready var pause_menu: PauseMenu = $PauseMenu

@onready var battle_button: Button = %BattleButton
@onready var campfire_button: Button = %CampfireButton
@onready var map_button: Button = %MapButton
@onready var rewards_button: Button = %RewardsButton
@onready var shop_button: Button = %ShopButton
@onready var treasure_button: Button = %TreasureButton

var stats: RunStats
var character: CharacterStats
var save_data: SaveGame
var spirit_root_badge: SpiritRootBadge
var potion_bar_panel: PanelContainer
var legacy_choice_layer: CanvasLayer
var card_change_feedback: CardChangeFeedback
var debug_console
var current_chapter := 1
var pending_chapter_advance := false
var run_finalized := false
var exploration_music: AudioStreamMP3


func _ready() -> void:
	if not run_startup:
		return
	
	pause_menu.save_and_quit.connect(
		func(): 
			get_tree().change_scene_to_file(MAIN_MENU_PATH)
	)
	
	match run_startup.type:
		RunStartup.Type.NEW_RUN:
			character = run_startup.picked_character.create_instance(run_startup.selected_spirit_root)
			_start_run()
		RunStartup.Type.CONTINUED_RUN:
			_load_run()


func _start_run() -> void:
	stats = RunStats.new()
	stats.configure_difficulty(run_startup.difficulty_level)
	current_chapter = 1
	character.hero_skill_stage = current_chapter
	stats.apply_chapter_card_weights(current_chapter)
	if run_startup.spirit_root_declined:
		stats.apply_rootless_start(character)
	character.health = stats.get_starting_health(character.max_health)
	
	_setup_event_connections()
	_setup_top_bar()
	_setup_debug_console()

	_configure_map_difficulty()
	map.generate_new_map(current_chapter)
	map.unlock_floor(0)

	_grant_starter_potions()
	_play_exploration_music()

	save_data = SaveGame.new()
	_save_run(true)
	_show_starting_spirit_root_card.call_deferred()
	_show_defeat_legacy_choice_if_available.call_deferred()


func _random_reward_potion(context := PotionRewardPool.RewardContext.STANDARD) -> Potion:
	var pool: Array[Potion] = []
	for path in POTION_REWARD_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var potion := load(path) as Potion
		if potion and potion.can_appear_as_reward(character):
			pool.append(potion)
	if pool.is_empty():
		return null
	return PotionRewardPool.pick(pool, current_chapter, context)


func _grant_starter_potions() -> void:
	# 起手赠送 2 个符箓丹药（也方便测试，获取系统接好后可调整）。
	for path in ["res://potions/healing_pill.tres", "res://potions/flame_talisman.tres"]:
		if ResourceLoader.exists(path):
			potion_handler.add_potion(load(path) as Potion)


func _show_defeat_legacy_choice_if_available() -> void:
	var candidates := _filter_defeat_legacy_relics(DEFEAT_LEGACY.load_relics())
	if candidates.is_empty():
		DEFEAT_LEGACY.delete_data()
		return

	_show_defeat_legacy_choice_panel(candidates)


func _filter_defeat_legacy_relics(relics: Array[Relic]) -> Array[Relic]:
	var candidates: Array[Relic] = []
	var seen_ids := {}
	var current_starting_relic_id := ""
	if character and character.starting_relic:
		current_starting_relic_id = character.starting_relic.id

	for relic: Relic in relics:
		if not relic:
			continue
		if relic.id.is_empty() or seen_ids.has(relic.id):
			continue
		if relic.id == current_starting_relic_id:
			continue
		seen_ids[relic.id] = true
		candidates.append(relic)

	return candidates


func _show_defeat_legacy_choice_panel(candidates: Array[Relic]) -> void:
	if legacy_choice_layer:
		legacy_choice_layer.queue_free()

	get_tree().paused = true

	legacy_choice_layer = CanvasLayer.new()
	legacy_choice_layer.name = "DefeatLegacyChoice"
	legacy_choice_layer.layer = 8
	legacy_choice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(legacy_choice_layer)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.012, 0.010, 0.014, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	legacy_choice_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.custom_minimum_size = Vector2(860, 520)
	panel.add_theme_stylebox_override("panel", _make_legacy_panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -430
	panel.offset_top = -260
	panel.offset_right = 430
	panel.offset_bottom = 260
	legacy_choice_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	content.add_child(_make_legacy_label("劫灰遗宝", 38, Color("f2c94f"), HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_make_legacy_label(
		"上一轮失败后，劫灰中留下了这些法宝。选择一件替换本命法宝，或保留当前本命法宝。",
		20,
		Color("e8d8b8"),
		HORIZONTAL_ALIGNMENT_CENTER,
		true
	))
	content.add_child(_create_current_starter_relic_row())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 250)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for relic: Relic in candidates:
		list.add_child(_create_legacy_relic_button(relic))

	var keep_button := Button.new()
	keep_button.text = "保留当前本命法宝"
	keep_button.custom_minimum_size = Vector2(360, 56)
	keep_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	keep_button.focus_mode = Control.FOCUS_ALL
	keep_button.pressed.connect(_complete_defeat_legacy_choice.bind(null))
	_apply_legacy_button_text_style(keep_button, 24)
	keep_button.add_theme_stylebox_override("normal", _make_legacy_button_style(Color(0.07, 0.055, 0.05, 0.92), Color(0.60, 0.48, 0.26, 0.84)))
	keep_button.add_theme_stylebox_override("hover", _make_legacy_button_style(Color(0.12, 0.085, 0.06, 0.96), Color("f2c94f")))
	keep_button.add_theme_stylebox_override("pressed", _make_legacy_button_style(Color(0.045, 0.035, 0.032, 0.98), Color(0.80, 0.54, 0.28, 0.94)))
	content.add_child(keep_button)


func _create_current_starter_relic_row() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)

	row.add_child(_make_legacy_label("当前本命法宝", 20, Color("d8c49a")))

	if character and character.starting_relic:
		row.add_child(_create_relic_icon(character.starting_relic, 48))
		row.add_child(_make_legacy_label(character.starting_relic.relic_name, 22, Color("fff0c2")))

	return row


func _create_legacy_relic_button(relic: Relic) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(780, 84)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_complete_defeat_legacy_choice.bind(relic))
	_apply_legacy_button_text_style(button, 20)
	button.add_theme_stylebox_override("normal", _make_legacy_button_style(Color(0.035, 0.030, 0.035, 0.92), Color(0.50, 0.38, 0.21, 0.78)))
	button.add_theme_stylebox_override("hover", _make_legacy_button_style(Color(0.08, 0.045, 0.055, 0.96), Color("f2c94f")))
	button.add_theme_stylebox_override("pressed", _make_legacy_button_style(Color(0.025, 0.020, 0.024, 0.98), Color(0.82, 0.50, 0.24, 0.94)))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_top = 10
	row.offset_right = -16
	row.offset_bottom = -10
	row.add_theme_constant_override("separation", 14)
	button.add_child(row)

	row.add_child(_create_relic_icon(relic, 56))

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	text_box.add_child(_make_legacy_label(relic.relic_name, 22, Color("ffe7ad")))
	text_box.add_child(_make_legacy_label(relic.get_tooltip(), 17, Color("d8c7a4"), HORIZONTAL_ALIGNMENT_LEFT, true))

	return button


func _create_relic_icon(relic: Relic, icon_size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = relic.icon if relic else null
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _complete_defeat_legacy_choice(relic: Relic = null) -> void:
	if relic and character:
		var previous_relic := character.starting_relic
		if previous_relic:
			relic_handler.remove_relic(previous_relic.id)
		character.starting_relic = relic
		relic_handler.add_relic(relic)
		_polish_relic_row()

	DEFEAT_LEGACY.delete_data()
	_close_defeat_legacy_choice_panel()
	_save_run(true)


func _close_defeat_legacy_choice_panel() -> void:
	if legacy_choice_layer:
		legacy_choice_layer.queue_free()
		legacy_choice_layer = null
	get_tree().paused = false


func _make_legacy_label(
	text: String,
	font_size: int,
	color: Color,
	alignment := HORIZONTAL_ALIGNMENT_LEFT,
	wrap := false
) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.84))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _apply_legacy_button_text_style(button: Button, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("ffe7ad"))
	button.add_theme_color_override("font_hover_color", Color("fff6d6"))
	button.add_theme_color_override("font_pressed_color", Color("d8a75e"))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_legacy_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.024, 0.026, 0.96)
	style.border_color = Color(0.72, 0.52, 0.25, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 18
	return style


func _make_legacy_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 8
	return style


func _save_run(was_on_map: bool) -> void:
	save_data.rng_seed = RNG.instance.seed
	save_data.rng_state = RNG.instance.state
	save_data.run_stats = stats
	save_data.char_stats = character
	save_data.spirit_root = character.spirit_root
	save_data.current_deck = character.deck
	save_data.current_health = character.health
	save_data.relics = relic_handler.get_all_relics()
	save_data.potions = potion_handler.get_potions()
	save_data.last_room = map.last_room
	save_data.map_data = map.map_data.duplicate()
	save_data.floors_climbed = map.floors_climbed
	save_data.current_chapter = current_chapter
	save_data.was_on_map = was_on_map
	save_data.save_data()


func _load_run() -> void:
	save_data = SaveGame.load_data()
	if not save_data:
		push_warning("没有可用存档（可能已损坏并被清理），返回主菜单。")
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return

	RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	stats = save_data.run_stats
	if not stats:
		stats = RunStats.new()
	stats.refresh_difficulty_modifiers(false)
	character = save_data.char_stats
	current_chapter = maxi(save_data.current_chapter, 1)
	character.hero_skill_stage = clampi(current_chapter, 1, TOTAL_CHAPTERS)
	stats.apply_chapter_card_weights(current_chapter)
	if save_data.spirit_root != Card.Element.NONE:
		character.spirit_root = save_data.spirit_root
	character.deck = save_data.current_deck
	character.health = save_data.current_health
	character.ensure_demonic_card_element_distribution()
	character.bind_all_card_piles_to_owner()
	relic_handler.add_relics(save_data.relics)
	potion_handler.load_potions(save_data.potions)
	_setup_top_bar()
	_setup_debug_console()
	_setup_event_connections()
	
	_configure_map_difficulty()
	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_room)
	if save_data.last_room and not save_data.was_on_map:
		_on_map_exited(save_data.last_room)
	else:
		_play_exploration_music()


func _change_view(scene: PackedScene) -> Node:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()
	
	get_tree().paused = false
	var new_view := scene.instantiate()
	current_view.add_child(new_view)
	map.hide_map()
	
	return new_view


func _show_map() -> void:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	get_tree().paused = false
	_play_exploration_music()
	map.show_map()
	if map.last_room:
		map.unlock_next_rooms()
	else:
		map.unlock_floor(0)
	
	_save_run(true)


func _play_exploration_music() -> void:
	if not exploration_music:
		exploration_music = MUSIC_EXPLORATION.duplicate() as AudioStreamMP3
		exploration_music.loop = true
	MusicPlayer.play(exploration_music, true, EXPLORATION_MUSIC_VOLUME_DB)


func _setup_event_connections() -> void:
	potion_handler.character_stats = character
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_on_battle_reward_exited)
	Events.campfire_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_on_treasure_room_exited)
	Events.event_room_exited.connect(_show_map)
	Events.blessing_exited.connect(_show_map)
	if not Events.card_acquired_animation_requested.is_connected(_on_card_acquired_animation):
		Events.card_acquired_animation_requested.connect(_on_card_acquired_animation)
	if not Events.ui_notice_requested.is_connected(_on_ui_notice_requested):
		Events.ui_notice_requested.connect(_on_ui_notice_requested)
	if not Events.card_change_feedback_requested.is_connected(_on_card_change_feedback_requested):
		Events.card_change_feedback_requested.connect(_on_card_change_feedback_requested)
	if not Events.card_played.is_connected(_on_card_played_for_stats):
		Events.card_played.connect(_on_card_played_for_stats)
	if not Events.enemy_died.is_connected(_on_enemy_died_for_stats):
		Events.enemy_died.connect(_on_enemy_died_for_stats)
	if not Events.player_died.is_connected(_on_run_defeated):
		Events.player_died.connect(_on_run_defeated)
	if not Events.event_choice_resolved.is_connected(_on_event_resolved_for_stats):
		Events.event_choice_resolved.connect(_on_event_resolved_for_stats)
	if not Events.shop_card_bought.is_connected(_on_shop_purchase_for_stats):
		Events.shop_card_bought.connect(_on_shop_purchase_for_stats)
	if not Events.shop_relic_bought.is_connected(_on_shop_purchase_for_stats):
		Events.shop_relic_bought.connect(_on_shop_purchase_for_stats)
	if not Events.shop_potion_bought.is_connected(_on_shop_purchase_for_stats):
		Events.shop_potion_bought.connect(_on_shop_purchase_for_stats)
	if not Events.shop_card_removed.is_connected(_on_shop_purchase_for_stats):
		Events.shop_card_removed.connect(_on_shop_purchase_for_stats)
	if not potion_handler.potion_used.is_connected(_on_potion_used_for_stats):
		potion_handler.potion_used.connect(_on_potion_used_for_stats)
	if not potion_handler.potion_used.is_connected(_on_potion_inventory_changed):
		potion_handler.potion_used.connect(_on_potion_inventory_changed)
	if not potion_handler.potion_discarded.is_connected(_on_potion_inventory_changed):
		potion_handler.potion_discarded.connect(_on_potion_inventory_changed)
	
	battle_button.pressed.connect(_change_view.bind(BATTLE_SCENE))
	campfire_button.pressed.connect(_change_view.bind(CAMPFIRE_SCENE))
	map_button.pressed.connect(_show_map)
	rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARD_SCENE))
	shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))


var _notice_layer: CanvasLayer
var _notice_box: VBoxContainer


func _on_card_change_feedback_requested(title: String, cards: Array[Card], detail: String) -> void:
	_ensure_card_change_feedback()
	card_change_feedback.request_feedback(title, cards, detail)


func _ensure_card_change_feedback() -> void:
	if card_change_feedback:
		return
	card_change_feedback = CARD_CHANGE_FEEDBACK_SCRIPT.new() as CardChangeFeedback
	card_change_feedback.name = "CardChangeFeedback"
	add_child(card_change_feedback)


func _show_starting_spirit_root_card() -> void:
	if not character or not character.deck or not character.has_spirit_root():
		return
	var bonus_cards: Array[Card] = []
	for card: Card in character.deck.cards:
		if card and card.mechanic_tags.has(CharacterStats.SPIRIT_ROOT_BONUS_TAG):
			bonus_cards.append(card)
	if not bonus_cards.is_empty():
		_on_card_change_feedback_requested(
			"获得职业牌",
			bonus_cards,
			"灵根觉醒，以下职业牌已加入牌组。"
		)


# 随机效果结果播报：居中 toast 逐条堆叠、各自淡入停留后消失。
# 祝福/事件的"随机突破了哪张牌"等结果经 Events.ui_notice_requested 汇到这里。
func _on_ui_notice_requested(text: String) -> void:
	if text.is_empty() or not is_inside_tree():
		return
	_ensure_notice_layer()

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := InkTheme.make_style(
		Color(0.035, 0.024, 0.020, 0.90),
		Color(0.74, 0.54, 0.26, 0.84),
		1,
		8,
		Color(0, 0, 0, 0.42),
		8
	)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("f2e4be"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)
	_notice_box.add_child(panel)

	panel.modulate = Color(1, 1, 1, 0.0)
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.45)
	tween.tween_callback(panel.queue_free)


func _ensure_notice_layer() -> void:
	if _notice_layer:
		return
	_notice_layer = CanvasLayer.new()
	_notice_layer.name = "NoticeLayer"
	_notice_layer.layer = 21
	add_child(_notice_layer)

	_notice_box = VBoxContainer.new()
	_notice_box.name = "NoticeBox"
	_notice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_notice_box.anchor_left = 0.5
	_notice_box.anchor_right = 0.5
	_notice_box.offset_left = -340.0
	_notice_box.offset_right = 340.0
	_notice_box.offset_top = 168.0
	_notice_box.add_theme_constant_override("separation", 8)
	_notice_layer.add_child(_notice_box)


# 获得新卡（商店购买等）：幽灵卡从来源位置飞向顶栏总牌库按钮 + 计数 punch。
func _on_card_acquired_animation(card: Card, from_global_center: Vector2) -> void:
	if not card or not deck_button or not is_inside_tree():
		return

	var layer := get_node_or_null("DeckViewLayer") as CanvasLayer
	if not layer:
		return

	var ghost := CARD_VISUALS_SCENE.instantiate() as CardVisuals
	ghost.name = "AcquiredCardGhost"
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ghost_size := Vector2(224, 322)
	ghost.size = ghost_size
	ghost.pivot_offset = ghost_size * 0.5
	ghost.scale = Vector2.ONE * 0.72
	layer.add_child(ghost)
	ghost.card = card
	ghost.position = from_global_center - ghost_size * 0.5

	var target := deck_button.get_global_rect().get_center() - ghost_size * 0.5
	var tween := ghost.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "position", target, 0.60)
	tween.tween_property(ghost, "scale", Vector2.ONE * 0.10, 0.60)
	tween.tween_property(ghost, "rotation_degrees", 16.0, 0.60)
	tween.tween_property(ghost, "modulate:a", 0.45, 0.60)
	tween.set_parallel(false)
	tween.tween_callback(_punch_deck_counter)
	tween.tween_callback(ghost.queue_free)


func _punch_deck_counter() -> void:
	if not deck_button or not deck_button.counter:
		return
	var counter := deck_button.counter
	counter.pivot_offset = counter.size * 0.5
	counter.scale = Vector2.ONE * 1.5
	var tween := counter.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(counter, "scale", Vector2.ONE, 0.4)


func _setup_top_bar():
	character.stats_changed.connect(health_ui.update_stats.bind(character))
	health_ui.update_stats(character)
	gold_ui.run_stats = stats
	_polish_top_bar()
	_setup_spirit_root_badge()
	
	relic_handler.add_relic(character.starting_relic)
	if not Events.relic_tooltip_requested.is_connected(relic_tooltip.show_tooltip):
		Events.relic_tooltip_requested.connect(relic_tooltip.show_tooltip)
	if Events.relic_tooltip_hide_requested.is_connected(relic_tooltip.hide):
		Events.relic_tooltip_hide_requested.disconnect(relic_tooltip.hide)
	if not Events.relic_tooltip_hide_requested.is_connected(relic_tooltip.hide_tooltip):
		Events.relic_tooltip_hide_requested.connect(relic_tooltip.hide_tooltip)
	
	deck_button.card_pile = character.deck
	deck_view.card_pile = character.deck
	_ensure_deck_view_overlay()
	deck_button.pressed.connect(deck_view.show_current_view.bind("牌组"))
	_polish_deck_button()


func _ensure_deck_view_overlay() -> void:
	var layer := get_node_or_null("DeckViewLayer") as CanvasLayer
	if not layer:
		layer = CanvasLayer.new()
		layer.name = "DeckViewLayer"
		layer.layer = 18
		add_child(layer)

	if deck_view.get_parent() != layer:
		deck_view.reparent(layer)

	deck_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_view.offset_left = 0.0
	deck_view.offset_top = 0.0
	deck_view.offset_right = 0.0
	deck_view.offset_bottom = 0.0
	deck_view.hide()


func _setup_debug_console() -> void:
	if not debug_console:
		debug_console = DEBUG_CONSOLE.new()
		add_child(debug_console)
	debug_console.setup(character, stats, relic_handler, potion_handler)


func _polish_top_bar() -> void:
	var top_bar := $TopBar
	var background := $TopBar/Background as TextureRect
	if background:
		# 隐藏整条顶栏背景装饰框：各功能元素（身份牌/灵根/丹药/回合横幅/总牌库/设置）
		# 都有各自独立的面板底图，这条横跨全宽的装饰框只会在中间空白处露出一段空凹槽。
		background.hide()

	var bar_items := $TopBar/BarItems as VBoxContainer
	if bar_items:
		# 顶栏容器只负责排版，空白区域不能挡住其后的地图节点；实际按钮/图标仍自行接收输入。
		bar_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_items.custom_minimum_size = Vector2(0, 0)
		bar_items.offset_left = 14.0
		bar_items.offset_top = 0.0
		bar_items.offset_right = -88.0
		bar_items.offset_bottom = 96.0
		bar_items.add_theme_constant_override("separation", 0)

	var top_row := $TopBar/BarItems/TopRow as HBoxContainer
	if top_row:
		top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.custom_minimum_size = Vector2(0, 88)
		top_row.add_theme_constant_override("separation", 18)

	var left_info := health_ui.get_parent() as HBoxContainer
	if left_info:
		left_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_info.add_theme_constant_override("separation", 10)
		if not left_info.has_node("TopInfoSpacer"):
			var spacer := Control.new()
			spacer.name = "TopInfoSpacer"
			spacer.custom_minimum_size = Vector2(88, 42)
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			left_info.add_child(spacer)
			left_info.move_child(spacer, 0)
		var top_spacer := left_info.get_node_or_null("TopInfoSpacer") as Control
		if top_spacer:
			top_spacer.custom_minimum_size = Vector2(96, 42)
		health_ui.custom_minimum_size = Vector2(142, 42)
		gold_ui.custom_minimum_size = Vector2(112, 42)

	if not top_bar.has_node("TopLeftPanel"):
		var panel := TextureRect.new()
		panel.name = "TopLeftPanel"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		top_bar.add_child(panel)
		top_bar.move_child(panel, 1)
	var left_panel := top_bar.get_node_or_null("TopLeftPanel") as TextureRect
	if left_panel:
		left_panel.position = Vector2(0, 0)
		left_panel.size = Vector2(376, 88)
		left_panel.texture = InkTheme.HUD_BLUE_TOP_LEFT_PANEL
		left_panel.modulate = Color(1, 1, 1, 0.82)

	if not top_bar.has_node("TopClassEmblem"):
		var emblem := TextureRect.new()
		emblem.name = "TopClassEmblem"
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emblem.texture = InkTheme.HUD_BLUE_CLASS_EMBLEM
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top_bar.add_child(emblem)
	var emblem := top_bar.get_node_or_null("TopClassEmblem") as TextureRect
	if emblem:
		emblem.position = Vector2(2, -2)
		emblem.size = Vector2(96, 96)
		emblem.visible = false

	var portrait := top_bar.get_node_or_null("TopClassPortrait") as TextureRect
	if not portrait:
		portrait = TextureRect.new()
		portrait.name = "TopClassPortrait"
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		top_bar.add_child(portrait)
	portrait.texture = DEMONIC_HEAD_ICON
	portrait.position = Vector2(4, 0)
	portrait.size = Vector2(92, 92)
	portrait.modulate = Color(1, 1, 1, 1)
	portrait.visible = true
	top_bar.move_child(portrait, top_bar.get_child_count() - 1)

	var class_title := top_bar.get_node_or_null("TopClassTitle") as Label
	if not class_title:
		class_title = Label.new()
		class_title.name = "TopClassTitle"
		class_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		class_title.add_theme_font_size_override("font_size", 17)
		class_title.add_theme_color_override("font_color", Color("ffe4a4"))
		class_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		class_title.add_theme_constant_override("shadow_offset_x", 2)
		class_title.add_theme_constant_override("shadow_offset_y", 2)
		top_bar.add_child(class_title)
	class_title.position = Vector2(118, 6)
	class_title.size = Vector2(112, 24)
	class_title.text = character.character_name if character and not character.character_name.is_empty() else ""

	_style_top_stat_widgets()
	_remove_skill_button()
	_polish_relic_row()
	_polish_settings_button()


func _is_demonic_character() -> bool:
	if not character:
		return false
	if character.battle_anim_id == "demonic_cultivator":
		return true
	var source_path := character.resource_path
	if source_path.contains("demonic_cultivator"):
		return true
	if character.starting_deck and character.starting_deck.resource_path.contains("demonic_cultivator"):
		return true
	return false


func _style_top_stat_widgets() -> void:
	var health_icon := health_ui.get_node_or_null("HealthImage") as TextureRect
	if health_icon:
		health_icon.custom_minimum_size = Vector2(28, 28)

	var gold_icon := gold_ui.get_node_or_null("Icon") as TextureRect
	if gold_icon:
		gold_icon.custom_minimum_size = Vector2(30, 30)

	for label: Label in [health_ui.health_label, health_ui.max_health_label, gold_ui.label]:
		if not label:
			continue
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color("fff0c8"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)


func _apply_compact_top_panel(panel: Control, panel_size: Vector2) -> void:
	panel.custom_minimum_size = panel_size
	var style := InkTheme.make_texture_style(InkTheme.HUD_BLUE_PILE_PANEL, 32, 18, Color(1, 1, 1, 0.96))
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)


func _polish_deck_button() -> void:
	deck_button.custom_minimum_size = Vector2(268, 74)
	deck_button.ignore_texture_size = true
	deck_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	deck_button.texture_normal = null
	deck_button.texture_hover = null
	deck_button.texture_pressed = null

	var existing_panel := deck_button.get_node_or_null("DeckPanel")
	if not existing_panel:
		var panel := TextureRect.new()
		panel.name = "DeckPanel"
		panel.show_behind_parent = true
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.texture = InkTheme.HUD_BLUE_DECK_PANEL
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		deck_button.add_child(panel)
	var deck_panel := deck_button.get_node_or_null("DeckPanel") as TextureRect
	if deck_panel:
		deck_panel.texture = InkTheme.HUD_BLUE_DECK_PANEL
		deck_panel.modulate = Color(1, 1, 1, 0.95)

	var deck_icon := deck_button.get_node_or_null("DeckIcon") as TextureRect
	if not deck_icon:
		deck_icon = TextureRect.new()
		deck_icon.name = "DeckIcon"
		deck_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		deck_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		deck_button.add_child(deck_icon)
	deck_icon.texture = InkTheme.HUD_BATTLE_DECK_ICON
	deck_icon.position = Vector2(172, 11)
	deck_icon.size = Vector2(72, 52)
	deck_icon.modulate = Color(0.92, 0.88, 1.0, 0.92)

	var title := deck_button.get_node_or_null("DeckTitle") as Label
	if not title:
		title = Label.new()
		title.name = "DeckTitle"
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.text = "总牌库"
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color("ffe0a0"))
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		deck_button.add_child(title)
	title.position = Vector2(28, 12)
	title.size = Vector2(104, 32)

	if deck_button.counter:
		deck_button.counter.position = Vector2(114, 39)
		deck_button.counter.size = Vector2(60, 26)
		deck_button.counter.add_theme_font_size_override("font_size", 22)
		deck_button.counter.add_theme_color_override("font_color", Color("fff0c8"))
		deck_button.counter.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		deck_button.counter.add_theme_constant_override("shadow_offset_x", 2)
		deck_button.counter.add_theme_constant_override("shadow_offset_y", 2)
		deck_button.counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		deck_button.counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _polish_settings_button() -> void:
	var top_bar := $TopBar
	var settings_button := top_bar.get_node_or_null("BattleSettingsButton") as TextureButton
	if not settings_button:
		settings_button = TextureButton.new()
		settings_button.name = "BattleSettingsButton"
		settings_button.ignore_texture_size = true
		settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		settings_button.tooltip_text = "设置"
		settings_button.pressed.connect(_open_pause_menu)
		top_bar.add_child(settings_button)

	settings_button.texture_normal = InkTheme.HUD_BATTLE_SETTINGS_NORMAL
	settings_button.texture_hover = InkTheme.HUD_BATTLE_SETTINGS_HOVER
	settings_button.texture_pressed = InkTheme.HUD_BATTLE_SETTINGS_PRESSED
	settings_button.anchor_left = 1.0
	settings_button.anchor_right = 1.0
	settings_button.anchor_top = 0.0
	settings_button.anchor_bottom = 0.0
	settings_button.offset_left = -76.0
	settings_button.offset_top = 0.0
	settings_button.offset_right = -12.0
	settings_button.offset_bottom = 64.0

	var settings_icon := settings_button.get_node_or_null("SettingsIcon") as TextureRect
	if not settings_icon:
		settings_icon = TextureRect.new()
		settings_icon.name = "SettingsIcon"
		settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		settings_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		settings_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		settings_button.add_child(settings_icon)
	settings_icon.texture = InkTheme.HUD_BATTLE_SETTINGS_ICON
	settings_icon.position = Vector2(13, 13)
	settings_icon.size = Vector2(38, 38)
	settings_icon.modulate = Color(1, 0.92, 0.76, 0.96)


func _remove_skill_button() -> void:
	var top_bar := $TopBar
	var skill_button := top_bar.get_node_or_null("TopSkillButton") as TextureButton
	if skill_button:
		skill_button.queue_free()


func _open_pause_menu() -> void:
	pause_menu.open()


func _setup_spirit_root_badge() -> void:
	if not spirit_root_badge:
		spirit_root_badge = SPIRIT_ROOT_BADGE_SCENE.instantiate() as SpiritRootBadge
		var bar_items := gold_ui.get_parent()
		bar_items.add_child(spirit_root_badge)
		bar_items.move_child(spirit_root_badge, gold_ui.get_index() + 1)

	spirit_root_badge.character = character
	spirit_root_badge.visible = true
	_apply_compact_top_panel(spirit_root_badge, Vector2(140, 66))

	# 丹药栏：复用灵根徽章的面板样式，放在其右侧
	var badge_parent := spirit_root_badge.get_parent()
	if not potion_bar_panel:
		potion_bar_panel = PanelContainer.new()
		potion_bar_panel.name = "PotionBar"
		potion_bar_panel.custom_minimum_size = Vector2(200, 66)
		potion_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		InkTheme.apply_battle_blue_panel(potion_bar_panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		potion_bar_panel.add_child(hb)
		var lbl := Label.new()
		lbl.name = "PotionTitle"
		lbl.text = "丹药"
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color("e2a36a"))
		lbl.add_theme_color_override("font_shadow_color", Color(0.08, 0, 0, 0.9))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(lbl)
		potion_handler.reparent(hb)
		potion_handler.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge_parent.add_child(potion_bar_panel)
	badge_parent.move_child(potion_bar_panel, spirit_root_badge.get_index() + 1)
	potion_bar_panel.visible = true
	_apply_compact_top_panel(potion_bar_panel, Vector2(200, 66))
	potion_handler.custom_minimum_size = Vector2(154, 50)
	potion_handler.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	_polish_relic_row()


func _polish_relic_row() -> void:
	var top_bar := $TopBar
	var relic_row := $TopBar/BarItems/RelicRow as HBoxContainer
	if not relic_row:
		return

	var existing_backdrop := top_bar.get_node_or_null("RelicLaneBackdrop")
	if existing_backdrop:
		existing_backdrop.queue_free()

	var left_info := health_ui.get_parent() as HBoxContainer
	if left_info:
		var relic_bar := left_info.get_node_or_null("RelicBar") as PanelContainer
		if relic_bar:
			relic_bar.queue_free()

	relic_row.visible = true
	relic_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_row.custom_minimum_size = Vector2(0, 120)
	relic_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relic_row.add_theme_constant_override("separation", 10)

	var relic_title := relic_row.get_node_or_null("RelicTitle") as Label
	if relic_title:
		relic_title.custom_minimum_size = Vector2.ZERO
		relic_title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		relic_title.text = ""
		relic_title.visible = false
		relic_title.add_theme_font_size_override("font_size", 20)
		relic_title.add_theme_color_override("font_color", Color("ffe0a0"))
		relic_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		relic_title.add_theme_constant_override("shadow_offset_x", 2)
		relic_title.add_theme_constant_override("shadow_offset_y", 2)
		relic_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if relic_handler.get_parent() != relic_row:
		relic_handler.reparent(relic_row)
	relic_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_handler.custom_minimum_size = Vector2(0, 120)
	relic_handler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relic_handler.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var relic_container := relic_handler.get_node_or_null("Relics") as HFlowContainer
	if relic_container:
		relic_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		relic_container.add_theme_constant_override("h_separation", 8)
		relic_container.add_theme_constant_override("v_separation", 8)


func _show_regular_battle_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character

	reward_scene.potion_handler = potion_handler
	reward_scene.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	reward_scene.add_card_reward()
	# 掉落即使药囊已满也会展示，玩家可在奖励页丢弃旧物后领取。
	if stats.roll_standard_potion_drop():
		reward_scene.add_potion_reward(_random_reward_potion(PotionRewardPool.RewardContext.STANDARD))


func _show_elite_battle_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.relic_handler = relic_handler
	reward_scene.potion_handler = potion_handler

	reward_scene.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	reward_scene.add_relic_reward(RELIC_REWARD_POOL.get_random_available(
		character, relic_handler, current_chapter, RelicRewardPool.RewardContext.ELITE
	))
	reward_scene.add_card_reward(BattleReward.CardRewardTier.ELITE)
	reward_scene.add_card_fusion_reward()
	# 精英战必掉一个符箓丹药；满槽时允许先丢弃旧物再领取。
	reward_scene.add_potion_reward(_random_reward_potion(PotionRewardPool.RewardContext.ELITE))


func _show_boss_battle_rewards() -> void:
	pending_chapter_advance = true
	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.relic_handler = relic_handler
	reward_scene.potion_handler = potion_handler

	reward_scene.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	reward_scene.add_card_reward(BattleReward.CardRewardTier.BOSS)
	var relic_choices := RELIC_REWARD_POOL.get_random_available_choices(
		character, relic_handler, 3, current_chapter, RelicRewardPool.RewardContext.BOSS
	)
	reward_scene.add_relic_choice_rewards(relic_choices)
	reward_scene.add_potion_reward(_random_reward_potion(PotionRewardPool.RewardContext.BOSS))


func _on_battle_reward_exited() -> void:
	if pending_chapter_advance:
		pending_chapter_advance = false
		_advance_to_next_chapter()
	else:
		_show_map()


func _on_battle_room_entered(room: Room) -> void:
	var battle_scene: Battle = _change_view(BATTLE_SCENE) as Battle
	battle_scene.char_stats = character
	battle_scene.battle_stats = room.battle_stats
	battle_scene.relics = relic_handler
	battle_scene.start_battle()


func _on_treasure_room_entered() -> void:
	_play_exploration_music()
	# 宝箱节点不再停留播放开箱动画，进入后直接展示两件法宝供选择。
	var relic_choices := RELIC_REWARD_POOL.get_random_available_choices(
		character,
		relic_handler,
		2,
		current_chapter,
		RelicRewardPool.RewardContext.TREASURE
	)
	_on_treasure_room_exited(relic_choices)


func _on_treasure_room_exited(relic_choices: Array[Relic]) -> void:
	if relic_choices.is_empty():
		_show_map()
		return

	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.relic_handler = relic_handler
	
	reward_scene.add_relic_choice_rewards(relic_choices)


func _on_campfire_entered() -> void:
	_play_exploration_music()
	var campfire := _change_view(CAMPFIRE_SCENE) as Campfire
	campfire.setup(character, stats)


func _on_shop_entered() -> void:
	_play_exploration_music()
	var shop := _change_view(SHOP_SCENE) as Shop
	shop.char_stats = character
	shop.run_stats = stats
	shop.relic_handler = relic_handler
	shop.potion_handler = potion_handler
	Events.shop_entered.emit(shop)
	shop.populate_shop()


func _on_event_room_entered(room: Room) -> void:
	_play_exploration_music()
	var event_room := _change_view(room.event_scene) as EventRoom
	event_room.character_stats = character
	event_room.run_stats = stats
	event_room.setup()
	# 事件场景众多且各有 _ready，入场淡入统一在这里做。
	InkTheme.animate_screen_entrance(event_room)


func _on_blessing_room_entered() -> void:
	_play_exploration_music()
	var blessing := _change_view(BLESSING_SCENE) as Blessing
	blessing.relic_handler = relic_handler
	blessing.setup(character, stats, current_chapter)


func _on_card_played_for_stats(_card: Card) -> void:
	if stats:
		stats.cards_played += 1


func _on_enemy_died_for_stats(_enemy: Enemy) -> void:
	if stats:
		stats.enemies_defeated += 1


func _on_event_resolved_for_stats(_effect: String, _amount: int, _character: CharacterStats, _run_stats: RunStats) -> void:
	if stats:
		stats.events_resolved += 1


func _on_shop_purchase_for_stats(_item, gold_cost: int) -> void:
	if stats:
		stats.gold_spent += maxi(gold_cost, 0)


func _on_potion_used_for_stats(_potion: Potion) -> void:
	if stats:
		stats.potions_used += 1


func _on_potion_inventory_changed(_potion: Potion) -> void:
	if save_data and map and map.visible:
		_save_run(true)


func _record_battle_victory() -> void:
	if not stats:
		return
	stats.battles_won += 1
	if not map.last_room:
		return
	match map.last_room.type:
		Room.Type.ELITE:
			stats.elites_defeated += 1
		Room.Type.BOSS:
			stats.bosses_defeated += 1


func _on_run_defeated() -> void:
	_finalize_run(false)


func _finalize_run(won: bool) -> String:
	if run_finalized:
		return RunHistory.load_data().last_run_summary
	run_finalized = true
	var history := RunHistory.load_data()
	var summary := history.record_run(
		stats,
		won,
		current_chapter,
		character.deck.cards.size() if character and character.deck else 0,
		relic_handler.get_all_relics().size() if relic_handler else 0
	)
	var error := history.save_data()
	if error != OK:
		push_warning("无法保存轮回战绩：%s" % error)
	return summary


func _on_battle_won() -> void:
	_record_battle_victory()
	if map.is_final_floor_reached():
		if current_chapter >= TOTAL_CHAPTERS:
			var run_summary := _finalize_run(true)
			var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
			var difficulty_profile := DifficultyProfile.load_data()
			var unlocked_next := difficulty_profile.record_victory(stats.difficulty_level)
			var profile_error := difficulty_profile.save_data()
			if profile_error != OK:
				push_warning("无法保存心魔难度进度：%s" % profile_error)
			win_screen.set_completion(
				character,
				stats.difficulty_level,
				difficulty_profile.unlocked_level if unlocked_next else -1,
				run_summary
			)
			SaveGame.delete_data()
		else:
			_show_boss_battle_rewards()
	elif map.last_room and map.last_room.type == Room.Type.ELITE:
		_show_elite_battle_rewards()
	else:
		_show_regular_battle_rewards()


func _advance_to_next_chapter() -> void:
	current_chapter += 1
	character.hero_skill_stage = clampi(current_chapter, 1, TOTAL_CHAPTERS)
	stats.apply_chapter_card_weights(current_chapter)
	character.heal(stats.get_chapter_recovery_amount(character.health, character.max_health))
	_configure_map_difficulty()
	map.generate_new_map(current_chapter)
	map.unlock_floor(0)
	_show_map()


func _configure_map_difficulty() -> void:
	if map and map.map_generator:
		map.map_generator.difficulty_stats = stats


func _on_map_exited(room: Room) -> void:
	_save_run(false)
	
	match room.type:
		Room.Type.MONSTER:
			_on_battle_room_entered(room)
		Room.Type.ELITE:
			_on_battle_room_entered(room)
		Room.Type.TREASURE:
			_on_treasure_room_entered()
		Room.Type.CAMPFIRE:
			_on_campfire_entered()
		Room.Type.SHOP:
			_on_shop_entered()
		Room.Type.BOSS:
			_on_battle_room_entered(room)
		Room.Type.EVENT:
			_on_event_room_entered(room)
		Room.Type.BLESSING:
			_on_blessing_room_entered()
