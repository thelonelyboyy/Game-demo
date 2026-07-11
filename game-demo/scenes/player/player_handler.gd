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
const DEMONIC_HERO_SKILL_SELF_DAMAGE := 2
const DEMONIC_HERO_SKILL_FINAL_SELF_DAMAGE := 1

@export var relics: RelicHandler
@export var player: Player
@export var hand: Hand

var character: CharacterStats
var battle_running := false
var player_actions_enabled := false
# 英雄技能每回合限一次，回合开始重置。
var _hero_skill_used_this_turn := false
var _hand_full_notice_emitted_this_turn := false
var draw_tween: Tween
var discard_tween: Tween


func _ready() -> void:
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.hero_skill_requested.is_connected(use_hero_skill):
		Events.hero_skill_requested.connect(use_hero_skill)


func start_battle(char_stats: CharacterStats) -> void:
	if not char_stats or not char_stats.deck:
		return

	character = char_stats
	character.draw_pile = character.deck.custom_duplicate()
	character.draw_pile.bind_cards_to_owner(character)
	character.draw_pile.shuffle()
	character.draw_pile.move_innate_cards_to_top()
	character.discard = CardPile.new()
	character.discard.bind_cards_to_owner(character)
	battle_running = true
	player_actions_enabled = false

	if relics and not relics.relics_activated.is_connected(_on_relics_activated):
		relics.relics_activated.connect(_on_relics_activated)
	if player and player.status_handler and not player.status_handler.statuses_applied.is_connected(_on_statuses_applied):
		player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()


func start_turn() -> void:
	if not _can_use_card_piles():
		return

	player_actions_enabled = false
	_hero_skill_used_this_turn = false
	_hand_full_notice_emitted_this_turn = false
	character.block = 0
	character.reset_mana()
	Events.player_turn_started.emit()
	if relics:
		relics.activate_relics_by_type(Relic.Type.START_OF_TURN)


func end_turn() -> void:
	if not battle_running:
		return

	player_actions_enabled = false
	if hand:
		hand.disable_hand()
	if relics:
		relics.activate_relics_by_type(Relic.Type.END_OF_TURN)


func can_use_hero_skill() -> bool:
	return (
		battle_running
		and player_actions_enabled
		and not _hero_skill_used_this_turn
		and _is_demonic_character()
		and character != null
		and player != null
		and player.stats != null
		and player.stats.health > 0
		and hand != null
		and not hand.is_full()
	)


func use_hero_skill(origin_global := Vector2.ZERO) -> void:
	if not can_use_hero_skill():
		return

	_hero_skill_used_this_turn = true
	# 代价走真实伤害结算：会被护体吸收并吃伤害修正，致死沿用角色受伤时序。
	player.take_damage(_get_hero_skill_self_damage(), Modifier.Type.DMG_TAKEN)
	if not battle_running:
		return

	var generated_card := _create_demonic_hero_skill_card()
	if not generated_card:
		return

	hand.add_card(generated_card, false, origin_global)
	if player_actions_enabled:
		hand.enable_hand()
	Events.card_drawn.emit(generated_card)
	Events.hero_skill_used.emit()


func draw_card(is_start_of_turn_draw := false) -> void:
	if not _can_use_card_piles() or not hand:
		return
	if hand.is_full():
		_notify_hand_full()
		return

	reshuffle_deck_from_discard()
	if not character.draw_pile or character.draw_pile.empty():
		return

	var card := character.draw_pile.draw_card()
	if not card:
		return
	if not hand.add_card(card):
		character.draw_pile.add_card_to_top(card)
		_notify_hand_full()
		return
	Events.card_drawn.emit(card)
	if not is_start_of_turn_draw:
		Events.card_extra_drawn.emit(card)
	reshuffle_deck_from_discard()


func draw_cards(amount: int, is_start_of_turn_draw: bool = false) -> void:
	if not _can_use_card_piles() or amount <= 0:
		if is_start_of_turn_draw and battle_running:
			player_actions_enabled = true
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

	var cards_to_clean_up := 0
	discard_tween = create_tween()
	for card_ui: CardUI in hand.get_children():
		var card := card_ui.card
		if card and card.is_temporary_card():
			cards_to_clean_up += 1
			discard_tween.tween_callback(remove_card_from_hand.bind(card_ui))
		elif card and card.is_ethereal_card():
			cards_to_clean_up += 1
			discard_tween.tween_callback(exhaust_card_from_hand.bind(card_ui))
		elif card and card.is_retained_card():
			_reset_retained_card_cost(card_ui)
		else:
			cards_to_clean_up += 1
			discard_tween.tween_callback(discard_card_from_hand.bind(card_ui))
		discard_tween.tween_interval(HAND_DISCARD_INTERVAL)
	
	if cards_to_clean_up == 0:
		discard_tween.kill()
		_on_discard_tween_finished()
		return

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
	if card.is_temporary_card():
		return
	if card.is_consumable_card() or card.type == Card.Type.POWER:
		if card.is_consumable_card():
			_trigger_card_lifecycle(card, Card.LifecycleTrigger.EXHAUSTED)
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
		player_actions_enabled = true
		Events.player_hand_drawn.emit()


func _on_discard_tween_finished() -> void:
	if not battle_running:
		return
	_reset_retained_hand_costs()
	character.reset_temporary_card_costs()
	Events.player_hand_discarded.emit()


func _exit_tree() -> void:
	battle_running = false
	player_actions_enabled = false
	if draw_tween and draw_tween.is_running():
		draw_tween.kill()
	if discard_tween and discard_tween.is_running():
		discard_tween.kill()
	if Events.card_played.is_connected(_on_card_played):
		Events.card_played.disconnect(_on_card_played)
	if Events.hero_skill_requested.is_connected(use_hero_skill):
		Events.hero_skill_requested.disconnect(use_hero_skill)
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


func add_discovered_cards_to_hand(cards: Array[Card], origin_global := Vector2.ZERO) -> void:
	if not battle_running or not hand:
		return

	var overflow_count := 0
	for card: Card in cards:
		if not card:
			continue
		card.temporary = false
		card.bind_spirit_root_owner(character)
		if hand.add_card(card, false, origin_global):
			Events.card_drawn.emit(card)
		else:
			card.reset_temporary_cost()
			character.discard.add_card(card)
			overflow_count += 1
	if overflow_count > 0:
		Events.ui_notice_requested.emit("手牌已满，%s 张发现牌进入弃牌堆" % overflow_count)
	if player_actions_enabled:
		hand.enable_hand()


func _notify_hand_full() -> void:
	if _hand_full_notice_emitted_this_turn:
		return
	_hand_full_notice_emitted_this_turn = true
	Events.ui_notice_requested.emit("手牌已满（最多 %s 张）" % Hand.MAX_HAND_SIZE)


func discard_card_from_hand(card_ui: CardUI, play_discard_animation := true) -> void:
	if not card_ui or not is_instance_valid(card_ui):
		return
	var card := card_ui.card
	if card:
		_trigger_card_lifecycle(card, Card.LifecycleTrigger.DISCARDED)
		character.discard.add_card(card)
	if hand:
		hand.discard_card(card_ui, play_discard_animation)


func exhaust_card_from_hand(card_ui: CardUI, trigger_effects := true) -> void:
	if not card_ui or not is_instance_valid(card_ui):
		return
	var card := card_ui.card
	if card and trigger_effects:
		_trigger_card_lifecycle(card, Card.LifecycleTrigger.EXHAUSTED)
	if hand:
		hand.discard_card(card_ui, false)


func remove_card_from_hand(card_ui: CardUI) -> void:
	if not card_ui or not is_instance_valid(card_ui):
		return
	if hand:
		hand.discard_card(card_ui, false)


func _trigger_card_lifecycle(card: Card, trigger: Card.LifecycleTrigger) -> void:
	if not card:
		return
	var targets: Array[Node] = []
	if player:
		targets.append(player)
	card.handle_lifecycle_trigger(trigger, targets, player.modifier_handler if player else null)


func _reset_retained_card_cost(card_ui: CardUI) -> void:
	if not card_ui or not card_ui.card:
		return
	card_ui.card.reset_temporary_cost()
	card_ui.card = card_ui.card


func _reset_retained_hand_costs() -> void:
	if not hand:
		return
	for card_ui: CardUI in hand.get_children():
		_reset_retained_card_cost(card_ui)


func _create_demonic_hero_skill_card() -> Card:
	if not character or not character.draftable_cards:
		return null

	var candidates: Array[Card] = []
	for card: Card in character.draftable_cards.cards:
		if _is_valid_demonic_hero_skill_candidate(card):
			candidates.append(card)

	var picked := RNG.array_pick_random(candidates) as Card
	if not picked:
		return null

	var generated := picked.duplicate(true) as Card
	generated.temporary = true
	generated.ensure_mechanic_tag(Card.TEMPORARY_MECHANIC_TAG)
	if character.hero_skill_stage >= 2:
		generated.upgrade()
	if character.hero_skill_stage >= 3:
		generated.reduce_cost_for_turn(1)
	generated.bind_spirit_root_owner(character)
	return generated


func _get_hero_skill_self_damage() -> int:
	if character and character.hero_skill_stage >= 3:
		return DEMONIC_HERO_SKILL_FINAL_SELF_DAMAGE
	return DEMONIC_HERO_SKILL_SELF_DAMAGE


func _is_valid_demonic_hero_skill_candidate(card: Card) -> bool:
	if not card:
		return false
	if card.get_profession() != Card.Profession.DEMONIC:
		return false
	if card.type == Card.Type.ATTACK:
		return false
	if _is_basic_defense_card(card):
		return false
	return true


func _is_basic_defense_card(card: Card) -> bool:
	return (
		card.id == "defend"
		or card.id == "demon_defend"
		or card.id.ends_with("_defend")
		or card.get_display_name() == "防御"
	)


func _is_demonic_character() -> bool:
	if not character:
		return false
	if character.character_name == "魔修" or character.battle_anim_id == "demonic_cultivator":
		return true
	var paths := [
		character.resource_path,
		character.starting_deck.resource_path if character.starting_deck else "",
		character.draftable_cards.resource_path if character.draftable_cards else "",
	]
	return ("%s %s %s" % [paths[0], paths[1], paths[2]]).contains("demonic_cultivator")
