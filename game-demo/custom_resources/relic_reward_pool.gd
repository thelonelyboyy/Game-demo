class_name RelicRewardPool
extends Resource

enum RewardContext {STANDARD, ELITE, TREASURE, BOSS, SHOP}

const CONTEXT_WEIGHTS := {
	RewardContext.STANDARD: [
		[70.0, 25.0, 5.0, 0.0],
		[55.0, 32.0, 13.0, 0.0],
		[42.0, 38.0, 20.0, 0.0],
	],
	RewardContext.ELITE: [
		[55.0, 35.0, 10.0, 0.0],
		[40.0, 42.0, 18.0, 0.0],
		[30.0, 42.0, 28.0, 0.0],
	],
	RewardContext.TREASURE: [
		[45.0, 40.0, 15.0, 0.0],
		[32.0, 43.0, 25.0, 0.0],
		[22.0, 43.0, 35.0, 0.0],
	],
	RewardContext.BOSS: [
		[0.0, 20.0, 55.0, 25.0],
		[0.0, 15.0, 55.0, 30.0],
		[0.0, 10.0, 50.0, 40.0],
	],
	RewardContext.SHOP: [
		[58.0, 34.0, 8.0, 0.0],
		[48.0, 38.0, 14.0, 0.0],
		[38.0, 42.0, 20.0, 0.0],
	],
}

@export var relics: Array[Relic] = []


func get_random_available(
	char_stats: CharacterStats,
	relic_handler: RelicHandler,
	chapter := 1,
	context := RewardContext.STANDARD
) -> Relic:
	var choices := get_random_available_choices(char_stats, relic_handler, 1, chapter, context)
	if choices.is_empty():
		return null

	return choices[0]


func get_random_available_choices(
	char_stats: CharacterStats,
	relic_handler: RelicHandler,
	count := 2,
	chapter := 1,
	context := RewardContext.STANDARD
) -> Array[Relic]:
	var available_relics: Array[Relic] = []
	for relic: Relic in relics:
		if not relic:
			continue

		var can_appear: bool = relic.can_appear_as_reward(char_stats)
		var already_had_it: bool = relic_handler and relic_handler.has_relic(relic.id)
		if can_appear and not already_had_it:
			available_relics.append(relic)

	if available_relics.is_empty():
		return []

	var choices: Array[Relic] = []
	for _i in mini(count, available_relics.size()):
		var picked := _pick_weighted(available_relics, chapter, context)
		if not picked:
			break
		choices.append(picked)
		available_relics.erase(picked)
	return choices


func _pick_weighted(available_relics: Array[Relic], chapter: int, context: int) -> Relic:
	var context_key := context if CONTEXT_WEIGHTS.has(context) else RewardContext.STANDARD
	var chapter_index := clampi(chapter, 1, 3) - 1
	var weights: Array = CONTEXT_WEIGHTS[context_key][chapter_index]
	var candidates_by_rarity := {}
	var total_weight := 0.0

	for relic: Relic in available_relics:
		if not candidates_by_rarity.has(relic.rarity):
			candidates_by_rarity[relic.rarity] = []
		candidates_by_rarity[relic.rarity].append(relic)

	for rarity in candidates_by_rarity:
		if rarity < weights.size():
			total_weight += float(weights[rarity])

	if total_weight <= 0.0:
		return RNG.array_pick_random(available_relics) as Relic

	var roll := RNG.instance.randf_range(0.0, total_weight)
	var fallback: Relic
	for rarity in candidates_by_rarity:
		if rarity >= weights.size():
			continue
		var rarity_weight := float(weights[rarity])
		if rarity_weight <= 0.0:
			continue
		fallback = RNG.array_pick_random(candidates_by_rarity[rarity]) as Relic
		roll -= rarity_weight
		if roll <= 0.0:
			return fallback

	return fallback
