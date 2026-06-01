class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var card_name: Label = $Name
@onready var description: RichTextLabel = $Description


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	if not card:
		cost.text = ""
		card_name.text = ""
		description.text = ""
		icon.texture = null
		rarity.modulate = Color.WHITE
		return

	cost.text = str(card.cost)
	card_name.text = card.get_display_name()
	description.text = card.get_default_tooltip().replace(
		"[center][b]%s[/b]\n" % card.get_display_name(),
		"[center]"
	)
	icon.texture = card.icon
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
