class_name RetainedManaBossRelic
extends Relic

@export var max_retained := 2

var relic_ui: RelicUI
var stored_mana := 0


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)
	if not Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.connect(_on_player_turn_ended)


func activate_relic(_owner: RelicUI) -> void:
	stored_mana = 0


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
	if Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.disconnect(_on_player_turn_ended)
	stored_mana = 0


func _on_player_turn_ended() -> void:
	var character := _get_character()
	if not character:
		stored_mana = 0
		return
	stored_mana = mini(maxi(character.mana, 0), maxi(max_retained, 0))


func _on_player_turn_started() -> void:
	var character := _get_character()
	if not character or stored_mana <= 0:
		stored_mana = 0
		return
	character.mana += stored_mana
	stored_mana = 0
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()


func _get_character() -> CharacterStats:
	if not relic_ui or not is_instance_valid(relic_ui):
		return null
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats is CharacterStats:
		return null
	return player.stats as CharacterStats
