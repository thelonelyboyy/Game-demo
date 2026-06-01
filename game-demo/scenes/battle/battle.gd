class_name Battle
extends Node2D

const PIXEL_WORLD_SCALE := 5.0
const SPIRIT_ROOT_HANDLER := preload("res://scenes/battle/spirit_root_handler.gd")

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var relics: RelicHandler

@onready var battle_ui: BattleUI = $BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var player: Player = $Player

var pixel_world: Node2D
var spirit_root_handler: SpiritRootHandler


func _ready() -> void:
	_setup_pixel_world()
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)


func start_battle() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)
	
	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics
	enemy_handler.setup_enemies(battle_stats)
	_setup_spirit_root_handler()
	_prepare_world_ui()
	enemy_handler.reset_enemy_actions()
	
	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)


func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_player_died() -> void:
	Events.battle_over_screen_requested.emit("渡劫失败", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()


func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_COMBAT:
			player_handler.start_battle(char_stats)
			battle_ui.initialize_card_pile_ui()
		Relic.Type.END_OF_COMBAT:
			Events.battle_over_screen_requested.emit("战斗胜利", BattleOverPanel.Type.WIN)


func _setup_pixel_world() -> void:
	if pixel_world:
		return

	pixel_world = Node2D.new()
	pixel_world.name = "PixelWorld"
	pixel_world.scale = Vector2.ONE * PIXEL_WORLD_SCALE
	add_child(pixel_world)
	move_child(pixel_world, 0)

	for child_name in ["Background", "CardDropArea", "EnemyHandler", "Player"]:
		var child := get_node_or_null(child_name)
		if child:
			child.reparent(pixel_world, false)


func _prepare_world_ui() -> void:
	_prepare_scaled_node_ui(player)
	for enemy: Enemy in enemy_handler.get_children():
		_prepare_scaled_node_ui(enemy)


func _prepare_scaled_node_ui(world_node: Node) -> void:
	if not world_node:
		return

	for ui_name in ["StatsUI", "IntentUI", "StatusHandler"]:
		var ui_node := world_node.get_node_or_null(ui_name) as Control
		if ui_node:
			ui_node.scale = Vector2.ONE / PIXEL_WORLD_SCALE


func _setup_spirit_root_handler() -> void:
	if not spirit_root_handler:
		spirit_root_handler = SPIRIT_ROOT_HANDLER.new() as SpiritRootHandler
		add_child(spirit_root_handler)

	spirit_root_handler.setup(char_stats, player_handler, player, enemy_handler)
