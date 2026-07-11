extends Node

const PROFILE_TEST_PATH := "user://difficulty_profile_smoke.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_standard_rules()
	_check_threshold_rules()
	_check_map_scaling()
	_check_profile_progression()
	_finish()


func _check_standard_rules() -> void:
	var stats := RunStats.new()
	stats.configure_difficulty(0)
	_check(stats.difficulty_level == 0, "standard difficulty is level zero")
	_check(stats.gold == RunStats.STARTING_GOLD, "standard difficulty keeps starting gold")
	_check(stats.card_rewards == RunStats.BASE_CARD_REWARDS, "standard difficulty keeps three card rewards")
	_check(is_equal_approx(stats.get_enemy_health_multiplier(2), 1.0), "standard difficulty keeps boss health")
	_check(stats.get_campfire_heal_amount(100) == 30, "standard campfire heals thirty percent")
	_check(stats.get_chapter_recovery_amount(40, 100) == 60, "standard chapter transition fully heals")


func _check_threshold_rules() -> void:
	var stats := RunStats.new()
	stats.configure_difficulty(8)
	_check(stats.card_rewards == 2, "difficulty eight reduces card choices")
	_check(is_equal_approx(stats.enemy_health_multiplier, 1.05), "difficulty eight includes enemy health rule")
	_check(stats.apply_gold_reward_multiplier(100) == 90, "difficulty eight reduces battle gold")
	_check(stats.get_campfire_heal_amount(100) == 25, "difficulty eight reduces campfire healing")

	stats.configure_difficulty(15)
	_check(stats.gold == 55, "difficulty fifteen includes reduced starting gold")
	_check(stats.get_starting_health(100) == 90, "difficulty fifteen starts injured")
	_check(stats.get_chapter_recovery_amount(40, 100) == 30, "difficulty fifteen only heals half missing health between chapters")
	_check(stats.apply_shop_cost_multiplier(100) == 125, "difficulty fifteen applies final shop markup")
	_check(is_equal_approx(stats.get_enemy_health_multiplier(1), 1.15 * 1.10), "difficulty fifteen stacks elite health")
	_check(is_equal_approx(stats.get_enemy_damage_multiplier(2), 1.10 * 1.15), "difficulty fifteen stacks boss damage")
	_check(RunStats.DIFFICULTY_RULES.size() == RunStats.MAX_DIFFICULTY_LEVEL + 1, "every difficulty level has a rule description")

	stats.gold = 33
	stats.refresh_difficulty_modifiers(false)
	_check(stats.gold == 33, "loading difficulty modifiers does not reset current gold")


func _check_map_scaling() -> void:
	var difficulty := RunStats.new()
	difficulty.configure_difficulty(15)
	var generator := MapGenerator.new()
	generator.current_chapter = 2
	generator.difficulty_stats = difficulty

	var normal := BattleStats.new()
	normal.enemy_health_multiplier = 1.0
	normal.enemy_damage_multiplier = 1.0
	normal.gold_reward_min = 100
	normal.gold_reward_max = 100
	generator._apply_chapter_scaling(normal, 0)
	_check(is_equal_approx(normal.enemy_health_multiplier, 1.30 * 1.15), "map stacks chapter and difficulty health")
	_check(is_equal_approx(normal.enemy_damage_multiplier, 1.15 * 1.10), "map stacks chapter and difficulty damage")
	_check(normal.gold_reward_min == 108, "map stacks chapter and reduced difficulty gold")

	var boss := BattleStats.new()
	boss.enemy_health_multiplier = 1.0
	boss.enemy_damage_multiplier = 1.0
	generator._apply_chapter_scaling(boss, 2)
	_check(is_equal_approx(boss.enemy_health_multiplier, 1.30 * 1.15 * 1.10), "map adds boss health modifier")
	_check(is_equal_approx(boss.enemy_damage_multiplier, 1.15 * 1.10 * 1.15), "map adds boss damage modifier")
	generator.free()


func _check_profile_progression() -> void:
	if FileAccess.file_exists(PROFILE_TEST_PATH):
		DirAccess.remove_absolute(PROFILE_TEST_PATH)
	var profile := DifficultyProfile.load_data(PROFILE_TEST_PATH)
	_check(profile.unlocked_level == 0 and profile.selected_level == 0, "new profile starts at standard difficulty")
	_check(profile.select_level(10) == 0, "profile cannot select a locked difficulty")
	_check(profile.record_victory(0), "first victory unlocks a level")
	_check(profile.unlocked_level == 1 and profile.selected_level == 1, "victory unlocks and selects the next level")
	_check(profile.save_data(PROFILE_TEST_PATH) == OK, "difficulty profile saves")

	var loaded := DifficultyProfile.load_data(PROFILE_TEST_PATH)
	_check(loaded.unlocked_level == 1 and loaded.selected_level == 1, "difficulty profile reloads progression")
	loaded.unlocked_level = DifficultyProfile.MAX_LEVEL
	loaded.selected_level = DifficultyProfile.MAX_LEVEL
	_check(not loaded.record_victory(DifficultyProfile.MAX_LEVEL), "maximum difficulty does not unlock past cap")
	_check(loaded.unlocked_level == DifficultyProfile.MAX_LEVEL, "difficulty unlock remains capped")
	DirAccess.remove_absolute(PROFILE_TEST_PATH)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("DIFFICULTY_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DIFFICULTY_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
