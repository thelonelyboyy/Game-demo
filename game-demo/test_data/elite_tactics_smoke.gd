extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const ELITE_BATTLES := [
	{"path": "res://battles/demo_e_blood_moon_hunt.tres", "kind": "pack_buff", "summon_id": "mist_wolf"},
	{"path": "res://battles/demo_e_bronze_formation.tres", "kind": "team_block", "summon_id": "paper_soldier"},
	{"path": "res://battles/demo_e_eclipse_ritual.tres", "kind": "deck_pollution", "summon_id": "venom_moth"},
]

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_random_action_repeat_guard()
	for spec: Dictionary in ELITE_BATTLES:
		await _check_elite_battle(String(spec.path), String(spec.kind), String(spec.summon_id))
	_finish()


func _check_random_action_repeat_guard() -> void:
	var picker := EnemyActionPicker.new()
	for index in 3:
		var action := EnemyAction.new()
		action.name = "ChanceAction%s" % index
		action.type = EnemyAction.Type.CHANCE_BASED
		action.chance_weight = 1.0
		action.max_consecutive_uses = 2
		picker.add_child(action)
	RNG.instance.seed = 81723
	var previous: EnemyAction
	var streak := 0
	for _i in 200:
		var picked := picker.get_chance_based_action()
		_check(picked != null, "weighted action picker always returns an action")
		if picked == previous:
			streak += 1
		else:
			previous = picked
			streak = 1
		_check(streak <= 2, "weighted enemy actions never repeat more than configured")
	picker.free()


func _check_elite_battle(battle_path: String, kind: String, summon_id: String) -> void:
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

	_check(await _end_turn_and_wait(battle), "%s first enemy turn finishes within the smoke timeout" % battle_path)
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

	_check(await _end_turn_and_wait(battle), "%s second enemy turn finishes within the smoke timeout" % battle_path)
	enemies = _get_live_enemies(battle)
	_check(enemies.size() == 3, "%s summons a third combatant on its second enemy turn" % battle_path)
	_check(_count_enemy_id(enemies, summon_id) == 2, "%s summons the advertised reinforcement" % battle_path)
	_check(_enemies_have_actions(enemies), "%s gives summoned reinforcements a future intent" % battle_path)
	_check(battle.battle_active, "%s remains active after reinforcement joins" % battle_path)
	if not enemies.is_empty():
		var overflow := battle.enemy_handler.summon_enemy(enemies.back().stats, 3)
		_check(overflow == null and _get_live_enemies(battle).size() == 3, "%s enforces the three-enemy summon cap" % battle_path)

	_check(battle.player != null and battle.player.stats.health > 0, "%s first enemy turn is survivable" % battle_path)
	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


func _end_turn_and_wait(battle: Battle, timeout_seconds := 12.0) -> bool:
	var state := {"ended": false}
	var on_turn_ended := func() -> void: state.ended = true
	Events.enemy_turn_ended.connect(on_turn_ended, CONNECT_ONE_SHOT)
	battle.battle_ui._on_end_turn_button_pressed()
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while is_instance_valid(battle) and battle.battle_active and not state.ended:
		if Time.get_ticks_msec() >= deadline:
			break
		await get_tree().process_frame
	if Events.enemy_turn_ended.is_connected(on_turn_ended):
		Events.enemy_turn_ended.disconnect(on_turn_ended)
	return state.ended


func _enemies_have_actions(enemies: Array[Enemy]) -> bool:
	if enemies.is_empty():
		return false
	for enemy: Enemy in enemies:
		if not enemy.current_action:
			return false
	return true


func _count_enemy_id(enemies: Array[Enemy], enemy_id: String) -> int:
	var count := 0
	for enemy: Enemy in enemies:
		if enemy.stats and enemy.stats.id == enemy_id:
			count += 1
	return count


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
