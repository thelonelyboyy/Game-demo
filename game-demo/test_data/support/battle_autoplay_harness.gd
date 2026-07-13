class_name BattleAutoplayHarness
extends RefCounted

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const AUTOPLAYER := preload("res://test_data/support/battle_autoplayer.gd")
const CATALOG := preload("res://test_data/support/demonic_autoplay_catalog.gd")


func run(host: Node, archetype: String, encounter: Dictionary, seed_value: int) -> Dictionary:
	var errors := PackedStringArray()
	if not host or not host.is_inside_tree():
		return _setup_failure("autoplay host is not inside the tree")

	host.get_tree().paused = false
	RNG.instance.seed = seed_value
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(String(encounter.path)) as BattleStats
	if not battle_scene or not relic_scene or not character_resource or not battle_stats:
		return _setup_failure("support resources failed to load for %s" % encounter.get("id", encounter.path))
	if not CATALOG.DECKS.has(archetype) or not CATALOG.RELICS.has(archetype):
		return _setup_failure("unknown archetype: %s" % archetype)

	var character := character_resource.create_instance() as CharacterStats
	character.deck = _build_deck(CATALOG.DECKS[archetype], character, errors)
	_upgrade_deck(character.deck, int(encounter.get("upgrade_count", 0)))
	var relic_handler := relic_scene.instantiate() as RelicHandler
	host.add_child(relic_handler)
	await host.get_tree().process_frame
	if character.starting_relic:
		relic_handler.add_relic(character.starting_relic.duplicate(true) as Relic)
	for relic_path: String in CATALOG.RELICS[archetype]:
		var relic := load(relic_path) as Relic
		if relic:
			relic_handler.add_relic(relic.duplicate(true) as Relic)
		else:
			errors.append("relic failed to load: %s" % relic_path)

	var battle := battle_scene.instantiate() as Battle
	host.add_child(battle)
	battle.char_stats = character
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()

	var driver = AUTOPLAYER.new()
	var result: Dictionary = await driver.run(battle, int(encounter.max_turns))
	result["setup_ok"] = errors.is_empty()
	result["errors"] = errors
	result["archetype"] = archetype
	result["encounter_id"] = String(encounter.get("id", encounter.path))
	result["seed"] = seed_value

	host.get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await host.get_tree().process_frame
	return result


func _build_deck(paths: Array, character: CharacterStats, errors: PackedStringArray) -> CardPile:
	var pile := CardPile.new()
	for path: String in paths:
		var source := load(path) as Card
		if source:
			pile.add_card(source.create_runtime_copy())
		else:
			errors.append("card failed to load: %s" % path)
	pile.bind_cards_to_owner(character)
	return pile


func _upgrade_deck(deck: CardPile, amount: int) -> void:
	if not deck or amount <= 0:
		return
	var upgraded_count := 0
	for card: Card in deck.cards:
		if upgraded_count >= amount:
			return
		if card and card.upgrade():
			upgraded_count += 1


func _setup_failure(message: String) -> Dictionary:
	return {
		"setup_ok": false,
		"won": false,
		"turns": 0,
		"cards_played": 0,
		"player_health": 0,
		"enemies_remaining": 0,
		"timed_out": false,
		"play_log": PackedStringArray(),
		"errors": PackedStringArray([message]),
	}
