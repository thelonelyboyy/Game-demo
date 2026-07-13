extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const AUTOPLAYER := preload("res://test_data/support/battle_autoplayer.gd")
const BASIC_STRIKE := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const BASIC_DEFEND := "res://characters/demonic_cultivator/cards/demon_defend.tres"
const ENCOUNTERS := [
	{"tier": "normal", "path": "res://battles/demo_n_bronze_puppet.tres", "max_turns": 12},
	{"tier": "elite", "path": "res://battles/demo_e_iron_golem.tres", "max_turns": 16},
	{"tier": "boss", "path": "res://battles/demo_b_bone_dragon.tres", "max_turns": 20},
]
const ARCHETYPES := {
	"blood": [
		BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_ward.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_ward.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_forge_armor.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/demon_desperate_burst.tres",
		"res://characters/demonic_cultivator/cards/demon_desperate_burst.tres",
		"res://characters/demonic_cultivator/cards/demon_flesh_rebirth.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_blood_qi_guard.tres",
	],
	"soul": [
		BASIC_STRIKE, BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/soul_drain.tres",
		"res://characters/demonic_cultivator/cards/soul_drain.tres",
		"res://characters/demonic_cultivator/cards/demon_soul_devour_claw.tres",
		"res://characters/demonic_cultivator/cards/demon_soul_devour_claw.tres",
		"res://characters/demonic_cultivator/cards/demon_shatter_soul_seal.tres",
		"res://characters/demonic_cultivator/cards/demon_shatter_soul_seal.tres",
		"res://characters/demonic_cultivator/cards/phase3/demon_soul_armor.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_soul_mark_sense.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_soul_rite.tres",
	],
	"flame": [
		BASIC_STRIKE, BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/demon_flame_blue.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_green.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_yellow.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_purple.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_white.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_black.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_red.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_flame_continuity.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_flame_refining.tres",
	],
}
const ARCHETYPE_RELICS := {
	"blood": [
		"res://relics/demon_blood_crucible.tres",
		"res://relics/demon_blood_tally.tres",
		"res://relics/sacrifice_blade.tres",
		"res://relics/demon_blood_pact_crown.tres",
	],
	"soul": [
		"res://relics/demon_soul_bell.tres",
		"res://relics/demon_soul_censer.tres",
		"res://relics/demon_wraith_banner.tres",
	],
	"flame": [
		"res://relics/demon_flame_lantern.tres",
		"res://relics/demon_flame_wheel_core.tres",
		"res://relics/demon_ash_furnace.tres",
	],
}

var failures := PackedStringArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var original_time_scale := Engine.time_scale
	Engine.time_scale = 10.0
	for archetype: String in ARCHETYPES:
		for encounter: Dictionary in ENCOUNTERS:
			await _run_battle(archetype, encounter)
	Engine.time_scale = original_time_scale
	_finish()


func _run_battle(archetype: String, encounter: Dictionary) -> void:
	get_tree().paused = false
	RNG.instance.seed = 7300 + ARCHETYPES.keys().find(archetype) * 100 + ENCOUNTERS.find(encounter)
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(String(encounter.path)) as BattleStats
	_check(battle_scene and relic_scene and character_resource and battle_stats, "%s %s support resources load" % [archetype, encounter.tier])
	if not battle_scene or not relic_scene or not character_resource or not battle_stats:
		return

	var character := character_resource.create_instance() as CharacterStats
	character.deck = _build_deck(ARCHETYPES[archetype], character)
	var relic_handler := relic_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	relic_handler.add_relic(character.starting_relic.duplicate(true) as Relic)
	for relic_path: String in ARCHETYPE_RELICS[archetype]:
		var relic := load(relic_path) as Relic
		_check(relic != null, "%s relic loads" % relic_path)
		if relic:
			relic_handler.add_relic(relic.duplicate(true) as Relic)

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()

	var driver = AUTOPLAYER.new()
	var result: Dictionary = await driver.run(battle, int(encounter.max_turns))
	print("ARCHETYPE_AUTOPLAY_RESULT:%s:%s:won=%s:turns=%s:hp=%s:cards=%s" % [
		archetype, encounter.tier, result.won, result.turns, result.player_health, result.cards_played
	])
	_check(bool(result.won), "%s build clears %s encounter; log=%s" % [archetype, encounter.tier, ",".join(result.play_log)])

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame


func _build_deck(paths: Array, character: CharacterStats) -> CardPile:
	var pile := CardPile.new()
	for path: String in paths:
		var source := load(path) as Card
		_check(source != null, "%s card loads" % path)
		if source:
			pile.add_card(source.create_runtime_copy())
	pile.bind_cards_to_owner(character)
	return pile


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("ARCHETYPE_AUTOPLAY_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("ARCHETYPE_AUTOPLAY_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
