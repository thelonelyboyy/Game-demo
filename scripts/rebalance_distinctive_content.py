"""Give structurally duplicated cards distinct jobs without changing card IDs.

The pass is deterministic and safe to re-run.  It keeps each profession's
existing effect package, then differentiates duplicate packages through card
lifecycle, growth, sequencing conditions, or pile interaction.
"""

from __future__ import annotations

import json
import math
import re
from collections import defaultdict
from pathlib import Path

import card_effect_table as cet
import card_table as ct


ROOT = Path(__file__).resolve().parents[1]


def _set_res_field(text: str, key: str, value: str) -> str:
    head, resource = text.split("[resource]", 1)
    pattern = re.compile(rf"^{re.escape(key)} = .*$", re.M)
    if pattern.search(resource):
        resource = pattern.sub(f"{key} = {value}", resource, count=1)
    else:
        resource = re.sub(r'(\nscript = ExtResource\("[^"]+"\)\n)', rf'\1{key} = {value}\n', resource, count=1)
    return head + "[resource]" + resource


def _identity_tags(card: dict) -> list[str]:
    cid = card["id"]
    tags: list[str] = []
    if card["profession"] == "体修":
        tags.append("金身" if any(k in cid for k in ("gold", "bone", "skin", "guard")) else "承伤转化")
    elif card["profession"] == "剑修":
        tags.append("铸剑" if any(k in cid for k in ("forge", "marrow", "hundred", "nurture")) else "剑式连携")
    elif card["profession"] == "魔修":
        if any(k in cid for k in ("blood", "sacrifice")):
            tags.append("血炼")
        elif any(k in cid for k in ("soul", "mark", "ghost")):
            tags.append("魂印")
        elif any(k in cid for k in ("flame", "fire", "ash")):
            tags.append("魔焰")
        else:
            tags.append("煞气")
    elif card["profession"] == "驭兽":
        tags.append("召唤" if any(k in cid for k in ("call", "summon", "beast")) else "兽群")
    else:
        tags.append("五行术式" if card["element"] != "无" else "通用术式")
    return tags


def _existing_tags(text: str) -> list[str]:
    resource = text.split("[resource]", 1)[1]
    match = re.search(r'^mechanic_tags = PackedStringArray\((.*)\)$', resource, re.M)
    return json.loads("[" + match.group(1) + "]") if match and match.group(1).strip() else []


def _set_tags(text: str, additions: list[str]) -> str:
    tags = _existing_tags(text)
    if "循环术式" in additions and "循环" in tags:
        tags.remove("循环")
    for tag in additions:
        if tag not in tags:
            tags.append(tag)
    rendered = "PackedStringArray(" + ", ".join(json.dumps(tag, ensure_ascii=False) for tag in tags) + ")"
    return _set_res_field(text, "mechanic_tags", rendered)


def _add_condition(text: str, kind: int, card: dict) -> str:
    """Add a visible combo rider to the first numeric standard effect."""
    block_pattern = re.compile(r'(\[sub_resource type="Resource" id="[^"]+"\]\n)(.*?)(?=\n\[|\Z)', re.S)
    found = False

    def replace(match: re.Match[str]) -> str:
        nonlocal found
        body = match.group(2)
        amount_match = re.search(r'^amount = (\d+)$', body, re.M)
        description_match = re.search(r'^description_template = "([^"]*)"$', body, re.M)
        if found or not amount_match or not description_match:
            return match.group(0)
        found = True
        if re.search(r'^require_condition = true$', body, re.M):
            return match.group(0)
        amount = int(amount_match.group(1))
        bonus = max(1, math.ceil(amount * 0.5))
        fields = ["require_condition = true", f"condition_type = {kind}"]
        if kind == 6:
            # A non-identical preceding type creates an actual two-card sequence.
            wanted = {"攻击": 1, "技能": 0, "功法": 0}.get(card["type"], 0)
            fields.append(f"condition_card_type = {wanted}")
        else:
            element = ct.ELEMENT_R.get(card["element"], 0)
            wanted = element - 1 if element > 1 else (5 if element == 1 else 4)
            fields.append(f"condition_element = {wanted}")
        fields.append(f"bonus_amount = {bonus}")
        description = description_match.group(1)
        if "{condition}" not in description:
            description += " 连携（{condition}）：额外获得 {bonus} 点效果。"
        body = re.sub(r'^description_template = "[^"]*"$', f'description_template = "{description}"', body, count=1, flags=re.M)
        body = re.sub(r'(script = ExtResource\("[^"]+"\)\n)', r'\1' + "\n".join(fields) + "\n", body, count=1)
        return match.group(1) + body

    return block_pattern.sub(replace, text)


def _structure(card: dict, effects: list[dict]) -> tuple:
    return (
        card["type"], card["target"], card["cost"],
        tuple(sorted((row["trigger"], row["effect"], row["param"]) for row in effects)),
    )


def main() -> None:
    cards = [ct.parse_card(path) for path in ct.find_card_files()]
    effects_by_card: dict[str, list[dict]] = defaultdict(list)
    for row in cet.parse_all():
        effects_by_card[row["card_id"]].append(row)
    groups: dict[tuple, list[dict]] = defaultdict(list)
    for card in cards:
        if card["status_card"] or card["curse_card"] or card["eternal"] or card["profession"] == "融合":
            continue
        groups[_structure(card, effects_by_card[card["id"]])].append(card)

    changed: list[str] = []
    differentiated = 0
    for members in groups.values():
        if len(members) < 2:
            continue
        for index, card in enumerate(sorted(members, key=lambda value: value["id"])):
            path = ct.PROJECT_ROOT / card["file"]
            text = path.read_text(encoding="utf-8")
            specialty = ""
            variant = index % 8
            if variant == 0:
                text = _set_res_field(text, "retains", "true")
                text = _set_res_field(text, "growth_trigger", "4")
                text = _set_res_field(text, "growth_amount", "1")
                text = _set_res_field(text, "growth_limit", "3")
                specialty = "蓄势"
            elif variant == 1:
                text = _set_res_field(text, "innate", "true")
                specialty = "先手"
            elif variant == 2:
                text = _set_res_field(text, "exhausts", "true")
                specialty = "爆发"
            elif variant == 3:
                text = _set_res_field(text, "cyclic", "true")
                specialty = "循环术式"
            elif variant == 4:
                text = _add_condition(text, 6, card)
                specialty = "异式连携"
            elif variant == 5:
                text = _add_condition(text, 7, card)
                specialty = "五行连携"
            elif variant == 6:
                text = _set_res_field(text, "search_count", "1")
                text = _set_res_field(text, "exhausts", "true")
                specialty = "定向检索"
            else:
                text = _set_res_field(text, "retrieve_count", "1")
                specialty = "弃牌回收"
            text = _set_tags(text, _identity_tags(card) + [specialty])
            original = path.read_text(encoding="utf-8")
            if text != original:
                path.write_text(text, encoding="utf-8")
                changed.append(card["id"])
            differentiated += 1

    # Every card receives at least one readable identity tag in game_data.
    for card in cards:
        path = ct.PROJECT_ROOT / card["file"]
        text = path.read_text(encoding="utf-8")
        new_text = _set_tags(text, _identity_tags(card))
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            changed.append(card["id"])

    print(f"differentiated={differentiated} changed_files={len(set(changed))}")


if __name__ == "__main__":
    main()
