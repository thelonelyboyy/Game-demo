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
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
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

	map.generate_new_map(current_chapter)
	map.unlock_floor(0)

	_grant_starter_potions()

	save_data = SaveGame.new()
	_save_run(true)


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
	_setup_spirit_root_badge()
	
	relic_handler.add_relic(character.starting_relic)
	Events.relic_tooltip_requested.connect(relic_tooltip.show_tooltip)
	
	deck_button.card_pile = character.deck
	deck_view.card_pile = character.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("牌组"))


func _setup_spirit_root_badge() -> void:
	if not spirit_root_badge:
		spirit_root_badge = SPIRIT_ROOT_BADGE_SCENE.instantiate() as SpiritRootBadge
		var bar_items := gold_ui.get_parent()
		bar_items.add_child(spirit_root_badge)
		bar_items.move_child(spirit_root_badge, gold_ui.get_index() + 1)

	spirit_root_badge.character = character

	# 丹药栏：复用灵根徽章的面板样式，放在其右侧
	var badge_parent := spirit_root_badge.get_parent()
	if not potion_bar_panel:
		potion_bar_panel = PanelContainer.new()
		potion_bar_panel.name = "PotionBar"
		potion_bar_panel.custom_minimum_size = Vector2(178, 56)
		potion_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		InkTheme.apply_demonic_panel(potion_bar_panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		potion_bar_panel.add_child(hb)
		var lbl := Label.new()
		lbl.text = "丹"
		lbl.add_theme_font_size_override("font_size", 18)
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
