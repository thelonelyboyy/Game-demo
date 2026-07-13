class_name ManaSealStatus
extends Status

@export var mana_loss := 1


func apply_status(target: Node) -> void:
	var player := target as Player
	if player and player.stats is CharacterStats:
		(player.stats as CharacterStats).mana = maxi(0, (player.stats as CharacterStats).mana - mana_loss)
	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip % [mana_loss, duration]
