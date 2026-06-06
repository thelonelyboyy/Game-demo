extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BOSS_BATTLES := [
	"res://battles/demo_b_bone_dragon.tres",
	"res://battles/demo_b_black_lotus.tres",
	"res://battles/demo_b_sky_guardian.tres",
	"res://battles/demo_b_sword_soul.tres",
	"res://battles/demo_b_eclipse_tyrant.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	for battle_path: String in BOSS_BATTLES:
		print("BOSS_BATTLE_SMOKE_STEP:%s" % battle_path)
		await _check_boss_battle(battle_path)

	_finish()


func _check_boss_battle(battle_path: String) -> void:
	var battle_stats := load(battle_path) as BattleStats
	_check(battle_stats != null, "%s loads battle stats" % battle_path)
	if not battle_stats:
		return

	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null, "boss smoke support scenes load")
	if not battle_scene or not relic_handler_scene or not character_resource:
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()

	await get_tree().create_timer(1.8).timeout
	_check(battle.enemy_handler.get_child_count() > 0, "%s spawns boss enemy" % battle_path)
	_check(_enemies_have_actions(battle), "%s boss has intent action" % battle_path)

	battle.battle_ui._on_end_turn_button_pressed()
	await get_tree().create_timer(2.0).timeout
	_check(battle.player != null and battle.player.stats != null and battle.player.stats.health > 0, "%s enemy turn completes without killing smoke player" % battle_path)

	for enemy: Enemy in _get_live_enemies(battle):
		enemy.take_damage(enemy.stats.health + enemy.stats.block + 999, Modifier.Type.DMG_TAKEN)

	await get_tree().create_timer(1.0).timeout
	var battle_over_panel := battle.get_node_or_null("BattleOverLayer/BattleOverPanel") as BattleOverPanel
	_check(battle_over_panel != null and battle_over_panel.visible, "%s shows victory panel after boss dies" % battle_path)
	get_tree().paused = false

	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


func _enemies_have_actions(battle: Battle) -> bool:
	for enemy: Enemy in _get_live_enemies(battle):
		if enemy.current_action == null:
			return false
	return not _get_live_enemies(battle).is_empty()


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	if not battle or not battle.enemy_handler:
		return enemies

	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	return enemies


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("BOSS_BATTLE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("BOSS_BATTLE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
