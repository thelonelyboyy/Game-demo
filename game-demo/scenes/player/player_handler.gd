# Player turn order:
# 1. START_OF_TURN Relics 
# 2. START_OF_TURN Statuses
# 3. Draw Hand
# 4. End Turn 
# 5. END_OF_TURN Relics 
# 6. END_OF_TURN Statuses
# 7. Discard Hand
class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25

@export var relics: RelicHandler
@export var player: Player
@export var hand: Hand

var character: CharacterStats
var battle_running := false
var draw_tween: Tween
var discard_tween: Tween


func _ready() -> void:
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)


func start_battle(char_stats: CharacterStats) -> void:
	if not char_stats or not char_stats.deck:
		return

	character = char_stats
	character.draw_pile = character.deck.custom_duplicate()
	character.draw_pile.bind_cards_to_owner(character)
	character.draw_pile.shuffle()
	character.discard = CardPile.new()
	character.discard.bind_cards_to_owner(character)
	battle_running = true

	if relics and not relics.relics_activated.is_connected(_on_relics_activated):
		relics.relics_activated.connect(_on_relics_activated)
	if player and player.status_handler and not player.status_handler.statuses_applied.is_connected(_on_statuses_applied):
		player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()


func start_turn() -> void:
	if not _can_use_card_piles():
		return

	character.block = 0
	character.reset_mana()
	Events.player_turn_started.emit()
	if relics:
		relics.activate_relics_by_type(Relic.Type.START_OF_TURN)


func end_turn() -> void:
	if not battle_running:
		return

	if hand:
		hand.disable_hand()
	if relics:
		relics.activate_relics_by_type(Relic.Type.END_OF_TURN)


func draw_card(is_start_of_turn_draw := false) -> void:
	if not _can_use_card_piles() or not hand:
		return

	reshuffle_deck_from_discard()
	if not character.draw_pile or character.draw_pile.empty():
		return

	var card := character.draw_pile.draw_card()
	if not card:
		return
	hand.add_card(card)
	Events.card_drawn.emit(card)
	if not is_start_of_turn_draw:
		Events.card_extra_drawn.emit(card)
	reshuffle_deck_from_discard()


func draw_cards(amount: int, is_start_of_turn_draw: bool = false) -> void:
	if not _can_use_card_piles() or amount <= 0:
		if is_start_of_turn_draw and battle_running:
			Events.player_hand_drawn.emit()
		return

	draw_tween = create_tween()
	for i in range(amount):
		draw_tween.tween_callback(draw_card.bind(is_start_of_turn_draw))
		draw_tween.tween_interval(HAND_DRAW_INTERVAL)
	
	draw_tween.finished.connect(_on_draw_tween_finished.bind(is_start_of_turn_draw))


func discard_cards() -> void:
	if not _can_use_card_piles() or not hand:
		return

	if hand.get_child_count() == 0:
		character.reset_temporary_card_costs()
		Events.player_hand_discarded.emit()
		return

	discard_tween = create_tween()
	for card_ui: CardUI in hand.get_children():
		discard_tween.tween_callback(character.discard.add_card.bind(card_ui.card))
		discard_tween.tween_callback(hand.discard_card.bind(card_ui))
		discard_tween.tween_interval(HAND_DISCARD_INTERVAL)
	
	discard_tween.finished.connect(_on_discard_tween_finished)


func reshuffle_deck_from_discard() -> void:
	if not _can_use_card_piles():
		return

	if not character.draw_pile.empty():
		return

	var reshuffled_count := 0
	while not character.discard.empty():
		character.draw_pile.add_card(character.discard.draw_card())
		reshuffled_count += 1

	character.draw_pile.shuffle()
	if reshuffled_count > 0:
		Events.deck_reshuffled.emit(reshuffled_count)


func _on_card_played(card: Card) -> void:
	if not battle_running or not character or not character.discard or not card:
		return
	if card.exhausts or card.type == Card.Type.POWER:
		return
	
	character.discard.add_card(card)


func _on_statuses_applied(type: Status.Type) -> void:
	if not battle_running or not character:
		return

	match type:
		Status.Type.START_OF_TURN:
			draw_cards(character.cards_per_turn, true)
		Status.Type.END_OF_TURN:
			discard_cards()


func _on_relics_activated(type: Relic.Type) -> void:
	if not battle_running or not player or not player.status_handler:
		return

	match type:
		Relic.Type.START_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
		Relic.Type.END_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_draw_tween_finished(is_start_of_turn_draw: bool) -> void:
	if not battle_running:
		return
	if hand:
		hand.enable_hand()
	if is_start_of_turn_draw:
		Events.player_hand_drawn.emit()


func _on_discard_tween_finished() -> void:
	if not battle_running:
		return
	character.reset_temporary_card_costs()
	Events.player_hand_discarded.emit()


func _exit_tree() -> void:
	battle_running = false
	if draw_tween and draw_tween.is_running():
		draw_tween.kill()
	if discard_tween and discard_tween.is_running():
		discard_tween.kill()
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if relics and relics.relics_activated.is_connected(_on_relics_activated):
		relics.relics_activated.disconnect(_on_relics_activated)
	if player and player.status_handler and player.status_handler.statuses_applied.is_connected(_on_statuses_applied):
		player.status_handler.statuses_applied.disconnect(_on_statuses_applied)


func _can_use_card_piles() -> bool:
	return (
		battle_running
		and character != null
		and character.draw_pile != null
		and character.discard != null
	)
