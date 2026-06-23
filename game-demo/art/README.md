# 美术资源目录约定

所有美术资源统一放在 `art/` 下，按**用途**分类（替换 UI / 美术时按目录找文件即可）。
新增或替换资源时，请放进对应子目录，不要再散落到 `art/` 根目录。

> 最近更新：清理了未引用的旧背景 / 标题图 / 占位 tile；接入了魔修、剑修战斗逐帧动画。
> 下表的数量为当前仓库实际 PNG 数（不含 `.import`）。

## 目录划分

| 目录 | 放什么 | 当前内容 |
|---|---|---|
| `backgrounds/` (4) | 各界面整屏背景 | `background1.png`（**主菜单背景，已把「万劫求仙」标题与标语烤进图里**）、`background.png`（通用）、`blessing_cavern_bg.png`（灵根/祝福）、`shop_market_bg.png`（商店）。⚠️ 见下方「背景的特殊情况」 |
| `characters/` (5) | 玩家职业立绘 + 商人 | 四职业 `*_cultivator_portrait.png` / `beastmaster_portrait.png`、`shopkeeper_blink.png`（商人） |
| `enemies/` (23) | 敌人与 Boss 立绘 | 透明底单图，如 `bone_dragon.png`、`black_lotus_matriarch.png` 等 |
| `cards/` (150) | 卡面插画，按职业分子目录 | `cards/<职业>/`（每职业 20 张占位小图）；`cards/sword_cultivator/ai/`、`cards/demonic_cultivator/ai/`（各 35 张 **AI 大插画**，剑修/魔修卡的 `icon` 指向这里） |
| `frame_animation/` (168) | 战斗角色逐帧动画 | `<id>_<动作>/frame_001.png…`，见下方「战斗帧动画」 |
| `relics/` (64) | 法宝/遗物图标 | `relics/icons/`（44 张 AI 图标，透明底）、`relics/phase4/`（20 张，后期法宝） |
| `map/` (9) | 地图节点与背景 | `map/nodes/`（8 个节点图标：boss/elite/monster/shop/treasure/campfire/blessing/unknown）、`map/backgrounds/map_scroll_bg.png`（地图卷轴底图） |
| `treasure/` (4) | 宝箱与宝箱房背景 | `treasure_chest_closed/open/opening.png`、`treasure_room_bg.png` |
| `ui/` (30) | 界面元件 | `ui/cards/generated/`（7 套卡框）、`ui/icons/`（HUD 小图标 + `status_*` 状态 AI 图标）、`ui/rewards/`（奖励图标）、`ui/top_bar_ink.png`。`ui/title/` **目前为空**（旧标题图已删，标题烤进了 `background1.png`） |
| `tiles/` (22) | **共享像素图标集** + 意图图标 | `tile_XXXX.png`（19 张 16px 像素图，多处共用）、`intent_attack_sword/_block_shield/_buff_self.png`（敌人意图）。见下方「关于 tiles」 |
| `audio/` | 音效与音乐 | `slash.ogg`、`enemy_attack.ogg`、`dark_theme_jaggedstone.ogg` 等 |
| `fonts/` | 字体 | `pixel_rpg.ttf` |
| `shaders/` | 着色器及其材质 | `white_sprite_material.gdshader` / `.tres`（敌人受击白闪） |

## 战斗帧动画 `frame_animation/`

`CharacterStats.battle_anim_id` 非空时，玩家在战斗中改用逐帧动画（`scenes/player/player.gd` 运行时构建 `SpriteFrames`，贴图缺失则回退静态立绘）。
文件夹命名 `<battle_anim_id>_<动作>/`，帧文件 `frame_001.png` 起按序号递增。动作与帧率定义在 `player.gd` 的 `ANIM_DEFS`（当前统一 10fps）。

| 动作 | 触发时机 |
|---|---|
| `standby` | 待机循环 |
| `attack` | 打出攻击牌（动画播完后才结算伤害） |
| `attacked` | 受到伤害（动画播完后才扣血） |
| `Spellcasting` | 打出非攻击牌（技能/功法） |
| `death` | 死亡（播完后结算死亡） |

当前已配置：
- **魔修** `demonic_cultivator`：standby/attack/attacked/Spellcasting/death（5 套，全） 
- **剑修** `sword_cultivator`：standby/attack/attacked（无 Spellcasting/death，会自动跳过）
- 体修、驭兽暂无帧动画（仍静态立绘）

> ⚠️ 新增帧文件夹后，务必在 Godot 编辑器导入一次（或跑 `--headless --editor --quit`），否则贴图加载失败。

## 背景的特殊情况

- **主菜单**用 `art/backgrounds/background1.png`（标题已烤进图）。
- **战斗背景**与**角色选择背景**当前硬编码在项目根目录：`res://test2.png`（战斗）、`res://test1.png`（选人），**不在 `art/backgrounds/` 下**。要替换战斗/选人背景请改这两张图，或把它们移进 `art/backgrounds/` 并同步改 `battle.gd` / `character_selector.gd` 里的 `preload` 路径。
- 历史的 `battle_bg.png` / `main_menu_bg.png` 已删除（未被引用）。

## 关于 `tiles/`

`tile_XXXX.png` 是一套**通用 16px 像素图标**，被卡牌、词条(status)、敌人意图、UI 多处**共用**，
并非「一张卡一张图」。因此**不要**把某个 tile 改成单张卡的名字——会产生误导。
若要做「每张卡专属插画」，应在 `cards/<职业>/` 下新增独立美术再把卡牌 `icon` 指过去，而不是重命名共享 tile。

当前 19 张 `tile_*` **均有引用**（之前未引用的已清理）。`intent_*.png` 是敌人意图气泡用的彩色图标。
> 这批像素图属低清待替换资源；正式美术（AI 图标）已用于 `relics/icons/`、`ui/icons/status_*`、`map/nodes/`。

## 命名约定

- 一律使用**英文小写 + 下划线**命名。
- 资源引用是路径式 `res://art/...`。**移动/重命名请在 Godot 编辑器内操作**，编辑器会自动更新
  `.tscn/.tres` 的引用；`.gd` 里硬编码的 `preload("res://art/...")` 需手动改。
- 新增/替换 PNG 后要在编辑器导入一次，否则会「文件在但加载失败」。
- 改完跑 `python scripts/validate_project.py` 可抓出断引用（含 `.gd`）。
