"""Export ALL tunable game data into one workbook: game_data.xlsx.

包含三张数据表：卡牌 / 祝福 / 怪物AI，外加一张说明。
改完表后运行 scripts/xlsx_to_game_data.py 回写，再在 Godot 导入一次。
"""

from __future__ import annotations

from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.worksheet.datavalidation import DataValidation

import card_table as ct
import blessing_table as bt
import ai_table as at

OUT = Path(__file__).resolve().parents[1] / "game_data.xlsx"

FONT = "Microsoft YaHei"
HEADER_FILL = PatternFill("solid", fgColor="2C2418")
READONLY_FILL = PatternFill("solid", fgColor="EDEDED")
EDIT_FILL = PatternFill("solid", fgColor="FFFDE7")
_thin = Side(style="thin", color="D0D0D0")
BORDER = Border(left=_thin, right=_thin, top=_thin, bottom=_thin)
ICON_KEYS = ["max_health", "full_heal", "gold", "max_mana", "draw", "upgrade",
             "remove_card", "duplicate_card", "relic"]


def _style_header(ws, ncols):
    for c in range(1, ncols + 1):
        cell = ws.cell(1, c)
        cell.font = Font(name=FONT, bold=True, color="FFF0BC")
        cell.fill = HEADER_FILL
        cell.alignment = Alignment(horizontal="center", vertical="center")
        cell.border = BORDER


def _style_body(ws, ncols, readonly_cols):
    for r in range(2, ws.max_row + 1):
        for c in range(1, ncols + 1):
            cell = ws.cell(r, c)
            cell.font = Font(name=FONT)
            cell.border = BORDER
            cell.alignment = Alignment(horizontal="center" if c != 1 else "left", vertical="center")
            cell.fill = READONLY_FILL if c in readonly_cols else EDIT_FILL


def _dv(ws, values, col, last_row):
    d = DataValidation(type="list", formula1='"%s"' % ",".join(values), allow_blank=True)
    ws.add_data_validation(d)
    d.add(f"{ws.cell(1, col).column_letter}2:{ws.cell(1, col).column_letter}{last_row}")


def _widths(ws, widths):
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[ws.cell(1, c).column_letter].width = w


def build_cards(ws):
    headers = ["文件", "id", "职业", "名称", "费用", "类型", "目标", "稀有度", "消耗", "元素"]
    for i in range(1, ct.MAX_EFFECTS + 1):
        headers += [f"效果{i}", f"效果{i}值"]
    ws.append(headers)
    readonly = {1, 2, 3}
    for i in range(ct.MAX_EFFECTS):
        readonly.add(11 + i * 2)
    for card in (ct.parse_card(p) for p in ct.find_card_files()):
        row = [card["file"], card["id"], card["profession"], card["name"], card["cost"],
               card["type"], card["target"], card["rarity"], "是" if card["exhausts"] else "否", card["element"]]
        for i in range(ct.MAX_EFFECTS):
            if i < len(card["effects"]):
                label, amount, extra = card["effects"][i]
                row += [f"{label}({extra})" if extra else label, amount]
            else:
                row += ["", None]
        ws.append(row)
    _style_header(ws, len(headers))
    _style_body(ws, len(headers), readonly)
    last = ws.max_row
    _dv(ws, list(ct.TYPE.values()), 6, last)
    _dv(ws, list(ct.TARGET.values()), 7, last)
    _dv(ws, list(ct.RARITY.values()), 8, last)
    _dv(ws, ["是", "否"], 9, last)
    _dv(ws, list(ct.ELEMENT.values()), 10, last)
    _widths(ws, [42, 24, 6, 12, 5, 6, 7, 7, 5, 5] + [10, 7] * ct.MAX_EFFECTS)
    ws.freeze_panes = "D2"


def build_blessings(ws):
    headers = ["来源", "来源描述", "祝福名", "祝福描述", "命格", "图标"]
    for i in range(1, bt.MAX_EFFECTS + 1):
        headers += [f"效果{i}", f"效果{i}值"]
    ws.append(headers)
    readonly = {1, 2}
    for r in bt.to_rows():
        row = [r["source"], r["source_desc"], r["name"], r["desc"], r["cls"], r["icon"]]
        for i in range(bt.MAX_EFFECTS):
            if i < len(r["effects"]):
                t, a = r["effects"][i]
                row += [t, a]
            else:
                row += ["", None]
        ws.append(row)
    _style_header(ws, len(headers))
    _style_body(ws, len(headers), readonly)
    last = ws.max_row
    _dv(ws, bt.CLASS_VALUES, 5, last)
    _dv(ws, ICON_KEYS, 6, last)
    for i in range(bt.MAX_EFFECTS):
        _dv(ws, [""] + bt.EFFECT_TYPES, 7 + i * 2, last)
    _widths(ws, [12, 30, 14, 42, 10, 12] + [14, 8] * bt.MAX_EFFECTS)
    ws.freeze_panes = "C2"


def build_ai(ws):
    headers = ["敌人", "文件", "行动", "类型", "数值", "出招序列"]
    ws.append(headers)
    readonly = {1, 2, 3, 4}
    for ai in at.parse_all():
        for i, a in enumerate(ai["actions"]):
            ws.append([ai["name"], ai["file"], a["node"], a["type"], a["value"],
                       ai["sequence"] if i == 0 else ""])
    _style_header(ws, len(headers))
    _style_body(ws, len(headers), readonly)
    _widths(ws, [12, 52, 18, 8, 7, 16])
    ws.freeze_panes = "C2"


def build_legend(ws):
    notes = [
        "万劫求仙 数值总表 — 使用说明",
        "",
        "1. 只改【浅黄色】列；【灰色】列是只读定位/分组用，尽量别动。",
        "2. 改完保存后运行：python scripts/xlsx_to_game_data.py",
        "3. 然后在 Godot 编辑器里导入一次（--editor --quit）。",
        "",
        "【卡牌】只调数值（费用 / 各效果值）；增删效果、改状态种类仍在 Godot 改。",
        "【祝福】可改 祝福描述/命格/效果类型/效果值；导入时按表整体重建 blessings.json。",
        "   效果类型: " + " / ".join(bt.EFFECT_TYPES),
        "   命格: 空=通用, demonic=魔修, sword=剑修, body=体修, beastmaster=驭兽",
        "   lose_max_health / lose_gold 为代价类效果（负面）。",
        "【怪物AI】只覆盖 4 个固定套路敌人；改 数值 与 出招序列。",
        "   出招序列: 子节点下标(从0)按回合循环，如 0,1,2 = 第1回合行动0 → 第2回合行动1 → ...",
        "   格挡行动改数值时，意图显示文字会自动同步。",
    ]
    for n in notes:
        ws.append([n])
    ws.column_dimensions["A"].width = 96
    ws["A1"].font = Font(name=FONT, bold=True, size=13)


def main() -> None:
    wb = Workbook()
    ws_cards = wb.active
    ws_cards.title = "卡牌"
    build_cards(ws_cards)
    build_blessings(wb.create_sheet("祝福"))
    build_ai(wb.create_sheet("怪物AI"))
    build_legend(wb.create_sheet("说明"))
    wb.save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
