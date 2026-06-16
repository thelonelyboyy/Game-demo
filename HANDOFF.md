# 万劫求仙项目交接文档

更新时间：2026-06-16  
项目根目录：`E:\code\game-demo`  
Godot 工程目录：`E:\code\game-demo\game-demo`  
Godot 版本：4.5.2 stable mono  
Godot 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe`

## 1. 当前状态（2026-06-16）

- 稳定运行的杀戮尖塔式修仙卡牌肉鸽 Demo。本轮做了大量系统、数值、美术与工程改动，**汇总见第 6 节「本轮系统级更新」**。
- **工作区有大批未提交改动**（约 107 改 / 2 删 / 42 新增）：剑修+魔修卡牌接入 AI 插画、10 张新魔修卡、剑修/魔修战斗帧动画、意图系统、数值平衡、敌人行动时序修复、地图实验回退、新状态/意图图标等。提交前请按第 5 节验证。
- `validate_project.py` 通过（0 error）；`run_godot_checks.py` 7 项基本通过，但 `run-flow` 存在一个**偶发**的 `Lambda capture freed`（见第 8 节已知问题）。
- 新增完整开发路线图：根目录 `ROADMAP.md`（通往「杀戮尖塔级成品」的分阶段优化方案，11 个阶段、每步带验收标准）。

## 2. 项目概况

这是一个 Godot 4 制作的国产修仙题材卡牌肉鸽 Demo，玩法结构接近《杀戮尖塔》：

- 主菜单、新开局、继续游戏、角色选择、灵根选择。
- 地图爬塔，包含普通战斗、精英、Boss、事件、商店、宝箱、篝火、祝福。
- 回合制卡牌战斗，支持抽牌、弃牌、消耗、费用、目标选择、敌人意图和胜负结算。
- 当前职业包括体修、剑修、魔修、驭兽。
- 图鉴包含卡牌、法宝/遗物、怪物、词条等内容。
- 近期视觉方向已转向云海仙山、国风修仙、暗金卡牌、肉鸽实体卡质感。

常用入口：

- 主场景：`res://scenes/ui/main_menu.tscn`
- 战斗场景：`res://scenes/battle/battle.tscn`
- 地图场景：`res://scenes/map/map.tscn`
- 图鉴场景：`res://scenes/ui/codex.tscn`
- 商店场景：`res://scenes/shop/shop.tscn`
- 宝箱场景：`res://scenes/treasure/treasure.tscn`
- 祝福场景：`res://scenes/blessing/blessing.tscn`

主流程：

```text
MainMenu
  -> 新的轮回 -> CharacterSelector -> SpiritRootSelector -> Run
  -> 继续游戏 -> RunStartup.CONTINUED_RUN -> Run
  -> 图鉴大全 -> CodexPanel
```

Run 流程：

```text
Run
  -> 创建/读取 SaveGame
  -> 生成或恢复 Map
  -> 点击房间触发 Room.Type
  -> 战斗 / 奖励 / 商店 / 事件 / 篝火 / 宝箱 / 祝福
  -> Boss 后推进章节
  -> 第 3 章 Boss 后进入 WinScreen
```

## 3. 目录结构速览

```text
E:\code\game-demo
├─ game-demo\                 Godot 工程根目录
│  ├─ project.godot           Godot 工程配置
│  ├─ art\                    美术资源（背景/角色/怪物/卡框/标题/遗物图标等）
│  │  ├─ cards\<职业>\ai\      卡牌 AI 大插画（剑修、魔修已接；体修、驭兽待补）
│  │  ├─ frame_animation\      战斗角色逐帧动画 <id>_standby|attack|attacked（魔修、剑修）
│  │  └─ tiles\                共享 16px 占位像素图（含 intent_* 意图图标）
│  ├─ battles\                战斗配置 BattleStats
│  ├─ characters\             职业资源、初始牌组、职业卡牌
│  ├─ common_cards\           通用卡牌
│  ├─ custom_resources\       核心 Resource 类型
│  ├─ effects\                卡牌效果资源脚本
│  ├─ enemies\                敌人资源、敌人场景、敌人行动
│  ├─ fusion_cards\           融合结果卡牌
│  ├─ fusion_recipes\         卡牌融合配方
│  ├─ global\                 Autoload，全局事件/音频/RNG
│  ├─ relics\                 法宝/遗物资源与奖励池
│  ├─ scenes\                 主要 UI、战斗、地图、商店、事件等场景
│  ├─ statuses\               词条/状态资源与脚本
│  └─ test_data\              Godot smoke 测试场景
├─ scripts\
│  ├─ validate_project.py     资源和内容校验脚本
│  ├─ run_godot_checks.py     Headless Godot smoke 测试
│  └─ generate_relic_icons.py 遗物图标生成脚本
├─ ROADMAP.md                 通往成品的分阶段优化方案（11 阶段，每步带验收标准）
├─ tmp\                       AI 出图工作流暂存（已 gitignore，不入库）
└─ HANDOFF.md                 本交接文档
```

## 4. 核心系统提醒

- Autoload：`Events`、`Shaker`、`MusicPlayer`、`SFXPlayer`、`RNG`。
- 卡牌资源：`res://custom_resources/card.gd`、`res://custom_resources/cultivation_card.gd`。
- 卡牌效果统一走 `configured_effects`：旧字段驱动路径（`base_damage`、`muscle_stacks` 等）已从 `cultivation_card.gd` 删除，新卡只能用 `configured_effects` 配置效果。`validate_project.py` 仍会拦截任何在 `.tres` 里重新写入旧字段的情况。
- 新增卡牌后要检查职业卡池、图鉴扫描、奖励/商店来源。
- 修改主流程后必须跑 `run-flow`。
- 修改 Boss、敌人或战斗配置后必须跑 `boss-battle`。
- 修改图鉴资源扫描后必须跑 `codex` smoke。
- 修改存档字段后要测试继续游戏。
- **战斗角色帧动画**：`CharacterStats.battle_anim_id` 非空时，玩家在战斗中改用 `art/frame_animation/<id>_standby|attack|attacked/` 逐帧动画（`scenes/player/player.gd` 运行时构建 SpriteFrames，贴图缺失则回退静态立绘）。已配置：魔修=`demonic_cultivator`、剑修=`sword_cultivator`。帧率在 `player.gd` 的 `ANIM_DEFS`（当前统一 10fps）。待机循环、出攻击牌播攻击、受击播受击；白闪/震屏已移除。新增帧文件夹后务必在编辑器导入。
- **敌人意图系统**：`Intent.category`（12 种分类）驱动 `scenes/ui/intent_ui.gd` 的彩色气泡；攻击/防御/强化等分类用 `art/tiles/intent_*.png` 贴图、其余分类用代码绘制图标兜底。给敌人意图分类：在其 AI 场景（如 `enemies/crab/crab_enemy_ai.tscn`）的 Intent 子资源里设 `category`。
- **存档自愈**：`SaveGame.load_data()` 加载前用 `get_dependencies` 检查依赖是否齐全，缺失/损坏则清理坏档并返回 null（`run.gd` 也会在空存档时返回主菜单）。注意：存档仍按路径内嵌大量资源引用，**移动/重命名被引用的资源会让旧存档失效**（架构隐患，见 ROADMAP 阶段 0）。
- **章节难度爬升**：`scenes/map/map_generator.gd` 的 `CHAPTER_HEALTH/DAMAGE/GOLD_MULTIPLIERS` 让敌人血量/伤害/金币按章节递增（经 `_battle_for_room` 复制缩放，不污染战斗池）；进入新一章在 `run.gd._advance_to_next_chapter` 回满血；测试地图（`map_mode != ROGUELIKE`）开启 `Map.free_navigation`（所有节点可点，直接点 Boss 也能进章）。
- **数值/平衡关键位置**：商店按稀有度定价 `shop_card.gd PRICE_BY_RARITY` + 法宝价位带 `shop_relic.gd`；暗金卡上架 `shop.gd MYTHIC_SHOP_CHANCE=0.04`；灵根缩放 `character_stats.gd get_spirit_root_modified_value`（初悟+1/小成×1.2+1/大成×1.4+1/圆满×1.8+1）；剑意上限 `statuses/sword_intent.gd MAX_STACKS=4`；灵气回蓝上限 `statuses/energy_charge.gd MAX_MANA_PER_TURN=2`；四职业每回合均抽 5 张。
- **敌人行动延迟回调**：敌人攻击/格挡行动用 `get_tree().create_timer()`/补间 `finished` 回调发 `enemy_action_completed`，**必须捕获 `enemy.get_instance_id()` 而非节点本身**（否则补间未完成前敌人/战斗被释放会报 `Lambda capture freed`）。新增此类行动请照此写法。

## 5. 快速验证命令

在项目根目录 `E:\code\game-demo` 执行：

```powershell
python scripts\validate_project.py
```

Godot 检查：

```powershell
python scripts\run_godot_checks.py --godot "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe"
```

如新增或替换 PNG 资源后需要触发 Godot 导入：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe" --headless --editor --quit --path "E:\code\game-demo\game-demo"
```

最近检查结果：

- `validate_project.py`：0 error / 0 warning。
- `run_godot_checks.py`：`main`/`character-selector`/`codex`/`battle`/`map`/`boss-battle` 通过；`run-flow` **偶发** `Lambda capture freed`（重跑通常即过，根因见第 8 节）。
- `run_godot_checks.py` 已改用 UTF-8 解码 Godot 输出，修复了中文 Windows 上的 GBK 解码崩溃。
- ⚠️ **新增/替换 PNG 后必须在 Godot 编辑器导入一次**（或跑上面的 `--headless --editor --quit`），否则会出现「文件在但加载失败 / no loader found」的错误，而 `validate_project.py` 查不出（它只查文件是否存在、查不出"未导入"）。

## 6. 最近改动摘要

### 本轮（2026-06-16）系统级更新

> 以下为本轮新增/改动的系统总览，详细机制位置见第 4 节。

- **改名**：游戏更名为「万劫求仙」（`project.godot` + 主菜单文案 + 本文档）。⚠️ 主菜单**标题 logo 图**仍是旧的 `baijie_chengxian_title.png`（图里写着"百劫成仙"），需重做替换。
- **卡牌效果系统**：彻底删除旧字段驱动路径，`cultivation_card.gd` 只走 `configured_effects`（见第 4 节）。
- **存档自愈**：缺失/损坏存档自动清理降级，不再崩或卡死。
- **三章难度爬升 + 进章回血 + 测试地图自由导航**。
- **敌人意图系统**：12 种分类 + 彩色气泡 + 贴图优先/代码兜底图标。
- **数值平衡**：商店稀有度定价、暗金卡 4%、灵根缩放、剑意封顶 4、灵气回蓝封顶 2、四职业抽 5。
- **战斗帧动画**：`battle_anim_id` 机制；魔修、剑修已接（待机/攻击/受击）；帧率 `ANIM_DEFS` 当前 10fps。体修、驭兽暂无动画（仍静态立绘）。
- **新增 10 张魔修卡**（`characters/demonic_cultivator/cards/demon_*.tres`，已登记进 draftable 池），围绕献祭/魂印/以伤换爆发。
- **卡牌 AI 插画**：剑修、魔修卡牌已接入 AI 生成插画，路径 `art/cards/<职业>/ai/`（`.tres` 的 `icon` 指向该目录）。体修、驭兽待补。
- **敌人行动时序修复**：7 处敌人攻击/格挡行动改为捕获 instance_id，消除大部分 `Lambda capture freed`。
- **工具链**：`run_godot_checks.py` UTF-8 解码修复。
- **`.gitignore`**：新增排除美术工作流的临时/备份/源文件（`*_old.png`、`tmp_*/`、`*backup*/`、`GE/`、`gemini/`），避免污染仓库。
- **路线图**：新增 `ROADMAP.md`。
- **地图背景**：本轮做过"满屏/拉伸/加宽画布"等多种实验，最终**回退**到原始的「居中卷轴 + 山景两侧」样式（`map.gd`/`map.tscn`/`map_scroll_bg.png` 已恢复到提交版）。

### 历史改动（更早批次，供参考）

### 游戏名与主页

- 游戏名已改为 `万劫求仙`。
- `game-demo/project.godot` 中的项目名称已更新。
- 新增主页标题图资源：
  - `game-demo/art/ui/title/baijie_chengxian_title.png`
  - `game-demo/art/ui/title/baijie_chengxian_title.png.import`
- 主页 UI 已重新设计，更偏国产修仙肉鸽卡牌风格：
  - `game-demo/scenes/ui/main_menu.tscn`
  - `game-demo/scenes/ui/main_menu.gd`
- 当前主页包含标题图、云海仙山背景、墨色遮罩、菜单面板、玉金按钮样式和底部提示。
- 菜单按钮为：`继续游戏`、`新的轮回`、`图鉴大全`、`设置`、`退出`。

### 卡牌 UI

- 卡牌系统已从纯代码 StyleBox 外观升级为真实卡框贴图方案。
- 新增 7 套卡牌类型框资源，目录：
  - `game-demo/art/ui/cards/generated/`
- 当前卡框资源：
  - `card_frame_thunder.png`：雷系，紫色雷纹。
  - `card_frame_sword.png`：剑系，土金金属感。
  - `card_frame_mind.png`：心法，青绿玉石感。
  - `card_frame_secret.png`：秘术，暗紫符纹。
  - `card_frame_alchemy.png`：丹道，橙金丹火。
  - `card_frame_array.png`：剑阵，赤红阵纹。
  - `card_frame_default.png`：默认术法，古金墨色。
- `game-demo/scenes/ui/card_style.gd` 负责类型颜色和卡框路径映射。
- `game-demo/scenes/ui/card_visuals.tscn` 新增 `FrameTexture` 层。
- `game-demo/scenes/ui/card_visuals.gd` 负责把真实卡框、原有 `card.icon`、费用、名称、描述、类型文字叠加显示。
- 卡牌中间的大插画暂时没有生成或替换，仍沿用当前 `card.icon` 逻辑。
- 奖励、商店、牌库/预览、删除、升级、融合等界面已尽量复用同一套卡牌显示组件：
  - `game-demo/scenes/ui/card_menu_ui.gd`
  - `game-demo/scenes/ui/card_menu_ui.tscn`
  - `game-demo/scenes/ui/card_rewards.tscn`
  - `game-demo/scenes/shop/shop_card.gd`
  - `game-demo/scenes/shop/shop_card.tscn`
  - `game-demo/scenes/card_remove/card_remove.tscn`
  - `game-demo/scenes/card_upgrade/card_upgrade.tscn`
  - `game-demo/scenes/card_fusion/card_fusion.tscn`

### 战斗旧提示框清理

- 旧的卡牌 tooltip 会在战斗中选中卡牌或攻击指向怪物时出现在屏幕上方，已移除相关触发。
- 修改文件：
  - `game-demo/scenes/card_ui/card_states/card_base_state.gd`
  - `game-demo/scenes/card_target_selector/card_target_selector.gd`
- 当前处理：
  - 手牌 hover 不再主动请求旧 tooltip。
  - 攻击瞄准进入/退出敌人目标时不再请求旧 tooltip。
  - 开始瞄准时会发出 `Events.tooltip_hide_requested`，清掉残留提示。

### 地图、商店、宝箱、祝福等 UI

近期还做过以下界面方向调整：

- 地图切换为测试版本，并检查/补充测试路线里的宝箱节点。
- 地图节点 UI 重新设计，提高未到达节点透明度和路径可读性。
- 宝箱节点图标重新设计。
- 宝箱房间页面重做，宝箱奖励从随机 1 个遗物改为抽 2 个遗物二选一。
- 战斗结束奖励 UI 重做。
- 祝福/灵根选择界面重做，背景仍使用当前祝福场景背景资源。
- ESC 暂停菜单重做。
- 商店 UI 重做，更贴近修仙肉鸽卡牌主题。
- 所有法宝/遗物小图标已生成并替换，相关资源位于：
  - `game-demo/art/relics/icons/`
- 遗物图标生成脚本：
  - `scripts/generate_relic_icons.py`

## 7. 关键文件索引

### 主菜单

- `game-demo/scenes/ui/main_menu.tscn`
- `game-demo/scenes/ui/main_menu.gd`
- `game-demo/art/ui/title/baijie_chengxian_title.png`

### 卡牌显示

- `game-demo/scenes/ui/card_visuals.tscn`
- `game-demo/scenes/ui/card_visuals.gd`
- `game-demo/scenes/ui/card_style.gd`
- `game-demo/scenes/ui/card_menu_ui.tscn`
- `game-demo/scenes/ui/card_menu_ui.gd`
- `game-demo/art/ui/cards/generated/`

### 商店与奖励

- `game-demo/scenes/shop/shop_card.tscn`
- `game-demo/scenes/shop/shop_card.gd`
- `game-demo/scenes/ui/card_rewards.tscn`

### 战斗卡牌交互

- `game-demo/scenes/card_ui/card_states/card_base_state.gd`
- `game-demo/scenes/card_target_selector/card_target_selector.gd`

## 8. 当前注意事项与已知问题

### 美术现状

- 剑修、魔修卡牌已接入 AI 生成大插画（`art/cards/<职业>/ai/`）；**体修、驭兽卡面仍是占位小图**，待补。
- 卡框资源是 AI 生成贴图，作为临时美术可用；若后续有正式美术，应保持相同布局区域，避免重改 UI 坐标。
- `art/tiles/` 仍有一批 16px 占位像素图（被卡牌/词条/敌人共用），属低清待替换。

### 已知问题

- **`run-flow` 偶发 `Lambda capture freed`**：本轮已修 7 处敌人行动（攻击/格挡，boss 战 15/15 干净），但完整流程仍约 2/12 偶发——还有另一处来源未根除（疑似 `status_handler`/`relic_handler`/弃牌结算等多回合才走的补间回调）。非功能 bug（逻辑仍通过），但会干扰验证、将来上 CI 会变随机红灯。修法同样是把 `tween.finished` 的 lambda 改为不捕获节点 / 加 `is_instance_valid` 守卫。
- **`validate_project.py` 有盲区**：只查 `res://` 文件是否存在，查不出「文件在但未导入」（缺 `.import`）和字符串拼接路径（如 `card_style.gd` 的卡框）。新增美术务必在编辑器导入。
- **存档跨资源移动会失效**：存档按路径内嵌资源引用，移动/重命名被引用资源后旧档加载失败（已有自愈清档兜底，但会丢进度）。彻底修复需改成"按 id 重建"（ROADMAP 阶段 0）。
- **标题 logo** 仍显示旧游戏名"百劫成仙"，需重做图片。
- 卡牌显示逻辑没有修改 `Card` 数据结构，也没有改卡牌效果逻辑。
- 战斗手牌尺寸仍偏紧凑，主要是为了避免遮挡战斗场景。
- 如果再调整卡牌比例，要同步检查战斗手牌、奖励三选一、商店、图鉴/预览、升级、删除、融合界面。

## 9. 后续建议

1. 为高频卡牌优先生成或绘制正式大插画，替换当前临时小图标。
2. 对卡牌标题字体、描述字体补充更有国风感的正式字体资源。
3. 给主页按钮增加轻微 hover 音效、灵光粒子或水墨扩散效果。
4. 对地图、商店、宝箱、祝福页面做一次统一视觉 QA，检查字体大小、按钮状态和不同分辨率下的遮挡。
5. 在提交前重新运行 `validate_project.py` 和 `run_godot_checks.py`，并人工进入战斗、商店、地图、奖励、主菜单确认视觉效果。
