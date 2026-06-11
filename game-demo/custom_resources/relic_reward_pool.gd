class_name RelicRewardPool
extends Resource

@export var relics: Array[Relic] = []


func get_random_available(char_stats: CharacterStats, relic_handler: RelicHandler) -> Relic:
	var choices := get_random_available_choices(char_stats, relic_handler, 1)
	if choices.is_empty():
		return null

	return choices[0]


func get_random_available_choices(char_stats: CharacterStats, relic_handler: RelicHandler, count := 2) -> Array[Relic]:
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

	RNG.array_shuffle(available_relics)
	return available_relics.slice(0, mini(count, available_relics.size()))
