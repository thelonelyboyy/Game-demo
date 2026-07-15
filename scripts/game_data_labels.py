"""Chinese display labels used by the unified game-data workbook.

The workbook deliberately keeps only resource paths and stable IDs in their
technical form.  All user-facing classifications, effect names and parameter
names are translated here, and imports reverse the same mappings.
"""

from __future__ import annotations


CARD_EFFECT_LABELS = {
    "configured_block_effect": "获得护体",
    "configured_cleanse_debuff_effect": "净化负面状态",
    "configured_consume_status_to_block_effect": "消耗状态获得护体",
    "configured_consume_status_to_damage_effect": "消耗状态造成伤害",
    "configured_copy_previous_card_effect": "复制上一张牌",
    "configured_count_scaling_effect": "按数量成长",
    "configured_damage_effect": "造成伤害",
    "configured_delayed_effect": "延迟施放",
    "configured_demonic_engine_effect": "魔修机制",
    "configured_discard_random_block_effect": "随机弃牌并获得护体",
    "configured_discover_effect": "发现卡牌",
    "configured_draw_effect": "抽牌",
    "configured_exhaust_random_effect": "随机消耗卡牌",
    "configured_flame_effect": "焰轮效果",
    "configured_heal_effect": "回复生命",
    "configured_mana_effect": "获得灵气",
    "configured_mana_loss_effect": "失去灵气",
    "configured_pile_tutor_effect": "从牌堆检索",
    "configured_purge_affliction_effect": "清除污染牌",
    "configured_self_damage_effect": "自身受伤",
    "configured_self_damage_scaling_damage_effect": "按已损生命造成伤害",
    "configured_soul_mark_consume_effect": "消耗魂印",
    "configured_soul_mark_detonate_effect": "引爆魂印",
    "configured_status_effect": "施加状态",
    "configured_topdeck_filter_effect": "整理牌堆顶",
    "configured_x_cost_damage_effect": "按灵气造成伤害",
    "configured_x_cost_self_damage_effect": "按灵气自身受伤",
    "consume_status_effect": "消耗状态并转化",
    "low_health_bonus_damage_effect": "低生命额外伤害",
    "player_status_damage_effect": "按自身状态造成伤害",
    "target_status_bonus_damage_effect": "按目标状态追加伤害",
    "repeat_card_effect": "重复施放",
}


PARAM_LABELS = {
    "amount": "基础数值",
    "amount_per_count": "每个计数增加值",
    "base_amount": "固定基础值",
    "bonus_amount": "条件满足额外值",
    "bonus_flat": "固定共鸣值",
    "bonus_per_color": "每种颜色增加值",
    "block_per_stack": "每层护体",
    "cards_per_turn": "每回合卡牌数",
    "cards_to_discard": "弃牌张数",
    "choices_to_show": "候选张数",
    "condition_amount": "条件阈值",
    "consume_amount": "消耗层数",
    "damage_per_life": "每点已损生命伤害",
    "damage_per_mana": "每点灵气伤害",
    "damage_per_stack": "每层伤害",
    "delay_turns": "延迟回合数",
    "growth_amount": "每次成长值",
    "growth_limit": "成长上限",
    "health_ratio_threshold": "生命比例阈值",
    "hp_threshold": "生命值阈值",
    "max_bonus": "最大额外伤害",
    "max_cards": "最多处理张数",
    "max_stacks_to_consume": "最多消耗层数",
    "minimum_count": "最低计数",
    "rider_value": "附加效果数值",
    "self_damage_per_mana": "每点灵气自损",
    "temporary_cost_reduction": "临时费用降低",
    "threshold": "触发阈值",
    "value": "机制数值",
    "value_per_consumed_stack": "每层转化值",
    "value_per_stack": "每层数值",
    "damage": "伤害",
    "block": "护体",
    "base_damage": "基础伤害",
    "damage_per_discard": "每张弃牌伤害",
    "max_bonus_damage": "最大额外伤害",
    "healing": "治疗量",
    "health_cost": "生命消耗",
    "muscle_stacks": "劲气层数",
    "stacks": "状态层数",
    "stacks_per_action": "每次行动增加层数",
    "copies": "加入张数",
    "max_enemies": "敌人数量上限",
    "fallback_block": "召唤失败获得护体",
    "chance_weight": "选择权重",
    "max_consecutive_uses": "最大连续使用次数",
}
PARAM_LABELS_R = {value: key for key, value in PARAM_LABELS.items()}


BLESSING_EFFECT_LABELS = {
    "max_health": "增加最大生命", "lose_max_health": "失去最大生命",
    "full_heal": "生命回满", "gold": "获得灵石", "lose_gold": "失去灵石",
    "lose_all_gold": "失去全部灵石", "max_mana": "增加最大灵气", "draw": "增加抽牌",
    "upgrade": "突破卡牌", "remove_card": "移除卡牌",
    "remove_strike_defend": "移除打击或防御", "duplicate_card": "复制卡牌",
    "add_random_cards": "获得随机职业卡", "add_random_rare_card": "获得随机稀有卡",
    "transform_card": "变化卡牌", "grant_relic": "获得法宝",
    "gain_potion": "获得符箓丹药", "weaken_next_battles": "削弱后续敌人",
}
BLESSING_EFFECT_LABELS_R = {value: key for key, value in BLESSING_EFFECT_LABELS.items()}

CLASS_LABELS = {"": "通用", "demonic": "魔修", "sword": "剑修", "body": "体修", "beastmaster": "驭兽"}
CLASS_LABELS_R = {value: key for key, value in CLASS_LABELS.items()}

ICON_LABELS = {
    "max_health": "生命", "full_heal": "回春", "gold": "灵石", "max_mana": "灵气",
    "draw": "抽牌", "upgrade": "突破", "remove_card": "炼化", "duplicate_card": "衍法",
    "relic": "法宝", "potion": "丹药", "rare_card": "稀有卡牌", "seal": "封印",
}
ICON_LABELS_R = {value: key for key, value in ICON_LABELS.items()}


EVENT_EFFECT_LABELS = {
    "skip": "无事发生", "gain_gold": "获得灵石", "lose_gold": "失去灵石",
    "heal": "回复生命", "damage": "失去生命", "max_hp": "增加最大生命",
    "upgrade_random": "随机突破卡牌", "remove_random": "随机移除卡牌",
    "gain_random_card": "获得随机卡牌", "gain_rare_card": "获得稀有卡牌",
    "gain_curse": "获得污染牌", "duplicate_last": "复制最后一张牌",
    "gamble_even": "均衡赌局", "gamble_risky": "冒险赌局",
}
EVENT_EFFECT_LABELS_R = {value: key for key, value in EVENT_EFFECT_LABELS.items()}


AI_ACTION_LABELS = {
    "add_card_to_discard_action": "向弃牌堆加入卡牌",
    "add_card_to_draw_action": "向抽牌堆加入卡牌",
    "apply_status_action": "施加状态",
    "attack_and_block_action": "攻击并护体",
    "attack_and_status_action": "攻击并施加状态",
    "bat_attack_action": "攻击",
    "bat_block_action": "护体",
    "block_allies_action": "为友方护体",
    "block_and_add_card_action": "护体并加入卡牌",
    "block_and_exhaust_draw_action": "护体并消耗抽牌",
    "buff_allies_action": "强化友方",
    "crab_attack_action": "攻击",
    "crab_block_action": "护体",
    "crab_mega_block_action": "大量护体",
    "drain_attack_action": "吸取生命",
    "missing_health_attack_action": "按已损生命攻击",
    "pile_scaling_attack_action": "按牌堆数量攻击",
    "self_sacrifice_buff_action": "牺牲自身强化友方",
    "summon_enemy_action": "召唤敌人",
    "toxic_ghost_attack_action": "毒灵攻击",
    "toxic_ghost_block_action": "毒灵护体",
    "toxic_ghost_muscle_buff_action": "毒灵增加劲气",
}


def event_effect_to_zh(value: str) -> str:
    parts: list[str] = []
    for part in str(value or "").split("|"):
        if not part:
            continue
        name, sep, amount = part.partition(":")
        label = EVENT_EFFECT_LABELS.get(name, name)
        parts.append(label + (":" + amount if sep else ""))
    return "|".join(parts)


def event_effect_from_zh(value: str) -> str:
    parts: list[str] = []
    for part in str(value or "").split("|"):
        if not part:
            continue
        name, sep, amount = part.partition(":")
        raw = EVENT_EFFECT_LABELS_R.get(name, name)
        parts.append(raw + (":" + amount if sep else ""))
    return "|".join(parts)
