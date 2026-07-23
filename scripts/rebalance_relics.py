"""Focused relic balance pass: stronger identities, explicit limits and tradeoffs."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "game-demo" / "relics"

# Values are deliberately sparse: each listed relic receives a clear niche
# instead of a global percentage buff that would flatten the catalog again.
CHANGES = {
    "ink_guard_talisman": ({"block_amount": 8}, "墨甲符\n战斗开始时获得 8 点护体：稳定抵挡第一轮攻势。"),
    "stone_heart_bell": ({"block_amount": 5}, "石心铃\n每回合第一次受伤后获得 5 点护体，适合主动承伤流。"),
    "jade_abacus": ({"gold_amount": 15}, "玉算盘\n战斗结束后额外获得 15 灵石，专注长期经济。"),
    "lotus_mirror": ({"heal_amount": 5}, "莲华镜\n战斗结束后回复 5 点生命，稳定抹平小伤。"),
    "thunder_seal": ({"damage": 4}, "雷纹印\n每回合开始时对所有敌人造成 4 点伤害，擅长清理召唤物。"),
    "empty_breath_seal": ({"block_amount": 7}, "空息印\n回合结束时若灵气恰好为 0，获得 7 点护体；奖励精确耗尽。"),
    "war_pattern_bracer": ({"block_amount": 5}, "战纹护腕\n每回合第一次打出攻击牌时获得 5 点护体，鼓励攻守同回合。"),
    "tempered_scripture_seal": ({"block_amount": 6}, "淬经印\n每回合第一次打出已突破卡牌时获得 6 点护体。"),
    "demon_sacrifice_dagger": ({"damage_amount": 4, "once_per_turn": True}, "魔修专属。每回合第一次打出魔修牌时，对所有敌人造成 4 点伤害。"),
    "sacrifice_blade": ({"damage_amount": 3}, "祭血刃\n每次打出献祭牌时，对所有敌人造成 3 点伤害；以牌组代价换群伤。"),
    "demon_blood_crucible": ({"block_amount": 4}, "魔修专属。每次因自己的卡牌失去生命后获得 4 点护体，将血债转为防御。"),
    "demon_soul_censer": ({"block_amount": 8}, "魔修专属。每回合第一次一次消耗至少 3 层魂印时，获得 8 点护体。"),
    "body_marrow_drum": ({"block_amount": 9}, "体修专属。每回合第一次受到伤害后获得 9 点护体，突出后发制人。"),
    "retained_edge_tassel": ({"block_per_card": 4, "maximum_cards_counted": 3}, "回合结束时，每有 1 张保留牌便获得 4 点护体，最多计算 3 张。"),
    "stored_breath_furnace": ({"block_per_mana": 4, "maximum_mana_counted": 3}, "回合结束时，每剩余 1 点灵气获得 4 点护体，最多计算 3 点；与空息流形成相反构筑。"),
}


def _set_field(text: str, key: str, value) -> str:
    raw = "true" if value is True else "false" if value is False else str(value)
    pattern = re.compile(rf"^{re.escape(key)} = .+$", re.M)
    return pattern.sub(f"{key} = {raw}", text, count=1) if pattern.search(text) else text


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.tres"):
        text = path.read_text(encoding="utf-8")
        block = text.split("[resource]", 1)[1] if "[resource]" in text else ""
        match = re.search(r'^id = "([^"]+)"', block, re.M)
        if not match or match.group(1) not in CHANGES:
            continue
        values, tooltip = CHANGES[match.group(1)]
        updated = text
        for key, value in values.items():
            updated = _set_field(updated, key, value)
        updated = re.sub(r'^tooltip = ".*"$', "tooltip = " + json.dumps(tooltip, ensure_ascii=False), updated, count=1, flags=re.M)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            changed += 1
    print(f"rebalanced_relics={changed}")


if __name__ == "__main__":
    main()
