extends Node

const LIBRARY_PATH := "res://fusion_recipes/card_fusion_library.tres"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const STRIKE_PATH := "res://common_cards/strike.tres"
const DEFEND_PATH := "res://common_cards/defend.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var library := load(LIBRARY_PATH) as CardFusionLibrary
	var character := load(CHARACTER_PATH) as CharacterStats
	_check(library != null and character != null, "fusion suite resources load")
	if not library or not character:
		_finish()
		return

	_check(library.recipes.size() == 20, "fusion library contains twenty fixed recipes")
	var pair_keys := {}
	var card_by_id := {}
	for card: Card in character.draftable_cards.cards:
		if card and not card_by_id.has(card.id):
			card_by_id[card.id] = card
	for card: Card in character.starting_deck.cards:
		if card and not card_by_id.has(card.id):
			card_by_id[card.id] = card

	var dynamic_count := 0
	for recipe: CardFusionRecipe in library.recipes:
		_check(recipe != null, "fusion recipe loads")
		if not recipe:
			continue
		var ids := [recipe.first_card_id, recipe.second_card_id]
		ids.sort()
		var pair_key := "%s+%s" % ids
		_check(not pair_keys.has(pair_key), "fusion pair %s is unique" % pair_key)
		pair_keys[pair_key] = true
		if recipe.result_card:
			continue
		dynamic_count += 1
		_check(card_by_id.has(recipe.first_card_id), "%s first ingredient is draftable" % pair_key)
		_check(card_by_id.has(recipe.second_card_id), "%s second ingredient is draftable" % pair_key)
		if not card_by_id.has(recipe.first_card_id) or not card_by_id.has(recipe.second_card_id):
			continue
		_check_dynamic_recipe(library, recipe, card_by_id[recipe.first_card_id], card_by_id[recipe.second_card_id])

	_check(dynamic_count == 16, "sixteen demonic combination recipes are data-driven")
	_check_existing_manual_recipe(library)
	_check_fuse_transaction(library, card_by_id)
	_finish()


func _check_dynamic_recipe(library: CardFusionLibrary, recipe: CardFusionRecipe, first: Card, second: Card) -> void:
	var preview := library.get_fusion_preview(first, second) as CultivationCard
	_check(preview != null, "%s produces a fusion preview" % recipe.result_name)
	if not preview:
		return
	_check(preview.display_name == recipe.result_name, "%s keeps its recipe name" % recipe.result_name)
	_check(preview.id.begins_with("fusion_"), "%s receives a stable fusion id" % recipe.result_name)
	_check(preview.cost == recipe.result_cost, "%s uses its configured cost" % recipe.result_name)
	_check(preview.rarity >= Card.Rarity.UNCOMMON, "%s is at least uncommon" % recipe.result_name)
	var expected_effects := (first as CultivationCard).configured_effects.size() + (second as CultivationCard).configured_effects.size()
	_check(preview.configured_effects.size() == expected_effects, "%s merges both cards' main effects" % recipe.result_name)
	_check(preview.mechanic_tags.has("合炼"), "%s is marked as a fusion card" % recipe.result_name)
	var expected_element := first.element if first.element != Card.Element.NONE else second.element
	_check(preview.element == expected_element, "%s preserves the derived element" % recipe.result_name)
	if not preview.configured_effects.is_empty() and not (first as CultivationCard).configured_effects.is_empty():
		_check(preview.configured_effects[0] != (first as CultivationCard).configured_effects[0], "%s duplicates effect resources" % recipe.result_name)

	var reversed := library.get_fusion_preview(second, first)
	_check(reversed != null and reversed.id == preview.id, "%s recipe works in either ingredient order" % recipe.result_name)


func _check_existing_manual_recipe(library: CardFusionLibrary) -> void:
	var strike := load(STRIKE_PATH) as Card
	var defend := load(DEFEND_PATH) as Card
	var preview := library.get_fusion_preview(strike, defend)
	_check(preview != null and preview.id == "attack_guard_unity", "existing handcrafted fusion remains compatible")


func _check_fuse_transaction(library: CardFusionLibrary, card_by_id: Dictionary) -> void:
	if not card_by_id.has("demon_strike") or not card_by_id.has("demon_defend"):
		_check(false, "demonic starter fusion ingredients load")
		return
	var first := (card_by_id["demon_strike"] as Card).duplicate(true) as Card
	var second := (card_by_id["demon_defend"] as Card).duplicate(true) as Card
	var pile := CardPile.new()
	pile.add_card(first)
	pile.add_card(second)
	var result := library.fuse(pile, first, second)
	_check(result != null, "fusion transaction returns a result")
	_check(pile.cards.size() == 1 and pile.cards[0] == result, "fusion transaction consumes two cards and adds one")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("FUSION_SUITE_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("FUSION_SUITE_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("FUSION_SUITE_SMOKE: timed out")
	get_tree().quit(1)
