class_name SelfDamageRelic
extends Relic

enum RewardMode {BLOCK, MANA, DRAW, HEAL, STATUS}

@export var reward_mode := RewardMode.BLOCK
@export var amount := 1
@export var minimum_damage := 1
@export var status: Status
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.connect(_on_player_self_damaged)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_self_damaged.is_connected(_on_player_self_damaged):
		Events.player_self_damaged.disconnect(_on_player_self_damaged)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_player_self_damaged(damage: int) -> void:
	if damage < minimum_damage:
		return
	if once_per_turn and triggered_this_turn:
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return

	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	match reward_mode:
		RewardMode.BLOCK:
			var block_effect := BlockEffect.new()
			block_effect.amount = amount
			block_effect.execute([player])
		RewardMode.MANA:
			if player.stats is CharacterStats:
				(player.stats as CharacterStats).mana += amount
		RewardMode.DRAW:
			var draw_effect := CardDrawEffect.new()
			draw_effect.cards_to_draw = amount
			draw_effect.execute([player])
		RewardMode.HEAL:
			player.stats.heal(amount)
		RewardMode.STATUS:
			if status:
				var status_copy := status.duplicate() as Status
				status_copy.stacks = amount
				var status_effect := StatusEffect.new()
				status_effect.status = status_copy
				status_effect.execute([player])

	triggered_this_turn = true
	relic_ui.flash()
