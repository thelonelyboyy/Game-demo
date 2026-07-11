class_name CardVisuals
extends Control

const CARD_STYLE := preload("res://scenes/ui/card_style.gd")

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var frame_texture: TextureRect = $FrameTexture
@onready var title_bar: Panel = $TitleBar
@onready var card_name: Label = $TitleBar/Name
@onready var art_frame: Panel = $ArtFrame
@onready var icon: TextureRect = $ArtFrame/Icon
@onready var description_panel: Panel = $DescriptionPanel
@onready var description: RichTextLabel = $DescriptionPanel/DescBox/Description
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
# 我方回合且费用足够时，卡牌带一圈暖金辉光提示"可打出"。
var playable_glow := false
var style_helper: CardStyle = CARD_STYLE.new()


func _ready() -> void:
	ignore_mouse_input(self)
	description.mouse_filter = Control.MOUSE_FILTER_PASS
	frame_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	if not card:
		_clear_card()
		return

	cost.text = "禁" if card.blocks_manual_play() else card.get_cost_text()
	card_name.text = card.get_display_name()
	card_name.add_theme_font_size_override("font_size", _get_title_font_size(card_name.text))
	description.text = "[center]%s[/center]" % style_helper.format_card_text(card, card.get_default_tooltip())
	description.add_theme_font_size_override("normal_font_size", _get_description_font_size(description.text))
	icon.texture = card.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
	rarity.tooltip_text = _get_rarity_name(card.rarity)
	type_label.text = style_helper.get_card_type(card)

	if card.element != Card.Element.NONE:
		element_tag.text = _get_element_badge(card.element)
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


func flash_cost_insufficient() -> void:
	cost.modulate = Color(2.2, 0.4, 0.35)
	var tween := cost.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cost, "modulate", Color.WHITE, 0.60)


func set_playable_glow(value: bool) -> void:
	if playable_glow == value:
		return
	playable_glow = value
	if card:
		_apply_card_style(card, visual_state)


func set_disabled_visual(value: bool) -> void:
	disabled_visual = value
	disabled_overlay.visible = disabled_visual
	icon.modulate = Color(0.62, 0.62, 0.62, 0.68) if disabled_visual else Color.WHITE
	description.modulate = Color(0.76, 0.76, 0.76, 0.9) if disabled_visual else Color.WHITE
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


func ignore_mouse_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		ignore_mouse_input(child)


func _apply_empty_style() -> void:
	frame_texture.texture = load(CardStyle.FRAME_ROOT + "card_frame_default.png") as Texture2D
	frame_texture.modulate = Color(0.82, 0.82, 0.82, 0.82)
	panel.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		12,
		Color(0, 0, 0, 0),
		0
	))


func _apply_card_style(card_to_style: Card, state: int = VisualState.NORMAL) -> void:
	var style: Dictionary = style_helper.get_card_style(card_to_style)
	var dark := style["dark"] as Color
	var highlight := style["highlight"] as Color
	var gold := style["gold"] as Color
	var bright_gold := style["bright_gold"] as Color
	var frame_path := style["frame"] as String
	var frame := load(frame_path) as Texture2D
	if frame:
		frame_texture.texture = frame

	var frame_modulate := Color.WHITE
	var shadow_color := Color(0, 0, 0, 0)
	var shadow_size := 0
	var icon_alpha := 1.0

	if card_to_style.rarity == Card.Rarity.RARE:
		frame_modulate = Color(1.08, 1.04, 0.94, 1.0)
	elif card_to_style.rarity == Card.Rarity.MYTHIC:
		frame_modulate = Color(1.10, 0.96, 0.84, 1.0)

	if state == VisualState.HOVER:
		frame_modulate = frame_modulate * Color(1.16, 1.12, 1.08, 1.0)
	elif state == VisualState.DRAG:
		frame_modulate = frame_modulate * Color(1.20, 1.16, 1.10, 1.0)
	elif playable_glow:
		frame_modulate = frame_modulate * Color(1.08, 1.05, 1.0, 1.0)

	if disabled_visual:
		frame_modulate = Color(0.48, 0.48, 0.48, 0.72)
		icon_alpha = 0.68

	frame_texture.modulate = frame_modulate
	icon.modulate = Color(1, 1, 1, icon_alpha)

	panel.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		12,
		shadow_color,
		shadow_size
	))
	# Title banner is part of the frame texture; keep the overlay transparent.
	title_bar.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		6
	))
	# Art window and description plate borders are baked into the frame texture,
	# so keep these overlay panels transparent to avoid a doubled border.
	art_frame.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		4
	))
	description_panel.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		4
	))
	type_bar.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		6
	))
	cost_orb.set("theme_override_styles/panel", style_helper.make_panel_style(
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0),
		0,
		19
	))

	card_name.add_theme_color_override("font_color", Color("fff0bc"))
	card_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	card_name.add_theme_constant_override("shadow_offset_x", 2)
	card_name.add_theme_constant_override("shadow_offset_y", 2)
	description.add_theme_color_override("default_color", Color("eee7d2"))
	description.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	description.add_theme_constant_override("shadow_offset_x", 1)
	description.add_theme_constant_override("shadow_offset_y", 1)
	description.add_theme_font_size_override("normal_font_size", _get_description_font_size(description.text))
	type_label.add_theme_color_override("font_color", highlight.lerp(Color("fff2c2"), 0.36))
	type_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	type_label.add_theme_constant_override("shadow_offset_x", 1)
	type_label.add_theme_constant_override("shadow_offset_y", 1)
	element_tag.add_theme_color_override("font_color", highlight)
	element_tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	element_tag.add_theme_constant_override("shadow_offset_x", 1)
	element_tag.add_theme_constant_override("shadow_offset_y", 1)


func _get_title_font_size(value: String) -> int:
	if value.length() >= 7:
		return 14
	if value.length() >= 5:
		return 16
	return 18


func _get_description_font_size(value: String) -> int:
	var plain_text := _strip_bbcode(value).strip_edges()
	if plain_text.length() >= 62:
		return 10
	if plain_text.length() >= 44:
		return 11
	if plain_text.length() >= 28:
		return 12
	return 13


func _strip_bbcode(value: String) -> String:
	var result := ""
	var inside_tag := false
	for i in value.length():
		var character := value.substr(i, 1)
		if character == "[":
			inside_tag = true
		elif character == "]":
			inside_tag = false
		elif not inside_tag:
			result += character
	return result


func _get_element_badge(element: Card.Element) -> String:
	match element:
		Card.Element.METAL:
			return "金"
		Card.Element.WOOD:
			return "木"
		Card.Element.WATER:
			return "水"
		Card.Element.FIRE:
			return "火"
		Card.Element.EARTH:
			return "土"
		_:
			return ""


func _get_rarity_name(rarity_value: Card.Rarity) -> String:
	match rarity_value:
		Card.Rarity.UNCOMMON:
			return "蓝卡"
		Card.Rarity.RARE:
			return "金卡"
		Card.Rarity.MYTHIC:
			return "暗金卡"
		_:
			return "白卡"
