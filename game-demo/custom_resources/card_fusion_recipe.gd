class_name CardFusionRecipe
extends Resource

@export var first_card_id: String
@export var second_card_id: String
@export var result_card: Card
@export var result_name: String
@export var result_cost := -99


func matches(card_a: Card, card_b: Card) -> bool:
	if not card_a or not card_b:
		return false

	return (
		card_a.id == first_card_id and card_b.id == second_card_id
	) or (
		card_a.id == second_card_id and card_b.id == first_card_id
	)


func create_result(card_a: Card, card_b: Card) -> Card:
	if result_card:
		return result_card.duplicate(true) as Card
	if not card_a is CultivationCard or not card_b is CultivationCard:
		return null

	var first := card_a as CultivationCard
	var second := card_b as CultivationCard
	var result := first.duplicate(true) as CultivationCard
	if not result:
		return null

	var sorted_ids := [first.id, second.id]
	sorted_ids.sort()
	result.id = "fusion_%s_%s" % sorted_ids
	result.display_name = result_name if not result_name.is_empty() else "%s·%s" % [first.get_display_name(), second.get_display_name()]
	result.cost = result_cost if result_cost >= -1 else _get_automatic_cost(first, second)
	result.rarity = maxi(Card.Rarity.UNCOMMON, maxi(first.rarity, second.rarity))
	result.type = Card.Type.ATTACK if first.type == Card.Type.ATTACK or second.type == Card.Type.ATTACK else Card.Type.SKILL
	result.target = _merge_target(first.target, second.target)
	result.exhausts = first.exhausts and second.exhausts
	result.upgrade_type = Card.UpgradeType.STAT_BOOST
	result.upgraded = first.upgraded and second.upgraded
	result.fusion_level = 0
	result.element = first.element if first.element != Card.Element.NONE else second.element
	result.profession = first.get_profession() if first.get_profession() != Card.Profession.COMMON else second.get_profession()
	result.configured_effects = _merge_effects(first.configured_effects, second.configured_effects)
	result.discard_trigger_effects = _merge_effects(first.discard_trigger_effects, second.discard_trigger_effects)
	result.exhaust_trigger_effects = _merge_effects(first.exhaust_trigger_effects, second.exhaust_trigger_effects)
	result.mechanic_tags = _merge_tags(first.mechanic_tags, second.mechanic_tags, result.exhausts)
	return result


func _get_automatic_cost(first: Card, second: Card) -> int:
	if first.is_x_cost() or second.is_x_cost():
		return -1
	return maxi(0, ceili(float(first.cost + second.cost) * 0.65))


func _merge_target(first: Card.Target, second: Card.Target) -> Card.Target:
	if first == Card.Target.ALL_ENEMIES or second == Card.Target.ALL_ENEMIES:
		return Card.Target.ALL_ENEMIES
	if first == Card.Target.SINGLE_ENEMY or second == Card.Target.SINGLE_ENEMY:
		return Card.Target.SINGLE_ENEMY
	if first == Card.Target.EVERYONE or second == Card.Target.EVERYONE:
		return Card.Target.EVERYONE
	return Card.Target.SELF


func _merge_effects(first: Array[Resource], second: Array[Resource]) -> Array[Resource]:
	var merged: Array[Resource] = []
	for effect: Resource in first + second:
		if effect:
			merged.append(effect.duplicate(true))
	return merged


func _merge_tags(first: PackedStringArray, second: PackedStringArray, exhausts: bool) -> PackedStringArray:
	var merged := PackedStringArray(["合炼"])
	for tag: String in first + second:
		if tag == Card.CONSUMABLE_MECHANIC_TAG and not exhausts:
			continue
		if not merged.has(tag):
			merged.append(tag)
	return merged
