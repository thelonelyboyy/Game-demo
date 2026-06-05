class_name RelicRewardPool
extends Resource

@export var relics: Array[Relic] = []


func get_random_available(char_stats: CharacterStats, relic_handler: RelicHandler) -> Relic:
	var available_relics: Array[Relic] = []
	for relic: Relic in relics:
		if not relic:
			continue

		var can_appear: bool = relic.can_appear_as_reward(char_stats)
		var already_had_it: bool = relic_handler and relic_handler.has_relic(relic.id)
		if can_appear and not already_had_it:
			available_relics.append(relic)

	if available_relics.is_empty():
		return null

	return RNG.array_pick_random(available_relics) as Relic
