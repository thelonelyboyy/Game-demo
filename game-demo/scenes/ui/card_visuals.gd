class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var art_frame: Panel = $ArtFrame
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var card_name: Label = $Name
@onready var description: RichTextLabel = $Description
@onready var element_tag: Label = $ElementTag

enum VisualState { NORMAL, HOVER, DRAG }

var visual_state: int = VisualState.NORMAL


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
		_apply_empty_style()
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
	_apply_card_style(card, visual_state)


func apply_normal_style() -> void:
	visual_state = VisualState.NORMAL
	if card:
		_apply_card_style(card, visual_state)
	else:
		_apply_empty_style()


func apply_hover_style() -> void:
	visual_state = VisualState.HOVER
	if card:
		_apply_card_style(card, visual_state)


func apply_drag_style() -> void:
	visual_state = VisualState.DRAG
	if card:
		_apply_card_style(card, visual_state)


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


func _apply_empty_style() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("22201a")
	card_style.border_color = Color("6d6044")
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	panel.set("theme_override_styles/panel", card_style)


func _apply_card_style(card_to_style: Card, state: int = VisualState.NORMAL) -> void:
	var profession_color: Color = card_to_style.get_profession_color()
	var rarity_color: Color = Card.RARITY_COLORS.get(card_to_style.rarity, Color.WHITE)
	var border_width := 3
	var paper_color := _get_card_paper_color(profession_color, state)
	var border_color := rarity_color.lerp(profession_color, 0.22)
	var shadow_color := Color(0, 0, 0, 0.42)
	var shadow_size := 8

	if card_to_style.rarity == Card.Rarity.RARE:
		border_width = 4
	elif card_to_style.rarity == Card.Rarity.MYTHIC:
		border_width = 5
		paper_color = _get_mythic_paper_color(state)
		shadow_color = Color(0.55, 0.25, 0.08, 0.42)

	if state == VisualState.HOVER:
		border_color = rarity_color.lightened(0.18)
		shadow_color = rarity_color
		shadow_color.a = 0.34
		shadow_size = 14
	elif state == VisualState.DRAG:
		border_color = rarity_color.lightened(0.28)
		shadow_color = rarity_color
		shadow_color.a = 0.48
		shadow_size = 18

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = paper_color
	card_style.border_color = border_color
	card_style.border_width_left = border_width
	card_style.border_width_top = border_width
	card_style.border_width_right = border_width
	card_style.border_width_bottom = border_width
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.shadow_color = shadow_color
	card_style.shadow_size = shadow_size
	panel.set("theme_override_styles/panel", card_style)

	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color("2d281d").lerp(profession_color, 0.20)
	art_style.border_color = rarity_color.darkened(0.18)
	art_style.border_width_left = 2
	art_style.border_width_top = 2
	art_style.border_width_right = 2
	art_style.border_width_bottom = 2
	art_style.corner_radius_top_left = 4
	art_style.corner_radius_top_right = 4
	art_style.corner_radius_bottom_left = 4
	art_style.corner_radius_bottom_right = 4
	art_frame.set("theme_override_styles/panel", art_style)

	card_name.add_theme_color_override("font_color", _get_text_color(card_to_style.rarity))
	description.add_theme_color_override("default_color", _get_text_color(card_to_style.rarity).darkened(0.15))
	rarity.tooltip_text = card_to_style.get_rarity_name()


func _get_card_paper_color(profession_color: Color, state: int) -> Color:
	var base := Color("d8c89b").lerp(profession_color, 0.10)
	match state:
		VisualState.HOVER:
			return Color("eadbac").lerp(profession_color, 0.12)
		VisualState.DRAG:
			return Color("f0dda6").lerp(profession_color, 0.16)
		_:
			return base


func _get_mythic_paper_color(state: int) -> Color:
	match state:
		VisualState.HOVER:
			return Color("54301f")
		VisualState.DRAG:
			return Color("65381f")
		_:
			return Color("422719")


func _get_text_color(rarity_value: Card.Rarity) -> Color:
	if rarity_value == Card.Rarity.MYTHIC:
		return Color("f4d7a1")
	return Color("21180d")


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
