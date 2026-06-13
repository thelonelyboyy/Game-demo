# 美术资源目录约定

所有美术资源统一放在 `art/` 下，按**用途**分类（替换 UI / 美术时按目录找文件即可）。
新增或替换资源时，请放进对应子目录，不要再散落到 `art/` 根目录。

## 目录划分

| 目录 | 放什么 | 典型文件 |
|---|---|---|
| `backgrounds/` | 各界面整屏背景 | `main_menu_bg.png`(主菜单)、`battle_bg.png`(战斗)、`blessing_cavern_bg.png`(灵根/祝福)、`shop_market_bg.png`(商店)、`background.png`(通用) |
| `characters/` | 玩家职业立绘、NPC | 四职业 `*_portrait.png`、`shopkeeper_blink.png`(商人) |
| `enemies/` | 敌人与 Boss 立绘 | `bone_dragon.png`、`black_lotus_matriarch.png` 等 |
| `cards/` | 卡面插画，按职业分子目录 | `cards/<职业>/...` |
| `relics/` | 法宝/遗物图标（含 `icons/`，由脚本生成） | `relics/icons/*.png` |
| `map/` | 地图节点与图标（含 `nodes/`） | `map_boss.png`、`nodes/...` |
| `treasure/` | 宝箱与宝箱房背景 | `treasure_chest_*.png`、`treasure_room_bg.png` |
| `ui/` | 界面元件：图标、卡框、标题图 | `ui/icons/`(HUD 小图标)、`ui/cards/generated/`(卡框)、`ui/title/`(标题图)、`top_bar_ink.png` |
| `tiles/` | **共享像素图标集**（见下方说明） | `tile_0074.png` … `tile_0131.png` |
| `audio/` | 音效与音乐 | `slash.ogg`、`8_bit_iced_village_lofi.mp3` |
| `fonts/` | 字体 | `pixel_rpg.ttf` |
| `shaders/` | 着色器及其材质 | `white_sprite_material.gdshader` / `.tres` |

## 关于 `tiles/`

`tile_XXXX.png` 是一套**通用像素图标**，被卡牌、词条(status)、敌人意图、UI 多处**共用**，
并非「一张卡一张图」。例如 `tile_0127.png` 同时用于 3 张卡 + 4 个词条 + 1 个敌人意图，
`tile_0118.png` 被 6 张卡共用。因此**不要**把某个 tile 改成单张卡的名字——会产生误导。
如果要做「每张卡专属插画」，应在 `cards/<职业>/` 下新增独立美术，再把卡牌 `icon` 指过去，
而不是重命名共享 tile。

以下 tile 当前**无任何引用**（`.gd/.tscn/.tres` 全表为 0），可在后续单独的清理中删除：

```
tile_0084 0088 0089 0090 0091 0105 0107 0109 0111 0112 0113 0115 0116 0117 0123 0124 0125
```

## 命名约定

- 一律使用**英文小写 + 下划线**命名（已将 `主界面背景.png`→`main_menu_bg.png`、`战斗界面背景图.png`→`battle_bg.png`）。
- 资源引用是路径式 `res://art/...`。**移动/重命名请在 Godot 编辑器内操作**，编辑器会自动更新
  `.tscn/.tres` 的引用；`.gd` 里硬编码的 `preload("res://art/...")` 需手动改。
- 改完跑 `python scripts/validate_project.py` 可一键抓出断引用（含 `.gd`）。
