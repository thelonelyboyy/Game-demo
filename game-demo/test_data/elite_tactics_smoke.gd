extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const ELITE_BATTLES := [
	{"path": "res://battles/demo_e_blood_moon_hunt.tres", "kind": "pack_buff"},
	{"path": "res://battles/demo_e_bronze_formation.tres", "kind": "team_block"},
	{"path": "res://battles/demo_e_eclipse_ritual.tres", "kind": "deck_pollution"},
]

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	for spec: Dictionary in ELITE_BATTLES:
		await _check_elite_battle(String(spec.path), String(spec.kind))
	_finish()


func _check_elite_battle(battle_path: String, kind: String) -> void:
	var battle_stats := load(battle_path) as BattleStats
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(battle_stats != null, "%s loads battle stats" % battle_path)
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null, "elite smoke support resources load")
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
	_check(enemies.size() == 2, "%s spawns a two-enemy elite formation" % battle_path)
	_check(_enemies_have_actions(enemies), "%s gives every elite an intent" % battle_path)

	battle.battle_ui._on_end_turn_button_pressed()
	await get_tree().create_timer(3.8).timeout
	enemies = _get_live_enemies(battle)
	match kind:
		"pack_buff":
			for enemy: Enemy in enemies:
				_check(enemy.status_handler.get_status_stacks("muscle") >= 2, "%s pack howl buffs every ally" % battle_path)
		"team_block":
			for enemy: Enemy in enemies:
				_check(enemy.stats.block >= 12, "%s formation leaves block on every ally" % battle_path)
		"deck_pollution":
			_check(_discard_contains(battle, "eclipse_scar"), "%s adds eclipse scar to discard" % battle_path)

	_check(battle.player != null and battle.player.stats.health > 0, "%s first enemy turn is survivable" % battle_path)
	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


func _enemies_have_actions(enemies: Array[Enemy]) -> bool:
	if enemies.is_empty():
		return false
	for enemy: Enemy in enemies:
		if not enemy.current_action:
			return false
	return true


func _discard_contains(battle: Battle, card_id: String) -> bool:
	if not battle or not battle.player_handler or not battle.player_handler.character:
		return false
	var discard := battle.player_handler.character.discard
	if not discard:
		return false
	for card: Card in discard.cards:
		if card and card.id == card_id:
			return true
	return false


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
		print("ELITE_TACTICS_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("ELITE_TACTICS_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
