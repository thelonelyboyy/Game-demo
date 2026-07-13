class_name UnspentManaBlockRelic
extends Relic

@export var block_per_mana := 3
@export var maximum_mana_counted := 3


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return
	var character := player.stats as CharacterStats
	var counted_mana := mini(maxi(character.mana, 0), maxi(maximum_mana_counted, 0))
	if counted_mana <= 0:
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = counted_mana * block_per_mana
	var targets: Array[Node] = [player]
	block_effect.execute(targets)
	owner.flash()
