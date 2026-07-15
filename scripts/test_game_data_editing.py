"""Targeted checks for card breakthrough and fusion workbook writeback helpers."""

from __future__ import annotations

import tempfile
from pathlib import Path

import card_table as ct
import fusion_table as ft


def main() -> None:
    cards = [ct.parse_card(path) for path in ct.find_card_files()]
    assert cards and all(card["upgrade"] in ct.UPGRADE_R for card in cards)

    source_path = ct.find_card_files()[0]
    with tempfile.TemporaryDirectory() as temp_dir:
        copied_card = Path(temp_dir) / source_path.name
        copied_card.write_text(source_path.read_text(encoding="utf-8"), encoding="utf-8")
        row = dict(ct.parse_card(source_path))
        row["effect_amounts"] = []
        row["upgrade"] = "费用减少1" if row["cost"] > 0 else "数值提高50%"
        assert ct.update_card_file(copied_card, row)
        expected = ct.UPGRADE_R[row["upgrade"]]
        assert f"upgrade_type = {expected}" in copied_card.read_text(encoding="utf-8")

        old_base, old_root, old_library = ft.ROOT, ft.RECIPE_ROOT, ft.LIBRARY_PATH
        try:
            ft.ROOT = Path(temp_dir)
            ft.RECIPE_ROOT = Path(temp_dir) / "fusion_recipes"
            ft.RECIPE_ROOT.mkdir()
            ft.LIBRARY_PATH = ft.RECIPE_ROOT / "card_fusion_library.tres"
            first, second, third, fourth = cards[:4]
            rows = [
                {
                    "enabled": True,
                    "file": "",
                    "recipe_id": "codex_dynamic",
                    "first_id": first["id"],
                    "second_id": second["id"],
                    "mode": "动态合成",
                    "result_path": "",
                    "result_name": "定向测试合炼",
                    "result_cost": -99,
                },
                {
                    "enabled": False,
                    "file": "",
                    "recipe_id": "codex_disabled_recipe",
                    "first_id": third["id"],
                    "second_id": fourth["id"],
                    "mode": "动态合成",
                    "result_path": "",
                    "result_name": "停用测试合炼",
                    "result_cost": 1,
                },
            ]
            changed = ft.write_rows(rows)
            assert changed == 3
            assert (ft.RECIPE_ROOT / "codex_dynamic.tres").exists()
            assert (ft.RECIPE_ROOT / "codex_disabled_recipe.tres").exists()
            library_text = ft.LIBRARY_PATH.read_text(encoding="utf-8")
            assert "codex_dynamic.tres" in library_text
            assert "codex_disabled_recipe.tres" not in library_text
            assert any(row["recipe_id"] == "codex_dynamic" for row in ft.parse_all())
        finally:
            ft.ROOT, ft.RECIPE_ROOT, ft.LIBRARY_PATH = old_base, old_root, old_library

    print("GAME_DATA_EDITING_TEST_OK")


if __name__ == "__main__":
    main()
