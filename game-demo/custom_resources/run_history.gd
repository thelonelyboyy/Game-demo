class_name RunHistory
extends Resource

const HISTORY_PATH := "user://run_history.tres"

@export var total_runs := 0
@export var victories := 0
@export var defeats := 0
@export var highest_chapter := 0
@export var highest_difficulty := 0
@export var total_battles := 0
@export var total_elites := 0
@export var total_bosses := 0
@export var total_enemies_defeated := 0
@export var total_cards_played := 0
@export var total_events_resolved := 0
@export var total_gold_spent := 0
@export var total_potions_used := 0
@export var last_run_won := false
@export var last_run_summary := ""


func record_run(
	run_stats: RunStats,
	won: bool,
	chapter: int,
	deck_size: int,
	relic_count: int
) -> String:
	if not run_stats:
		return ""
	total_runs += 1
	if won:
		victories += 1
	else:
		defeats += 1
	highest_chapter = maxi(highest_chapter, chapter)
	highest_difficulty = maxi(highest_difficulty, run_stats.difficulty_level)
	total_battles += run_stats.battles_won
	total_elites += run_stats.elites_defeated
	total_bosses += run_stats.bosses_defeated
	total_enemies_defeated += run_stats.enemies_defeated
	total_cards_played += run_stats.cards_played
	total_events_resolved += run_stats.events_resolved
	total_gold_spent += run_stats.gold_spent
	total_potions_used += run_stats.potions_used
	last_run_won = won
	last_run_summary = _build_summary(run_stats, chapter, deck_size, relic_count)
	return last_run_summary


func _build_summary(run_stats: RunStats, chapter: int, deck_size: int, relic_count: int) -> String:
	return "第 %s 章｜战斗 %s（精英 %s / 首领 %s）｜击破 %s｜出牌 %s\n事件 %s｜消费 %s 灵石｜丹药 %s｜牌组 %s｜法宝 %s" % [
		chapter,
		run_stats.battles_won,
		run_stats.elites_defeated,
		run_stats.bosses_defeated,
		run_stats.enemies_defeated,
		run_stats.cards_played,
		run_stats.events_resolved,
		run_stats.gold_spent,
		run_stats.potions_used,
		deck_size,
		relic_count,
	]


func save_data(path := HISTORY_PATH) -> Error:
	return ResourceSaver.save(self, path)


static func load_data(path := HISTORY_PATH) -> RunHistory:
	if not FileAccess.file_exists(path):
		return RunHistory.new()
	var history := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as RunHistory
	return history if history else RunHistory.new()
