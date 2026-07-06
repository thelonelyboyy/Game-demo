class_name ConfiguredDemonicEngineEffect
extends "res://custom_resources/effects/card_effect.gd"

enum DemonicEngine {
	BLOOD_QI_GUARD,
	BLOODTHIRST,
	BLOOD_RECOMPENSE,
	SOUL_MARK_SENSE,
	SOUL_RITE,
	SOUL_FLAME_CYCLE,
	SOUL_ECHO,
	FLAME_CONTINUITY,
	FLAME_REFINING,
	SHA_NURTURE,
}

@export var engine: DemonicEngine = DemonicEngine.BLOOD_QI_GUARD
@export var value := 1
@export var threshold := 0


func execute(_card: CultivationCard, _targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var handler := _class_handler()
	if handler and handler.has_method("add_demonic_engine"):
		handler.add_demonic_engine(engine, value, threshold)


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return description_template

	match engine:
		DemonicEngine.BLOOD_QI_GUARD:
			return "功法：每当你因自损失去生命，获得 %d 点护体。" % value
		DemonicEngine.BLOODTHIRST:
			return "功法：每当你因自损失去生命，本回合攻击伤害 +%d。" % value
		DemonicEngine.BLOOD_RECOMPENSE:
			return "功法：本回合累计自损至少 %d 生命时，对全体敌人造成等量伤害（每回合 1 次）。" % threshold
		DemonicEngine.SOUL_MARK_SENSE:
			return "功法：你的攻击牌对带魂印的敌人额外造成 %d 点伤害。" % value
		DemonicEngine.SOUL_RITE:
			return "功法：回合开始时，给予随机敌人 %d 层魂印。" % value
		DemonicEngine.SOUL_FLAME_CYCLE:
			return "功法：每当你引爆魂印，抽 %d 张牌。" % value
		DemonicEngine.SOUL_ECHO:
			return "功法：每当敌人魂印被引爆或消耗，每层额外造成 %d 点伤害。" % value
		DemonicEngine.FLAME_CONTINUITY:
			return "功法：回合开始时，焰轮保留上回合最后点亮的 1 种颜色。"
		DemonicEngine.FLAME_REFINING:
			return "功法：每当你打出魔焰牌，令手牌中 1 张魔焰牌本回合费用 -%d。" % value
		DemonicEngine.SHA_NURTURE:
			return "功法：回合结束时，获得 %d 点煞气。" % value
		_:
			return ""


func get_primary_value(_card: CultivationCard) -> int:
	return 0


func upgrade_values() -> void:
	pass


func _class_handler() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.get_first_node_in_group("class_mechanic")
