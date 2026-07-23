"""Read/write the relic catalog and its tunable numeric parameters."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = ROOT / "game-demo"
RELIC_ROOT = PROJECT_ROOT / "relics"

TYPE = {0: "回合开始", 1: "战斗开始", 2: "回合结束", 3: "战斗结束", 4: "事件触发"}
CHARACTER = {0: "通用", 1: "体修", 2: "剑修", 3: "魔修", 4: "驭兽"}
RARITY = {0: "普通", 1: "稀有", 2: "珍品", 3: "首领"}

EFFECT_NAMES = {
    "affliction_draw_relic": "抽到污染牌后补牌", "block_relic": "获得护体",
    "campfire_relic": "篝火永久强化", "card_exhaust_draw_relic": "消耗牌后抽牌",
    "card_exhaust_threshold_relic": "消耗数量阈值奖励", "card_lifecycle_block_relic": "牌堆生命周期护体",
    "card_play_block_relic": "指定出牌护体", "card_play_damage_relic": "指定出牌伤害",
    "card_play_draw_relic": "指定出牌抽牌", "card_play_heal_relic": "指定出牌治疗",
    "card_play_status_relic": "指定出牌施加状态", "card_type_harmony_relic": "三类卡牌调和",
    "cursed_draw_boss_relic": "额外抽牌并植入污染", "damage_relic": "定时造成伤害",
    "deck_reshuffle_relic": "洗牌奖励", "deck_size_start_relic": "牌组规模奖励",
    "demonic_pact_relic": "魔契收益与代价", "discovery_assist_relic": "发现强化",
    "draw_relic": "额外抽牌", "end_turn_hand_block_relic": "按回合末手牌护体",
    "enemy_empower_mana_boss_relic": "敌我共同强化", "enemy_kill_relic": "击杀奖励",
    "event_choice_relic": "事件选择奖励", "flame_wheel_threshold_relic": "焰轮阈值奖励",
    "gold_relic": "战后灵石", "growth_echo_relic": "成长回响", "heal_relic": "定时治疗",
    "low_health_mana_relic": "低生命灵气", "mana_relic": "额外灵气",
    "player_hit_block_relic": "受击护体", "retained_mana_boss_relic": "保留灵气",
    "self_damage_relic": "自损奖励", "self_damage_threshold_relic": "自损阈值奖励",
    "soul_mark_spent_relic": "魂印消耗奖励", "status_relic": "定时施加状态",
    "unspent_mana_block_relic": "剩余灵气转护体", "upgraded_card_block_relic": "突破牌护体",
    "zero_cost_threshold_relic": "零费牌阈值奖励", "zero_mana_block_relic": "灵气耗尽护体",
}

PARAM_NAMES = {
    "amount": "效果数值", "battles_left": "持续战斗数", "block_amount": "护体值",
    "block_bonus": "额外护体", "block_per_card": "每张牌护体", "block_per_mana": "每点灵气护体",
    "bonus_upgrades": "额外突破数", "card_threshold": "卡牌数量阈值", "color_threshold": "焰轮颜色阈值",
    "copies_per_combat": "每场复制次数", "damage": "伤害", "damage_amount": "伤害值",
    "damage_threshold": "伤害阈值", "draw_amount": "抽牌数", "enemy_stacks": "敌方状态层数",
    "exhaust_threshold": "消耗数量阈值", "extra_growth_triggers": "额外成长次数",
    "extra_picks": "额外选择数", "gold_amount": "灵石数", "heal_amount": "治疗量",
    "health_ratio": "生命比例阈值", "mana_amount": "灵气值", "max_retained": "最多保留灵气",
    "maximum_cards_counted": "最多计算卡牌数", "maximum_deck_size": "最大牌组阈值",
    "maximum_mana_counted": "最多计算灵气", "minimum_consumed": "最低消耗层数",
    "minimum_damage": "最低伤害", "minimum_deck_size": "最小牌组阈值",
    "once_per_turn": "每回合限一次", "only_once_per_run": "每局限一次",
    "require_costly_choice": "要求有代价的选择", "requirement_amount": "要求数值",
    "scale_by_consumed": "按消耗层数成长", "skills_required": "所需技能牌数",
    "stacks": "状态层数", "status_stacks": "状态层数", "max_retained": "最多保留灵气",
}

BASE_FIELDS = {"script", "relic_name", "id", "type", "character_type", "rarity", "starter_relic", "exclusive_group", "icon", "tooltip"}


def _resource(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else ""


def _raw(block: str, key: str, default: str = "") -> str:
    match = re.search(rf"^{re.escape(key)} = (.+)$", block, re.M)
    return match.group(1).strip() if match else default


def _string(block: str, key: str) -> str:
    raw = _raw(block, key, '""')
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw.strip('"')


def parse_all() -> list[dict]:
    rows: list[dict] = []
    for path in sorted(RELIC_ROOT.rglob("*.tres")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        block = _resource(text)
        relic_id = _string(block, "id")
        if not relic_id:
            continue
        script_match = re.search(r'\[ext_resource type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"', text)
        script_path = script_match.group(1) if script_match else ""
        effect_key = Path(script_path).stem
        rows.append({
            "file": path.relative_to(PROJECT_ROOT).as_posix(), "id": relic_id,
            "name": _string(block, "relic_name"), "type": TYPE.get(int(_raw(block, "type", "0")), "回合开始"),
            "character": CHARACTER.get(int(_raw(block, "character_type", "0")), "通用"),
            "rarity": RARITY.get(int(_raw(block, "rarity", "0")), "普通"),
            "starter": _raw(block, "starter_relic", "false") == "true",
            "exclusive_group": _string(block, "exclusive_group"), "tooltip": _string(block, "tooltip"),
            "effect": EFFECT_NAMES.get(effect_key, "专属机制"), "script_path": script_path,
        })
    return rows


def parse_parameters() -> list[dict]:
    result: list[dict] = []
    by_file = {row["file"]: row for row in parse_all()}
    for rel, relic in by_file.items():
        block = _resource((PROJECT_ROOT / rel).read_text(encoding="utf-8"))
        for match in re.finditer(r'^([a-z_][a-z0-9_]*) = (-?\d+(?:\.\d+)?|true|false)$', block, re.M):
            key, raw = match.groups()
            if key in BASE_FIELDS or key not in PARAM_NAMES:
                continue
            value: int | float | bool
            if raw in ("true", "false"):
                value = raw == "true"
            else:
                number = float(raw)
                value = int(number) if number.is_integer() else number
            result.append({"file": rel, "id": relic["id"], "name": relic["name"], "param": PARAM_NAMES[key], "raw_param": key, "value": value})
    return result


def write_parameters(rel: str, edits: list[dict]) -> bool:
    path = PROJECT_ROOT / rel
    text = path.read_text(encoding="utf-8")
    original = text
    for edit in edits:
        key = str(edit["raw_param"])
        value = edit["value"]
        raw = "true" if value is True else "false" if value is False else str(value)
        pattern = re.compile(rf"^{re.escape(key)} = .+$", re.M)
        if not pattern.search(text):
            raise ValueError(f"法宝参数不存在: {key}")
        text = pattern.sub(f"{key} = {raw}", text, count=1)
    if text == original:
        return False
    path.write_text(text, encoding="utf-8")
    return True
