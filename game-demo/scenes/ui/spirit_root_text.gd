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
			return "圆满：每打出一张火属性牌，对敌方全体造成该牌强化后主要数值 50% 的爆炸伤害。"
		Card.Element.METAL:
			return "圆满：每打出一张金属性牌，获得 1 点劲气。"
		Card.Element.WATER:
			return "圆满：每打出一张水属性牌，抽 1 张牌，并让抽到的牌本回合费用 -1。"
		Card.Element.WOOD:
			return "圆满：玩家回合结束时，回复牌组内木属性卡牌数量的生命。"
		Card.Element.EARTH:
			return "圆满：每回合打出的第一张土属性牌，获得 1 层真元。真元会让护体牌额外获得护体。"
		_:
			return "未选择灵根。"


static func stage_rule(stage: int) -> String:
	match stage:
		1:
			return "小成：同元素卡牌数值提高 20%，向上取整后 +2。"
		2:
			return "大成：同元素卡牌数值提高 50%，向上取整后 +2。"
		3:
			return "圆满：同元素卡牌数值翻倍后 +2，并启用圆满效果。"
		_:
			return "初悟：同元素卡牌数值 +2。"


static func next_stage_hint(count: int) -> String:
	if count < 3:
		return "距离小成还需 %s 张同元素牌。" % (3 - count)
	if count < 5:
		return "距离大成还需 %s 张同元素牌。" % (5 - count)
	if count < 10:
		return "距离圆满还需 %s 张同元素牌。" % (10 - count)
	return "灵根已圆满。"


static func status_tooltip(character: CharacterStats) -> String:
	if not character or not character.has_spirit_root():
		return "灵根\n尚未选择灵根。"

	var count := character.count_spirit_root_cards()
	var stage := character.get_spirit_root_stage()
	var element := character.spirit_root
	return "%s灵根 · %s\n同元素牌：%s 张\n%s\n%s\n\n%s" % [
		element_name(element),
		character.get_spirit_root_stage_name(),
		count,
		stage_rule(stage),
		next_stage_hint(count),
		perfect_effect(element),
	]
