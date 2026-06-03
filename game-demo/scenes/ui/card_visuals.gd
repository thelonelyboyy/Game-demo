class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var card_name: Label = $Name
@onready var description: RichTextLabel = $Description
@onready var element_tag: Label = $ElementTag


func _ready() -> void:
	ignore_mouse_input(self)


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
		element_tag.hide()
		return

	cost.text = str(card.cost)
	card_name.text = card.get_display_name()
	if card.element != Card.Element.NONE:
		element_tag.text = card.get_element_name()
		element_tag.add_theme_color_override("font_color", _get_element_color(card.element))
		element_tag.show()
	else:
		element_tag.hide()
	description.text = _clean_card_text(card.get_default_tooltip())
	icon.texture = card.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rarity.modulate = Card.RARITY_COLORS[card.rarity]


func _clean_card_text(value: String) -> String:
	var text := value
	text = text.replace("[center][b]%s[/b]\n" % card.get_display_name(), "[center]")
	text = text.replace("[center]", "")
	text = text.replace("[/center]", "")
	text = text.replace("[b]", "")
	text = text.replace("[/b]", "")
	return text.strip_edges()


func ignore_mouse_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		ignore_mouse_input(child)


func _get_element_color(element: Card.Element) -> Color:
	match element:
		Card.Element.METAL:
			return Color("d9c77a")
		Card.Element.WOOD:
			return Color("79b66a")
		Card.Element.WATER:
			return Color("6fb2d8")
		Card.Element.FIRE:
			return Color("e06a3b")
		Card.Element.EARTH:
			return Color("b99358")
		_:
			return Color("eee7d2")
