extends Node

const CATALOG := preload("res://test_data/support/demonic_autoplay_catalog.gd")
const HARNESS := preload("res://test_data/support/battle_autoplay_harness.gd")

var failures := PackedStringArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var original_time_scale := Engine.time_scale
	Engine.time_scale = 10.0
	var harness = HARNESS.new()
	for archetype: String in CATALOG.DECKS:
		var archetype_filter := OS.get_environment("AUTOPLAY_ARCHETYPE").strip_edges()
		if not archetype_filter.is_empty() and archetype_filter != archetype:
			continue
		for encounter: Dictionary in CATALOG.BASELINE_ENCOUNTERS:
			var seed_value := 7300 + CATALOG.DECKS.keys().find(archetype) * 100 + CATALOG.BASELINE_ENCOUNTERS.find(encounter)
			var result: Dictionary = await harness.run(self, archetype, encounter, seed_value)
			print("ARCHETYPE_AUTOPLAY_RESULT:%s:%s:won=%s:turns=%s:hp=%s:cards=%s" % [
				archetype, encounter.tier, result.won, result.turns, result.player_health, result.cards_played
			])
			_check(bool(result.setup_ok), "%s %s setup failed: %s" % [archetype, encounter.tier, ",".join(result.errors)])
			_check(bool(result.won), "%s build clears %s encounter; log=%s" % [archetype, encounter.tier, ",".join(result.play_log)])
	Engine.time_scale = original_time_scale
	_finish()


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
