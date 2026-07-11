class_name SoulMarkSpentRelic
extends Relic

enum RewardMode {MANA, BLOCK, DAMAGE_ALL}

@export var reward_mode := RewardMode.MANA
@export var amount := 1
@export var scale_by_consumed := false
@export var once_per_turn := true

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.soul_mark_spent.is_connected(_on_soul_mark_spent):
		Events.soul_mark_spent.connect(_on_soul_mark_spent)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.soul_mark_spent.is_connected(_on_soul_mark_spent):
		Events.soul_mark_spent.disconnect(_on_soul_mark_spent)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_soul_mark_spent(consumed: int, _detonated: bool) -> void:
	if consumed <= 0 or (once_per_turn and triggered_this_turn):
		return
	if not relic_ui or not is_instance_valid(relic_ui):
		return

	var final_amount := amount * consumed if scale_by_consumed else amount
	match reward_mode:
		RewardMode.MANA:
			var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
			if player and player.stats is CharacterStats:
				(player.stats as CharacterStats).mana += final_amount
		RewardMode.BLOCK:
			var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
			if player:
				var block_effect := BlockEffect.new()
				block_effect.amount = final_amount
				block_effect.execute([player])
		RewardMode.DAMAGE_ALL:
			var enemies: Array[Node] = relic_ui.get_tree().get_nodes_in_group("enemies")
			if not enemies.is_empty():
				var damage_effect := DamageEffect.new()
				damage_effect.amount = final_amount
				damage_effect.receiver_modifier_type = Modifier.Type.NO_MODIFIER
				damage_effect.execute(enemies)

	triggered_this_turn = true
	relic_ui.flash()
