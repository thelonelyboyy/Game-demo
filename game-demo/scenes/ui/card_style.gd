class_name CardStyle
extends RefCounted

const TYPE_THUNDER := "雷系"
const TYPE_SWORD := "剑系"
const TYPE_MIND := "心法"
const TYPE_SECRET := "秘术"
const TYPE_ALCHEMY := "丹道"
const TYPE_ARRAY := "剑阵"
const TYPE_STATUS := "状态"
const TYPE_CURSE := "诅咒"
const TYPE_DEFAULT := "术法"

const DISPLAY_TYPE_ATTACK := "攻击"
const DISPLAY_TYPE_SKILL := "技能"
const DISPLAY_TYPE_POWER := "功法"

const FRAME_ROOT := "res://art/ui/cards/generated/"

const TYPE_COLORS := {
	TYPE_THUNDER: {
		"main": Color("7b4acb"),
		"dark": Color("241832"),
		"highlight": Color("c89bff"),
		"frame": FRAME_ROOT + "card_frame_thunder.png",
	},
	TYPE_SWORD: {
		"main": Color("c89a35"),
		"dark": Color("2c2413"),
		"highlight": Color("ffe08a"),
		"frame": FRAME_ROOT + "card_frame_sword.png",
	},
	TYPE_MIND: {
		"main": Color("2fa486"),
		"dark": Color("102a24"),
		"highlight": Color("9fffe0"),
		"frame": FRAME_ROOT + "card_frame_mind.png",
	},
	TYPE_SECRET: {
		"main": Color("9a5acb"),
		"dark": Color("21152d"),
		"highlight": Color("e0b0ff"),
		"frame": FRAME_ROOT + "card_frame_secret.png",
	},
	TYPE_ALCHEMY: {
		"main": Color("d47a22"),
		"dark": Color("2e1a0d"),
		"highlight": Color("ffb15c"),
		"frame": FRAME_ROOT + "card_frame_alchemy.png",
	},
	TYPE_ARRAY: {
		"main": Color("c64a32"),
		"dark": Color("2d1110"),
		"highlight": Color("ff8a6a"),
		"frame": FRAME_ROOT + "card_frame_array.png",
	},
	TYPE_STATUS: {
		"main": Color("59606a"),
		"dark": Color("141820"),
		"highlight": Color("b8c1d6"),
		"frame": FRAME_ROOT + "card_frame_default.png",
	},
	TYPE_CURSE: {
		"main": Color("4b284d"),
		"dark": Color("170b18"),
		"highlight": Color("d19ae0"),
		"frame": FRAME_ROOT + "card_frame_secret.png",
	},
	TYPE_DEFAULT: {
		"main": Color("b89c62"),
		"dark": Color("1d1a14"),
		"highlight": Color("e8d8a0"),
		"frame": FRAME_ROOT + "card_frame_default.png",
	},
}

const KEYWORDS := [
	"剑伤",
	"雷",
	"层",
	"灵气",
	"护体",
	"生命",
	"破绽",
	"煞气",
	"邪祟",
	"中毒",
	"攻击",
	"防御",
	"临时",
	"消耗",
	"保留",
	"固有",
	"检索",
	"取回",
	"归墟",
	"永恒",
	"周天",
	"虚无",
	"不可打出",
	"状态",
	"诅咒",
	"弃牌触发",
	"消耗触发",
	"成长",
	"发现",
	"格挡",
	"抽",
	"火",
	"金",
	"木",
	"水",
	"土",
]

const STATUS_TERM_HINTS := {
	"煞气": "魔修战斗资源。达到3/6/10档时强化伤害并带来风险，战斗结束清空。",
}


func get_card_type(card: Card) -> String:
	if not card:
		return DISPLAY_TYPE_SKILL

	match card.type:
		Card.Type.ATTACK:
			return DISPLAY_TYPE_ATTACK
		Card.Type.POWER:
			return DISPLAY_TYPE_POWER
		_:
			return DISPLAY_TYPE_SKILL


func _get_visual_archetype(card: Card) -> String:
	if not card:
		return TYPE_DEFAULT

	if card.is_curse_card():
		return TYPE_CURSE
	if card.is_status_card():
		return TYPE_STATUS

	var marker: String = _card_marker(card)
	if (
		marker.contains("剑阵")
		or marker.contains("劍陣")
		or marker.contains("array")
		or marker.contains("formation")
	):
		return TYPE_ARRAY
	if card.type == Card.Type.POWER:
		return TYPE_MIND
	if card.get_profession() == Card.Profession.DEMONIC:
		return TYPE_SECRET
	if card.element == Card.Element.FIRE:
		return TYPE_ALCHEMY
	if card.get_profession() == Card.Profession.SWORD or card.element == Card.Element.METAL:
		return TYPE_SWORD
	if card.element == Card.Element.WATER:
		return TYPE_THUNDER
	return TYPE_DEFAULT


func get_card_frame_path(card: Card) -> String:
	var card_type: String = _get_visual_archetype(card)
	var colors: Dictionary = TYPE_COLORS.get(card_type, TYPE_COLORS[TYPE_DEFAULT])
	return colors["frame"]


func get_card_style(card: Card) -> Dictionary:
	var visual_archetype: String = _get_visual_archetype(card)
	var colors: Dictionary = TYPE_COLORS.get(visual_archetype, TYPE_COLORS[TYPE_DEFAULT])
	return {
		"type_name": get_card_type(card),
		"main": colors["main"],
		"dark": colors["dark"],
		"highlight": colors["highlight"],
		"frame": colors["frame"],
		"gold": Color("d7b56d"),
		"bright_gold": Color("ffe3a0"),
		"ink": Color("050706"),
		"panel": Color("10130f"),
		"text": Color("f4ead1"),
		"muted": Color("c8bfa8"),
	}


func format_card_text(card: Card, value: String) -> String:
	var text := value
	if card:
		text = text.replace("[center][b]%s[/b]\n" % card.get_display_name(), "[center]")
	text = text.replace("[center]", "")
	text = text.replace("[/center]", "")
	text = text.replace("[b]", "")
	text = text.replace("[/b]", "")
	text = text.strip_edges()
	return _highlight_numbers_and_keywords(text)


func make_panel_style(
	bg: Color,
	border: Color,
	border_width := 1,
	radius := 6,
	shadow := Color(0, 0, 0, 0.0),
	shadow_size := 0,
	margin := 0
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	style.anti_aliasing = true
	return style


func make_style(
	bg: Color,
	border: Color,
	border_width := 1,
	radius := 6,
	shadow := Color(0, 0, 0, 0.0),
	shadow_size := 0,
	margin := 0
) -> StyleBoxFlat:
	return make_panel_style(bg, border, border_width, radius, shadow, shadow_size, margin)


func _highlight_numbers_and_keywords(value: String) -> String:
	var text := value
	var number_regex := RegEx.new()
	number_regex.compile("([0-9]+)")
	text = number_regex.sub(text, "[color=#f0c85b]$1[/color]", true)

	for term: String in STATUS_TERM_HINTS:
		text = text.replace(term, "[hint=%s][color=#e6a84f]%s[/color][/hint]" % [STATUS_TERM_HINTS[term], term])

	for keyword: String in KEYWORDS:
		if STATUS_TERM_HINTS.has(keyword):
			continue
		text = text.replace(keyword, "[color=#e6a84f]%s[/color]" % keyword)
	return text


func _card_marker(card: Card) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(card.id.to_lower())
	parts.append(card.get_display_name().to_lower())
	for keyword: String in card.get_keyword_labels():
		parts.append(keyword.to_lower())
	for tag: String in card.mechanic_tags:
		parts.append(tag.to_lower())
	return " ".join(parts)
