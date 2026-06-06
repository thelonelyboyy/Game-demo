class_name CardPlayDamageRelic
extends Relic

enum TargetMode {ALL_ENEMIES, RANDOM_ENEMY}

@export var match_tags := PackedStringArray()
@export var match_element := Card.Element.NONE
@export var match_profession := Card.Profession.COMMON
@export var damage_amount := 2
@export var target_mode := TargetMode.ALL_ENEMIES
@export var once_per_turn := false

var relic_ui: RelicUI
var triggered_this_turn := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.connect(_on_player_turn_started)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)


func _on_player_turn_started() -> void:
	triggered_this_turn = false


func _on_card_played(card: Card) -> void:
	if once_per_turn and triggered_this_turn:
		return
	if not _matches_card(card):
		return

	var targets := _get_targets()
	if targets.is_empty():
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage_amount
	damage_effect.execute(targets)
	triggered_this_turn = true
	relic_ui.flash()


func _matches_card(card: Card) -> bool:
	if not card:
		return false
	if match_profession != Card.Profession.COMMON and card.get_profession() == match_profession:
		return true
	if match_element != Card.Element.NONE and card.element == match_element:
		return true
	for tag: String in match_tags:
		if card.mechanic_tags.has(tag):
			return true
	return match_profession == Card.Profession.COMMON and match_element == Card.Element.NONE and match_tags.is_empty()


func _get_targets() -> Array[Node]:
	var enemies: Array[Node] = relic_ui.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return []
	if target_mode == TargetMode.RANDOM_ENEMY:
		var random_targets: Array[Node] = []
		var enemy := RNG.array_pick_random(enemies) as Node
		if enemy:
			random_targets.append(enemy)
		return random_targets
	return enemies
