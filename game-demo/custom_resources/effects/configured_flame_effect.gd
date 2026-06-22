class_name ConfiguredFlameEffect
extends "res://custom_resources/effects/card_effect.gd"

## 魔焰·焰轮：携带本牌颜色，先按焰轮里"其它颜色"数量结算共鸣，再把自身颜色加入焰轮。
## 焰轮状态由 ClassMechanicHandler 维护（组 "class_mechanic"），回合结束清空。

enum FlameColor { PURPLE, WHITE, GREEN, BLUE, BLACK, YELLOW, RED }
enum Bonus { NONE, BLOCK_SELF, DAMAGE_TARGET, DAMAGE_ALL, SOUL_MARK_TARGET, DRAW_SELF, MUSCLE_SELF }

const SOUL_MARK := preload("res://statuses/soul_mark.tres")
const MUSCLE := preload("res://statuses/muscle.tres")

@export var color: FlameColor = FlameColor.PURPLE
@export var bonus: Bonus = Bonus.NONE
@export var bonus_flat := 0          # 焰轮已有其它颜色时的固定共鸣量
@export var bonus_per_color := 0     # 每种其它颜色的增量
@export var target_mode := TargetMode.CARD_TARGETS


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var handler := _flame_handler()
	var others := 0
	if handler:
		others = handler.flame_other_color_count(color)

	if others > 0 and bonus != Bonus.NONE:
		var amount := bonus_flat + bonus_per_color * others
		if amount > 0:
			_apply_bonus(card, targets, modifiers, amount)

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
	var damage := amount
	if modifiers:
		damage = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT)
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
	match bonus:
		Bonus.BLOCK_SELF:
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
