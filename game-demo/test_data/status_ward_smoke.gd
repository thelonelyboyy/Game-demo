extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_e_eclipse_ritual.tres"
const SOUL_MARK_PATH := "res://statuses/soul_mark.tres"
const MUSCLE_PATH := "res://statuses/muscle.tres"
const DEBUFF_PATHS := [
	"res://statuses/bleed.tres",
	"res://statuses/exposed.tres",
	"res://statuses/enemy_exposed.tres",
	"res://statuses/mana_seal.tres",
	"res://statuses/soul_mark.tres",
	"res://statuses/weak.tres",
	"res://statuses/frail.tres",
]
const WARDED_ENEMIES := {
	"res://enemies/heartpiercer_shade/heartpiercer_shade_enemy.tres": 1,
	"res://enemies/heavenly_clerk/heavenly_clerk_enemy.tres": 1,
	"res://enemies/bronze_overseer/bronze_overseer_enemy.tres": 1,
	"res://enemies/eclipse_priest/eclipse_priest_enemy.tres": 2,
	"res://enemies/underworld_judge/underworld_judge_enemy.tres": 3,
	"res://enemies/venom_broodmother/venom_broodmother_enemy.tres": 2,
}

var failures: PackedStringArray = []
var blocked_count := 0


func _ready() -> void:
	get_tree().create_timer(20.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_resource_configuration()
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "status ward support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
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
	await get_tree().create_timer(2.4).timeout

	var priest := _find_enemy(battle, "eclipse_priest")
	_check(priest != null, "eclipse priest spawns for ward smoke")
	if priest:
		priest.status_handler.status_blocked.connect(_on_status_blocked)
		_check(priest.status_handler.get_status_stacks("spell_ward") == 2, "eclipse priest starts with two spell ward")

		var muscle := (load(MUSCLE_PATH) as Status).duplicate() as Status
		muscle.stacks = 1
		_apply_status(priest, muscle)
		await get_tree().process_frame
		_check(priest.status_handler.get_status_stacks("muscle") == 1, "positive status bypasses spell ward")
		_check(priest.status_handler.get_status_stacks("spell_ward") == 2, "positive status does not consume spell ward")

		_apply_status(priest, load(SOUL_MARK_PATH) as Status)
		await get_tree().process_frame
		_check(priest.status_handler.get_status("soul_mark") == null, "first debuff is blocked")
		_check(priest.status_handler.get_status_stacks("spell_ward") == 1, "first debuff consumes one ward")

		_apply_status(priest, load(SOUL_MARK_PATH) as Status)
		await get_tree().process_frame
		_check(priest.status_handler.get_status("soul_mark") == null, "second debuff is blocked")
		_check(priest.status_handler.get_status("spell_ward") == null, "spell ward disappears at zero stacks")

		_apply_status(priest, load(SOUL_MARK_PATH) as Status)
		await get_tree().process_frame
		_check(priest.status_handler.get_status_stacks("soul_mark") == 1, "debuff applies after spell ward is broken")
		_check(blocked_count == 2, "status handler reports exactly two blocked debuffs")

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_resource_configuration() -> void:
	for path: String in DEBUFF_PATHS:
		var status := load(path) as Status
		_check(status != null and status.is_debuff, "%s is marked as a debuff" % path)
	for path: String in WARDED_ENEMIES:
		var stats := load(path) as EnemyStats
		var expected_stacks: int = WARDED_ENEMIES[path]
		_check(stats != null and stats.starting_statuses.size() == 1, "%s has one configured starting status" % path)
		if stats and stats.starting_statuses.size() == 1:
			_check(stats.starting_statuses[0].id == "spell_ward", "%s starts with spell ward" % path)
			_check(stats.starting_statuses[0].stacks == expected_stacks, "%s has the configured ward stacks" % path)


func _apply_status(target: Enemy, status: Status) -> void:
	var effect := StatusEffect.new()
	effect.status = status
	var targets: Array[Node] = [target]
	effect.execute(targets)


func _find_enemy(battle: Battle, enemy_id: String) -> Enemy:
	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and enemy.stats and enemy.stats.id == enemy_id:
			return enemy
	return null


func _on_status_blocked(_status: Status) -> void:
	blocked_count += 1


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("STATUS_WARD_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("STATUS_WARD_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("STATUS_WARD_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
