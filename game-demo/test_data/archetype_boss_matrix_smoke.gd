extends Node

const CATALOG := preload("res://test_data/support/demonic_autoplay_catalog.gd")
const HARNESS := preload("res://test_data/support/battle_autoplay_harness.gd")
const SEEDS := [9101, 9102]
const MIN_WINS_PER_ARCHETYPE := 3

var failures := PackedStringArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var original_time_scale := Engine.time_scale
	Engine.time_scale = 18.0
	var harness = HARNESS.new()
	var selected_seeds := _selected_seeds()
	var selected_encounter_count := 0
	var encounter_archetype_wins := {}
	for encounter: Dictionary in CATALOG.BOSS_MATRIX:
		if _matches_filter("AUTOPLAY_BOSS", String(encounter.id)):
			selected_encounter_count += 1
			encounter_archetype_wins[String(encounter.id)] = 0
	for archetype: String in CATALOG.DECKS:
		if not _matches_filter("AUTOPLAY_ARCHETYPE", archetype):
			continue
		var wins := 0
		var total_turns := 0
		var total_health := 0
		for encounter: Dictionary in CATALOG.BOSS_MATRIX:
			if not _matches_filter("AUTOPLAY_BOSS", String(encounter.id)):
				continue
			var encounter_wins := 0
			for seed_value: int in selected_seeds:
				var derived_seed := seed_value + CATALOG.DECKS.keys().find(archetype) * 1000 + int(encounter.chapter) * 100
				var result: Dictionary = await harness.run(self, archetype, encounter, derived_seed)
				_check(bool(result.setup_ok), "%s %s setup failed: %s" % [archetype, encounter.id, ",".join(result.errors)])
				_check(not bool(result.timed_out), "%s %s seed %s timed out; log=%s" % [archetype, encounter.id, derived_seed, ",".join(result.play_log)])
				if result.won:
					wins += 1
					encounter_wins += 1
					total_health += int(result.player_health)
				total_turns += int(result.turns)
				print("ARCHETYPE_BOSS_MATRIX_RESULT:%s:%s:seed=%s:won=%s:turns=%s:hp=%s" % [
					archetype, encounter.id, derived_seed, result.won, result.turns, result.player_health
				])
				if not result.won:
					print("ARCHETYPE_BOSS_MATRIX_LOSS_LOG:%s:%s:seed=%s:%s" % [
						archetype, encounter.id, derived_seed, ",".join(result.play_log)
					])
			if encounter_wins > 0:
				encounter_archetype_wins[String(encounter.id)] += 1
		var battle_count := selected_encounter_count * selected_seeds.size()
		var minimum_wins := mini(MIN_WINS_PER_ARCHETYPE, battle_count)
		_check(wins >= minimum_wins, "%s wins %s/%s boss matrix battles; expected at least %s" % [
			archetype, wins, battle_count, minimum_wins
		])
		print("ARCHETYPE_BOSS_MATRIX_SUMMARY:%s:wins=%s/%s:avg_turns=%.2f:avg_win_hp=%.2f" % [
			archetype,
			wins,
			battle_count,
			float(total_turns) / float(maxi(battle_count, 1)),
			float(total_health) / float(maxi(wins, 1)),
		])
	if OS.get_environment("AUTOPLAY_ARCHETYPE").strip_edges().is_empty():
		for encounter_id: String in encounter_archetype_wins:
			_check(int(encounter_archetype_wins[encounter_id]) >= 2, "%s is cleared by %s archetypes; expected at least 2" % [
				encounter_id, encounter_archetype_wins[encounter_id]
			])
	Engine.time_scale = original_time_scale
	_finish()


func _matches_filter(environment_name: String, value: String) -> bool:
	var filter_value := OS.get_environment(environment_name).strip_edges()
	return filter_value.is_empty() or filter_value == value


func _selected_seeds() -> Array[int]:
	var selected: Array[int] = []
	var seed_filter := OS.get_environment("AUTOPLAY_SEED").strip_edges()
	for seed_value: int in SEEDS:
		if seed_filter.is_empty() or seed_filter == str(seed_value):
			selected.append(seed_value)
	return selected


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("ARCHETYPE_BOSS_MATRIX_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("ARCHETYPE_BOSS_MATRIX_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
