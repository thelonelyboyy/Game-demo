#!/usr/bin/env python3
"""Analyze the demonic draft pool and keep its balance report reproducible."""

from __future__ import annotations

import argparse
import re
from collections import Counter, OrderedDict
from dataclasses import dataclass
from pathlib import Path

import card_table

REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = REPO_ROOT / "game-demo"
POOL_PATH = PROJECT_ROOT / "characters" / "demonic_cultivator" / "demonic_cultivator_draftable_cards.tres"
REPORT_PATH = REPO_ROOT / "DEMONIC_BALANCE.md"

RARITY_ORDER = ["白", "蓝", "金", "暗金"]
TYPE_ORDER = ["攻击", "技能", "功法"]
ARCHETYPE_TOKENS = OrderedDict(
    [
        ("血契", ("献祭", "失去", "self_damage", "blood")),
        ("魔焰", ("煞气", "魔焰", "焰轮", "sha", "flame")),
        ("魂印", ("魂印", "soul_mark", "soul")),
        ("消耗", ("消耗", "净化", "exhaust")),
    ]
)
DAMAGE_EFFECT_SCRIPTS = (
    "configured_damage_effect.gd",
    "configured_flame_effect.gd",
    "configured_soul_mark_detonate_effect.gd",
    "configured_consume_status_to_damage_effect.gd",
    "configured_self_damage_scaling_damage_effect.gd",
    "configured_count_scaling_effect.gd",
    "configured_x_cost_damage_effect.gd",
    "low_health_bonus_damage_effect.gd",
)


@dataclass(frozen=True)
class PoolCard:
    path: str
    id: str
    name: str
    profession: str
    rarity: str
    card_type: str
    cost: int
    raw: str
    searchable: str

    def matches_archetype(self, tokens: tuple[str, ...]) -> bool:
        return any(token.lower() in self.searchable for token in tokens)


@dataclass
class PoolAnalysis:
    entries: list[PoolCard]
    unique_cards: list[PoolCard]
    rarity_counts: Counter[str]
    type_counts: Counter[str]
    cost_counts: Counter[int]
    archetype_cards: dict[str, list[PoolCard]]
    duplicate_weights: Counter[str]


def load_pool_analysis() -> PoolAnalysis:
    pool_text = POOL_PATH.read_text(encoding="utf-8")
    resource_paths = re.findall(r'path="(res://[^\"]+\.tres)"', pool_text)
    entries: list[PoolCard] = []
    for resource_path in resource_paths:
        if "/cards/" not in resource_path and "/common_cards/" not in resource_path:
            continue
        path = PROJECT_ROOT / resource_path.removeprefix("res://")
        parsed = card_table.parse_card(path)
        raw = path.read_text(encoding="utf-8", errors="replace")
        entries.append(
            PoolCard(
                path=resource_path,
                id=parsed["id"],
                name=parsed["name"],
                profession=parsed["profession"],
                rarity=parsed["rarity"],
                card_type=parsed["type"],
                cost=parsed["cost"],
                raw=raw,
                searchable=_build_searchable(parsed, raw),
            )
        )

    unique_by_id: OrderedDict[str, PoolCard] = OrderedDict()
    for card in entries:
        unique_by_id[card.id] = card
    unique_cards = list(unique_by_id.values())
    archetype_cards = {
        name: [card for card in unique_cards if card.matches_archetype(tokens)]
        for name, tokens in ARCHETYPE_TOKENS.items()
    }
    return PoolAnalysis(
        entries=entries,
        unique_cards=unique_cards,
        rarity_counts=Counter(card.rarity for card in unique_cards),
        type_counts=Counter(card.card_type for card in unique_cards),
        cost_counts=Counter(card.cost for card in unique_cards),
        archetype_cards=archetype_cards,
        duplicate_weights=Counter(card.id for card in entries),
    )


def _build_searchable(parsed: dict, raw: str) -> str:
    resource_section = raw.split("[resource]", 1)[1] if "[resource]" in raw else raw
    tags_match = re.search(r"^mechanic_tags = PackedStringArray\((.*)\)$", resource_section, re.M)
    tags = " ".join(re.findall(r'"([^\"]+)"', tags_match.group(1))) if tags_match else ""
    effect_text_match = re.search(r'^effect_text = "([^\"]*)"', resource_section, re.M)
    effect_text = effect_text_match.group(1) if effect_text_match else ""
    effect_scripts = " ".join(
        re.findall(r"res://custom_resources/effects/([a-z_]+)\.gd", raw)
    )
    status_ids = " ".join(re.findall(r"res://statuses/([a-z_0-9]+)\.tres", raw))
    hints: list[str] = []
    if parsed["exhausts"]:
        hints.extend(("消耗", "exhaust"))
    if "configured_self_damage" in effect_scripts or "x_cost_self_damage" in effect_scripts:
        hints.extend(("失去", "self_damage"))
    if "configured_flame_effect" in effect_scripts:
        hints.extend(("魔焰", "flame"))
    if "configured_purge_affliction_effect" in effect_scripts or "configured_exhaust_random_effect" in effect_scripts:
        hints.extend(("消耗", "净化", "exhaust"))
    return " ".join(
        (
            parsed["id"],
            parsed["name"],
            tags,
            effect_text,
            effect_scripts,
            status_ids,
            " ".join(hints),
        )
    ).lower()


def validate_analysis(analysis: PoolAnalysis) -> list[str]:
    errors: list[str] = []
    total = len(analysis.unique_cards)
    if not 75 <= total <= 100:
        errors.append(f"unique card count must stay in 75..100, got {total}")

    rarity_minimums = {"白": 24, "蓝": 24, "金": 12, "暗金": 4}
    for rarity, minimum in rarity_minimums.items():
        actual = analysis.rarity_counts[rarity]
        if actual < minimum:
            errors.append(f"{rarity} supply is too small: {actual}/{minimum}")

    type_ratio_ranges = {
        "攻击": (0.30, 0.50),
        "技能": (0.30, 0.55),
        "功法": (0.12, 0.25),
    }
    for card_type, (minimum, maximum) in type_ratio_ranges.items():
        ratio = analysis.type_counts[card_type] / max(total, 1)
        if not minimum <= ratio <= maximum:
            errors.append(f"{card_type} ratio {ratio:.1%} is outside {minimum:.0%}..{maximum:.0%}")

    one_cost_ratio = analysis.cost_counts[1] / max(total, 1)
    if not 0.50 <= one_cost_ratio <= 0.75:
        errors.append(f"one-cost ratio {one_cost_ratio:.1%} is outside 50%..75%")
    if analysis.cost_counts[-1] != 2:
        errors.append(f"demonic pool must contain exactly two X-cost cards, got {analysis.cost_counts[-1]}")
    expensive_count = sum(count for cost, count in analysis.cost_counts.items() if cost >= 3)
    if expensive_count / max(total, 1) > 0.10:
        errors.append(f"3+ cost cards exceed 10% of the pool: {expensive_count}/{total}")

    for archetype, cards in analysis.archetype_cards.items():
        if len(cards) < 15:
            errors.append(f"{archetype} archetype supply is too small: {len(cards)}/15")
        rarity_supply = Counter(card.rarity for card in cards)
        if rarity_supply["白"] < 5:
            errors.append(f"{archetype} archetype has too few common starters: {rarity_supply['白']}/5")
        for required_rarity in ("白", "蓝", "金"):
            if rarity_supply[required_rarity] == 0:
                errors.append(f"{archetype} archetype has no {required_rarity} card")

    maximum_weight = max(analysis.duplicate_weights.values(), default=0)
    if maximum_weight > 3:
        errors.append(f"a card has draft weight {maximum_weight}; maximum allowed is 3")

    for card in analysis.unique_cards:
        if not card.id:
            errors.append(f"card at {card.path} has an empty id")
        if card.card_type == "攻击" and not any(token in card.raw for token in DAMAGE_EFFECT_SCRIPTS):
            errors.append(f"attack card {card.id} has no recognized damage effect")
    return errors


def _share(count: int, total: int) -> str:
    return f"{count / max(total, 1):.1%}"


def render_report(analysis: PoolAnalysis) -> str:
    total = len(analysis.unique_cards)
    errors = validate_analysis(analysis)
    lines = [
        "# 魔修卡池平衡报告",
        "",
        "> 本文件由 `python scripts/demonic_pool_balance.py --write` 生成，请勿手工编辑。",
        "",
        "## 验证结论",
        "",
        f"- 状态：{'通过' if not errors else '失败'}",
        f"- 奖励池条目：{len(analysis.entries)}",
        f"- 唯一卡牌 ID：{total}",
        f"- 重复权重条目：{len(analysis.entries) - total}",
        "",
        "## 稀有度供给",
        "",
        "| 稀有度 | 数量 | 唯一池占比 | 最低门槛 |",
        "|---|---:|---:|---:|",
    ]
    rarity_minimums = {"白": 24, "蓝": 24, "金": 12, "暗金": 4}
    for rarity in RARITY_ORDER:
        count = analysis.rarity_counts[rarity]
        lines.append(f"| {rarity} | {count} | {_share(count, total)} | {rarity_minimums[rarity]} |")

    lines.extend(
        [
            "",
            "## 类型与费用曲线",
            "",
            "| 类型 | 数量 | 占比 |",
            "|---|---:|---:|",
        ]
    )
    for card_type in TYPE_ORDER:
        count = analysis.type_counts[card_type]
        lines.append(f"| {card_type} | {count} | {_share(count, total)} |")
    lines.extend(["", "| 费用 | 数量 | 占比 |", "|---:|---:|---:|"])
    for cost in sorted(analysis.cost_counts):
        label = "X" if cost == -1 else str(cost)
        count = analysis.cost_counts[cost]
        lines.append(f"| {label} | {count} | {_share(count, total)} |")

    lines.extend(
        [
            "",
            "## 四条构筑路线供给",
            "",
            "| 路线 | 总数 | 白 | 蓝 | 金 | 暗金 |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for archetype, cards in analysis.archetype_cards.items():
        rarity_counts = Counter(card.rarity for card in cards)
        lines.append(
            f"| {archetype} | {len(cards)} | "
            + " | ".join(str(rarity_counts[rarity]) for rarity in RARITY_ORDER)
            + " |"
        )

    weighted = [(card_id, count) for card_id, count in analysis.duplicate_weights.items() if count > 1]
    lines.extend(
        [
            "",
            "## 显式重复权重",
            "",
            "| 卡牌 ID | 权重 |",
            "|---|---:|",
        ]
    )
    for card_id, count in sorted(weighted, key=lambda item: (-item[1], item[0])):
        lines.append(f"| `{card_id}` | {count} |")

    lines.extend(
        [
            "",
            "## 设计说明",
            "",
            "- 奖励流程先按章节概率选择稀有度，再在该档候选中应用流派权重；因此稀有度表衡量的是内容供给，不等同于实际掉率。",
            "- 魔修保持攻击前倾，但攻击、技能、功法均设有宽松比例护栏，防止后续批量加牌破坏费用与类型曲线。",
            "- 血契、魔焰、魂印、消耗四条路线都必须覆盖白/蓝/金三档，保证第一章能起步、第二章能成型、Boss 奖励有终结组件。",
            "- 重复资源只承担显式初期权重，单卡最高权重限制为 3，避免同一张牌挤压奖励多样性。",
        ]
    )
    if errors:
        lines.extend(["", "## 失败项", ""])
        lines.extend(f"- {error}" for error in errors)
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true", help="Write the deterministic Markdown report.")
    parser.add_argument("--check", action="store_true", help="Validate thresholds and report freshness.")
    args = parser.parse_args()

    analysis = load_pool_analysis()
    report = render_report(analysis)
    errors = validate_analysis(analysis)
    if args.write:
        REPORT_PATH.write_text(report, encoding="utf-8")
        print(f"wrote {REPORT_PATH}")
    if args.check:
        if not REPORT_PATH.exists():
            errors.append(f"missing generated report: {REPORT_PATH}")
        elif REPORT_PATH.read_text(encoding="utf-8") != report:
            errors.append("DEMONIC_BALANCE.md is stale; run with --write")
    if not args.write and not args.check:
        print(report, end="")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
