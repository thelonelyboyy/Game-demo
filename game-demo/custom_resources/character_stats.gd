class_name CharacterStats
extends Stats

const SPIRIT_ROOT_BONUS_TAG := "spirit_root_bonus"

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_cards: CardPile
@export var cards_per_turn: int
@export var max_mana: int
@export var starting_relic: Relic
@export var spirit_root: Card.Element = Card.Element.NONE
# 战斗帧动画前缀：非空时玩家在战斗里用 art/frame_animation/<id>_standby|attack|attacked 帧动画
@export var battle_anim_id: String = ""

var mana: int : set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
var spirit_root_perfect_triggered_this_turn := false
var spirit_root_wood_played_this_turn := false


func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func can_play_card(card: Card) -> bool:
	if not card:
		return false
	if card.is_x_cost():
		return true
	return mana >= card.cost


func create_instance(selected_spirit_root: Card.Element = Card.Element.NONE) -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	instance.deck = instance.starting_deck.custom_duplicate()
	instance.spirit_root = selected_spirit_root
	instance.deck.bind_cards_to_owner(instance)
	instance.convert_random_starter_to_spirit_root()
	instance.grant_spirit_root_profession_card()
	instance.refresh_spirit_root_bonus_cards()
	instance.draw_pile = CardPile.new()
	instance.draw_pile.bind_cards_to_owner(instance)
	instance.discard = CardPile.new()
	instance.discard.bind_cards_to_owner(instance)
	return instance


func has_spirit_root() -> bool:
	return spirit_root != Card.Element.NONE


func convert_random_starter_to_spirit_root() -> void:
	if not has_spirit_root() or not deck:
		return

	var candidates: Array[Card] = []
	for card: Card in deck.cards:
		if card and _is_basic_starter_card(card):
			candidates.append(card)

	var picked := RNG.array_pick_random(candidates) as Card
	if picked:
		picked.element = spirit_root


func grant_spirit_root_profession_card() -> void:
	if not has_spirit_root() or not deck or not draftable_cards:
		return

	var candidates := _get_spirit_root_profession_card_candidates(true)
	if candidates.is_empty():
		candidates = _get_spirit_root_profession_card_candidates(false)
	if candidates.is_empty():
		candidates = _get_any_spirit_root_card_candidates()
	if candidates.is_empty():
		return

	var picked := RNG.array_pick_random(candidates) as Card
	if not picked:
		return

	var bonus_card := picked.duplicate(true) as Card
	bonus_card.element = spirit_root
	if not bonus_card.mechanic_tags.has(SPIRIT_ROOT_BONUS_TAG):
		bonus_card.mechanic_tags.append(SPIRIT_ROOT_BONUS_TAG)
	deck.add_card(bonus_card)


func refresh_spirit_root_bonus_cards() -> void:
	if not has_spirit_root() or not deck:
		return

	if get_spirit_root_stage() < 1:
		return

	for card: Card in deck.cards:
		if card and card.mechanic_tags.has(SPIRIT_ROOT_BONUS_TAG):
			card.upgrade()


func count_spirit_root_cards() -> int:
	return count_cards_of_element(spirit_root)


func count_cards_of_element(element: Card.Element) -> int:
	if not has_spirit_root() or not deck:
		return 0

	var count := 0
	for card: Card in deck.cards:
		if card and card.element == element:
			count += 1
	return count


func get_spirit_root_stage() -> int:
	var count := count_spirit_root_cards()
	if count >= 7:
		return 2
	if count >= 4:
		return 1
	return 0


func get_spirit_root_stage_name() -> String:
	match get_spirit_root_stage():
		1:
			return "小成"
		2:
			return "圆满"
		_:
			return "初悟"


func is_spirit_root_complete() -> bool:
	return has_spirit_root() and get_spirit_root_stage() >= 2


func get_spirit_root_modified_value(value: int) -> int:
	if value <= 0:
		return value

	match get_spirit_root_stage():
		1:
			return ceili(value * 1.2) + 1
		2:
			return ceili(value * 1.4) + 1
		_:
			return value + 1


func should_request_spirit_root_fire_choice(card: Card) -> bool:
	return (
		card
		and has_spirit_root()
		and is_spirit_root_complete()
		and spirit_root == Card.Element.FIRE
		and card.element == Card.Element.FIRE
		and card.type == Card.Type.ATTACK
		and not spirit_root_perfect_triggered_this_turn
	)


func reset_spirit_root_turn_flags() -> void:
	spirit_root_perfect_triggered_this_turn = false
	spirit_root_wood_played_this_turn = false
	stats_changed.emit()


func mark_spirit_root_perfect_triggered() -> void:
	spirit_root_perfect_triggered_this_turn = true
	stats_changed.emit()


func mark_spirit_root_wood_played() -> void:
	spirit_root_wood_played_this_turn = true
	stats_changed.emit()


func _is_basic_starter_card(card: Card) -> bool:
	return (
		card.id == "strike"
		or card.id == "defend"
		or card.id.ends_with("_strike")
		or card.id.ends_with("_defend")
		or card.display_name == "打击"
		or card.display_name == "防御"
	)


func _get_spirit_root_profession_card_candidates(require_same_element: bool) -> Array[Card]:
	var candidates: Array[Card] = []
	var profession := _get_character_profession()
	for card: Card in draftable_cards.cards:
		if not card or card.get_profession() != profession:
			continue
		if require_same_element and card.element != spirit_root:
			continue
		candidates.append(card)
	return candidates


func _get_any_spirit_root_card_candidates() -> Array[Card]:
	var candidates: Array[Card] = []
	for card: Card in draftable_cards.cards:
		if card and card.element == spirit_root:
			candidates.append(card)
	return candidates


func _get_character_profession() -> Card.Profession:
	var path := resource_path
	if character_name.contains("体"):
		return Card.Profession.BODY
	if character_name.contains("剑"):
		return Card.Profession.SWORD
	if character_name.contains("魔"):
		return Card.Profession.DEMONIC
	if character_name.contains("兽"):
		return Card.Profession.BEASTMASTER
	if path.contains("body_cultivator"):
		return Card.Profession.BODY
	if path.contains("sword_cultivator"):
		return Card.Profession.SWORD
	if path.contains("demonic_cultivator"):
		return Card.Profession.DEMONIC
	if path.contains("beastmaster"):
		return Card.Profession.BEASTMASTER
	return Card.Profession.COMMON


func bind_all_card_piles_to_owner() -> void:
	if deck:
		deck.bind_cards_to_owner(self)
	if draw_pile:
		draw_pile.bind_cards_to_owner(self)
	if discard:
		discard.bind_cards_to_owner(self)
	refresh_spirit_root_bonus_cards()


func reset_temporary_card_costs() -> void:
	if deck:
		deck.reset_temporary_card_costs()
	if draw_pile:
		draw_pile.reset_temporary_card_costs()
	if discard:
		discard.reset_temporary_card_costs()
