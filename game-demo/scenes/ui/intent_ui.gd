class_name IntentUI
extends Control

const BUBBLE := Rect2(0, 0, 190, 58)
const INNER_BUBBLE := Rect2(27, 10, 136, 38)
const GLYPH_LEFT := Vector2(52, 29)
const GLYPH_CENTER := Vector2(95, 29)
const ICON_SIZE := 32.0

# 分类专属图标（贴图优先，没有的分类回退到代码绘制）
const BADGE_FRAME := preload("res://assets/ui/generated/battle/battle_intent_badge_attack_9slice.png")
const ICON_SWORD := preload("res://assets/ui/generated/icons/icon_intent_attack.png")
const ICON_SHIELD := preload("res://art/tiles/intent_block_shield.png")
const ICON_BUFF := preload("res://art/tiles/intent_buff_self.png")
const CATEGORY_ICONS := {
	Intent.Category.ATTACK: ICON_SWORD,
	Intent.Category.MULTI_ATTACK: ICON_SWORD,
	Intent.Category.DEFEND: ICON_SHIELD,
	Intent.Category.BUFF: ICON_BUFF,
}

@onready var label: Label = $Label

var _category: int = Intent.Category.ATTACK
var _accent := Color.WHITE
var _bubble := StyleBoxFlat.new()


func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return

	_category = intent.category
	var style := _style_for(_category)
	_accent = style.accent

	var fill: Color = style.fill
	fill.a = 0.9
	_bubble.bg_color = fill
	_bubble.border_color = style.border
	_bubble.set_border_width_all(2)
	_bubble.set_corner_radius_all(18)

	label.text = _label_for(intent)
	label.visible = label.text.length() > 0
	label.add_theme_color_override("font_color", style.accent)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if label.visible:
		label.position = Vector2(75, 4)
		label.size = Vector2(92, 48)
		label.add_theme_font_size_override("font_size", 23)

	queue_redraw()
	show()


func _draw() -> void:
	draw_style_box(_bubble, INNER_BUBBLE)
	draw_texture_rect(BADGE_FRAME, BUBBLE, false, Color(1, 1, 1, 0.96))
	var center := GLYPH_LEFT if label.visible else GLYPH_CENTER
	if CATEGORY_ICONS.has(_category):
		var tex: Texture2D = CATEGORY_ICONS[_category]
		var rect := Rect2(center - Vector2(ICON_SIZE, ICON_SIZE) * 0.5, Vector2(ICON_SIZE, ICON_SIZE))
		draw_texture_rect(tex, rect, false)
	else:
		_draw_glyph(_category, center, _accent)


func _draw_glyph(category: int, c: Vector2, col: Color) -> void:
	var w := 2.0
	match category:
		Intent.Category.ATTACK, Intent.Category.MULTI_ATTACK:
			draw_line(c + Vector2(-6, -8), c + Vector2(-3, 8), col, w, true)
			draw_line(c + Vector2(-1, -9), c + Vector2(2, 9), col, w, true)
			draw_line(c + Vector2(4, -8), c + Vector2(6, 8), col, w, true)
		Intent.Category.DEFEND:
			_draw_shield(c, col, w)
		Intent.Category.ATTACK_DEFEND:
			_draw_shield(c + Vector2(3, 0), col, w)
			draw_line(c + Vector2(-9, -9), c + Vector2(-3, 9), col, w, true)
		Intent.Category.BUFF:
			_draw_chevron(c + Vector2(0, -1), col, w, true)
			_draw_chevron(c + Vector2(0, 6), col, w, true)
		Intent.Category.DEBUFF:
			_draw_chevron(c + Vector2(0, -6), col, w, false)
			_draw_chevron(c + Vector2(0, 1), col, w, false)
		Intent.Category.CHARGE:
			draw_arc(c, 4.5, 0.0, TAU * 0.8, 16, col, w, true)
			draw_arc(c, 8.0, TAU * 0.4, TAU * 1.1, 20, col, w, true)
		Intent.Category.SUMMON:
			draw_circle(c + Vector2(0, 3), 5.0, col)
			draw_circle(c + Vector2(-6, -4), 2.5, col)
			draw_circle(c + Vector2(0, -7), 2.5, col)
			draw_circle(c + Vector2(6, -4), 2.5, col)
		Intent.Category.HEAL:
			draw_polyline(PackedVector2Array([
				c + Vector2(0, 8), c + Vector2(-7, -1), c + Vector2(-4, -6),
				c + Vector2(0, -2), c + Vector2(4, -6), c + Vector2(7, -1), c + Vector2(0, 8),
			]), col, w, true)
		Intent.Category.ESCAPE:
			draw_line(c + Vector2(-8, -5), c + Vector2(2, -5), col, w, true)
			draw_line(c + Vector2(-8, 0), c + Vector2(4, 0), col, w, true)
			draw_line(c + Vector2(-8, 5), c + Vector2(0, 5), col, w, true)
		Intent.Category.SLEEP:
			draw_polyline(PackedVector2Array([
				c + Vector2(-5, -5), c + Vector2(5, -5), c + Vector2(-5, 5), c + Vector2(5, 5),
			]), col, w, true)
		_:  # UNKNOWN
			draw_arc(c + Vector2(0, -3), 5.0, PI * 1.05, PI * 2.25, 14, col, w, true)
			draw_line(c + Vector2(2, 1), c + Vector2(0, 4), col, w, true)
			draw_circle(c + Vector2(0, 8), 1.4, col)


func _draw_shield(c: Vector2, col: Color, w: float) -> void:
	draw_polyline(PackedVector2Array([
		c + Vector2(-7, -7), c + Vector2(7, -7), c + Vector2(7, -1),
		c + Vector2(0, 9), c + Vector2(-7, -1), c + Vector2(-7, -7),
	]), col, w, true)


func _draw_chevron(c: Vector2, col: Color, w: float, up: bool) -> void:
	if up:
		draw_polyline(PackedVector2Array([c + Vector2(-6, 3), c + Vector2(0, -4), c + Vector2(6, 3)]), col, w, true)
	else:
		draw_polyline(PackedVector2Array([c + Vector2(-6, -3), c + Vector2(0, 4), c + Vector2(6, -3)]), col, w, true)


func _style_for(category: int) -> Dictionary:
	match category:
		Intent.Category.ATTACK, Intent.Category.MULTI_ATTACK:
			return {"border": Color("e57045"), "fill": Color("1a0e08"), "accent": Color("ffb59a")}
		Intent.Category.DEFEND:
			return {"border": Color("56b39a"), "fill": Color("0e1a18"), "accent": Color("9fffe0")}
		Intent.Category.ATTACK_DEFEND:
			return {"border": Color("c89a35"), "fill": Color("14110b"), "accent": Color("ffd9a0")}
		Intent.Category.BUFF:
			return {"border": Color("d7a93f"), "fill": Color("2c1f0c"), "accent": Color("ffe08a")}
		Intent.Category.DEBUFF:
			return {"border": Color("9a5acb"), "fill": Color("1b1230"), "accent": Color("e0b0ff")}
		Intent.Category.CHARGE:
			return {"border": Color("ff5a3c"), "fill": Color("240b06"), "accent": Color("ff9a7a")}
		Intent.Category.SUMMON:
			return {"border": Color("97c459"), "fill": Color("14200a"), "accent": Color("c7e89a")}
		Intent.Category.HEAL:
			return {"border": Color("c0503a"), "fill": Color("1c0e0a"), "accent": Color("ffc7b8")}
		Intent.Category.ESCAPE:
			return {"border": Color("6f86a8"), "fill": Color("11161f"), "accent": Color("bcd0e8")}
		Intent.Category.SLEEP:
			return {"border": Color("7d7460"), "fill": Color("14120c"), "accent": Color("cabf9f")}
		_:  # UNKNOWN
			return {"border": Color("9a8f74"), "fill": Color("16140d"), "accent": Color("d8cdaf")}


func _label_for(intent: Intent) -> String:
	var value := str(intent.current_text).strip_edges()
	var label_text := _category_label(intent.category)
	if value.is_empty():
		return label_text
	if label_text.is_empty():
		return value
	return "%s %s" % [label_text, value]


func _category_label(category: int) -> String:
	match category:
		Intent.Category.ATTACK, Intent.Category.MULTI_ATTACK:
			return "强攻"
		Intent.Category.DEFEND:
			return "防御"
		Intent.Category.ATTACK_DEFEND:
			return "攻防"
		Intent.Category.BUFF:
			return "强化"
		Intent.Category.DEBUFF:
			return "削弱"
		Intent.Category.CHARGE:
			return "蓄势"
		Intent.Category.SUMMON:
			return "召唤"
		Intent.Category.HEAL:
			return "疗愈"
		Intent.Category.ESCAPE:
			return "逃离"
		Intent.Category.SLEEP:
			return "休眠"
		_:
			return "未知"
