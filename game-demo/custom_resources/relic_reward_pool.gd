class_name RelicRewardPool
extends Resource

@export var relics: Array[Relic] = []


func get_random_available(char_stats: CharacterStats, relic_handler: RelicHandler) -> Relic:
	var available_relics := relics.filter(
		func(relic: Relic):
			if not relic:
				return false

			var can_appear := relic.can_appear_as_reward(char_stats)
			var already_had_it := relic_handler and relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)

	if available_relics.is_empty():
		return null

	return RNG.array_pick_random(available_relics)
