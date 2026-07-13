class_name LowHealthManaRelic
extends Relic

@export_range(0.05, 1.0) var health_ratio := 0.5
@export var mana_amount := 1


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	var character := player.stats as CharacterStats
	if float(character.health) / float(maxi(character.max_health, 1)) > health_ratio:
		return
	character.mana += mana_amount
	owner.flash()
