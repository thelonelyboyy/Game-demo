extends Node

const BATTLE_POOL_PATH := "res://battles/battle_stats_pool.tres"
const EXPECTED_COUNTS := {
	1: [11, 3, 3],
	2: [11, 3, 3],
	3: [11, 3, 3],
}

var failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var pool := (load(BATTLE_POOL_PATH) as BattleStatsPool).duplicate(true) as BattleStatsPool
	_check(pool != null, "battle pool loads")
	if not pool:
		_finish()
		return

	var ids_by_tier_and_chapter := {}
	for chapter in range(1, 4):
		pool.setup(chapter)
		for tier in range(3):
			var battles := pool._get_all_battles_for_tier(tier)
			var expected_count: int = EXPECTED_COUNTS[chapter][tier]
			_check(battles.size() == expected_count, "chapter %s tier %s has expected encounter count" % [chapter, tier])
			var ids := {}
			for battle: BattleStats in battles:
				ids[_battle_id(battle)] = true
				_check(battle.is_available_in_chapter(chapter), "chapter-filtered battle accepts active chapter")
			ids_by_tier_and_chapter["%s:%s" % [tier, chapter]] = ids

			var first_cycle := {}
			for i in range(30):
				var picked := pool.get_random_battle_for_tier(tier)
				_check(picked != null, "chapter %s tier %s always selects an encounter" % [chapter, tier])
				if picked:
					var picked_id := _battle_id(picked)
					_check(ids.has(picked_id), "random encounter stays inside chapter pool")
					if i < expected_count:
						first_cycle[picked_id] = true
			_check(first_cycle.size() == expected_count, "chapter %s tier %s does not repeat before bag exhaustion" % [chapter, tier])

	for tier in range(3):
		for first_chapter in range(1, 4):
			for second_chapter in range(first_chapter + 1, 4):
				var first: Dictionary = ids_by_tier_and_chapter["%s:%s" % [tier, first_chapter]]
				var second: Dictionary = ids_by_tier_and_chapter["%s:%s" % [tier, second_chapter]]
				_check(_sets_are_disjoint(first, second), "tier %s encounter pools do not repeat across chapters" % tier)

	_check_chapter_card_weights()
	_check_rootless_start()
	_check_element_supply_counts()
	_check_demonic_spirit_root_choices()
	_check_dominant_deck_element()
	_check_spirit_root_bonus_card()
	await _check_card_feedback_modal()

	_finish()


func _check_chapter_card_weights() -> void:
	var stats := RunStats.new()
	var previous_common := 101.0
	var previous_high_rarity := -1.0
	for chapter in range(1, 4):
		stats.apply_chapter_card_weights(chapter)
		var total := stats.common_weight + stats.uncommon_weight + stats.rare_weight + stats.mythic_weight
		var high_rarity := stats.rare_weight + stats.mythic_weight
		_check(is_equal_approx(total, 100.0), "chapter %s card rarity weights total 100" % chapter)
		_check(stats.common_weight < previous_common, "chapter %s does not increase common reward chance" % chapter)
		_check(high_rarity > previous_high_rarity, "chapter %s increases high-rarity reward chance" % chapter)
		previous_common = stats.common_weight
		previous_high_rarity = high_rarity


func _check_rootless_start() -> void:
	var base_character := load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	var character := base_character.create_instance(Card.Element.NONE) as CharacterStats
	var stats := RunStats.new()
	stats.configure_difficulty(0)
	var initial_max_health := character.max_health
	var initial_gold := stats.gold
	var initial_deck_size := character.deck.cards.size()

	var upgraded := stats.apply_rootless_start(character)
	_check(character.rootless_path, "declining a spirit root records the rootless path")
	_check(not character.has_spirit_root(), "rootless start does not grant an element")
	_check(character.max_health == initial_max_health + RunStats.ROOTLESS_MAX_HEALTH_BONUS, "rootless start grants max health")
	_check(stats.gold == initial_gold + RunStats.ROOTLESS_GOLD_BONUS, "rootless start grants gold")
	_check(character.deck.cards.size() == initial_deck_size, "rootless start does not change deck size")
	_check(upgraded != null and upgraded.upgraded, "rootless start upgrades one starter card")

	var max_health_after_first_grant := character.max_health
	var gold_after_first_grant := stats.gold
	_check(stats.apply_rootless_start(character) == null, "rootless compensation cannot be granted twice")
	_check(character.max_health == max_health_after_first_grant, "duplicate rootless grant does not add max health")
	_check(stats.gold == gold_after_first_grant, "duplicate rootless grant does not add gold")


func _check_element_supply_counts() -> void:
	var character := load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	var distribution := character.ensure_demonic_card_element_distribution()
	for element in [Card.Element.NONE, Card.Element.METAL, Card.Element.WATER, Card.Element.FIRE]:
		_check(distribution.get(element, 0) == 22, "demonic profession pool has an equal 22-card element share")
	for element in [Card.Element.METAL, Card.Element.WATER, Card.Element.FIRE]:
		_check(character.count_draftable_cards_of_element(element) == 22, "spirit root selector reports the exact profession-card supply")
	_check(character.count_draftable_cards_of_element(Card.Element.WOOD) == 0, "demonic profession pool excludes wood cards")
	_check(character.count_draftable_cards_of_element(Card.Element.EARTH) == 0, "demonic profession pool excludes earth cards")
	_check(character.count_draftable_cards_of_element(Card.Element.NONE) == 0, "neutral cards are excluded from spirit root supply")

	var element_by_name := {}
	for card: Card in character.draftable_cards.cards:
		if not card or card.get_profession() != Card.Profession.DEMONIC:
			continue
		_check(CharacterStats.DEMONIC_DRAFT_ELEMENTS.has(card.element), "demonic profession card uses an allowed element")
		var card_name := card.get_display_name()
		if element_by_name.has(card_name):
			_check(element_by_name[card_name] == card.element, "same-name weighted cards stay in one element share")
		else:
			element_by_name[card_name] = card.element


func _check_demonic_spirit_root_choices() -> void:
	var selector := preload("res://scenes/ui/spirit_root_selector.gd").new()
	var startup := RunStartup.new()
	startup.picked_character = load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	selector.run_startup = startup
	selector._roll_spirit_roots()
	_check(selector.offered_roots == [Card.Element.METAL, Card.Element.WATER, Card.Element.FIRE], "demonic selector always offers metal, water, and fire")
	selector.free()


func _check_dominant_deck_element() -> void:
	var base_character := load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	var character := base_character.create_instance(Card.Element.FIRE) as CharacterStats
	character.deck = CardPile.new()
	for element in [Card.Element.WATER, Card.Element.FIRE, Card.Element.WATER, Card.Element.FIRE]:
		var card := Card.new()
		card.element = element
		character.deck.add_card(card)
	_check(character.get_dominant_deck_element() == Card.Element.FIRE, "selected spirit root wins a tied dominant-element count")
	for _i in 3:
		var metal_card := Card.new()
		metal_card.element = Card.Element.METAL
		character.deck.add_card(metal_card)
	_check(character.get_dominant_deck_element() == Card.Element.METAL, "largest deck element becomes the displayed spirit-root attribute")
	_check(character.get_dominant_deck_element_count() == 3, "dominant deck element reports its exact card count")


func _check_spirit_root_bonus_card() -> void:
	var base_character := load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	for element in [Card.Element.METAL, Card.Element.WATER, Card.Element.FIRE]:
		var character := base_character.create_instance(element) as CharacterStats
		var bonus_cards: Array[Card] = []
		for card: Card in character.deck.cards:
			if card and card.mechanic_tags.has(CharacterStats.SPIRIT_ROOT_BONUS_TAG):
				bonus_cards.append(card)
		_check(bonus_cards.size() == 1, "spirit root start grants one marked profession card")
		if not bonus_cards.is_empty():
			_check(bonus_cards[0].element == element, "spirit root bonus card matches the selected element")


func _check_card_feedback_modal() -> void:
	var feedback := CardChangeFeedback.new()
	add_child(feedback)
	await get_tree().process_frame
	var source_character := load("res://characters/demonic_cultivator/demonic_cultivator.tres") as CharacterStats
	var cards: Array[Card] = [source_character.draftable_cards.cards[0]]
	feedback.request_feedback("获得卡牌", cards, "卡牌已加入牌组。")
	await get_tree().process_frame
	_check(feedback.visible, "card-change feedback blocks for player confirmation")
	_check(feedback.title_label.text == "获得卡牌", "card-change feedback displays the operation title")
	_check(feedback.cards_row.get_child_count() == 1, "card-change feedback displays the affected card art")
	feedback._on_confirm_pressed()
	_check(not feedback.visible, "card-change feedback closes only after confirmation")
	feedback.queue_free()


func _battle_id(battle: BattleStats) -> String:
	return battle.resource_path.get_file().get_basename()


func _sets_are_disjoint(first: Dictionary, second: Dictionary) -> bool:
	for id in first:
		if second.has(id):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CONTENT_PROGRESSION_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CONTENT_PROGRESSION_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
