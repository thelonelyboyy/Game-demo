extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const NORMAL_BATTLES := [
	{"path": "res://battles/demo_n_spirit_leech.tres", "kind": "mana_seal"},
	{"path": "res://battles/demo_n_scripture_moth.tres", "kind": "draw_exhaust"},
	{"path": "res://battles/demo_n_karma_collector.tres", "kind": "discard_scaling"},
]

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	for spec: Dictionary in NORMAL_BATTLES:
		await _check_normal_battle(String(spec.path), String(spec.kind))
	_finish()


func _check_normal_battle(battle_path: String, kind: String) -> void:
	var battle_stats := load(battle_path) as BattleStats
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(battle_stats != null, "%s loads battle stats" % battle_path)
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null, "normal tactic support resources load")
	if not battle_stats or not battle_scene or not relic_handler_scene or not character_resource:
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
	var enemies := _get_live_enemies(battle)
	_check(enemies.size() == 1, "%s spawns one tactical enemy" % battle_path)
	_check(not enemies.is_empty() and enemies[0].current_action != null, "%s exposes its opening intent" % battle_path)
	var health_before := battle.char_stats.health
	var hand_before := battle.player_handler.hand.get_child_count()
	var exhaust_before := battle.char_stats.exhaust_pile.cards.size()

	battle.battle_ui._on_end_turn_button_pressed()
	await get_tree().create_timer(4.2).timeout
	enemies = _get_live_enemies(battle)
	match kind:
		"mana_seal":
			_check(battle.char_stats.mana == battle.char_stats.max_mana - 1, "%s reduces next-turn mana by one" % battle_path)
			_check(battle.char_stats.health == health_before, "%s telegraphs mana pressure without hidden damage" % battle_path)
		"draw_exhaust":
			_check(battle.char_stats.exhaust_pile.cards.size() == exhaust_before + 1, "%s exhausts exactly one draw-pile card" % battle_path)
			_check(not enemies.is_empty() and enemies[0].stats.block >= 10, "%s gains its advertised block" % battle_path)
		"discard_scaling":
			var expected_damage := 8 + mini(hand_before * 2, 16)
			_check(health_before - battle.char_stats.health == expected_damage, "%s scales damage from the discarded hand" % battle_path)

	_check(battle.player != null and battle.player.stats.health > 0, "%s first enemy turn is survivable" % battle_path)
	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


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
		print("NORMAL_TACTICS_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("NORMAL_TACTICS_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
