"""Card fusion recipe table with create/update/enable writeback."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    import card_table as ct
except ModuleNotFoundError:
    from scripts import card_table as ct

ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = ROOT / "game-demo"
RECIPE_ROOT = PROJECT_ROOT / "fusion_recipes"
LIBRARY_PATH = RECIPE_ROOT / "card_fusion_library.tres"
RECIPE_ID_RE = re.compile(r"^[a-z0-9_]+$")


def _field(text: str, key: str) -> str:
    m = re.search(rf'^{key} = "((?:\\.|[^"\\])*)"', text.split("[resource]", 1)[-1], re.M)
    return json.loads('"' + m.group(1) + '"') if m else ""


def _int(text: str, key: str, default: int) -> int:
    m = re.search(rf"^{key} = (-?\d+)", text.split("[resource]", 1)[-1], re.M)
    return int(m.group(1)) if m else default


def _library_recipe_paths() -> list[str]:
    if not LIBRARY_PATH.exists():
        return []
    text = LIBRARY_PATH.read_text(encoding="utf-8")
    return re.findall(r'path="(res://fusion_recipes/[^"/]+\.tres)"', text)


def parse_all() -> list[dict]:
    cards = {card["id"]: card for card in (ct.parse_card(path) for path in ct.find_card_files())}
    enabled_paths = set(_library_recipe_paths())
    rows: list[dict] = []
    for path in sorted(RECIPE_ROOT.glob("*.tres")):
        if path == LIBRARY_PATH:
            continue
        text = path.read_text(encoding="utf-8")
        first_id, second_id = _field(text, "first_card_id"), _field(text, "second_card_id")
        result_m = re.search(r'\[ext_resource type="Resource" path="([^"]+)" id="([^"]+)"\]', text)
        result_path = result_m.group(1) if result_m and "/fusion_cards/" in result_m.group(1) else ""
        result_id = ""
        result_name = _field(text, "result_name")
        result_cost = _int(text, "result_cost", -99)
        if result_path:
            result_file = PROJECT_ROOT / result_path.removeprefix("res://")
            result_card = ct.parse_card(result_file)
            result_id, result_name, result_cost = result_card["id"], result_card["name"], result_card["cost"]
        resource_path = f"res://fusion_recipes/{path.name}"
        rows.append({
            "enabled": resource_path in enabled_paths,
            "file": path.relative_to(ROOT).as_posix(),
            "recipe_id": path.stem,
            "first_id": first_id,
            "first_name": cards.get(first_id, {}).get("name", "未找到"),
            "second_id": second_id,
            "second_name": cards.get(second_id, {}).get("name", "未找到"),
            "mode": "固定成品卡" if result_path else "动态合成",
            "result_path": result_path,
            "result_id": result_id,
            "result_name": result_name,
            "result_cost": result_cost,
            "cost_note": "使用成品卡费用" if result_path else ("自动计算" if result_cost < -1 else "固定费用"),
        })
    return rows


def _recipe_file(row: dict) -> Path:
    raw_file = str(row.get("file", "")).strip()
    recipe_id = str(row.get("recipe_id", "")).strip()
    if not RECIPE_ID_RE.fullmatch(recipe_id):
        raise ValueError(f"配方ID只能使用小写英文、数字和下划线：'{recipe_id}'")
    if raw_file.startswith("res://"):
        path = PROJECT_ROOT / raw_file.removeprefix("res://")
    elif raw_file:
        path = ROOT / raw_file
    else:
        path = RECIPE_ROOT / f"{recipe_id}.tres"
    path = path.resolve()
    if path.parent != RECIPE_ROOT.resolve() or path.suffix != ".tres":
        raise ValueError("配方文件必须位于 game-demo/fusion_recipes 且扩展名为 .tres")
    return path


def _result_resource_path(raw_path: str) -> tuple[str, Path]:
    resource_path = raw_path.strip()
    if not resource_path.startswith("res://fusion_cards/") or not resource_path.endswith(".tres"):
        raise ValueError("固定成品卡的结果卡文件必须是 res://fusion_cards/*.tres")
    path = (PROJECT_ROOT / resource_path.removeprefix("res://")).resolve()
    if not path.exists():
        raise ValueError(f"结果卡文件不存在：{resource_path}")
    return resource_path, path


def _render_recipe(row: dict) -> str:
    first_id = str(row["first_id"]).strip()
    second_id = str(row["second_id"]).strip()
    mode = str(row["mode"]).strip()
    lines = [
        '[gd_resource type="Resource" script_class="CardFusionRecipe" load_steps=%d format=3]' %
        (3 if mode == "固定成品卡" else 2),
        "",
        '[ext_resource type="Script" path="res://custom_resources/card_fusion_recipe.gd" id="1"]',
    ]
    if mode == "固定成品卡":
        result_path, _ = _result_resource_path(str(row.get("result_path", "")))
        lines.append(f'[ext_resource type="Resource" path="{result_path}" id="2"]')
    lines += [
        "",
        "[resource]",
        'script = ExtResource("1")',
        f"first_card_id = {json.dumps(first_id, ensure_ascii=False)}",
        f"second_card_id = {json.dumps(second_id, ensure_ascii=False)}",
    ]
    if mode == "固定成品卡":
        lines.append('result_card = ExtResource("2")')
    else:
        lines.append(f"result_name = {json.dumps(str(row.get('result_name', '')).strip(), ensure_ascii=False)}")
        lines.append(f"result_cost = {int(row.get('result_cost', -99))}")
    return "\n".join(lines) + "\n"


def _write_library(active_paths: list[str]) -> bool:
    current_order = _library_recipe_paths()
    desired = set(active_paths)
    ordered = [path for path in current_order if path in desired]
    ordered.extend(path for path in active_paths if path not in ordered)
    lines = [
        f'[gd_resource type="Resource" script_class="CardFusionLibrary" load_steps={len(ordered) + 2} format=3]',
        "",
        '[ext_resource type="Script" path="res://custom_resources/card_fusion_library.gd" id="1"]',
    ]
    for index, resource_path in enumerate(ordered, 2):
        lines.append(f'[ext_resource type="Resource" path="{resource_path}" id="{index}"]')
    references = ", ".join(f'ExtResource("{index}")' for index in range(2, len(ordered) + 2))
    lines += [
        "",
        "[resource]",
        'script = ExtResource("1")',
        'recipes = Array[Resource("res://custom_resources/card_fusion_recipe.gd")]([%s])' % references,
    ]
    rendered = "\n".join(lines) + "\n"
    original = LIBRARY_PATH.read_text(encoding="utf-8") if LIBRARY_PATH.exists() else ""
    if rendered == original:
        return False
    LIBRARY_PATH.write_text(rendered, encoding="utf-8")
    return True


def write_rows(rows: list[dict]) -> int:
    cards = {card["id"]: card for card in (ct.parse_card(path) for path in ct.find_card_files())}
    seen_ids: set[str] = set()
    seen_pairs: set[tuple[str, str]] = set()
    normalized: list[tuple[dict, Path]] = []
    for row in rows:
        recipe_id = str(row.get("recipe_id", "")).strip()
        if not recipe_id:
            continue
        if recipe_id in seen_ids:
            raise ValueError(f"配方ID重复：{recipe_id}")
        seen_ids.add(recipe_id)
        first_id = str(row.get("first_id", "")).strip()
        second_id = str(row.get("second_id", "")).strip()
        if first_id not in cards or second_id not in cards:
            missing = first_id if first_id not in cards else second_id
            raise ValueError(f"原料卡ID不存在：{missing}")
        if first_id == second_id:
            raise ValueError(f"{recipe_id} 的两张原料卡不能相同；同名卡合炼不需要配方")
        mode = str(row.get("mode", "动态合成")).strip()
        if mode not in ("动态合成", "固定成品卡"):
            raise ValueError(f"{recipe_id} 的结果方式无效：{mode}")
        pair = tuple(sorted((first_id, second_id)))
        enabled = bool(row.get("enabled", True))
        if enabled and pair in seen_pairs:
            raise ValueError(f"启用的配方原料组合重复：{first_id} + {second_id}")
        if enabled:
            seen_pairs.add(pair)
        if mode == "固定成品卡":
            _result_resource_path(str(row.get("result_path", "")))
        elif row.get("result_cost") in (None, ""):
            row["result_cost"] = -99
        normalized.append((row, _recipe_file(row)))

    changed = 0
    active_paths: list[str] = []
    for row, path in normalized:
        rendered = _render_recipe(row)
        original = path.read_text(encoding="utf-8") if path.exists() else ""
        if rendered != original:
            path.write_text(rendered, encoding="utf-8")
            changed += 1
        if bool(row.get("enabled", True)):
            active_paths.append(f"res://fusion_recipes/{path.name}")
    changed += int(_write_library(active_paths))
    return changed


def write_row(row: dict) -> bool:
    """Compatibility helper for callers that still update one existing row."""
    existing = parse_all()
    target_id = str(row.get("recipe_id", "")).strip()
    target_file = str(row.get("file", "")).strip()
    for item in existing:
        if (target_id and item["recipe_id"] == target_id) or (target_file and item["file"] == target_file):
            item.update(row)
            return write_rows(existing) > 0
    return write_rows(existing + [row]) > 0
