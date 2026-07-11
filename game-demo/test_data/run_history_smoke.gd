extends Node

const TEST_PATH := "user://run_history_smoke.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

	var first_stats := _make_stats(2, 7, 2, 1, 14, 43, 3, 120, 2)
	var history := RunHistory.new()
	var first_summary := history.record_run(first_stats, false, 2, 18, 5)
	_check(first_summary.contains("战斗 7"), "run summary includes battle count")
	_check(first_summary.contains("牌组 18"), "run summary includes deck size")
	_check(history.total_runs == 1 and history.defeats == 1, "defeat records one completed run")
	_check(history.highest_chapter == 2 and history.highest_difficulty == 2, "defeat records chapter and difficulty")
	_check(history.save_data(TEST_PATH) == OK, "run history saves")

	var loaded := RunHistory.load_data(TEST_PATH)
	_check(loaded.total_runs == 1 and loaded.last_run_summary == first_summary, "run history reloads")
	var second_stats := _make_stats(5, 12, 3, 3, 28, 91, 6, 260, 4)
	var second_summary := loaded.record_run(second_stats, true, 3, 24, 11)
	_check(loaded.total_runs == 2 and loaded.victories == 1 and loaded.defeats == 1, "victory accumulates without replacing defeat")
	_check(loaded.highest_chapter == 3 and loaded.highest_difficulty == 5, "history retains new records")
	_check(loaded.total_battles == 19, "battle totals accumulate")
	_check(loaded.total_elites == 5 and loaded.total_bosses == 4, "elite and boss totals accumulate")
	_check(loaded.total_enemies_defeated == 42 and loaded.total_cards_played == 134, "combat activity totals accumulate")
	_check(loaded.total_events_resolved == 9 and loaded.total_gold_spent == 380, "route economy totals accumulate")
	_check(loaded.total_potions_used == 6, "consumable totals accumulate")
	_check(loaded.last_run_won and loaded.last_run_summary == second_summary, "last run snapshot tracks victory")

	DirAccess.remove_absolute(TEST_PATH)
	_finish()


func _make_stats(
	difficulty: int,
	battles: int,
	elites: int,
	bosses: int,
	enemies: int,
	cards: int,
	events: int,
	gold: int,
	potions: int
) -> RunStats:
	var stats := RunStats.new()
	stats.difficulty_level = difficulty
	stats.battles_won = battles
	stats.elites_defeated = elites
	stats.bosses_defeated = bosses
	stats.enemies_defeated = enemies
	stats.cards_played = cards
	stats.events_resolved = events
	stats.gold_spent = gold
	stats.potions_used = potions
	return stats


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("RUN_HISTORY_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("RUN_HISTORY_SMOKE: %s" % failure)
	get_tree().quit(1)
