class_name Battle
extends Node2D

const PIXEL_WORLD_SCALE := 5.0
const SPIRIT_ROOT_HANDLER := preload("res://scenes/battle/spirit_root_handler.gd")
const CLASS_MECHANIC_HANDLER := preload("res://scenes/battle/class_mechanic_handler.gd")
const BATTLE_BACKGROUND := preload("res://test2.png")
const PLAYER_SCREEN_ANCHOR := Vector2(0.22, 0.42)
const ENEMY_SINGLE_SCREEN_ANCHOR := Vector2(0.74, 0.50)
const ENEMY_ROW_START_RATIO := 0.61
const ENEMY_ROW_END_RATIO := 0.84
const ENEMY_GROUND_RATIO := 0.50

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
var class_mechanic_handler: ClassMechanicHandler
var battle_active := false
var victory_resolving := false


func _ready() -> void:
	_setup_ink_backdrop()
	_setup_pixel_world()
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_died.connect(_on_enemy_died_for_victory)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)


func start_battle() -> void:
	get_tree().paused = false
	battle_active = false
	victory_resolving = false
	MusicPlayer.play(music, true)
	
	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics
	enemy_handler.setup_enemies(battle_stats)
	_arrange_combatants()
	_setup_spirit_root_handler()
	_setup_class_mechanic_handler()
	_prepare_world_ui()
	enemy_handler.reset_enemy_actions()
	
	if not relics.relics_activated.is_connected(_on_relics_activated):
		relics.relics_activated.connect(_on_relics_activated)
	battle_active = true
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)


func _on_enemies_child_order_changed() -> void:
	_check_for_battle_victory.call_deferred()


func _on_enemy_died_for_victory(_enemy: Enemy) -> void:
	_check_for_battle_victory.call_deferred()


func _check_for_battle_victory() -> void:
	if not battle_active or victory_resolving or not is_inside_tree():
		return

	if _get_live_enemies().is_empty() and is_instance_valid(relics):
		victory_resolving = true
		battle_active = false
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_player_died() -> void:
	battle_active = false
	Events.battle_over_screen_requested.emit("渡劫失败", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()


func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_COMBAT:
			player_handler.start_battle(char_stats)
			battle_ui.initialize_card_pile_ui()
		Relic.Type.END_OF_COMBAT:
			Events.battle_over_screen_requested.emit("战斗胜利", BattleOverPanel.Type.WIN)


func _exit_tree() -> void:
	battle_active = false
	victory_resolving = false
	if enemy_handler and enemy_handler.child_order_changed.is_connected(_on_enemies_child_order_changed):
		enemy_handler.child_order_changed.disconnect(_on_enemies_child_order_changed)
	if Events.enemy_died.is_connected(_on_enemy_died_for_victory):
		Events.enemy_died.disconnect(_on_enemy_died_for_victory)
	if Events.enemy_turn_ended.is_connected(_on_enemy_turn_ended):
		Events.enemy_turn_ended.disconnect(_on_enemy_turn_ended)
	if Events.player_turn_ended.is_connected(player_handler.end_turn):
		Events.player_turn_ended.disconnect(player_handler.end_turn)
	if Events.player_hand_discarded.is_connected(enemy_handler.start_turn):
		Events.player_hand_discarded.disconnect(enemy_handler.start_turn)
	if Events.player_died.is_connected(_on_player_died):
		Events.player_died.disconnect(_on_player_died)
	if relics and relics.relics_activated.is_connected(_on_relics_activated):
		relics.relics_activated.disconnect(_on_relics_activated)


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
			if child_name == "Background":
				child.hide()
			child.reparent(pixel_world, false)


func _prepare_world_ui() -> void:
	_prepare_combatant_presentation(player, true)
	_prepare_scaled_node_ui(player)
	for enemy: Enemy in _get_live_enemies():
		_prepare_combatant_presentation(enemy, false)
		_prepare_scaled_node_ui(enemy)


func _prepare_scaled_node_ui(world_node: Node) -> void:
	if not world_node:
		return

	for ui_name in ["StatsUI", "IntentUI", "StatusHandler"]:
		var ui_node := world_node.get_node_or_null(ui_name) as Control
		if ui_node:
			ui_node.scale = Vector2.ONE / PIXEL_WORLD_SCALE

	if world_node.has_method("refresh_battle_overlays"):
		world_node.call("refresh_battle_overlays")


func _arrange_combatants() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1920.0, 1080.0)

	player.position = _screen_to_world(viewport_size * PLAYER_SCREEN_ANCHOR)

	var enemies := _get_live_enemies()
	var enemy_count := enemies.size()
	if enemy_count == 0:
		return

	if enemy_count == 1:
		var enemy := enemies[0] as Node2D
		enemy.position = _screen_to_world(viewport_size * ENEMY_SINGLE_SCREEN_ANCHOR)
		return

	var enemy_y := viewport_size.y * ENEMY_GROUND_RATIO
	for enemy_index in enemy_count:
		var enemy := enemies[enemy_index] as Node2D
		var progress := float(enemy_index) / float(enemy_count - 1)
		var screen_x := lerpf(
			viewport_size.x * ENEMY_ROW_START_RATIO,
			viewport_size.x * ENEMY_ROW_END_RATIO,
			progress
		)
		var depth_offset := (absf(progress - 0.5) - 0.5) * 34.0
		enemy.position = _screen_to_world(Vector2(screen_x, enemy_y + depth_offset))


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return screen_position / PIXEL_WORLD_SCALE


func _get_live_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child in enemy_handler.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			enemies.append(child)
	return enemies


func _setup_spirit_root_handler() -> void:
	if not spirit_root_handler:
		spirit_root_handler = SPIRIT_ROOT_HANDLER.new() as SpiritRootHandler
		add_child(spirit_root_handler)

	spirit_root_handler.setup(char_stats, player_handler, player, enemy_handler)


func _setup_class_mechanic_handler() -> void:
	if not class_mechanic_handler:
		class_mechanic_handler = CLASS_MECHANIC_HANDLER.new() as ClassMechanicHandler
		add_child(class_mechanic_handler)

	class_mechanic_handler.setup(char_stats, player, player_handler, enemy_handler)


func _setup_ink_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.name = "InkBattleBackdrop"
	layer.layer = -1
	add_child(layer)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = BATTLE_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(background)
	_fit_battle_background(background)
	get_viewport().size_changed.connect(_fit_battle_background.bind(background))


func _fit_battle_background(background: TextureRect) -> void:
	if not is_instance_valid(background):
		return

	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0


func _prepare_combatant_presentation(world_node: Node, _is_player := false) -> void:
	if not world_node or world_node.has_node("InkStand"):
		return

	var sprite := world_node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.modulate = Color(0.96, 0.90, 0.78, 0.92)

	var stand := Node2D.new()
	stand.name = "InkStand"
	world_node.add_child(stand)
	world_node.move_child(stand, 0)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-24, 18),
		Vector2(22, 18),
		Vector2(32, 24),
		Vector2(10, 30),
		Vector2(-30, 27),
	])
	shadow.color = Color(0, 0, 0, 0.28)
	stand.add_child(shadow)
