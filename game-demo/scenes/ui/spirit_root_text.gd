class_name SpiritRootText
extends RefCounted


static func element_name(element: Card.Element) -> String:
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
			return "无"


static func element_color(element: Card.Element) -> Color:
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


static func perfect_effect(element: Card.Element) -> String:
	match element:
		Card.Element.FIRE:
			return "圆满：每回合第一张火属性攻击牌，选择伤害 ×1.5，或对主目标外所有敌人造成该牌最终实际伤害 50% 的余波。"
		Card.Element.METAL:
			return "圆满：每回合第一张金属性牌，获得 1 点劲气。"
		Card.Element.WATER:
			return "圆满：每回合第一张水属性牌，抽 1 张牌，并让抽到的第一张牌本回合费用 -1。"
		Card.Element.WOOD:
			return "圆满：回合结束时，若本回合打出过木属性牌，回复 3 点生命；若已满血，改为获得 3 点护体。"
		Card.Element.EARTH:
			return "圆满：每回合第一张土属性牌，获得 1 点真元。真元会让护体牌额外获得护体。"
		_:
			return "未选择灵根。"


static func stage_rule(stage: int) -> String:
	match stage:
		1:
			return "小成（4–6 张）：同元素牌主数值 = ceil(基础值 ×1.2) + 1。"
		2:
			return "圆满（7 张及以上）：同元素牌主数值 = ceil(基础值 ×1.4) + 1，并启用圆满效果。"
		_:
			return "初悟（0–3 张）：同元素牌主数值 +1。"


static func next_stage_hint(count: int) -> String:
	if count < 4:
		return "距离小成还需 %s 张同元素牌。" % (4 - count)
	if count < 7:
		return "距离圆满还需 %s 张同元素牌。" % (7 - count)
	return "灵根已圆满。"


static func status_tooltip(character: CharacterStats) -> String:
	if character and character.rootless_path:
		return "无相之路\n放弃灵根成长。开局最大生命 +8、获得 80 灵石，并随机突破 1 张初始牌。"
	if not character or not character.has_spirit_root():
		return "灵根\n尚未选择灵根。"

	var count := character.count_spirit_root_cards()
	var stage := character.get_spirit_root_stage()
	var element := character.spirit_root
	var turn_state := _perfect_turn_state(character)
	return "%s灵根 · %s\n同元素牌：%s 张\n%s\n%s%s\n\n%s" % [
		element_name(element),
		character.get_spirit_root_stage_name(),
		count,
		stage_rule(stage),
		next_stage_hint(count),
		turn_state,
		perfect_effect(element),
	]


static func _perfect_turn_state(character: CharacterStats) -> String:
	if not character.is_spirit_root_complete():
		return ""

	if character.spirit_root == Card.Element.WOOD:
		var wood_state := "已打出木牌" if character.spirit_root_wood_played_this_turn else "未打出木牌"
		var settle_state := "已结算" if character.spirit_root_perfect_triggered_this_turn else "待回合结束"
		return "\n本回合圆满：%s，%s。 " % [wood_state, settle_state]

	var state := "已触发" if character.spirit_root_perfect_triggered_this_turn else "未触发"
	return "\n本回合圆满：%s。 " % state
