#!/usr/bin/env python3
"""Validate standardized card effects and keyword fields across every card."""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

try:
    import card_effect_table
    import card_table
    import game_data_labels
except ModuleNotFoundError:
    from scripts import card_effect_table, card_table, game_data_labels


STANDARD_TAGS = {
    "消耗", "消耗牌", "保留", "保留牌", "固有", "固有牌", "永恒", "永恒牌",
    "虚无", "虚无牌", "临时", "临时牌", "周天", "循环", "循环牌", "不可打出",
    "不能打出", "无法打出", "状态", "状态牌", "诅咒", "诅咒牌", "弃牌触发",
    "弃置触发", "消耗触发", "消耗时触发", "抽牌触发", "抽到时触发", "滞留触发",
    "回合结束触发", "成长", "成长牌",
}
KEYWORD_COUNTS = ("search_count", "retrieve_count", "reclaim_count")
TRIGGER_FIELDS = tuple(card_effect_table.TRIGGERS)


def resource_section(text: str) -> str:
    return text.split("[resource]", 1)[1] if "[resource]" in text else ""


def resource_array_refs(text: str, field: str) -> list[str]:
    match = re.search(rf"^{re.escape(field)} = .*?\((.*)\)$", resource_section(text), re.M)
    return re.findall(r'SubResource\("([^"]+)"\)', match.group(1)) if match else []


def effect_blocks(text: str) -> dict[str, str]:
    return {
        match.group(1): match.group(2)
        for match in re.finditer(
            r'\[sub_resource type="Resource" id="([^"]+)"\]\n(.*?)(?=\n\[|\Z)',
            text,
            re.S,
        )
    }


def script_map(text: str) -> dict[str, str]:
    return {
        match.group(2): match.group(1)
        for match in re.finditer(
            r'\[ext_resource type="Script"[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"',
            text,
        )
    }


def main() -> int:
    errors: list[str] = []
    cards = card_table.find_card_files()
    ids: Counter[str] = Counter()
    component_count = 0
    cards_with_multiple_components = 0
    keyword_counts: Counter[str] = Counter()

    for path in cards:
        rel = path.relative_to(card_table.PROJECT_ROOT).as_posix()
        text = path.read_text(encoding="utf-8", errors="ignore")
        parsed = card_table.parse_card(path)
        ids[parsed["id"]] += 1
        for key in (
            "exhausts", "retains", "innate", "eternal", "ethereal", "temporary_keyword",
            "cyclic", "unplayable", "status_card", "curse_card",
        ):
            if parsed[key]:
                keyword_counts[key] += 1
        for key in KEYWORD_COUNTS:
            if parsed[key] > 0:
                keyword_counts[key] += 1
            if not 0 <= parsed[key] <= 10:
                errors.append(f"{rel}: {key} 必须在 0..10")

        tags_match = re.search(r"^mechanic_tags = PackedStringArray\((.*)\)$", resource_section(text), re.M)
        tags = re.findall(r'"([^"]+)"', tags_match.group(1)) if tags_match else []
        duplicated = sorted(set(tags) & STANDARD_TAGS)
        if duplicated:
            errors.append(f"{rel}: 标准关键词仍混在 mechanic_tags: {', '.join(duplicated)}")

        scripts = script_map(text)
        blocks = effect_blocks(text)
        referenced: list[str] = []
        for field in TRIGGER_FIELDS:
            referenced.extend(resource_array_refs(text, field))
        top_level_count = len(referenced) + sum(int(parsed[key] > 0) for key in KEYWORD_COUNTS)
        component_count += top_level_count
        if top_level_count > 1:
            cards_with_multiple_components += 1

        for effect_id in referenced:
            body = blocks.get(effect_id)
            if body is None:
                errors.append(f"{rel}: 标准效果 {effect_id} 未定义")
                continue
            ext = re.search(r'script = ExtResource\("([^"]+)"\)', body)
            script_path = scripts.get(ext.group(1), "") if ext else ""
            if "/custom_resources/effects/" not in script_path:
                errors.append(f"{rel}: {effect_id} 未使用标准效果组件脚本")
                continue
            disk_path = card_table.PROJECT_ROOT / script_path.removeprefix("res://")
            script_text = disk_path.read_text(encoding="utf-8", errors="ignore") if disk_path.exists() else ""
            if not re.search(r"^func execute\(", script_text, re.M):
                errors.append(f"{rel}: {script_path} 缺少 execute 标准接口")

        # All effect subresources must be referenced either by a lifecycle array or by
        # another effect component. This catches detached legacy payloads.
        for effect_id in blocks:
            if effect_id in referenced:
                continue
            if re.search(rf'SubResource\("{re.escape(effect_id)}"\)', text.replace(blocks[effect_id], "")):
                continue
            body = blocks[effect_id]
            ext = re.search(r'script = ExtResource\("([^"]+)"\)', body)
            script_path = scripts.get(ext.group(1), "") if ext else ""
            if "/custom_resources/effects/" in script_path:
                errors.append(f"{rel}: 游离效果组件 {effect_id}")

    for card_id, count in ids.items():
        if not card_id:
            errors.append("存在缺少 ID 的卡牌")
        elif count > 1:
            errors.append(f"重复卡牌 ID: {card_id} ({count})")

    rows = card_effect_table.parse_all()
    observed_scripts = {Path(row["script_path"]).stem for row in rows}
    missing_labels = sorted(name for name in observed_scripts if name not in game_data_labels.CARD_EFFECT_LABELS)
    if missing_labels:
        errors.append("效果中文名称映射缺失: " + ", ".join(missing_labels))

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(
        "CARD_STANDARDIZATION_OK "
        f"cards={len(cards)} components={component_count} numeric_rows={len(rows)} "
        f"multi_component_cards={cards_with_multiple_components} keywords={dict(keyword_counts)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
