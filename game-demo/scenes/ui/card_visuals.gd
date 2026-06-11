class_name CardVisuals
extends Control

const CARD_STYLE := preload("res://scenes/ui/card_style.gd")

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var title_bar: Panel = $TitleBar
@onready var title_left_mark: ColorRect = $TitleBar/LeftMark
@onready var title_right_mark: ColorRect = $TitleBar/RightMark
@onready var card_name: Label = $TitleBar/Name
@onready var art_frame: Panel = $ArtFrame
@onready var icon: TextureRect = $ArtFrame/Icon
@onready var description_panel: Panel = $DescriptionPanel
@onready var description: RichTextLabel = $DescriptionPanel/Description
@onready var type_bar: Panel = $TypeBar
@onready var type_label: Label = $TypeBar/TypeLabel
@onready var cost_orb: Panel = $CostOrb
@onready var cost: Label = $CostOrb/Cost
@onready var rarity: TextureRect = $Rarity
@onready var element_tag: Label = $ElementTag
@onready var disabled_overlay: ColorRect = $DisabledOverlay

enum VisualState { NORMAL, HOVER, DRAG }

var visual_state: int = VisualState.NORMAL
var disabled_visual := false


func _ready() -> void:
	ignore_mouse_input(self)


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	if not card:
		_clear_card()
		return

	cost.text = str(card.cost)
	card_name.text = card.get_display_name()
	card_name.add_theme_font_size_override("font_size", _get_title_font_size(card_name.text))
	description.text = _format_card_text(card.get_default_tooltip())
	icon.texture = card.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
	rarity.tooltip_text = card.get_rarity_name()
	type_label.text = CARD_STYLE.new().get_card_type(card)

	if card.element != Card.Element.NONE:
		element_tag.text = card.get_element_name()
		element_tag.show()
	else:
		element_tag.hide()

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


func set_disabled_visual(value: bool) -> void:
	disabled_visual = value
	disabled_overlay.visible = disabled_visual
	icon.modulate = Color(0.72, 0.72, 0.72, 0.62) if disabled_visual else Color.WHITE
	description.modulate = Color(0.72, 0.72, 0.72, 0.86) if disabled_visual else Color.WHITE
	cost.add_theme_color_override("font_color", Color("d65a54") if disabled_visual else Color("fff0bc"))
	if card:
		_apply_card_style(card, visual_state)


func _clear_card() -> void:
	cost.text = ""
	card_name.text = ""
	description.text = ""
	type_label.text = ""
	icon.texture = null
	rarity.modulate = Color.WHITE
	element_tag.hide()
	disabled_overlay.hide()
	_apply_empty_style()


func _format_card_text(value: String) -> String:
	var text := value
	text = text.replace("[center][b]%s[/b]\n" % card.get_display_name(), "[center]")
	text = text.replace("[center]", "")
	text = text.replace("[/center]", "")
	text = text.replace("[b]", "")
	text = text.replace("[/b]", "")
	text = text.strip_edges()
	return _highlight_numbers_and_keywords(text)


func _highlight_numbers_and_keywords(value: String) -> String:
	var text := value
	var number_regex := RegEx.new()
	number_regex.compile("([0-9]+)")
	text = number_regex.sub(text, "[color=#f0c85b]$1[/color]", true)

	for keyword in ["剑伤", "雷", "层", "灵气", "抽", "生命", "破绽", "邪祟", "丹", "护体", "攻击", "防御"]:
		text = text.replace(keyword, "[color=#e6a84f]%s[/color]" % keyword)
	return text


func ignore_mouse_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		ignore_mouse_input(child)


func _apply_empty_style() -> void:
	panel.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color("141611"),
		Color("6d6044"),
		3,
		8,
		Color(0, 0, 0, 0.45),
		8
	))


func _apply_card_style(card_to_style: Card, state: int = VisualState.NORMAL) -> void:
	var style: Dictionary = CARD_STYLE.new().get_card_style(card_to_style)
	var main := style["main"] as Color
	var dark := style["dark"] as Color
	var highlight := style["highlight"] as Color
	var gold := style["gold"] as Color
	var border_color := main.lerp(gold, 0.32)
	var shadow_color := Color(0, 0, 0, 0.56)
	var shadow_size := 10
	var border_width := 4

	if card_to_style.rarity == Card.Rarity.RARE:
		border_color = border_color.lightened(0.12)
		border_width = 5
	elif card_to_style.rarity == Card.Rarity.MYTHIC:
		border_color = Color("f1b85b")
		shadow_color = Color(0.82, 0.34, 0.10, 0.36)
		border_width = 5

	if state == VisualState.HOVER:
		border_color = highlight
		shadow_color = Color(highlight.r, highlight.g, highlight.b, 0.35)
		shadow_size = 16
	elif state == VisualState.DRAG:
		border_color = highlight.lightened(0.12)
		shadow_color = Color(highlight.r, highlight.g, highlight.b, 0.48)
		shadow_size = 20

	if disabled_visual:
		border_color = border_color.darkened(0.45)
		shadow_color = Color(0, 0, 0, 0.42)

	panel.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		dark.lerp(Color("070807"), 0.24),
		border_color,
		border_width,
		9,
		shadow_color,
		shadow_size
	))
	title_bar.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color(0.02, 0.02, 0.018, 0.74).lerp(dark, 0.34),
		border_color,
		1,
		5
	))
	art_frame.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color("10110e").lerp(dark, 0.35),
		border_color.lerp(gold, 0.35),
		2,
		4
	))
	description_panel.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color("080b0a").lerp(dark, 0.62),
		Color(border_color.r, border_color.g, border_color.b, 0.62),
		1,
		4
	))
	type_bar.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color("10100c").lerp(dark, 0.36),
		border_color,
		1,
		4
	))
	cost_orb.set("theme_override_styles/panel", CARD_STYLE.new().make_style(
		Color("151008").lerp(dark, 0.34),
		highlight.lerp(gold, 0.50),
		2,
		18,
		Color(highlight.r, highlight.g, highlight.b, 0.26),
		8
	))

	card_name.add_theme_color_override("font_color", Color("f9e8b4"))
	card_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	card_name.add_theme_constant_override("shadow_offset_x", 2)
	card_name.add_theme_constant_override("shadow_offset_y", 2)
	description.add_theme_color_override("default_color", Color("eee7d2"))
	description.add_theme_font_size_override("normal_font_size", 14)
	type_label.add_theme_color_override("font_color", highlight.lerp(Color("fff2c2"), 0.36))
	element_tag.add_theme_color_override("font_color", highlight)
	title_left_mark.color = border_color
	title_right_mark.color = border_color


func _get_title_font_size(value: String) -> int:
	if value.length() >= 7:
		return 16
	if value.length() >= 5:
		return 18
	return 20
