class_name ConfiguredFlameEffect
extends "res://custom_resources/effects/card_effect.gd"

## 魔焰·焰轮：携带本牌颜色，先按焰轮里"其它颜色"数量结算共鸣，再把自身颜色加入焰轮。
## 焰轮状态由 ClassMechanicHandler 维护（组 "class_mechanic"），回合结束清空。

enum FlameColor { PURPLE, WHITE, GREEN, BLUE, BLACK, YELLOW, RED }
enum Bonus { NONE, BLOCK_SELF, DAMAGE_TARGET, DAMAGE_ALL, SOUL_MARK_TARGET, DRAW_SELF, MUSCLE_SELF }
## rider：色卡专属机制（与共鸣 bonus 正交，可同时存在）。
enum Rider { NONE, SHA_QI_DOUBLE_BLOCK, REDUCE_FLAME_COST, FLAME_DAMAGE_BUFF, DETONATE_AT_COLORS }

const SOUL_MARK := preload("res://statuses/soul_mark.tres")
const MUSCLE := preload("res://statuses/muscle.tres")

@export var color: FlameColor = FlameColor.PURPLE
@export var bonus: Bonus = Bonus.NONE
@export var base_amount := 0         # 始终结算的基础量（把色卡主效果并入本效果，使 rider 能作用全部）
@export var bonus_flat := 0          # 焰轮已有其它颜色时的固定共鸣量
@export var bonus_per_color := 0     # 每种其它颜色的增量
@export var target_mode := TargetMode.CARD_TARGETS
@export var rider: Rider = Rider.NONE
@export var rider_value := 0         # 绿:煞气消耗 / 黄:焰伤基数 / 红:色数阈值


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var handler := _flame_handler()
	var others := 0
	if handler:
		others = handler.flame_other_color_count(color)

	# 主效果 + 共鸣数值：base 始终给；bonus_flat 仅当焰轮已有其它颜色。
	var amount := base_amount + bonus_per_color * others
	if others > 0:
		amount += bonus_flat

	# 绿 rider：消耗煞气令本效果数值（护体）翻倍。
	if rider == Rider.SHA_QI_DOUBLE_BLOCK and amount > 0 and handler and handler.has_method("consume_sha_qi"):
		if handler.consume_sha_qi(rider_value):
			amount *= 2

	if amount > 0 and bonus != Bonus.NONE:
		_apply_bonus(card, targets, modifiers, amount)

	# 黄 rider：本回合魔焰（共鸣）伤害 +(rider_value + 其它色数)。
	if rider == Rider.FLAME_DAMAGE_BUFF and handler and handler.has_method("add_flame_damage_bonus"):
		handler.add_flame_damage_bonus(rider_value + others)

	# 蓝 rider：手牌中最多「其它色数」张魔焰卡费用-1。
	if rider == Rider.REDUCE_FLAME_COST and handler and handler.has_method("reduce_flame_card_costs"):
		handler.reduce_flame_card_costs(others, card)

	# 红 rider：含本色焰轮达阈值色数 → 引爆所有敌人的魂印。
	if rider == Rider.DETONATE_AT_COLORS and handler and handler.has_method("detonate_all_soul_marks"):
		if others + 1 >= rider_value:
			handler.detonate_all_soul_marks(modifiers)

	if handler:
		handler.flame_add_color(color)


func _flame_handler() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var handler := tree.get_first_node_in_group("class_mechanic")
	if handler and handler.has_method("flame_other_color_count"):
		return handler
	return null


func _apply_bonus(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler, amount: int) -> void:
	match bonus:
		Bonus.BLOCK_SELF:
			var be := BlockEffect.new()
			be.amount = amount
			be.execute(get_targets(card, targets, TargetMode.PLAYER))
		Bonus.DRAW_SELF:
			var de := CardDrawEffect.new()
			de.cards_to_draw = amount
			de.execute(get_targets(card, targets, TargetMode.PLAYER))
		Bonus.MUSCLE_SELF:
			_apply_status(card, targets, TargetMode.PLAYER, MUSCLE, amount)
		Bonus.SOUL_MARK_TARGET:
			_apply_status(card, targets, target_mode, SOUL_MARK, amount)
		Bonus.DAMAGE_TARGET:
			_deal(card, get_targets(card, targets, target_mode), amount, modifiers)
		Bonus.DAMAGE_ALL:
			_deal(card, get_targets(card, targets, TargetMode.ALL_ENEMIES), amount, modifiers)


func _deal(card: CultivationCard, tgts: Array[Node], amount: int, modifiers: ModifierHandler) -> void:
	# 黄·狂烬：本回合魔焰（共鸣）伤害 +flame_damage_bonus（方案甲，仅作用共鸣伤害）。
	var damage := amount
	var handler := _flame_handler()
	if handler and handler.has_method("flame_damage_bonus"):
		damage += handler.flame_damage_bonus()
	if modifiers:
		damage = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT)
	damage = DEBUG_CONSOLE_STATE.apply_next_dealt(damage)
	if damage <= 0:
		return
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound = card.sound if card else null
	damage_effect.execute(tgts)


func _apply_status(card: CultivationCard, targets: Array[Node], mode: int, status_res: Status, amount: int) -> void:
	var tgts := get_targets(card, targets, mode)
	if tgts.is_empty() or amount <= 0:
		return
	var status_copy := status_res.duplicate() as Status
	status_copy.stacks = amount
	var status_effect := StatusEffect.new()
	status_effect.status = status_copy
	status_effect.execute(tgts)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	var parts := PackedStringArray()
	var main := _bonus_description()
	if not main.is_empty():
		parts.append(main)
	var rd := _rider_description()
	if not rd.is_empty():
		parts.append(rd)
	return "\n".join(parts)


func _bonus_description() -> String:
	match bonus:
		Bonus.BLOCK_SELF:
			if base_amount > 0:
				return "获得 %d 点护体（每有 1 种其它魔焰颜色额外 +%d）。" % [base_amount, bonus_per_color]
			return "共鸣：每有 1 种其它魔焰颜色，额外获得 %d 点护体。" % bonus_per_color
		Bonus.DAMAGE_TARGET:
			return "共鸣：每有 1 种其它魔焰颜色，额外造成 %d 点伤害。" % bonus_per_color
		Bonus.DAMAGE_ALL:
			return "共鸣：每有 1 种其它魔焰颜色，额外对全体造成 %d 点伤害。" % bonus_per_color
		Bonus.SOUL_MARK_TARGET:
			return "共鸣：焰轮已有其它颜色时，施加 %d 层魂印。" % bonus_flat
		Bonus.DRAW_SELF:
			return "共鸣：焰轮已有其它颜色时，抽 %d 张牌。" % bonus_flat
		Bonus.MUSCLE_SELF:
			return "共鸣：每有 1 种其它魔焰颜色，额外获得 %d 层劲气。" % bonus_per_color
		_:
			return ""


func _rider_description() -> String:
	match rider:
		Rider.SHA_QI_DOUBLE_BLOCK:
			return "若煞气≥%d，消耗 %d 煞气令本牌护体翻倍。" % [rider_value, rider_value]
		Rider.REDUCE_FLAME_COST:
			return "每有 1 种其它魔焰颜色，令手牌 1 张魔焰卡本回合费用-1。"
		Rider.FLAME_DAMAGE_BUFF:
			return "本回合魔焰伤害 +%d（每有 1 种其它魔焰颜色额外 +1）。" % rider_value
		Rider.DETONATE_AT_COLORS:
			return "焰轮达 %d 色时，引爆所有敌人的魂印。" % rider_value
		_:
			return ""
