"""Rebuild event choices around distinct risk/reward identities."""

from __future__ import annotations

import event_table as et


# title -> choice index -> (text, effect sequence, legacy amount)
CHANGES: dict[str, dict[int, tuple[str, str, int]]] = {
    "山中奇遇": {0: ("照见另一条命数：随机拓印一张牌", "duplicate_random", 0)},
    "古剑冢": {0: ("以旧剑重铸一式：随机重铸一张牌，再突破它", "transform_random|upgrade_random:1", 0)},
    "游方丹师": {1: ("试吞洗髓丹：失去 12% 最大生命，最大生命 +5", "damage_percent:12|max_hp:5", 0)},
    "灵泉": {0: ("饮尽灵泉：回复 25% 最大生命", "heal_percent", 25)},
    "破碎封印": {0: ("引封印净火入体：净化一张污染牌", "purify_affliction", 1)},
    "云上小市": {0: ("按牌组规模出售见闻：每张永久牌换 3 灵石", "gain_gold_per_card", 3)},
    "饿鬼叩门": {1: ("以伤饲鬼：失去 10% 最大生命，每点已损生命换 2 灵石", "damage_percent:10|gain_gold_per_missing_hp:2", 0)},
    "照心玉镜": {0: ("照见旧法：随机重铸一张牌", "transform_random", 1)},
    "雷击木": {0: ("引雷淬体：失去 15% 最大生命，随机突破两张牌", "damage_percent:15|upgrade_random:2", 0)},
    "迷路弟子": {0: ("为其引路：按牌组每张牌获得 2 灵石", "gain_gold_per_card", 2)},
    "魔念低语": {0: ("纳魔念入识海：最大生命 +7，获得一张污染牌", "max_hp:7|gain_curse:1", 0)},
    "锈蚀丹炉": {0: ("熔掉旧法：移除一张牌并获得一张随机牌", "remove_random:1|gain_random_card:1", 0)},
    "白骨桥": {0: ("踏骨借阴气疗伤：失去 5 最大生命，回复 35% 最大生命", "max_hp:-5|heal_percent:35", 0)},
    "墨石碑": {0: ("以墨洗识海：净化一张污染牌并回复 8 生命", "purify_affliction:1|heal:8", 0)},
    "沉睡灵兽": {0: ("与灵兽同息：回复 20% 最大生命，获得一张随机牌", "heal_percent:20|gain_random_card:1", 0)},
    "剑雨残阵": {0: ("闯阵悟剑：失去 12% 最大生命，突破两张牌", "damage_percent:12|upgrade_random:2", 0)},
    "月下渡船": {1: ("替船家讲经：按牌组每张牌获得 2 灵石", "gain_gold_per_card", 2)},
    "红线仙": {0: ("剪断恶缘：优先净化一张污染牌", "purify_affliction", 1)},
    "坠星坑": {0: ("以伤换星屑：失去 10% 最大生命，每点已损生命换 2 灵石", "damage_percent:10|gain_gold_per_missing_hp:2", 0)},
    "无声道场": {0: ("坐忘旧法：随机重铸一张牌并获得 20 灵石", "transform_random:1|gain_gold:20", 0)},
    "欠债商人": {0: ("接过他的债册：获得 85 灵石与一张污染牌", "gain_gold:85|gain_curse:1", 0)},
    "摄魂铜铃": {0: ("镇铃净魂：净化一张污染牌，再随机突破一张牌", "purify_affliction:1|upgrade_random:1", 0)},
    "净莲池": {0: ("入池净念：回复 18% 最大生命并净化一张污染牌", "heal_percent:18|purify_affliction:1", 0)},
    "灵税小吏": {1: ("以万法辩经：随机重铸一张牌", "transform_random", 1)},
    "古战场": {0: ("依伤势搜刮：每点已损生命换 3 灵石", "gain_gold_per_missing_hp", 3)},
    "狐仙客栈": {1: ("讲尽旅途故事：按牌组每张牌获得 2 灵石", "gain_gold_per_card", 2)},
    "裂纹玉简": {0: ("碎简重悟：随机重铸一张牌并突破一张牌", "transform_random:1|upgrade_random:1", 0)},
    "血月小庙": {0: ("以血换命：失去 18% 最大生命，最大生命 +8", "damage_percent:18|max_hp:8", 0)},
    "云中藏书阁": {0: ("以旧换新：随机重铸一张牌并获得一张随机牌", "transform_random:1|gain_random_card:1", 0)},
    "灵兽足迹": {0: ("循伤追迹：失去 8% 最大生命，每点已损生命换 2 灵石", "damage_percent:8|gain_gold_per_missing_hp:2", 0)},
    "小天劫云": {1: ("借雷洗牌：失去 10% 最大生命，随机重铸一张牌", "damage_percent:10|transform_random:1", 0)},
    "魂灯洞窟": {0: ("以魂火净识：失去 8% 最大生命，净化一张污染牌并突破一张牌", "damage_percent:8|purify_affliction:1|upgrade_random:1", 0)},
    "血玉莲": {0: ("吞莲换血：失去 15% 最大生命，最大生命 +6", "damage_percent:15|max_hp:6", 0)},
    "暮色魔市": {0: ("买下秘匣：支付 65 灵石，随机重铸一张牌并突破它", "lose_gold:65|transform_random:1|upgrade_random:1", 0)},
    "断命算盘": {1: ("算尽旧法：随机拓印一张牌，失去 6 最大生命", "duplicate_random:1|max_hp:-6", 0)},
    "灰烬剑炉": {0: ("投牌炼金：移除一张牌，按剩余牌组每张换 3 灵石", "remove_random:1|gain_gold_per_card:3", 0)},
    "月骨桥": {0: ("踏骨观伤：失去 8% 最大生命，每点已损生命换 3 灵石", "damage_percent:8|gain_gold_per_missing_hp:3", 0)},
    "无声魔经": {0: ("默诵禁章：失去 16% 最大生命，突破两张牌", "damage_percent:16|upgrade_random:2", 0)},
    "坠星石柱": {0: ("折寿汲髓：失去 4 最大生命，随机拓印一张牌", "max_hp:-4|duplicate_random:1", 0)},
    "鬼契水榭": {0: ("签下鬼契：获得 125 灵石与两张污染牌", "gain_gold:125|gain_curse:2", 0)},
    "赤镜心魔": {0: ("直视心魔：失去 14% 最大生命，重铸并突破一张牌", "damage_percent:14|transform_random:1|upgrade_random:1", 0)},
    "血经石壁": {0: ("以血拓经：失去 12% 最大生命，获得一张金卡", "damage_percent:12|gain_rare_card:1", 0)},
    "幽都魂拍": {1: ("抵押魂火：失去 10% 最大生命，获得一张金卡", "damage_percent:10|gain_rare_card:1", 0)},
    "天焰魔眼": {0: ("承受天焰：失去 18% 最大生命，突破两张牌", "damage_percent:18|upgrade_random:2", 0)},
}


def main() -> None:
    changed = 0
    for event in et.parse_all():
        edits = CHANGES.get(event["title"])
        if not edits:
            continue
        for index, values in edits.items():
            text, effect, amount = values
            event["choices"][index] = {"text": text, "effect": effect, "amount": amount}
        if et.write_event(event):
            changed += 1
    print(f"rebalanced_events={changed}")


if __name__ == "__main__":
    main()
