# 万劫求仙项目交接文档

更新时间：2026-07-06
项目根目录：`E:\code\game-demo`  
Godot 工程目录：`E:\code\game-demo\game-demo`  
Godot 版本：4.5.2 stable mono  
Godot 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe`
Godot Console 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe`

## 1. 当前状态（2026-07-06）

- 稳定运行的杀戮尖塔式修仙卡牌肉鸽 Demo。当前焦点：**把魔修打磨成完整 Demo**。
- **当前开发策略**：暂时不继续精抠单个 UI，优先把魔修职业做成可完整通关、可调试、可扩展的 Demo 闭环。
- **Demo 职业范围已收束**：选人界面当前只开放魔修，体修/剑修/驭兽都暂时 disabled；代码和资源仍保留，后续可再恢复。
- **UI 风格统一已推进一轮**：`InkTheme` 扩展了暗黑修仙通用面板/按钮/标题样式，并已套到战斗奖励、商店、宝箱、祝福、篝火、删牌、升牌、融合、牌堆、胜负面板、暂停菜单、调试控制台、灵根选择等界面。后续新增页面应优先复用 `scenes/ui/ink_theme.gd`，不要各自重新写一套 StyleBox。
- **事件池临时切换**：旧事件暂时禁用，当前 `event_room_pool.tres` 只开放最近新增的 10 个事件，便于集中验证新事件质量。
- **调试控制台已加入**：Run 场景内按 **Ctrl + 反引号** 打开，不再使用 F8（Godot 编辑器里 F8 会直接停止运行）。可增删/升级/融合卡牌，调血量、金币、法宝、丹药，以及编辑下次造成/受到伤害，便于 Demo 调试。
- **灵根机制已重做**：保留开局三选一与“打击/防御转元素”，新增同元素灵根职业卡、三段成长和圆满专属被动；旧圆满规则已禁用。详见第 4、6 节。
- **失败遗产已加入**：失败后下一局进地图时，可从上一局获得的法宝中选 1 个替换本命法宝，也可以不替换。
- **法宝说明交互已改**：法宝/遗物现在应使用鼠标悬停小 tooltip 显示效果，不再点击后全屏展示。
- **Godot MCP 已重新校准到 9085**：Codex 全局配置 `C:\Users\Administrator\.codex\config.toml` 的 `mcp_servers.godot` 现在指向 `E:\code\Godot-MCP\server\dist\index.js`，并显式设置 `GODOT_MCP_URL=ws://localhost:9085`；项目 `.mcp.json` 也同步为 `godot` server。2026-07-01 已用 MCP stdio client 验证可列出 16 个工具，并可通过 Godot WebSocket 返回 `get_project_info`。
- **主页/选人/战斗 UI 已按 `art/design` 目标图方向推进**：主页改成暗黑修仙主视觉；选人界面使用现有 UI 资产贴近目标图；魔修战斗界面已进入“卡牌式玩家/怪物信息框 + 中央战场 + 底部手牌”的布局方向。
- **战斗 UI 最新资源位置**：新一批生成 HUD 资源在 `game-demo/assets/ui/generated/battle/`、`game-demo/art/ui/battle_cards/`、`game-demo/art/ui/battle_widgets/`；旧一轮 `game-demo/art/ui/battle_hud/demonic_blue/` 仍保留给部分面板/历史对照。预览图在 `game-demo/art/design/run_battle_ui_preview.png` / `battle_ui_preview.png`。
- **战斗顶栏最新约定**：Run 顶部使用黑金面板资源，角色名必须读取 `CharacterStats.character_name`；灵根/丹药仍在顶栏；总牌库按钮在右上；设置按钮在最右。法宝/遗物独占顶栏下方一栏，**不显示“法宝”标题**，放不下由 `HFlowContainer` 自动换第二行；不要再把法宝挤进顶栏小面板。
- **HUD 美术说明**：`assets/ui/generated/battle` 与 `demonic_blue` 中的 HUD PNG 多为程序化/生成式临时美术，逻辑和布局已接好；若追求目标图级精致度，后续可用同名 PNG 替换，脚本引用不必大改。
- **地图节点 hover/focus 说明已补**：精英战、营火、商店、机缘、宝箱等节点会给新玩家显示含义提示。
- **新增「符箓丹药」系统**（可携带一次性消耗品，对标药水）：战斗奖励/商店获取、3 槽位、战斗内/部分战斗外使用。见第 4、6 节。
- **魔修机制大改**（三系统，引爆倍率 X=3）：阶段1 煞气 ✅、阶段2 魂印引爆 ✅、阶段3 魔焰焰轮 ✅（含 7 色 rider 细化）。见第 4、6 节。
- 本轮继续追加魔修功法引擎卡、战斗 UI 卡牌化布局、出牌预览动画、战斗总牌组 overlay 修复、符箓丹药伤害修复、选人职业收束与文档更新。
- `validate_project.py` 现在 **0 error / 0 warning**（2026-07-06 复跑；校验脚本已修掉「默认值字段被当成缺失」的误报，不再有历史的 198 个假错）。
- `run_godot_checks.py`：2026-07-01 最近一次用 Godot exe 跑过全量检查，`main`/`character-selector`/`codex`/`battle`/`map`/`run-flow`/`boss-battle` 全部通过。
- **统一 Excel 数值总表**：`game_data.xlsx`（卡牌/祝福/怪物AI 三张数据表 + 说明）——改表回写 `.tres`/`.json`/`.tscn`，一个文件调全部数值平衡（见第 6、7 节）。旧的独立 `cards.xlsx` 已被它取代。
- 开发路线图见根目录 `ROADMAP.md`。

## 2. 项目概况

这是一个 Godot 4 制作的国产修仙题材卡牌肉鸽 Demo，玩法结构接近《杀戮尖塔》：

- 主菜单、新开局、继续游戏、角色选择、灵根选择。
- 地图爬塔，包含普通战斗、精英、Boss、事件、商店、宝箱、篝火、祝福。
- 回合制卡牌战斗，支持抽牌、弃牌、消耗、费用、目标选择、敌人意图和胜负结算。
- 代码和资源中仍保留体修、剑修、魔修、驭兽；当前 Demo 入口暂只开放魔修。
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
│  │  ├─ design\              目标图/当前截图/战斗 UI 预览图与设计计划
│  │  ├─ frame_animation\      战斗角色逐帧动画 <id>_standby|attack|attacked（魔修、剑修）
│  │  ├─ ui\battle_hud\demonic_blue\ 战斗 HUD 临时透明 PNG（黑金暗蓝，程序化生成）
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
│  └─ test_data\              Godot smoke 测试场景（含战斗 UI 截图 helper）
├─ scripts\
│  ├─ validate_project.py     资源和内容校验脚本
│  ├─ run_godot_checks.py     Headless Godot smoke 测试
│  └─ generate_relic_icons.py 遗物图标生成脚本
├─ ROADMAP.md                 通往成品的分阶段优化方案（11 阶段，每步带验收标准）
├─ game_data.xlsx             统一数值总表（卡牌/祝福/怪物AI）
├─ tmp\                       AI 出图工作流暂存（已 gitignore，不入库）
└─ HANDOFF.md                 本交接文档
```

## 4. 核心系统提醒

- Autoload：`Events`、`Shaker`、`MusicPlayer`、`SFXPlayer`、`RNG`。
- 卡牌资源：`res://custom_resources/card.gd`、`res://custom_resources/cultivation_card.gd`。
- 卡牌效果统一走 `configured_effects`：旧字段驱动路径（`base_damage`、`muscle_stacks` 等）已从 `cultivation_card.gd` 删除，新卡只能用 `configured_effects` 配置效果。`validate_project.py` 仍会拦截任何在 `.tres` 里重新写入旧字段的情况。
- 新增卡牌后要检查职业卡池、图鉴扫描、奖励/商店来源。
- **新增任何可收集资源类型（卡牌/法宝/词条/怪物/符箓丹药等）必须接入图鉴扫描** `scenes/ui/codex.gd`（`_collect_all_data` + `_build_directory` + 对应 `_show_*_detail`），否则玩家在图鉴里看不到。图鉴用运行时递归 `DirAccess` 扫描目录，新增同类资源会自动出现，但**新类型需手动加扫描根**。
- 图鉴/扫描器查不出"文件在但未导入"（缺 `.import`）：新增 `.tres`/PNG 后务必在编辑器导入一次。
- 修改主流程后必须跑 `run-flow`。
- 修改 Boss、敌人或战斗配置后必须跑 `boss-battle`。
- 修改图鉴资源扫描后必须跑 `codex` smoke。
- 修改存档字段后要测试继续游戏。
- **战斗角色帧动画**：`CharacterStats.battle_anim_id` 非空时，玩家在战斗中改用 `art/frame_animation/<id>_<动作>/` 逐帧动画（`scenes/player/player.gd` 运行时构建 SpriteFrames，贴图缺失则回退静态立绘）。动作：`standby`(待机循环)/`attack`/`attacked`/`Spellcasting`(出非攻击牌)/`death`(死亡，停在末帧)。已配置：魔修=`demonic_cultivator`(5 套全)、剑修=`sword_cultivator`(standby/attack/attacked)。帧率 `ANIM_DEFS` 当前统一 **20fps**。**攻击/受击时序**：出攻击牌→播攻击动画→动画结束才结算伤害（`card.gd` 经 `Events.attack_animation_finished` 门控）；受击同理——受击动画播完才扣血（`player.take_damage`）。新增帧文件夹后务必在编辑器导入。
- **敌人意图系统**：`Intent.category`（12 种分类）驱动 `scenes/ui/intent_ui.gd` 的彩色气泡；攻击/防御/强化等分类用 `art/tiles/intent_*.png` 贴图、其余分类用代码绘制图标兜底。给敌人意图分类：在其 AI 场景（如 `enemies/crab/crab_enemy_ai.tscn`）的 Intent 子资源里设 `category`。
- **存档自愈**：`SaveGame.load_data()` 加载前用 `get_dependencies` 检查依赖是否齐全，缺失/损坏则清理坏档并返回 null（`run.gd` 也会在空存档时返回主菜单）。注意：存档仍按路径内嵌大量资源引用，**移动/重命名被引用的资源会让旧存档失效**（架构隐患，见 ROADMAP 阶段 0）。
- **章节难度爬升**：`scenes/map/map_generator.gd` 的 `CHAPTER_HEALTH/DAMAGE/GOLD_MULTIPLIERS` 让敌人血量/伤害/金币按章节递增（经 `_battle_for_room` 复制缩放，不污染战斗池）；进入新一章在 `run.gd._advance_to_next_chapter` 回满血；测试地图（`map_mode != ROGUELIKE`）开启 `Map.free_navigation`（所有节点可点，直接点 Boss 也能进章）。
- **数值/平衡关键位置**：商店按稀有度定价 `shop_card.gd PRICE_BY_RARITY` + 法宝价位带 `shop_relic.gd`；暗金卡上架 `shop.gd MYTHIC_SHOP_CHANCE=0.04`；灵根缩放 `character_stats.gd get_spirit_root_modified_value`（初悟 0-3 张：主数值+1；小成 4-6 张：ceil(基础主数值×1.2)+1；圆满 7+ 张：ceil(基础主数值×1.4)+1，并解锁每回合最多一次的元素被动）；剑意上限 `statuses/sword_intent.gd MAX_STACKS=4`；灵气回蓝上限 `statuses/energy_charge.gd MAX_MANA_PER_TURN=2`；四职业每回合均抽 5 张。
- **灵根圆满被动**：逻辑集中在 `scenes/battle/spirit_root_handler.gd` 与相关卡牌/效果钩子，回合开始可靠重置触发次数。火：每回合第一张火攻击牌弹选择，伤害×1.5 或按最终实际伤害 50% 溅射其它敌人；金：第一张金牌得 1 劲气；水：第一张水牌抽 1，抽到的第一张牌本回合费用 -1；土：第一张土牌得 1 真元；木：回合结束若本回合打出过木牌，回复 3 点生命，满血则得 3 护体。UI/tooltip/status 文案需要让玩家看懂本回合是否已触发。
- **敌人行动延迟回调**：敌人攻击/格挡行动用 `get_tree().create_timer()`/补间 `finished` 回调发 `enemy_action_completed`，**必须捕获 `enemy.get_instance_id()` 而非节点本身**（否则补间未完成前敌人/战斗被释放会报 `Lambda capture freed`）。新增此类行动请照此写法。
- **祝福系统（数据驱动）**：祝福内容在 `data/blessings.json`（5 类来源，`blessing.gd` 运行时读取），效果分发在 `blessing.gd._apply_effect`。可经 `game_data.xlsx` 的「祝福」表编辑回写。新增效果类型要同时在 `_apply_effect` 加分支 + `blessing_table.py EFFECT_TYPES` 登记。命格共鸣按 `_character_class()`（资源路径判职业）过滤。
- **固定套路敌人 AI**：`EnemyActionPicker` 的 `fixed_sequence`（子节点下标数组）非空时按回合循环固定出招、忽略权重/条件；空时保持原随机逻辑。仅 4 个固定敌人（符纸兵/雾隐狼/牛魔/渊狱剑魂）用，各有专属 AI 场景。数值/序列可经 `game_data.xlsx` 的「怪物AI」表编辑。注意：AI 挂在敌人身上，正式地图出现这些敌人时也用此套路。

## 5. 快速验证命令

在项目根目录 `E:\code\game-demo` 执行：

```powershell
python scripts\validate_project.py
```

Godot 检查：

```powershell
python scripts\run_godot_checks.py --godot "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe"
```

如新增或替换 PNG 资源后需要触发 Godot 导入：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe" --path "E:\code\game-demo\game-demo" --editor --quit
```

战斗 UI 视觉截图 helper：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe" --path "E:\code\game-demo\game-demo" --scene "res://test_data/capture_run_battle_ui_preview.tscn"
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe" --path "E:\code\game-demo\game-demo" --scene "res://test_data/capture_battle_ui_preview.tscn"
```

最近检查结果：

- `validate_project.py`：0 error / 0 warning（2026-07-06 最近一次复跑，最近 UI/系统改动后仍保持无校验错误）。
- `run_godot_checks.py`：`main`/`character-selector`/`codex`/`battle`/`map`/`run-flow`/`boss-battle` 全部通过（最近一次完整跑通：2026-07-01）。
- 2026-07-06 针对性复现检查已过：攻击牌出牌预览坐标不再报错；无卡牌来源的攻击符箓/丹药可正常伤害敌人；战斗中打开总牌组会进入独立 `DeckViewLayer`，不再和顶栏 UI 错位。
- 战斗 UI 预览：`art/design/run_battle_ui_preview.png` 与 `art/design/battle_ui_preview.png` 可用于人工对照；截图 helper 会临时写 marker，提交/交接前删除 `*_marker.txt`。
- `run_godot_checks.py` 已改用 UTF-8 解码 Godot 输出，修复了中文 Windows 上的 GBK 解码崩溃。
- ⚠️ **新增/替换 PNG 后必须在 Godot 编辑器导入一次**（跑上面的 console exe `--editor --quit`），否则会出现「文件在但加载失败 / no loader found」的错误，而 `validate_project.py` 查不出（它只查文件是否存在、查不出"未导入"）。Godot 退出时偶尔有 RID/resource leak 警告；只要没有 `SCRIPT ERROR` / `Parse Error` / `Failed to load script`，通常不是本轮 UI 脚本问题。

## 6. 最近改动摘要

### 本轮（2026-07-06）魔修 Demo 收束、战斗 UI 与交互修复

- **选人界面暂时只开放魔修**：`character_selector.gd` 中剑修也已 disabled，Demo 范围明确为“魔修单职业完整可通关”。
- **新增魔修功法/引擎卡与配套牌**：落地 10 张功法引擎、4 张技能、2 张 X 费终结技；相关新插画在 `art/cards/demonic_cultivator/ai/demon_*.png`，新资源在 `characters/demonic_cultivator/cards/engines/` 与魔修卡池。
- **战斗 UI 卡牌化布局推进**：新增 `battle_combatant_card.gd`，玩家/怪物信息逐步转为目标图方向的卡牌式信息框；抽牌堆、弃牌堆、焰轮、能量、结束回合、敌人意图等已接入新的黑金暗紫 HUD 资源。
- **出牌预览动画**：`card_ui.gd` 出牌时发 `card_play_preview_requested`，`battle_ui.gd` 在战场中央放大悬停一会再淡出；修复了预览层 `to_local()` 坐标转换导致的攻击牌报错。
- **战斗中总牌组错位修复**：`run.gd` 运行时把 `%DeckView` 移到独立 `CanvasLayer`（`DeckViewLayer`，layer 18），解决战斗打开总牌组时和顶栏/战斗 HUD 错位的问题。
- **符箓丹药伤害修复**：`CardEffect.execute_damage()` 现在允许 `card == null`，攻击类丹药/符箓恢复对敌人生效；火灵根选择等只在真实卡牌来源时触发。
- **交接给手感优化的文件地图已补**：第 7 节新增“战斗界面 / 手感优化重点（给 Claude）”，后续优化 tween、hover、拖拽、命中反馈、hit pause、目标选择反馈时优先看那里。

### 本轮（2026-07-01）Demo 机制、事件、控制台与 UI 统一

- **灵根机制重做**：开局仍随机三选一；选择后仍把一张打击或防御转成对应元素，同时新增一张随机同元素“灵根职业卡”。同元素永久牌计入成长，阶段改为初悟 0-3、小成 4-6、圆满 7+，并禁用旧圆满触发规则。
- **灵根圆满被动落地**：火/金/水/土/木各自拥有每回合最多一次的圆满效果；回合开始重置触发状态；水的费用减免只持续本回合；木在回合结束按是否打出木牌结算；火的选择资源见 `custom_resources/spirit_root_fire_choice.gd`。
- **失败遗产法宝替换**：新增 `custom_resources/defeat_legacy.gd`；失败后记录本局获得的法宝，下一局进入地图时可选一个替换角色本命法宝，也可保留原本命法宝。
- **法宝 hover tooltip**：遗物/法宝说明改为鼠标悬停的小窗口，避免点击后进入全屏效果说明；相关文件在 `scenes/relic_handler/relic_tooltip.*`、`relic_ui.gd`、`relic_handler.gd`、`run.gd`。
- **新增 10 个事件并临时只开放新事件池**：事件场景位于 `scenes/event_rooms/`，插图位于 `art/event_illustrations/`；`event_room_pool.tres` 当前只包含最近新增的 10 个事件，旧事件暂时不出现在地图事件房。
- **调试控制台**：新增 `scenes/debug/debug_console.gd` 与 `custom_resources/debug_console_state.gd`，Run 场景按 Ctrl + 反引号打开。支持增删/升级/融合卡牌，改血量/金币/法宝/丹药，以及设置下次造成/受到伤害；伤害测试钩子已接到 `card_effect.gd`、`configured_flame_effect.gd`、`configured_soul_mark_detonate_effect.gd`、`player.gd`。
- **全局 UI 风格统一一轮**：扩展 `scenes/ui/ink_theme.gd`，新增暗黑修仙通用标题、面板、按钮、图标底板等工具函数，并套到奖励、商店、宝箱、祝福、篝火、删牌、升牌、融合、牌堆、胜负面板、暂停菜单、调试控制台、灵根选择等界面。
- **编码配置补强**：新增 `.editorconfig` 与 `.gitattributes`，目标是统一 UTF-8 和文本文件规范，减少 Windows 终端/编辑器里中文乱码与换行差异。
- **验证结果**：2026-07-01 最近一次 `run_godot_checks.py` 全部 smoke 项通过；本轮收尾会再做轻量 diff 检查后提交推送。

### 本轮（2026-06-26）UI、资产与工具链更新

- **Godot MCP 配置修复**：根目录 `.mcp.json` 使用 server 名 `godot`，命令为 `C:/Program Files/nodejs/node.exe E:/code/Godot-MCP/server/dist/index.js`，并设置 `GODOT_MCP_URL=ws://localhost:9085`。Codex 设置页的全局 `godot` server 也需保持同样路径和端口。若设置里启用了 godot 但模型工具列表没有 `mcp__godot__...`，优先检查全局配置是否仍指向旧的 `E:\code\game-demo\mcp-server-dist\index.js`；这份旧 server 默认连 `9090`，会导致 MCP 初始化超时。
- **主页目标图落地**：`main_menu.gd` / `main_menu.tscn` 改为暗黑修仙主界面方向，透明中心菜单、无九宫格外框、按钮 hover/focus 比默认态略长，取消“新的轮回”默认 focus 高亮；新增/替换主页背景资产 `art/backgrounds/main_menu_background_v2.png`。
- **选人界面目标图落地**：`character_selector.gd` 和相关背景帧资源更新，剑修/魔修选择页更贴近 `art/design/选人界面目标.png`；动画背景帧做了数量与导入资源整理。
- **地图节点可读性增强**：`map_room.gd` / `map.gd` 增加 hover/focus 说明，精英战、营火、商店、机缘、宝箱等节点对新玩家更清晰。
- **图鉴/数据/卡牌平衡扩展**：新增 `data/`、`docs/`、`game_data.xlsx` 与 `scripts/*_table.py` / `game_data_to_xlsx.py` / `xlsx_to_game_data.py` 等统一数据表工具；大量卡牌、祝福、怪物 AI 与动作脚本随表格/平衡调整更新。
- **魔修战斗界面按 `art/design/target.png` 重构**：`battle_ui.gd`、`mana_ui.gd`、`flame_wheel_ui.gd`、`intent_ui.gd`、`run.gd`、`ink_theme.gd` 等接入 `assets/ui/generated/battle/` 新 HUD 资产；底部焰轮、法力球、牌堆、结束回合按钮、敌人意图、Run 顶栏都转为黑金暗蓝风格。
- **默认战斗/预览辅助**：`battle.tscn` 与 `run_startup.tres` 的默认预览角色转向魔修；新增 `test_data/capture_battle_ui_preview.*` 与 `capture_run_battle_ui_preview.*` 方便截图对照 `art/design/battle_ui_preview.png` / `run_battle_ui_preview.png`。
- **验证结果**：2026-06-26 已跑 `validate_project.py`（0 error / 0 warning）与 `run_godot_checks.py --godot ...Godot_v4.5.2-stable_mono_win64.exe`，全部 smoke 项通过。

### 本轮（2026-06-25）系统级更新

- **统一 Excel 数值总表 `game_data.xlsx`**（新）：一个文件三张表（卡牌/祝福/怪物AI）调全部数值。导出 `game_data_to_xlsx.py` / 回写 `xlsx_to_game_data.py`；模块 `card_table`/`blessing_table`/`ai_table`。详见第 7 节。修了 `card_table.py` 一个既有正则缺陷（`amount` 误匹配 `consume_amount`，会写坏魂印引爆卡）——现已锚定行首 `^amount`，特殊效果安全跳过。
- **祝福系统重构为 5 类「劫中遗赠」**（数据外置到 `data/blessings.json`，`blessing.gd` 运行时读取）：灵脉余泽(续航)/残仙遗蜕(以命换力·带代价)/补天盟密阵(牌组改造)/照命石审判(赌命·发法宝)/命格共鸣(角色专属，按 `_character_class()` 过滤)。效果用 `effects` 数组（可叠加收益+代价）：`max_health/lose_max_health/full_heal/gold/lose_gold/max_mana/draw/upgrade/remove_card/duplicate_card/grant_relic`。持续型走发法宝（`run.gd` 已把 `relic_handler` 传入祝福场景）。
- **剑修/魔修数值上调**：血量 32/30 → **100**，每回合费用(`max_mana`) 3 → **4**。⚠️ 敌人伤害/章节缩放仍按旧血量配置，需重新配平（见第 8 节待办）。
- **测试地图固定 + 敌人 AI 固定套路**：`map_generator.gd` 两个测试模式的普通/精英/Boss 固定为 符纸兵+雾隐狼 / 牛魔 / 渊狱剑魂（`TEST_FIXED_*`，正式 roguelike 仍随机）。这 4 个敌人各建专属 AI 场景，用 `EnemyActionPicker.fixed_sequence`（按回合循环固定出招，空序列时其它敌人保持原随机逻辑）。
- **选人界面优化**：动画背景改异步加载(`ResourceLoader.load_threaded_request`)+帧集缓存，消除进入/切换卡顿；帧率可按角色覆盖(`animated_background_fps`，剑修 12fps)。
- **战斗 HUD 重构 + 目标图**：见 `art/design/battle_redesign_plan.md`（对照 `now.png`→`target.png` 的分区计划）。

### 本轮（2026-06-23）系统级更新

- **魔焰焰轮 7 色 rider 细化**（阶段3 收尾）：绿消煞翻倍 / 蓝减魔焰费用 / 黄本回合魔焰共鸣伤害+（2+其它色数）/ 红 4 色引爆全体魂印。`ConfiguredFlameEffect` 新增 `Rider` 枚举与 `base_amount`，`class_mechanic_handler.gd` 加 `consume_sha_qi`/`reduce_flame_card_costs`/`detonate_all_soul_marks`/焰伤 buff。详见第 4 节阶段3。
- **符箓丹药接入图鉴**：`codex.gd` 新增「符箓丹药」分类（符箓/丹药二级分组、稀有度颜色、按效果类型解析展示）。
- **魔修卡牌改名/平衡**：`demon_flame`→「魔焰燎原」（与「魔焰焚心」区分）；血祭斩 9→7、血盾 10→8（`cards.xlsx` 同步）。
- **主菜单动效**：赤红灵光粒子（满屏）+ 背景呼吸辉光。
- **战斗焰盘常显**：魔修战斗开局即显示焰轮（空时全暗）。
- **符箓丹药专属图标**：6 张新图标接入 `art/potions/icons/`（替换借用的通用图标）。

### 本轮（2026-06-19）系统级更新

> 详细机制见第 4 节；魔修大改完整方案见记忆 `demonic-overhaul-plan`。

- **符箓丹药系统**（新）：可携带一次性消耗品（对标药水）。`custom_resources/potion.gd`（复用 `CardEffect`）；`scenes/potion_handler/`（3 槽位、点击使用、hover tooltip）；顶栏灵根右侧显示；战斗内可用，回血类丹药战斗外也可用。**获取**：普通战斗 ~40% 掉落、精英必掉、商店上架 2 个。`SaveGame.potions` 持久化。起手赠送 2 个。6 张初始：回春丹/聚气丹/引灵符/烈焰符/寒冰符/血祭符。
- **魔修·阶段1 煞气**（`statuses/sha_qi`，逻辑在 `scenes/battle/class_mechanic_handler.gd`）：受伤(`player_hit`)/出煞气牌得煞气；≥3 卡伤+1、≥6 造成/受到×2、≥10 天魔降世(本回合×3，回合末关、下回合开始失50%最大生命+煞气降5)。仅魔修生效。阈值用 modifier 系统**原地改值**实现（不要用 `remove_value`，它 queue_free 延迟会丢值）。煞气牌：引煞诀/聚煞。
- **魔修·阶段2 魂印引爆(X=3)**：新增 `configured_soul_mark_detonate_effect.gd`（消耗 N 层→ 3×N 伤害，**走玩家 DMG_DEALT 增伤**，被煞气放大）与 `configured_soul_mark_consume_effect.gd`（转化消耗）。回合末 DoT 仍由敌人自身状态结算(stacks×2)，**不吃增伤**。卡：引爆 裂魂/三魂同焚/魂葬，转化 魂铠/摄魂续元（均已入抽卡池）。
- **魔修·阶段3 魔焰焰轮**：`configured_flame_effect.gd`（携带本牌颜色，先按焰轮里"其它颜色"数结算共鸣，再把自身颜色加入焰轮）；焰轮状态在 `class_mechanic_handler.gd`（组 `class_mechanic`，回合开始/结束清空）。7 张七色魔焰卡（紫蚀魂/白护魂/绿镇煞/蓝灵涌·移出战斗/黑噬血/黄狂烬/红焚界），初始卡组加魔焰紫·蚀魂，全部入抽卡池。共鸣按"每有1种其它颜色"缩放。**7 色 rider 已细化**（`ConfiguredFlameEffect` 新增 `Rider` 枚举 + `base_amount`/`rider`/`rider_value`，逻辑落在 `class_mechanic_handler.gd`）：
  - 紫·蚀魂：破绽+伤，共鸣挂魂印（`SOUL_MARK_TARGET`）。
  - 白·护魂：伤+护体，共鸣每其它色+护体（`BLOCK_SELF`）。
  - 黑·噬血：失血+伤，共鸣每其它色+伤（`DAMAGE_TARGET`）。
  - **绿·镇煞**：10 护体(每其它色+5)；煞气≥2 时消 2 煞气令**本牌护体翻倍**（`Rider.SHA_QI_DOUBLE_BLOCK`，`consume_sha_qi`）。
  - **蓝·灵涌**：2 灵气；每有 1 种其它色 → 手牌 1 张魔焰卡**费用-1**（`Rider.REDUCE_FLAME_COST`，`reduce_flame_card_costs`，自限上限、排除本牌；复用 `card.reduce_cost_for_turn`）。消耗。
  - **黄·狂烬**：本回合**魔焰共鸣伤害 +（2+其它色数）**，可叠加（`Rider.FLAME_DAMAGE_BUFF`，handler `_flame_damage_bonus`，回合切换清空；**仅作用共鸣伤害**=方案甲，在 `_deal` 叠加）。
  - **红·焚界**：群伤+共鸣群伤；焰轮含红达 **4 色 → 引爆所有敌人魂印**（`Rider.DETONATE_AT_COLORS`，`detonate_all_soul_marks`，每层 3 伤走玩家增伤）。
  - 卡面文案由 `ConfiguredFlameEffect.get_description`（共鸣+rider）与基础效果描述拼接；各卡 `effect_text` 同步更新作兜底。绿/黄已把主效果并入 flame effect 以便 rider 作用全部数值。
- **魔修三系统已全部落地** ✅（煞气/魂印引爆/魔焰焰轮）。
- **战斗内焰轮 UI**：`scenes/battle/flame_wheel_ui.gd`（"焰" + 7 色色珠，本回合点亮的颜色高亮、其余暗淡，空焰轮隐藏），置于战斗左下能量条上方。实时刷新走新信号 `Events.flame_wheel_changed`（`class_mechanic_handler` 加色/清空时发出）。
- **丹药栏 UI**：`run.gd` 把符箓丹药槽包进 `InkTheme` 面板（与灵根徽章同款边框 + "丹" 标签），放在顶栏灵根徽章右侧。

### 本轮（2026-06-18）系统级更新

> 详细机制位置见第 4、7 节。

- **卡牌模板重做**：`card_visuals.tscn` 改为**锚点比例布局**（不再用固定像素偏移，任意尺寸不漂移），各元素对齐卡框窗口；描述文字垂直居中。
- **插画移到边框下层 + 填满窗口**：把 7 张卡框 PNG（`art/ui/cards/generated/card_frame_*.png`）的插画窗用洪水填充**挖空成透明**，渲染顺序改为「插画在下、边框在上」，插画铺满窗口、金边压在插画之上。
- **卡牌整体放大 1.4 倍**：`Hand.CARD_SIZE` 160×230→224×322（含扇形间距）、`card_ui.tscn`、`card_visuals.tscn`、`card_menu_ui.tscn` 同步；奖励三选一容器加宽、牌库网格列数 7→6、融合网格列数 4→3，防溢出。
- **全量 mipmap**：所有会缩小显示的高清美术（卡插画/卡框/帧动画/立绘/敌人/法宝·状态·地图图标/背景）开启 mipmap，消除缩放白点/走样；**像素 `tiles/tile_*` 不开**。新增/替换高清图记得开 mipmap 再导入。
- **战斗动画**：接入魔修**施法 `Spellcasting` / 死亡 `death`** 帧动画；`ANIM_DEFS` 帧率统一 **20fps**。
- **攻击/受击时序**：攻击牌出牌→播放攻击动画→**动画结束才结算伤害**（`card.gd` 用 `Events.attack_animation_finished` 门控；玩家无动画时立即发信号兜底）；受击对称——`player.take_damage` 受击动画播完才扣血。
- **战斗人物**：缩小至 80%（`player.gd MAX_BATTLE_ART_HEIGHT 102→82`）+ 上移（`battle.gd PLAYER_SCREEN_ANCHOR y 0.50→0.42`）。
- **护体蓝条**：`stats_ui` 血条下方新增蓝色护体条；状态栏下移让位（`player.gd`/`enemy.gd` 的 +27→+46）。玩家/怪物共用。
- **状态图标**：放大（17→26px）+ **悬停 tooltip**（`status_ui.gd` 把 `status.tooltip` 填到 `tooltip_text`）。修复 tooltip 被遮挡——`battle.tscn` 的 `Hand` 控件改 `mouse_filter=IGNORE`（空白处穿透）、`StatusUI` 改 STOP。
- **选人界面**：隐藏体修/驭兽（`enabled` 开关，默认选剑修）；**移除立绘**；**按职业切换背景**——剑修=`art/backgrounds/sw.png`、魔修=`art/backgrounds/demonic_selector_bg.png`；**去掉了背景上的色罩/暗角**（`AccentTint`/`Vignette` 已隐藏）。
- **商店/融合 UI**：商店标题上移防遮挡；融合每行列数下调。
- **魔修打击/防御换图**：新建 `demon_strike.tres` / `demon_defend.tres`（用 `art/cards/demonic_cultivator/ai/attack.png` / `defense.png`，秘术框），换进魔修起手牌组；**不影响其它职业的通用打击/防御**。
- **Excel 数值管线**（新工具）：`cards.xlsx` + `scripts/cards_to_xlsx.py`（导出）/`xlsx_to_cards.py`（回写）/`card_table.py`（共用）。改 xlsx 的浅黄列→跑回写脚本→Godot 导入。只调数值（费用/伤害/护体/层数/名称/类型等），增删效果/改状态种类仍在 Godot 改。幂等（无改动导入=改 0 文件）。
- **art 清理 + 校验修复**：删除未用资源（旧标题图/背景/占位 tile/未用帧）；`validate_project.py` 已修掉默认值字段误报（现 0 error）；更新 `art/README.md`。
- **外部图标**：接入了一批 `art/generated_icons/tile_replacements/` 生成图标（替换占位 tile）。

### 上一轮（2026-06-16）系统级更新

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

### 主菜单 / 选人

- `game-demo/scenes/ui/main_menu.tscn` / `.gd`（标题已烤进 `art/backgrounds/background1.png`）
- `game-demo/scenes/ui/character_selector.tscn` / `.gd`（当前体修/剑修/驭兽均 disabled，只开放魔修；按职业背景：剑修 `art/backgrounds/sw.png`、魔修 `art/backgrounds/demonic_selector_bg.png`；无色罩/暗角）

### 数值工具 · 统一 Excel 管线

- `game_data.xlsx`（统一数值总表，项目根）——三张数据表：**卡牌 / 祝福 / 怪物AI** + 说明页。只改浅黄列，灰列只读。
- 导出：`python scripts/game_data_to_xlsx.py`（读 .tres/.json/.tscn → xlsx）
- 回写：`python scripts/xlsx_to_game_data.py`（xlsx → .tres/.json/.tscn），之后 Godot 导入一次。
- 模块：`scripts/card_table.py`（卡牌）/ `blessing_table.py`（祝福，读写 `data/blessings.json`）/ `ai_table.py`（4 个固定套路敌人 .tscn）。
- **覆盖范围**：卡牌只调标准 amount 类效果（伤害/护体/治疗/状态层数）+ 费用；祝福可改描述/命格/效果类型+值（导入按表整体重建 JSON）；AI 改 数值 + 出招序列。
- **不可调**：魂印引爆 `damage_per_stack`、魔焰焰轮 color/rider 等特殊字段（表中留空，仍在 Godot 改）。幂等：无修改回写 = 改 0 文件。
- 旧 `cards.xlsx` + `cards_to_xlsx.py`/`xlsx_to_cards.py` 已被取代（保留未删）。

### 卡牌显示

- `game-demo/scenes/ui/card_visuals.tscn`
- `game-demo/scenes/ui/card_visuals.gd`
- `game-demo/scenes/ui/card_style.gd`
- `game-demo/scenes/ui/card_menu_ui.tscn`
- `game-demo/scenes/ui/card_menu_ui.gd`
- `game-demo/art/ui/cards/generated/`

### 战斗界面 / 手感优化重点（给 Claude）

- `game-demo/scenes/battle/battle.tscn` / `game-demo/scenes/battle/battle.gd`：战斗场景入口、背景、玩家/敌人节点、站位锚点、BattleUI 与战斗流程连接。不要在这里改核心结算，除非只是调整视觉站位或信号转接。
- `game-demo/scenes/ui/battle_ui.gd`：战斗 HUD 总控，负责手牌、法力/能量、回合、抽牌堆/弃牌堆、结束回合、玩家/怪物卡片、敌人意图位置、出牌预览动画和 HUD 布局。
- `game-demo/scenes/ui/battle_combatant_card.gd`：运行时玩家/怪物信息卡，头像、卡面、竖向血条/护体条、状态图标、敌人意图挂点都在这里。
- `game-demo/scenes/ui/mana_ui.tscn` / `game-demo/scenes/ui/mana_ui.gd`：能量显示；当前是靠战斗 UI 运行时摆位，后续可优化数字 tween、脉冲和消耗反馈。
- `game-demo/scenes/battle/flame_wheel_ui.gd`：魔修焰轮显示、颜色点亮、大小和左下角布局；焰轮逻辑来源在 `class_mechanic_handler.gd`。
- `game-demo/scenes/ui/hand.gd`：底部手牌扇形布局、hover 放大、选中抬升、间距、角度、动画时长，是“丝滑手感”的核心文件之一。
- `game-demo/scenes/card_ui/card_ui.gd` 与 `game-demo/scenes/card_ui/card_states/*.gd`：单张卡的输入状态机、hover/drag/aim/release/play 流程；出牌预览信号也从这里发出。
- `game-demo/scenes/card_target_selector/card_target_selector.gd`：攻击牌瞄准线、目标检测、目标高亮；适合加更明显的吸附、轨迹、目标反馈。
- `game-demo/scenes/ui/card_visuals.tscn` / `.gd` 与 `game-demo/scenes/ui/card_style.gd`：卡牌正面渲染、文本、插画、卡框、稀有度/类型风格。
- `game-demo/scenes/ui/card_pile_view.gd` 与 `game-demo/scenes/ui/card_pile_opener.gd`：抽牌堆/弃牌堆/总牌组查看窗口。战斗总牌组现在由 `run.gd` 移到 `DeckViewLayer` 避免错位。
- `game-demo/scenes/run/run.gd`：Run 顶栏、总牌库按钮、丹药/法宝/灵根栏、`DeckViewLayer`、进入战斗时的 UI 显隐。战斗 HUD 和 Run 顶栏有交界，改 overlay 前一定看这里。
- `game-demo/scenes/player/player.gd` 与 `game-demo/scenes/enemy/enemy.gd`：玩家/敌人立绘、帧动画、受击/死亡表现、旧血条 overlay 显隐、伤害文字时序。
- `game-demo/scenes/ui/ink_theme.gd`：暗黑修仙通用 StyleBox、按钮、面板、标题底板工具。新面板先复用这里，避免每个页面继续长出自己的皮肤。
- 战斗 UI 资产重点目录：`game-demo/art/ui/battle_cards/`、`game-demo/art/ui/battle_widgets/`、`game-demo/assets/ui/generated/battle/`、`game-demo/art/design/run_battle_ui_preview.png`、`game-demo/art/design/battle_ui_preview.png`。
- 给 Claude 的手感优化建议：优先处理 tween/easing、hover/drag inertia、目标吸附反馈、出牌悬停节奏、命中停顿、轻量屏幕震动、音效钩子和伤害数字节奏；在 UI 手感稳定前不要改卡牌数值、战斗结算或存档结构。

### 商店与奖励

- `game-demo/scenes/shop/shop_card.tscn`
- `game-demo/scenes/shop/shop_card.gd`
- `game-demo/scenes/ui/card_rewards.tscn`

### 战斗卡牌交互

- `game-demo/scenes/card_ui/card_states/card_base_state.gd`
- `game-demo/scenes/card_target_selector/card_target_selector.gd`

### 灵根 / 失败遗产 / 调试控制台

- `game-demo/scenes/ui/spirit_root_selector.gd`（灵根三选一、转元素、发灵根职业卡）
- `game-demo/custom_resources/character_stats.gd`（灵根成长阶段与数值修正）
- `game-demo/scenes/battle/spirit_root_handler.gd`（圆满被动、每回合触发次数、回合开始/结束重置）
- `game-demo/custom_resources/spirit_root_fire_choice.gd`（火圆满选择结果资源）
- `game-demo/custom_resources/defeat_legacy.gd`（失败后可继承的法宝列表）
- `game-demo/scenes/debug/debug_console.gd`（Run 内调试控制台，Ctrl + 反引号打开）
- `game-demo/custom_resources/debug_console_state.gd`（调试控制台跨系统状态，含下次伤害修正）

### 事件 / 法宝说明

- `game-demo/scenes/event_rooms/event_room_pool.tres`（当前仅开放 10 个新事件）
- `game-demo/scenes/event_rooms/*_event.tscn`（事件场景）
- `game-demo/art/event_illustrations/`（事件插图）
- `game-demo/scenes/relic_handler/relic_tooltip.tscn` / `.gd`（法宝 hover 小 tooltip）
- `game-demo/scenes/relic_handler/relic_ui.gd`

## 8. 当前注意事项与已知问题

### 美术现状

- 剑修、魔修卡牌已接入 AI 生成大插画（`art/cards/<职业>/ai/`）；**体修、驭兽卡面仍是占位小图**，待补。
- 新增魔修功法/配套牌插画统一放在 `art/cards/demonic_cultivator/ai/demon_*.png`，后续如重出图应继续参考现有魔修人物风格，避免卡面角色长相割裂。
- 通用卡（打击/防御等 `common_cards/`）仍用 16px 占位图，放大后偏糊；魔修起手已用专属 `demon_strike`/`demon_defend`（AI 图）替代。
- 卡框资源是 AI 生成贴图，插画窗已挖空透明；新卡框需保持相同窗口区域与透明窗，避免重改 UI。
- `art/tiles/tile_*` 仍是 16px 占位像素图（**不要给它们开 mipmap**）；部分已被 `art/generated_icons/tile_replacements/` 替换。

### 已知问题

- **Godot MCP 工具注入时机**：MCP 修复后，当前已经开始的 Codex turn 不会热插入 `mcp__godot__...` 命名空间；需要新开一轮、重载线程或重启 Codex 让工具列表重新生成。验证命令可用 MCP stdio client 列工具，预期包含 `open_scene`、`get_project_info`、`list_nodes`、`execute_editor_script` 等 16 个工具；Godot 侧 `get_project_info` 应返回项目名「万劫求仙」和当前场景路径。
- **UI 统一仍需人工视觉 QA**：这轮先用现有资产和 `InkTheme` 统一了大部分页面风格，没有继续精抠每个界面的像素级布局。后续若要达到目标图级品质，应逐页进 Godot 检查按钮状态、文本遮挡、面板透明度和不同分辨率下的间距。
- **旧事件当前被临时禁用**：`event_room_pool.tres` 只开放 10 个新事件是为了集中验证。等新事件稳定后，记得决定是恢复旧事件、分章节混池，还是按权重轮换。
- **调试控制台快捷键**：使用 Ctrl + 反引号，不要再绑定 F8。F8 在 Godot 编辑器运行时会停止项目，看起来像“按控制台键直接退出”。
- **战斗 UI 手感仍是下一阶段重点**：本轮已把总牌组 overlay、出牌预览报错、符箓丹药伤害修好，但手牌 hover/drag、攻击瞄准吸附、命中反馈、hit pause、伤害数字节奏和音效反馈还没做到成品级。详见第 7 节 Claude 文件地图。
- **单体攻击符箓/丹药目标选择仍偏简单**：无卡牌来源的攻击效果已能生效，但如果没有显式目标，当前主要走第一个存活敌人的兜底逻辑。若要做成品手感，建议后续给攻击丹药/符箓增加一次性目标选择状态。
- **战斗数值待按 100 血重配平**：剑修/魔修血量已 30/32→100、费用 3→4，但敌人伤害（固定 AI 的处决 12/重砸 10 等）和 `map_generator.gd` 章节缩放仍按旧血量配置，现在战斗偏软。需重新配平敌人伤害 + 章节倍率（可经 `game_data.xlsx` 怪物AI 表 + `map_generator` 倍率调）。
- **`run-flow` 偶发 `Lambda capture freed`**：完整流程约 2/12 偶发，还有一处多回合补间回调来源未根除（疑似 `status_handler`/`relic_handler`/弃牌结算）。非功能 bug（逻辑仍通过，重跑即过），但将来上 CI 会随机红灯。修法：把 `tween.finished` 的 lambda 改为捕获 `get_instance_id()` / 加 `is_instance_valid` 守卫。
- **`validate_project.py` 仍有盲区**：查不出「文件在但未导入」（缺 `.import`）和字符串拼接路径。新增美术务必在编辑器导入。（注：默认值字段误报已修，现 0 error。）
- **存档跨资源移动会失效**：存档按路径内嵌资源引用，移动/重命名被引用资源后旧档加载失败（有自愈清档兜底，但丢进度）。彻底修复需改成"按 id 重建"（ROADMAP 阶段 0）。
- **魔修待办**：~~`demon_flame`/`demon_flame_heart` 重名~~（已改：群伤献祭的 `demon_flame`→「魔焰燎原」，单体破绽的 `demon_flame_heart` 保留「魔焰焚心」）；~~血祭白卡偏强~~（已调：血祭斩 9→7、血盾 10→8，`cards.xlsx` 同步）；~~魔焰 rider 待细化~~（已细化，见第 6 节）；魂印仍可补更多"引爆" payoff 卡；确认 37 张魔修卡都进了 `demonic_cultivator_draftable_cards.tres`。
- **符箓丹药图标**：已接入 6 张专属图标到 `art/potions/icons/`（healing_pill/qi_pill/draw_talisman/flame_talisman/frost_talisman/blood_rite_talisman），替换原借用的通用图标。⚠️ 新增 PNG 务必在编辑器导入一次（`--headless --editor --quit`），否则潜在丹药 `.tres` 加载失败、`main/codex/run-flow/boss-battle` 全红。
- 调整卡牌比例时，要同步检查战斗手牌、奖励三选一、商店、图鉴/预览、升级、删除、融合界面（当前卡 224×322，详见第 6 节 1.4x 改动）。
- 主菜单标题已烤进背景图 `art/backgrounds/background1.png`（旧 `baijie_chengxian_title.png` 已删）；战斗/选人背景部分仍硬编码在项目根 `test1.png`/`test2.png`（见 `art/README.md`）。

## 9. 后续建议

1. 优先把魔修单职业 Demo 跑通：战斗、事件、商店、宝箱、篝火、Boss、失败/胜利、失败遗产都要完整体验一遍。
2. 下一轮重点建议交给 Claude 优化战斗手感：手牌 hover/drag、目标吸附、出牌悬停、命中停顿、伤害数字、轻量震动、音效反馈。
3. 为高频卡牌优先生成或绘制正式大插画，替换当前临时小图标；魔修卡面人物风格要统一。
4. 对卡牌标题字体、描述字体补充更有国风感的正式字体资源。
5. 对地图、商店、宝箱、祝福页面做一次统一视觉 QA，检查字体大小、按钮状态和不同分辨率下的遮挡。
6. 提交前重新运行 `validate_project.py`；较大系统改动后再跑 `run_godot_checks.py`，并人工进入战斗、商店、地图、奖励、主菜单确认视觉效果。
