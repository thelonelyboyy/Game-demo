class_name ConfiguredDiscoverEffect
extends "res://custom_resources/effects/card_effect.gd"

const CARD_DISCOVERY_REQUEST := preload("res://custom_resources/card_discovery_request.gd")

@export var card_pool: CardPile
@export var choices_to_show := 3
@export var allow_skip := false
@export_multiline var prompt := ""


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var player_handler := _get_player_handler(card, targets)
	if not player_handler or not card_pool:
		return

	var choices := _build_choices(player_handler.character)
	if choices.is_empty():
		return

	var request = CARD_DISCOVERY_REQUEST.new()
	request.source_card = card
	request.title = "发现"
	request.prompt = prompt
	request.choices = choices
	request.picks = clampi(maxi(1, get_modified_amount(card)), 1, choices.size())
	request.allow_skip = allow_skip
	request.completed.connect(_on_discovery_completed.bind(player_handler))
	Events.card_discovery_prepared.emit(request)

	if Events.card_discovery_requested.get_connections().is_empty():
		request.resolve(choices.slice(0, request.picks))
	else:
		Events.card_discovery_requested.emit(request)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	var pick_count := maxi(1, get_modified_amount(card, player_modifiers, enemy_modifiers))
	var choice_count := maxi(1, choices_to_show)
	return "发现：从固定卡池随机展示 %s 张，选择 %s 张加入手牌；这些牌会参与本场战斗的抽牌弃牌循环。" % [
		choice_count,
		pick_count,
	]


func _build_choices(owner: CharacterStats) -> Array[Card]:
	var candidates: Array[Card] = []
	for card: Card in card_pool.cards:
		if card:
			candidates.append(card)
	RNG.array_shuffle(candidates)

	var choices: Array[Card] = []
	var count := mini(maxi(1, choices_to_show), candidates.size())
	for i in range(count):
		var discovered := candidates[i].duplicate(true) as Card
		if not discovered:
			continue
		discovered.temporary = false
		discovered.remove_mechanic_tags(Card.TEMPORARY_MECHANIC_TAGS)
		discovered.reset_temporary_cost()
		if owner:
			discovered.bind_spirit_root_owner(owner)
		choices.append(discovered)
	return choices


func _on_discovery_completed(selected_cards: Array[Card], player_handler: PlayerHandler) -> void:
	if not player_handler or selected_cards.is_empty():
		return
	player_handler.add_discovered_cards_to_hand(selected_cards)


func _get_player_handler(card: CultivationCard, targets: Array[Node]) -> PlayerHandler:
	var tree := _get_tree(card, targets)
	if not tree:
		return null
	return tree.get_first_node_in_group("player_handler") as PlayerHandler
