class_name CardFusionLibrary
extends Resource

@export var recipes: Array[CardFusionRecipe] = []


func can_fuse(card_a: Card, card_b: Card) -> bool:
	return get_fusion_preview(card_a, card_b) != null


func get_fusion_preview(card_a: Card, card_b: Card) -> Card:
	if not card_a or not card_b or card_a == card_b:
		return null

	if card_a.id == card_b.id:
		return _create_same_card_result(card_a, card_b)

	var recipe := get_recipe(card_a, card_b)
	if not recipe:
		return null

	var result := recipe.create_result(card_a, card_b)
	if result and recipe.result_card:
		result.element = card_a.element
	return result


func get_fusion_message(card_a: Card, card_b: Card) -> String:
	if not card_a or not card_b:
		return "请选择两张需要融合的卡牌。"

	if card_a == card_b:
		return "不能选择同一张卡牌本体。"

	if card_a.id == card_b.id:
		return "同名卡合炼：消耗两张同名卡，生成一张费用不变、主要数值提高 50% 的合炼卡。"

	if get_recipe(card_a, card_b):
		return "丹方已成：消耗两张原卡，炼成一张全新的融合卡。"

	return "暂无融合丹方。"


func fuse(card_pile: CardPile, card_a: Card, card_b: Card) -> Card:
	if not card_pile:
		return null

	var result := get_fusion_preview(card_a, card_b)
	if not result:
		return null

	if not card_pile.remove_card(card_a):
		return null
	if not card_pile.remove_card(card_b):
		card_pile.add_card(card_a)
		return null

	card_pile.add_card(result)
	return result


func get_recipe(card_a: Card, card_b: Card) -> CardFusionRecipe:
	for recipe: CardFusionRecipe in recipes:
		if recipe and recipe.matches(card_a, card_b):
			return recipe

	return null


func _create_same_card_result(card_a: Card, card_b: Card) -> Card:
	var result := card_a.duplicate(true) as Card
	if not result:
		return null

	result.fusion_level = maxi(card_a.fusion_level, card_b.fusion_level) + 1
	result._upgrade_values()
	return result
