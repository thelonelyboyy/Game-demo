"""Emit the current workbook data as JSON for the artifact workbook builder."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import ai_table as at
import blessing_table as bt
import card_table as ct
import card_effect_table as cet
import fusion_table as ft
import game_data_labels as labels
import event_table as et
import enemy_table as ent
import level_table as lt
import potion_table as pt
import shop_price_table as st
import relic_table as rt


def main() -> None:
    cards = []
    for path in ct.find_card_files():
        card = ct.parse_card(path)
        cards.append(card)
    blessings = bt.to_rows()
    for blessing in blessings:
        blessing["cls"] = labels.CLASS_LABELS.get(blessing["cls"], blessing["cls"])
        blessing["icon"] = labels.ICON_LABELS.get(blessing["icon"], blessing["icon"])
        blessing["effects"] = [
            (labels.BLESSING_EFFECT_LABELS.get(effect, effect), amount)
            for effect, amount in blessing["effects"]
        ]
    events = et.parse_all()
    for event in events:
        for choice in event["choices"]:
            choice["effect"] = labels.event_effect_to_zh(choice["effect"])
        event["root_effects"] = [labels.event_effect_to_zh(value) for value in event["root_effects"]]
    potions = pt.parse_all()
    for potion in potions:
        for effect in potion["effects"]:
            for param in effect["params"]:
                param["name"] = labels.PARAM_LABELS.get(param["name"], param["name"])
    ai = at.parse_all()
    for config in ai:
        for action in config["actions"]:
            action["display_name"] = labels.AI_ACTION_LABELS.get(action["script"], "未命名行动")
            for param in action["params"]:
                param["name"] = labels.PARAM_LABELS.get(param["name"], param["name"])

    card_effects = cet.parse_all()
    effect_catalog_map: dict[tuple[str, str], dict] = {}
    for effect in card_effects:
        key = (effect["effect"], effect["script_path"])
        item = effect_catalog_map.setdefault(key, {
            "effect": effect["effect"], "script_path": effect["script_path"],
            "params": set(), "cards": set(), "rows": 0,
        })
        item["params"].add(effect["param"])
        item["cards"].add(effect["card_id"])
        item["rows"] += 1
    effect_catalog = [
        {
            "effect": item["effect"], "script_path": item["script_path"],
            "params": "、".join(sorted(item["params"])),
            "card_count": len(item["cards"]), "row_count": item["rows"],
        }
        for item in sorted(effect_catalog_map.values(), key=lambda value: (value["effect"], value["script_path"]))
    ]
    keyword_standards = [
        {"keyword": "消耗", "switch": "消耗", "count": "", "rule": "打出后进入消耗堆；未打出时正常弃置。", "priority": "打出：临时 > 消耗 > 功法移出 > 周天 > 弃牌"},
        {"keyword": "保留", "switch": "保留", "count": "", "rule": "回合结束不会进入弃牌堆；使用后按其他关键词结算。", "priority": "回合末：临时 > 虚无 > 保留 > 弃牌"},
        {"keyword": "蓄势", "switch": "成长触发=蓄势后", "count": "每次成长值/成长上限", "rule": "保留牌在回合结束仍在手中时，本场主要数值成长。", "priority": "先触发滞留效果，再成长，最后保留"},
        {"keyword": "固有", "switch": "固有", "count": "", "rule": "战斗第一回合优先进入起手。", "priority": "先移动全部固有牌到抽牌堆顶，再抽起手牌"},
        {"keyword": "连携", "switch": "效果条件", "count": "条件满足额外值", "rule": "上一张牌的类型或元素满足条件时，效果获得牌面注明的额外值。", "priority": "只读取本回合上一张已打出的牌"},
        {"keyword": "检索X", "switch": "检索", "count": "检索张数", "rule": "打开抽牌堆，选择 X 张牌加入手牌。", "priority": "多个选牌关键词按检索→取回→归墟依次结算"},
        {"keyword": "取回X", "switch": "取回", "count": "取回张数", "rule": "打开弃牌堆，选择 X 张牌加入手牌。", "priority": "多个选牌关键词按检索→取回→归墟依次结算"},
        {"keyword": "归墟X", "switch": "归墟", "count": "归墟张数", "rule": "打开消耗堆，选择 X 张牌加入手牌。", "priority": "多个选牌关键词按检索→取回→归墟依次结算"},
        {"keyword": "永恒", "switch": "永恒", "count": "", "rule": "无法打出，不能从永久牌组删除、变化或合炼。", "priority": "永恒限制始终优先"},
        {"keyword": "虚无", "switch": "虚无", "count": "", "rule": "回合结束仍在手牌时进入消耗堆。", "priority": "回合末：临时 > 虚无 > 保留 > 弃牌"},
        {"keyword": "临时", "switch": "临时", "count": "", "rule": "打出后或回合结束仍在手牌时直接移除。", "priority": "打出与回合末均最高"},
        {"keyword": "周天", "switch": "周天", "count": "", "rule": "打出后置于抽牌堆顶。", "priority": "打出：临时 > 消耗 > 功法移出 > 周天 > 弃牌"},
        {"keyword": "不可打出", "switch": "不可打出", "count": "", "rule": "不能主动使用。", "priority": "与状态牌、诅咒牌、永恒共同阻止打出"},
        {"keyword": "状态牌", "switch": "状态牌", "count": "", "rule": "用于污染抽牌循环，默认不可打出。", "priority": "可用机制标签“可打出”明确覆盖"},
        {"keyword": "诅咒牌", "switch": "诅咒牌", "count": "", "rule": "负面牌组污染，默认不可打出。", "priority": "可用机制标签“可打出”明确覆盖"},
    ]

    payload = {
        "cards": cards,
        "card_effects": card_effects,
        "effect_catalog": effect_catalog,
        "keyword_standards": keyword_standards,
        "fusions": ft.parse_all(),
        "blessings": blessings,
        "events": events,
        "potions": potions,
        "relics": rt.parse_all(),
        "relic_params": rt.parse_parameters(),
        "enemies": ent.parse_all(),
        "ai": ai,
        "levels": lt.parse_all(),
        "shop_prices": st.parse_all(),
        "meta": {
            "card_effects": ct.MAX_EFFECTS,
            "blessing_effects": bt.MAX_EFFECTS,
            "event_choices": et.MAX_CHOICES,
            "event_effect_types": list(labels.EVENT_EFFECT_LABELS.values()),
            "blessing_effect_types": list(labels.BLESSING_EFFECT_LABELS.values()),
            "blessing_classes": list(labels.CLASS_LABELS.values()),
            "blessing_icons": list(labels.ICON_LABELS.values()),
            "ai_params": at.MAX_PARAMS,
            "level_enemies": lt.MAX_ENEMIES,
        },
    }
    if len(sys.argv) > 1:
        Path(sys.argv[1]).write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    else:
        json.dump(payload, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main()
