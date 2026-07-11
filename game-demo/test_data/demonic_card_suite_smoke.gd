extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const BLOOD_DEBT_PATH := "res://characters/demonic_cultivator/cards/demon_blood_debt.tres"
const SHA_BLADE_PATH := "res://characters/demonic_cultivator/cards/demon_sha_blade.tres"
const MYRIAD_MARKS_PATH := "res://characters/demonic_cultivator/cards/demon_myriad_marks_return.tres"
const SHA_QI_PATH := "res://statuses/sha_qi.tres"
const SOUL_MARK_PATH := "res://statuses/soul_mark.tres"

var failures: PackedStringArray = []
var current_step := "startup"


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	current_step = "load_support"
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "demonic suite support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	current_step = "setup_relics"
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	current_step = "setup_battle"
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	current_step = "wait_for_battle"
	await get_tree().create_timer(1.8).timeout

	current_step = "resolve_cards"
	var enemies := _get_live_enemies(battle)
	_check(enemies.size() == 2, "demonic suite starts with two enemies")
	if enemies.size() >= 2:
		current_step = "blood_debt"
		await _check_blood_debt(battle, enemies[0])
		current_step = "sha_blade"
		await _check_sha_blade(battle, enemies[0])
		current_step = "myriad_marks"
		await _check_myriad_marks(battle, enemies)

	current_step = "cleanup"
	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	current_step = "finish"
	_finish()


func _check_blood_debt(battle: Battle, enemy: Enemy) -> void:
	var card := (load(BLOOD_DEBT_PATH) as Card).duplicate(true) as CultivationCard
	Events.player_self_damaged.emit(4)
	var before := enemy.stats.health
	card.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(before - enemy.stats.health == 9, "blood debt converts current-turn self damage into attack damage")


func _check_sha_blade(battle: Battle, enemy: Enemy) -> void:
	var sha := (load(SHA_QI_PATH) as Status).duplicate() as Status
	sha.stacks = 3
	battle.player.status_handler.add_status(sha)
	var card := (load(SHA_BLADE_PATH) as Card).duplicate(true) as CultivationCard
	var before := enemy.stats.health
	card.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(battle.player.status_handler.get_status_stacks("sha_qi") == 1, "sha blade consumes at most two sha qi")
	_check(before - enemy.stats.health >= 10, "sha blade converts consumed sha qi into damage")


func _check_myriad_marks(battle: Battle, enemies: Array[Enemy]) -> void:
	for enemy: Enemy in enemies:
		var mark := (load(SOUL_MARK_PATH) as Status).duplicate() as Status
		mark.stacks = 3
		enemy.status_handler.add_status(mark)
	var before := [enemies[0].stats.health, enemies[1].stats.health]
	var card := (load(MYRIAD_MARKS_PATH) as Card).duplicate(true) as CultivationCard
	var targets: Array[Node] = []
	targets.assign(enemies)
	card.apply_effects(targets, battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	for i in enemies.size():
		_check(enemies[i].status_handler.get_status_stacks("soul_mark") == 0, "myriad marks consumes all marks on enemy %s" % i)
		_check(before[i] - enemies[i].stats.health >= 6, "myriad marks damages enemy %s from consumed marks" % i)


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
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
		print("DEMONIC_CARD_SUITE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DEMONIC_CARD_SUITE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DEMONIC_CARD_SUITE_SMOKE_TIMEOUT: %s" % current_step)
	get_tree().paused = false
	get_tree().quit(2)
