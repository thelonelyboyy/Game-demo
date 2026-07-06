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
const DEBUG_CONSOLE := preload("res://scenes/debug/debug_console.gd")
const DEMONIC_HEAD_ICON := preload("res://art/characters/demonic_cultivator_head_icon.png")
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
const DEFEAT_LEGACY := preload("res://custom_resources/defeat_legacy.gd")
const POTION_REWARD_PATHS := [
	"res://potions/healing_pill.tres",
	"res://potions/qi_pill.tres",
	"res://potions/draw_talisman.tres",
	"res://potions/flame_talisman.tres",
	"res://potions/frost_talisman.tres",
	"res://potions/blood_rite_talisman.tres",
	"res://potions/greater_healing_pill.tres",
	"res://potions/jade_skin_pill.tres",
	"res://potions/spirit_surge_pill.tres",
	"res://potions/clarity_pill.tres",
	"res://potions/gold_body_pill.tres",
	"res://potions/true_essence_pill.tres",
	"res://potions/marrow_strength_pill.tres",
	"res://potions/sword_heart_pill.tres",
	"res://potions/demon_blood_pill.tres",
	"res://potions/beast_lure_pill.tres",
	"res://potions/thunder_talisman.tres",
	"res://potions/five_thunder_talisman.tres",
	"res://potions/expose_talisman.tres",
	"res://potions/bleed_talisman.tres",
	"res://potions/warding_talisman.tres",
	"res://potions/cloudstep_talisman.tres",
	"res://potions/qi_barrier_talisman.tres",
	"res://potions/sword_guard_talisman.tres",
	"res://potions/soul_snare_talisman.tres",
	"res://potions/soul_burst_talisman.tres",
]
const POTION_DROP_CHANCE := 0.4
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const TOTAL_CHAPTERS := 3

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
var debug_console
var current_chapter := 1


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
	current_chapter = 1
	
	_setup_event_connections()
	_setup_top_bar()
	_setup_debug_console()

	map.generate_new_map(current_chapter)
	map.unlock_floor(0)

	_grant_starter_potions()

	save_data = SaveGame.new()
	_save_run(true)
	_show_defeat_legacy_choice_if_available.call_deferred()


func _random_reward_potion() -> Potion:
	var pool: Array[Potion] = []
	for path in POTION_REWARD_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var potion := load(path) as Potion
		if potion and potion.can_appear_as_reward(character):
			pool.append(potion)
	if pool.is_empty():
		return null
	return RNG.array_pick_random(pool)


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
	character = save_data.char_stats
	current_chapter = maxi(save_data.current_chapter, 1)
	if save_data.spirit_root != Card.Element.NONE:
		character.spirit_root = save_data.spirit_root
	character.deck = save_data.current_deck
	character.health = save_data.current_health
	character.bind_all_card_piles_to_owner()
	relic_handler.add_relics(save_data.relics)
	potion_handler.load_potions(save_data.potions)
	_setup_top_bar()
	_setup_debug_console()
	_setup_event_connections()
	
	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_room)
	if save_data.last_room and not save_data.was_on_map:
		_on_map_exited(save_data.last_room)


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
	map.show_map()
	if map.last_room:
		map.unlock_next_rooms()
	else:
		map.unlock_floor(0)
	
	_save_run(true)


func _setup_event_connections() -> void:
	potion_handler.character_stats = character
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.campfire_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_on_treasure_room_exited)
	Events.event_room_exited.connect(_show_map)
	Events.blessing_exited.connect(_show_map)
	
	battle_button.pressed.connect(_change_view.bind(BATTLE_SCENE))
	campfire_button.pressed.connect(_change_view.bind(CAMPFIRE_SCENE))
	map_button.pressed.connect(_show_map)
	rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARD_SCENE))
	shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))


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
		bar_items.custom_minimum_size = Vector2(0, 0)
		bar_items.offset_left = 14.0
		bar_items.offset_top = 0.0
		bar_items.offset_right = -88.0
		bar_items.offset_bottom = 96.0
		bar_items.add_theme_constant_override("separation", 0)

	var top_row := $TopBar/BarItems/TopRow as HBoxContainer
	if top_row:
		top_row.custom_minimum_size = Vector2(0, 88)
		top_row.add_theme_constant_override("separation", 18)

	var left_info := health_ui.get_parent() as HBoxContainer
	if left_info:
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
	pause_menu.show()
	get_tree().paused = true


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
	# 普通战斗有概率掉落符箓丹药（槽位满则不掉）。
	if not potion_handler.is_full() and RNG.instance.randf_range(0.0, 1.0) < POTION_DROP_CHANCE:
		reward_scene.add_potion_reward(_random_reward_potion())


func _show_elite_battle_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.relic_handler = relic_handler
	reward_scene.potion_handler = potion_handler

	reward_scene.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	reward_scene.add_relic_reward(RELIC_REWARD_POOL.get_random_available(character, relic_handler))
	reward_scene.add_card_fusion_reward()
	# 精英战必掉一个符箓丹药（槽位满则跳过）。
	if not potion_handler.is_full():
		reward_scene.add_potion_reward(_random_reward_potion())


func _on_battle_room_entered(room: Room) -> void:
	var battle_scene: Battle = _change_view(BATTLE_SCENE) as Battle
	battle_scene.char_stats = character
	battle_scene.battle_stats = room.battle_stats
	battle_scene.relics = relic_handler
	battle_scene.start_battle()


func _on_treasure_room_entered() -> void:
	var treasure_scene := _change_view(TREASURE_SCENE) as Treasure
	treasure_scene.relic_handler = relic_handler
	treasure_scene.char_stats = character
	treasure_scene.generate_relic_choices(2)


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
	var campfire := _change_view(CAMPFIRE_SCENE) as Campfire
	campfire.char_stats = character


func _on_shop_entered() -> void:
	var shop := _change_view(SHOP_SCENE) as Shop
	shop.char_stats = character
	shop.run_stats = stats
	shop.relic_handler = relic_handler
	shop.potion_handler = potion_handler
	Events.shop_entered.emit(shop)
	shop.populate_shop()


func _on_event_room_entered(room: Room) -> void:
	var event_room := _change_view(room.event_scene) as EventRoom
	event_room.character_stats = character
	event_room.run_stats = stats
	event_room.setup()


func _on_blessing_room_entered() -> void:
	var blessing := _change_view(BLESSING_SCENE) as Blessing
	blessing.relic_handler = relic_handler
	blessing.setup(character, stats, current_chapter)


func _on_battle_won() -> void:
	if map.is_final_floor_reached():
		if current_chapter >= TOTAL_CHAPTERS:
			var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
			win_screen.character = character
			SaveGame.delete_data()
		else:
			_advance_to_next_chapter()
	elif map.last_room and map.last_room.type == Room.Type.ELITE:
		_show_elite_battle_rewards()
	else:
		_show_regular_battle_rewards()


func _advance_to_next_chapter() -> void:
	current_chapter += 1
	# 进入新一章时角色回满血
	character.health = character.max_health
	map.generate_new_map(current_chapter)
	map.unlock_floor(0)
	_show_map()


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
