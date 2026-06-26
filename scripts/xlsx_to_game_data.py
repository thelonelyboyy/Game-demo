"""Write edited game_data.xlsx back into card .tres, blessings.json and AI .tscn.

Run:  python scripts/xlsx_to_game_data.py
然后在 Godot 编辑器里导入一次（--editor --quit）。
"""

from __future__ import annotations

from pathlib import Path

from openpyxl import load_workbook

import card_table as ct
import blessing_table as bt
import ai_table as at

XLSX = Path(__file__).resolve().parents[1] / "game_data.xlsx"


def _rowvals(ws):
    headers = [c.value for c in ws[1]]
    idx = {h: i for i, h in enumerate(headers)}
    for r in range(2, ws.max_row + 1):
        yield idx, [c.value for c in ws[r]]


def import_cards(ws, errors) -> int:
    changed = 0
    for idx, vals in _rowvals(ws):
        if not vals or not vals[idx["文件"]]:
            continue
        rel = str(vals[idx["文件"]]).strip()
        path = ct.PROJECT_ROOT / rel
        if not path.exists():
            errors.append(f"[卡牌] file not found {rel}")
            continue

        def gv(name, default=""):
            v = vals[idx[name]]
            return default if v is None else v

        try:
            row = {
                "name": str(gv("名称")),
                "cost": int(gv("费用", 0)),
                "type": str(gv("类型")).strip(),
                "target": str(gv("目标")).strip(),
                "rarity": str(gv("稀有度")).strip(),
                "exhausts": str(gv("消耗")).strip() == "是",
                "element": str(gv("元素")).strip(),
                "effect_amounts": [],
            }
            for key, table in (("type", ct.TYPE_R), ("target", ct.TARGET_R),
                               ("rarity", ct.RARITY_R), ("element", ct.ELEMENT_R)):
                if row[key] not in table:
                    raise ValueError(f"非法{key}值 '{row[key]}'")
            for i in range(1, ct.MAX_EFFECTS + 1):
                label = vals[idx[f"效果{i}"]]
                amt = vals[idx[f"效果{i}值"]]
                row["effect_amounts"].append(None if label in (None, "")
                                             else (int(amt) if amt is not None else None))
        except (ValueError, TypeError) as e:
            errors.append(f"[卡牌] {rel}: {e}")
            continue

        if ct.update_card_file(path, row):
            changed += 1
    return changed


def import_blessings(ws, errors) -> bool:
    rows = []
    for idx, vals in _rowvals(ws):
        if not vals or not vals[idx["来源"]]:
            continue

        def gv(name, default=""):
            v = vals[idx[name]]
            return default if v is None else v

        effects = []
        for i in range(1, bt.MAX_EFFECTS + 1):
            t = gv(f"效果{i}")
            a = vals[idx[f"效果{i}值"]]
            t = str(t).strip()
            if t:
                try:
                    effects.append((t, int(a) if a is not None else 0))
                except (ValueError, TypeError):
                    errors.append(f"[祝福] {gv('祝福名')}: 效果{i}值非数字 '{a}'")
        rows.append({
            "source": str(gv("来源")).strip(),
            "source_desc": str(gv("来源描述")),
            "name": str(gv("祝福名")),
            "desc": str(gv("祝福描述")),
            "cls": str(gv("命格")).strip(),
            "icon": str(gv("图标")).strip(),
            "effects": effects,
        })
    return bt.write_rows(rows)


def import_ai(ws, errors) -> int:
    # group by 文件
    by_file: dict[str, dict] = {}
    order: list[str] = []
    for idx, vals in _rowvals(ws):
        if not vals or not vals[idx["文件"]]:
            continue
        rel = str(vals[idx["文件"]]).strip()
        if rel not in by_file:
            by_file[rel] = {"seq": "", "actions": []}
            order.append(rel)
        type_label = str(vals[idx["类型"]]).strip()
        field = "block" if type_label == at.TYPE_BLOCK else "damage"
        try:
            value = int(vals[idx["数值"]])
        except (ValueError, TypeError):
            errors.append(f"[怪物AI] {rel} {vals[idx['行动']]}: 数值非数字")
            continue
        by_file[rel]["actions"].append({"node": str(vals[idx["行动"]]).strip(),
                                        "field": field, "value": value})
        seq = vals[idx["出招序列"]]
        if seq not in (None, "") and not by_file[rel]["seq"]:
            by_file[rel]["seq"] = str(seq).strip()

    changed = 0
    for rel in order:
        info = by_file[rel]
        if at.write_file(rel, info["seq"], info["actions"]):
            changed += 1
    return changed


def main() -> None:
    if not XLSX.exists():
        raise SystemExit(f"not found: {XLSX} (先跑 game_data_to_xlsx.py)")

    wb = load_workbook(XLSX, data_only=True)
    errors: list[str] = []

    n_cards = import_cards(wb["卡牌"], errors)
    bless_changed = import_blessings(wb["祝福"], errors)
    n_ai = import_ai(wb["怪物AI"], errors)

    print(f"卡牌: 更新 {n_cards} 个文件")
    print(f"祝福: {'已更新 blessings.json' if bless_changed else '无改动'}")
    print(f"怪物AI: 更新 {n_ai} 个文件")
    if errors:
        print("跳过(有错误):")
        for e in errors:
            print("  " + e)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
