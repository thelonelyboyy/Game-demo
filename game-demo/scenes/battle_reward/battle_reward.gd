class_name BattleReward
extends Control

const CARD_REWARDS = preload("res://scenes/ui/card_rewards.tscn")
const CARD_FUSION = preload("res://scenes/card_fusion/card_fusion.tscn")
const CARD_FUSION_LIBRARY := preload("res://fusion_recipes/card_fusion_library.tres")
const REWARD_BUTTON = preload("res://scenes/ui/reward_button.tscn")
const GOLD_ICON := preload("res://art/gold.png")
const GOLD_TEXT := "%s 灵石"
const CARD_ICON := preload("res://art/rarity.png")
const FUSION_ICON := preload("res://art/map/map_elite.png")
const FUSION_TEXT := "卡牌融合"
const CARD_TEXT := "择取新术法"
const REWARD_RARITY_ORDER := [
	Card.Rarity.COMMON,
	Card.Rarity.UNCOMMON,
	Card.Rarity.RARE,
	Card.Rarity.MYTHIC,
]

@export var run_stats: RunStats
@export var character_stats: CharacterStats
@export var relic_handler: RelicHandler

@onready var rewards: VBoxContainer = %Rewards

var card_reward_total_weight := 0.0
var card_reward_choices: Array[Card] = []
var active_card_rewards: CardRewards
var active_card_fusion: CardFusion
var card_rarity_weights := {
	Card.Rarity.COMMON: 0.0,
	Card.Rarity.UNCOMMON: 0.0,
	Card.Rarity.RARE: 0.0,
	Card.Rarity.MYTHIC: 0.0,
}


func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()


func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)


func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.auto_consume = false
	card_reward.pressed.connect(_show_card_rewards.bind(card_reward))
	rewards.add_child.call_deferred(card_reward)


func add_relic_reward(relic: Relic) -> void:
	if not relic:
		return

	var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
	relic_reward.reward_icon = relic.icon
	relic_reward.reward_text = relic.relic_name
	relic_reward.pressed.connect(_on_relic_reward_taken.bind(relic))
	rewards.add_child.call_deferred(relic_reward)


func add_card_fusion_reward() -> void:
	var fusion_reward := REWARD_BUTTON.instantiate() as RewardButton
	fusion_reward.reward_icon = FUSION_ICON
	fusion_reward.reward_text = FUSION_TEXT
	fusion_reward.auto_consume = false
	fusion_reward.pressed.connect(_show_card_fusion.bind(fusion_reward))
	rewards.add_child.call_deferred(fusion_reward)


func _show_card_rewards(card_reward: RewardButton) -> void:
	if active_card_rewards or not run_stats or not character_stats:
		return

	active_card_rewards = CARD_REWARDS.instantiate() as CardRewards
	add_child(active_card_rewards)
	active_card_rewards.card_reward_selected.connect(_on_card_reward_taken.bind(card_reward))

	if card_reward_choices.is_empty():
		card_reward_choices = _generate_card_reward_choices()

	active_card_rewards.rewards = card_reward_choices
	active_card_rewards.show()


func _generate_card_reward_choices() -> Array[Card]:
	var card_reward_array: Array[Card] = []
	var available_cards: Array[Card] = character_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		_setup_card_chances()
		var picked_card := _pick_reward_card(available_cards)
		if not picked_card:
			break

		picked_card.bind_spirit_root_owner(character_stats)
		card_reward_array.append(picked_card)
		available_cards.erase(picked_card)

	return card_reward_array


func _pick_reward_card(available_cards: Array[Card]) -> Card:
	if available_cards.is_empty():
		return null

	var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)
	for rarity in REWARD_RARITY_ORDER:
		if card_rarity_weights[rarity] > roll:
			return _get_random_available_card(available_cards, rarity)

	return _get_random_available_card(available_cards, Card.Rarity.COMMON)


func _show_card_fusion(fusion_reward: RewardButton) -> void:
	if active_card_fusion or not character_stats:
		return

	active_card_fusion = CARD_FUSION.instantiate() as CardFusion
	add_child(active_card_fusion)
	active_card_fusion.card_pile = character_stats.deck
	active_card_fusion.fusion_library = CARD_FUSION_LIBRARY
	active_card_fusion.closed.connect(_on_card_fusion_closed)
	active_card_fusion.fusion_completed.connect(_on_card_fusion_completed.bind(fusion_reward))


func _setup_card_chances() -> void:
	card_reward_total_weight = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight + run_stats.mythic_weight
	card_rarity_weights[Card.Rarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Card.Rarity.UNCOMMON] = run_stats.common_weight + run_stats.uncommon_weight
	card_rarity_weights[Card.Rarity.RARE] = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	card_rarity_weights[Card.Rarity.MYTHIC] = card_reward_total_weight


func _get_random_available_card(available_cards: Array[Card], with_rarity: Card.Rarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card):
			return card.rarity == with_rarity
	)

	if all_possible_cards.is_empty():
		all_possible_cards = available_cards.filter(
			func(card: Card):
				return card.rarity != Card.Rarity.MYTHIC
		)
	if all_possible_cards.is_empty():
		all_possible_cards = available_cards

	return RNG.array_pick_random(all_possible_cards)


func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return

	run_stats.gold += amount


func _on_card_reward_taken(card: Card, card_reward: RewardButton) -> void:
	active_card_rewards = null
	if not character_stats or not card:
		return

	character_stats.deck.add_card(card)
	card_reward_choices.clear()
	if is_instance_valid(card_reward):
		card_reward.queue_free()


func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return

	relic_handler.add_relic(relic)


func _on_card_fusion_closed() -> void:
	active_card_fusion = null


func _on_card_fusion_completed(_result: Card, fusion_reward: RewardButton) -> void:
	active_card_fusion = null
	if is_instance_valid(fusion_reward):
		fusion_reward.queue_free()


func _on_back_button_pressed() -> void:
	Events.battle_reward_exited.emit()
