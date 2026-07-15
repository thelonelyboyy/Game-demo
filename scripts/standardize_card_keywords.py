"""Migrate lifecycle keywords out of free-form mechanic_tags into Card fields."""

from __future__ import annotations

import re

import card_table as ct


TAG_FIELDS = {
    "消耗": "exhausts",
    "消耗牌": "exhausts",
    "保留": "retains",
    "保留牌": "retains",
    "固有": "innate",
    "固有牌": "innate",
    "永恒": "eternal",
    "永恒牌": "eternal",
    "虚无": "ethereal",
    "虚无牌": "ethereal",
    "临时": "temporary_keyword",
    "临时牌": "temporary_keyword",
    "周天": "cyclic",
    "循环": "cyclic",
    "循环牌": "cyclic",
    "不可打出": "unplayable",
    "不能打出": "unplayable",
    "无法打出": "unplayable",
    "状态": "status_card",
    "状态牌": "status_card",
    "诅咒": "curse_card",
    "诅咒牌": "curse_card",
}

DERIVED_TAG_FIELDS = {
    "弃牌触发": "discard_trigger_effects",
    "弃置触发": "discard_trigger_effects",
    "消耗触发": "exhaust_trigger_effects",
    "消耗时触发": "exhaust_trigger_effects",
    "抽牌触发": "draw_trigger_effects",
    "抽到时触发": "draw_trigger_effects",
    "滞留触发": "end_turn_trigger_effects",
    "回合结束触发": "end_turn_trigger_effects",
}


def _set_true(resource: str, key: str) -> str:
    pattern = re.compile(rf"^{re.escape(key)} = (?:true|false)$", re.M)
    if pattern.search(resource):
        return pattern.sub(f"{key} = true", resource, count=1)
    anchor = re.search(r"^exhausts = .*$", resource, re.M)
    if anchor:
        return resource[: anchor.end()] + f"\n{key} = true" + resource[anchor.end() :]
    anchor = re.search(r"^cost = .*$", resource, re.M)
    if anchor:
        return resource[: anchor.end()] + f"\n{key} = true" + resource[anchor.end() :]
    script = re.search(r'^script = ExtResource\("[^"]+"\)$', resource, re.M)
    if script:
        return resource[: script.end()] + f"\n{key} = true" + resource[script.end() :]
    raise ValueError(f"cannot insert {key}")


def migrate_text(text: str) -> str:
    if "[resource]" not in text:
        return text
    head, resource = text.split("[resource]", 1)
    tags_match = re.search(r"^mechanic_tags = PackedStringArray\((.*)\)$", resource, re.M)
    if not tags_match:
        return text
    tags = re.findall(r'"([^"]+)"', tags_match.group(1))
    remaining: list[str] = []
    for tag in tags:
        if tag in TAG_FIELDS:
            resource = _set_true(resource, TAG_FIELDS[tag])
            continue
        derived_field = DERIVED_TAG_FIELDS.get(tag)
        if derived_field and re.search(rf"^{derived_field} = .*SubResource", resource, re.M):
            continue
        if tag == "成长" and re.search(r"^growth_trigger = [1-9]\d*$", resource, re.M):
            continue
        remaining.append(tag)

    if remaining:
        encoded = ", ".join(f'"{tag}"' for tag in remaining)
        resource = re.sub(
            r"^mechanic_tags = PackedStringArray\(.*\)$",
            f"mechanic_tags = PackedStringArray({encoded})",
            resource,
            count=1,
            flags=re.M,
        )
    else:
        resource = re.sub(r"^mechanic_tags = PackedStringArray\(.*\)\n?", "", resource, count=1, flags=re.M)
    return head + "[resource]" + resource


def main() -> None:
    changed = 0
    for path in ct.find_card_files():
        text = path.read_text(encoding="utf-8")
        migrated = migrate_text(text)
        if migrated != text:
            path.write_text(migrated, encoding="utf-8")
            changed += 1
    print(f"standardized keyword fields in {changed} card resources")


if __name__ == "__main__":
    main()
