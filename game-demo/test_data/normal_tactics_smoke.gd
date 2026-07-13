extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const NORMAL_BATTLES := [
	{"path": "res://battles/demo_n_spirit_leech.tres", "kind": "mana_seal"},
	{"path": "res://battles/demo_n_scripture_moth.tres", "kind": "draw_exhaust"},
	{"path": "res://battles/demo_n_karma_collector.tres", "kind": "discard_scaling"},
	{"path": "res://battles/demo_n_blood_rite_acolyte.tres", "kind": "blood_rite"},
	{"path": "res://battles/demo_n_warded_husk.tres", "kind": "attack_guard"},
	{"path": "res://battles/demo_n_heartpiercer_shade.tres", "kind": "exposed_setup"},
	{"path": "res://battles/demo_n_ash_sutra_monk.tres", "kind": "draw_pollution"},
	{"path": "res://battles/demo_n_blood_revenant.tres", "kind": "blood_drain"},
	{"path": "res://battles/demo_n_heavenly_clerk.tres", "kind": "missing_health"},
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
	var pollution_id := "spirit_lock_seal" if kind == "draw_pollution" else "eclipse_scar"
	var pollution_before := _count_card_id(battle, pollution_id)
	var enemy_health_before := enemies[0].stats.health if not enemies.is_empty() else 0
	if kind == "blood_drain" and not enemies.is_empty():
		enemies[0].stats.health -= 15
		enemy_health_before = enemies[0].stats.health
	elif kind == "missing_health":
		battle.char_stats.health = maxi(battle.char_stats.max_health - 40, 1)
		Events.player_hit.emit()
		await get_tree().process_frame
		health_before = battle.char_stats.health
		var expected_intent := 10 + floori(40.0 / float(battle.char_stats.max_health) * 16.0)
		_check(not enemies.is_empty() and enemies[0].current_action.intent.current_text == str(expected_intent), "%s refreshes its intent after player health changes" % battle_path)

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
		"blood_rite":
			_check(not enemies.is_empty() and enemies[0].stats.health == enemy_health_before - 4, "%s pays its advertised blood-rite health" % battle_path)
			_check(not enemies.is_empty() and enemies[0].status_handler.get_status_stacks("muscle") == 2, "%s gains two muscle from its blood rite" % battle_path)
			_check(battle.char_stats.health == health_before, "%s blood rite deals no hidden player damage" % battle_path)
		"attack_guard":
			_check(health_before - battle.char_stats.health == 8, "%s deals its attack-and-guard damage" % battle_path)
			_check(not enemies.is_empty() and enemies[0].stats.block == 8, "%s keeps its attack-and-guard block" % battle_path)
		"exposed_setup":
			var exposed := battle.player.status_handler.get_status("exposed")
			_check(exposed != null and exposed.duration == 1, "%s leaves one enemy-turn window of exposed" % battle_path)
			_check(battle.char_stats.health == health_before, "%s telegraphs exposed before its multi-hit" % battle_path)
		"draw_pollution":
			_check(
				_count_card_id(battle, pollution_id) == pollution_before + 1,
				"%s adds exactly one draw-trigger pollution card across combat piles" % battle_path
			)
		"blood_drain":
			_check(health_before - battle.char_stats.health == 14, "%s deals its advertised drain damage" % battle_path)
			_check(not enemies.is_empty() and enemies[0].stats.health == enemy_health_before + 10, "%s restores ten health after draining" % battle_path)
		"missing_health":
			var expected_damage := 10 + floori(40.0 / float(battle.char_stats.max_health) * 16.0)
			_check(health_before - battle.char_stats.health == expected_damage, "%s scales damage from missing health" % battle_path)

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


func _count_card_id(battle: Battle, card_id: String) -> int:
	var count := 0
	for pile: CardPile in [battle.char_stats.draw_pile, battle.char_stats.discard, battle.char_stats.exhaust_pile]:
		if not pile:
			continue
		for card: Card in pile.cards:
			if card and card.id == card_id:
				count += 1
	for child: Node in battle.player_handler.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.id == card_id:
			count += 1
	return count


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
