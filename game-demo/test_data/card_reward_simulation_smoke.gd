extends Node

const DEMONIC_CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const CHAPTER_REWARD_BATCHES := 180
const SYNERGY_SAMPLES := 1200
const BASE_SEED := 20260713
const ARCHETYPE_TAGS := {
	"blood": "献祭",
	"flame": "魔焰",
	"soul": "魂印",
	"exhaust": "消耗",
}

var failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var character_resource := load(DEMONIC_CHARACTER_PATH) as CharacterStats
	_check(character_resource != null, "demonic character resource loads")
	if not character_resource:
		_finish()
		return

	var reward := BattleReward.new()
	reward.character_stats = character_resource.create_instance()
	reward.run_stats = RunStats.new()
	var chapter_results := _simulate_chapter_rewards(reward)
	_check_chapter_curve(chapter_results)
	_check_hard_pity(reward)
	_check_archetype_sampling(reward)
	reward.free()
	_finish()


func _simulate_chapter_rewards(reward: BattleReward) -> Dictionary:
	var results := {}
	for chapter in range(1, 4):
		RNG.instance.seed = BASE_SEED + chapter
		reward.run_stats.apply_chapter_card_weights(chapter)
		reward.run_stats.card_reward_miss_streak = 0
		reward.card_reward_tier = BattleReward.CardRewardTier.NORMAL
		var rarity_counts := {
			Card.Rarity.COMMON: 0,
			Card.Rarity.UNCOMMON: 0,
			Card.Rarity.RARE: 0,
			Card.Rarity.MYTHIC: 0,
		}
		var high_rarity_sets := 0
		var upgraded_cards := 0
		var max_miss_streak := 0
		var all_choices_complete := true
		var all_choices_unique := true
		for _batch in CHAPTER_REWARD_BATCHES:
			var choices := reward._generate_card_reward_choices()
			all_choices_complete = all_choices_complete and choices.size() == reward.run_stats.card_rewards
			var ids := {}
			var has_high_rarity := false
			for card: Card in choices:
				ids[card.id] = true
				rarity_counts[card.rarity] = int(rarity_counts.get(card.rarity, 0)) + 1
				has_high_rarity = has_high_rarity or card.rarity >= Card.Rarity.RARE
				upgraded_cards += int(card.upgraded)
			all_choices_unique = all_choices_unique and ids.size() == choices.size()
			high_rarity_sets += int(has_high_rarity)
			max_miss_streak = maxi(max_miss_streak, reward.run_stats.card_reward_miss_streak)

		var total_cards := CHAPTER_REWARD_BATCHES * reward.run_stats.card_rewards
		var common_share := float(rarity_counts[Card.Rarity.COMMON]) / total_cards
		var high_share := float(rarity_counts[Card.Rarity.RARE] + rarity_counts[Card.Rarity.MYTHIC]) / total_cards
		var upgrade_share := float(upgraded_cards) / total_cards
		results[chapter] = {
			"common_share": common_share,
			"high_share": high_share,
			"upgrade_share": upgrade_share,
			"mythic_count": rarity_counts[Card.Rarity.MYTHIC],
			"high_rarity_sets": high_rarity_sets,
			"max_miss_streak": max_miss_streak,
		}
		_check(all_choices_complete, "chapter %s always returns the configured reward count" % chapter)
		_check(all_choices_unique, "chapter %s reward choices always have unique ids" % chapter)
		_check(max_miss_streak <= BattleReward.RARE_PITY_HARD_LIMIT, "chapter %s never exceeds the rare pity limit" % chapter)
		print(
			"CARD_REWARD_SIM chapter=%s common=%.3f high=%.3f upgraded=%.3f high_sets=%s max_miss=%s"
			% [chapter, common_share, high_share, upgrade_share, high_rarity_sets, max_miss_streak]
		)
	return results


func _check_chapter_curve(results: Dictionary) -> void:
	if results.size() != 3:
		_check(false, "all three chapter simulations complete")
		return
	var chapter_one: Dictionary = results[1]
	var chapter_two: Dictionary = results[2]
	var chapter_three: Dictionary = results[3]
	_check(int(chapter_one["mythic_count"]) == 0, "chapter one never offers mythic cards")
	_check(float(chapter_one["common_share"]) > float(chapter_two["common_share"]), "common rewards decrease from chapter one to two")
	_check(float(chapter_two["common_share"]) > float(chapter_three["common_share"]), "common rewards decrease from chapter two to three")
	_check(float(chapter_one["high_share"]) < float(chapter_two["high_share"]), "rare rewards increase from chapter one to two")
	_check(float(chapter_two["high_share"]) < float(chapter_three["high_share"]), "rare rewards increase from chapter two to three")
	_check(float(chapter_one["upgrade_share"]) == 0.0, "chapter one rewards are not pre-upgraded")
	_check(float(chapter_two["upgrade_share"]) >= 0.075, "chapter two has a meaningful upgraded-card supply")
	_check(float(chapter_three["upgrade_share"]) > float(chapter_two["upgrade_share"]), "upgraded-card supply increases in chapter three")


func _check_hard_pity(reward: BattleReward) -> void:
	RNG.instance.seed = BASE_SEED + 10
	reward.run_stats.apply_chapter_card_weights(1)
	reward.card_reward_tier = BattleReward.CardRewardTier.NORMAL
	for _sample in 80:
		reward.run_stats.card_reward_miss_streak = BattleReward.RARE_PITY_HARD_LIMIT
		var choices := reward._generate_card_reward_choices()
		_check(choices.any(func(card: Card): return card.rarity >= Card.Rarity.RARE), "hard pity always produces a rare reward")
		_check(reward.run_stats.card_reward_miss_streak == 0, "hard pity reward always resets its counter")


func _check_archetype_sampling(reward: BattleReward) -> void:
	for route_index in ARCHETYPE_TAGS.size():
		var route: String = ARCHETYPE_TAGS.keys()[route_index]
		var tag: String = ARCHETYPE_TAGS[route]
		reward.character_stats.deck = CardPile.new()
		for support_index in 5:
			var support := Card.new()
			support.id = "%s_support_%s" % [route, support_index]
			support.mechanic_tags = PackedStringArray([tag])
			reward.character_stats.deck.add_card(support)

		var matching_candidate := Card.new()
		matching_candidate.id = "%s_candidate" % route
		matching_candidate.mechanic_tags = PackedStringArray([tag])
		var candidates: Array[Card] = [matching_candidate]
		for neutral_index in 3:
			var neutral := Card.new()
			neutral.id = "neutral_%s_%s" % [route_index, neutral_index]
			candidates.append(neutral)

		RNG.instance.seed = BASE_SEED + 100 + route_index
		var matching_picks := 0
		for _sample in SYNERGY_SAMPLES:
			matching_picks += int(reward._pick_synergy_weighted_card(candidates) == matching_candidate)
		var matching_share := float(matching_picks) / SYNERGY_SAMPLES
		print("CARD_REWARD_SYNERGY route=%s share=%.3f" % [route, matching_share])
		_check(matching_share > 0.34, "%s route receives a visible reward uplift" % route)
		_check(matching_share < 0.44, "%s route reward uplift stays within its balance cap" % route)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CARD_REWARD_SIMULATION_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CARD_REWARD_SIMULATION_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
