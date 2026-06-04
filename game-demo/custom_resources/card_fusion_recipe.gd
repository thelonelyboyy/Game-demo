class_name CardFusionRecipe
extends Resource

@export var first_card_id: String
@export var second_card_id: String
@export var result_card: Card


func matches(card_a: Card, card_b: Card) -> bool:
	if not card_a or not card_b:
		return false

	return (
		card_a.id == first_card_id and card_b.id == second_card_id
	) or (
		card_a.id == second_card_id and card_b.id == first_card_id
	)
