# 万劫求仙项目交接文档

更新时间：2026-07-13（魔修完整 Demo 内容、奖励平衡与运行时验证）
项目根目录：`E:\code\game-demo`  
Godot 工程目录：`E:\code\game-demo\game-demo`  
Godot 版本：4.5.2 stable mono  
Godot 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe`
Godot Console 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe`

## 1. 当前状态（2026-07-13）

- 稳定运行的杀戮尖塔式修仙卡牌肉鸽 Demo。当前焦点：**把魔修打磨成完整 Demo**。
- **当前开发策略**：暂时不继续精抠单个 UI，优先把魔修职业做成可完整通关、可调试、可扩展的 Demo 闭环。
- **Demo 职业范围已收束**：选人界面当前只开放魔修，体修/剑修/驭兽都暂时 disabled；代码和资源仍保留，后续可再恢复。
- **UI 风格统一已推进一轮**：`InkTheme` 扩展了暗黑修仙通用面板/按钮/标题样式，并已套到战斗奖励、商店、宝箱、祝福、篝火、删牌、升牌、融合、牌堆、胜负面板、暂停菜单、调试控制台、灵根选择等界面。后续新增页面应优先复用 `scenes/ui/ink_theme.gd`，不要各自重新写一套 StyleBox。
- **事件池已完成分章恢复**：45 个事件按三章各 15 个独立配置；每章地图使用洗牌袋抽取，袋内耗尽前不会重复。
- **地图已切回正式 ROGUELIKE 模式**（2026-07-06）：`map.tscn` `map_mode = 1`，测试线性地图与自由导航已关闭；地图同轮加了走过路径染金、可选节点/连线呼吸、开图错落浮现、章节层数进度牌、平滑滚动与位置标记。
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
- **战斗手感优化专场已完成（2026-07-06，约 25 项）**：手牌 hover/拖拽/补位、飘字/命中特效/命中停顿、回合横幅/Boss 名牌/煞气阈值演出、抽弃牌飞行、洗牌提示、死亡溶解、金币滚动、地图标记、功法牌演出等全部落地；同轮已补 CC0 音效与战斗/主菜单 BGM。详见第 6 节「战斗手感优化专场」与第 7 节文件地图。
- **2026-07-07 Godot MCP 修复**：修复 `HitEffect` 被挂进 `EnemyHandler` 后，下一回合 typed 遍历把 `hit_effect.gd` 当 `enemy.gd` 导致崩溃的问题；特效改挂战斗世界层，`EnemyHandler` 遍历统一过滤 `Enemy`。
- `validate_project.py` 现在 **0 error / 0 warning**（2026-07-07 复跑；校验脚本已修掉「默认值字段被当成缺失」的误报，不再有历史的 198 个假错）。
- `run_godot_checks.py`：2026-07-13 最近一次全量运行 25 项检查全部通过，覆盖主流程、卡牌机制、状态法障、三章内容、普通敌人战术、9 Boss、精英战术、心魔难度、通用/魔修法宝与魔契、奖励经济与批量模拟、分章事件、合炼、战绩和篝火选择。
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
- **章节难度爬升**：`scenes/map/map_generator.gd` 的 `CHAPTER_HEALTH/DAMAGE/GOLD_MULTIPLIERS` 让敌人血量/伤害/金币按章节递增（经 `_battle_for_room` 复制缩放，不污染战斗池）；凡境进章回满，心魔 10 起只恢复一半已损生命；测试地图（`map_mode != ROGUELIKE`）开启 `Map.free_navigation`（所有节点可点，直接点 Boss 也能进章）。
- **数值/平衡关键位置**：商店按稀有度定价 `shop_card.gd PRICE_BY_RARITY` + 法宝价位带 `shop_relic.gd`；暗金卡上架 `shop.gd MYTHIC_SHOP_CHANCE=0.04`；灵根缩放 `character_stats.gd get_spirit_root_modified_value`（初悟 0-3 张：主数值+1；小成 4-6 张：ceil(基础主数值×1.2)+1；圆满 7+ 张：ceil(基础主数值×1.4)+1，并解锁每回合最多一次的元素被动）；剑意上限 `statuses/sword_intent.gd MAX_STACKS=4`；灵气回蓝上限 `statuses/energy_charge.gd MAX_MANA_PER_TURN=2`；四职业每回合均抽 5 张。
- **灵根圆满被动**：逻辑集中在 `scenes/battle/spirit_root_handler.gd` 与相关卡牌/效果钩子，回合开始可靠重置触发次数。火：每回合第一张火攻击牌弹选择，伤害×1.5 或按最终实际伤害 50% 溅射其它敌人；金：第一张金牌得 1 劲气；水：第一张水牌抽 1，抽到的第一张牌本回合费用 -1；土：第一张土牌得 1 真元；木：回合结束若本回合打出过木牌，回复 3 点生命，满血则得 3 护体。UI/tooltip/status 文案需要让玩家看懂本回合是否已触发。
- **敌人行动延迟回调**：敌人攻击/格挡行动用 `get_tree().create_timer()`/补间 `finished` 回调发 `enemy_action_completed`，**必须捕获 `enemy.get_instance_id()` 而非节点本身**（否则补间未完成前敌人/战斗被释放会报 `Lambda capture freed`）。新增此类行动请照此写法。
- **祝福系统（数据驱动，2026-07-06 Neow 化重做）**：祝福内容在 `data/blessings.json`（5 类来源，`blessing.gd` 运行时读取），效果分发在 `blessing.gd._apply_effect`。可经 `game_data.xlsx` 的「祝福」表编辑回写。新增效果类型要同时在 `_apply_effect` 加分支 + `blessing_table.py EFFECT_TYPES` 登记。命格共鸣按 `_character_class()`（资源路径判职业）过滤。
  - **选择结构（杀戮尖塔 Neow 式）**：不再"抽 1 个来源出 3 个同质选项"，而是打乱 5 个来源、每个来源各出 1 条，凑 4 个选项同台——稳妥（灵脉余泽·绿）/ 改牌（补天盟密阵·蓝）/ 以劫换福（残仙遗蜕·红）/ 豪赌（照命石审判·金）/ 命格专属（命格共鸣·紫，按职业过滤，无匹配则跳过该来源）。每行带来源徽记（`SOURCE_COLORS`）。
  - **新效果类型**：`remove_strike_defend`（只删打击/防御，id contains 匹配兼容 demon_strike）/ `add_random_cards`（随机职业卡）/ `add_random_rare_card`（随机金卡，无金卡退全池）/ `transform_card`（删起手牌换职业卡）/ `gain_potion`（经 "run" 组借 run 的丹药奖池发放，未改 run.gd）/ `lose_all_gold` / `weaken_next_battles`（发消耗性法宝）。
  - **破劫之印**（`relics/blessing_broken_seal.gd/.tres`，祝福专属、不入奖励池）：START_OF_COMBAT 使敌人以七成气血入场，`battles_left` 计数用尽后 `owner.queue_free()` 自碎；计数是 @export 字段随存档持久化。
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

- `validate_project.py`：0 error / 0 warning（2026-07-07 最近一次复跑，最近 UI/系统改动后仍保持无校验错误）。
- `run_godot_checks.py`：`main`/`character-selector`/`codex`/`battle`/`map`/`run-flow`/`boss-battle` 全部通过（最近一次完整跑通：2026-07-07）。
- 2026-07-06/07 针对性复现检查已过：攻击牌出牌预览坐标不再报错；无卡牌来源的攻击符箓/丹药可正常伤害敌人；战斗中打开总牌组会进入独立 `DeckViewLayer`，不再和顶栏 UI 错位；敌人受击 `HitEffect` 不再污染 `EnemyHandler`，下一轮 `reset_enemy_actions()` 不再类型崩溃。
- 战斗 UI 预览：`art/design/run_battle_ui_preview.png` 与 `art/design/battle_ui_preview.png` 可用于人工对照；截图 helper 会临时写 marker，提交/交接前删除 `*_marker.txt`。
- `run_godot_checks.py` 已改用 UTF-8 解码 Godot 输出，修复了中文 Windows 上的 GBK 解码崩溃。
- ⚠️ **新增/替换 PNG 后必须在 Godot 编辑器导入一次**（跑上面的 console exe `--editor --quit`），否则会出现「文件在但加载失败 / no loader found」的错误，而 `validate_project.py` 查不出（它只查文件是否存在、查不出"未导入"）。Godot 退出时偶尔有 RID/resource leak 警告；只要没有 `SCRIPT ERROR` / `Parse Error` / `Failed to load script`，通常不是本轮 UI 脚本问题。

## 6. 最近改动摘要

### 本轮（2026-07-07）MCP 修复与提交前整理

- **修复截图中的 Godot 报错**：`HitEffect.spawn()` 原先把命中特效加到受击敌人的父节点；敌人的父节点是 `EnemyHandler`，导致下一轮 `for enemy: Enemy in get_children()` 把 `HitEffect` 当 `Enemy` 遍历并报 `Trying to assign value of type 'hit_effect.gd' to a variable of type 'enemy.gd'`。
- **修复方式**：`hit_effect.gd` 新增父节点选择逻辑，遇到 `EnemyHandler` 时把特效挂到其父级战斗世界层；`enemy_handler.gd` 新增 `get_live_enemies()`，重置行动、敌方回合、手牌刷新意图都只遍历真正的 `Enemy`，并清理无效/待删除的 acting enemy。
- **验证**：`validate_project.py` 与 `run_godot_checks.py` 全量通过；另用临时回归场景验证“敌人受击生成 HitEffect 后再 reset_enemy_actions”通过，临时测试文件已删除。
- **提交范围提醒**：本次提交包含此前手感/音频/地图/非战斗界面动画/敌人卡图等一整批工作树改动，并删除旧 `cards.xlsx` 与 `game-demo/cards_config.xlsx`；当前数值总表以根目录 `game_data.xlsx` 为准。

### 本轮（2026-07-06）战斗手感优化专场（Claude 完成）

> 一次性落地约 25 项战斗界面手感/反馈优化，随后补上 CC0 音效/BGM 与非战斗界面入场/hover 动效；已通过 `validate_project.py`（0 error）与 `run_godot_checks.py` 全量 smoke。

**新增文件**（均在 `game-demo/scenes/battle/`）：

- `floating_text.gd`（`FloatingCombatText`）：战斗飘字。伤害红 / 格挡蓝"盾 N" / 自损暗红 / 治疗绿。世界节点经 `get_global_transform_with_canvas` 换算画布坐标，飘字挂 `ui_layer` 组（BattleUI），不受世界缩放影响。
- `hit_pause.gd`（`HitPause`）：命中停顿。实际扣血瞬间 `Engine.time_scale` 压到 0.05 持续 80ms（玩家挨打 120ms），恢复计时器用 `ignore_time_scale`。⚠️ **无头模式直接跳过**——否则会拖慢 smoke 测试里受 time_scale 影响的计时器，曾把 boss-battle 推过 60s 上限。
- `hit_effect.gd`（`HitEffect`）：命中冲击特效，代码绘制放射冲击线+中心闪光 0.26s。敌人命中橙金、玩家受击红、功法吸收/天魔降世金红。挂战斗世界层（会从 EnemyHandler 逃逸到其父节点），受击者释放不影响播完。

**新增 Events 信号**：`card_discarded`（弃牌动画）、`deck_reshuffled`（洗牌提示）、`sha_qi_tier_changed`（煞气档位演出）、`card_acquired_animation_requested`（购卡飞牌库）。

**手牌/卡牌交互**（`hand.gd`、`card_ui.gd`、`card_states/*`、`card_visuals.gd`）：

- Hover：聚焦响应 0.11s + `TRANS_BACK` 回弹放大，邻牌按距离衰减让位（`NEIGHBOR_PUSH=46`）。
- 补位：牌数变化的重排用 `TRANS_SPRING` 0.36s（弹簧感）；hover 让位仍走快速 cubic，两者分开。
- 抽牌从抽牌堆位置飞入（起点由 battle_ui 布局时写入 `hand.draw_origin_global`）；弃牌用 CardVisuals 幽灵卡飞向弃牌堆（不动 CardUI 状态机）。
- 拖拽惯性：自由拖拽按鼠标横向速度倾斜 ±9°，停下 0.3s 回正。
- 可打出的卡（我方回合且费用够）带暖金辉光（`card_visuals.playable_glow`，由 `card_ui` 的 `playable`/`disabled` setter 联动）；费用不足点击 → 卡面摇头 + 费用数字闪红。
- 结束回合按钮在无牌可打时亮度呼吸提示（battle_ui `_update_end_turn_breath`，0.2s 轮询）。

**数值条与信息卡**（`battle_combatant_card.gd`、`mana_ui.gd`）：

- 血条/护体条 0.45s tween 过渡 + 变化闪白/闪蓝 + 标签 punch；有 0.12s 轮询，**只在数值真正变化时启动动画**（diff 检测，重绑定时重置）。
- 状态图标改签名比对刷新：新词条弹出+淡入、层数变化数字 punch（原先每 0.12s 全量重建，动画活不过一帧）。
- 敌人意图文本变化（换招）→ 徽章弹跳+闪亮；能量球增减脉冲。

**打击感**（`enemy.gd`、`player.gd`）：

- 伤害落地按当前护体拆成"扣血红字 + 格挡蓝字"两条飘字；治疗经 `update_stats` 血量增量检测统一挂绿字（丹药/摄魂续元/木灵根/敌人疗愈全覆盖）；DoT（魂印灼烧/流血）走 `DamageEffect→take_damage`，飘字天然覆盖。
- 玩家受击：命中停顿 0.09s + 自身震动 + 战场根节点微震（敌人原有白闪+震动保留）。
- 敌人死亡溶解：染红压扁下沉淡出 0.62s 再发 `enemy_died`/释放；溶解中关碰撞、藏意图，`do_turn` 有 `_dying` 守卫。⚠️ 若再放慢需注意 boss_battle_smoke 击杀后只等 1.0s 就断言胜利面板。

**演出**（`battle_ui.gd`、`battle_over_panel.gd`、`flame_wheel_ui.gd`、`card_target_selector.gd`）：

- 敌我回合切换中央横幅（金「我方回合」/红「敌方回合」）+ 回合徽章脉冲；Boss 战开场延迟 1.45s 显示 Boss 名牌（`BOSS_IDS` 与 enemy.gd Boss 名单一致，紫色、停留 1.6s）。
- 煞气阈值演出：`class_mechanic_handler` 档位(0-3)变化发 `sha_qi_tier_changed`；升档弹横幅（凝聚/翻涌/天魔降世），玩家立绘按档位渐进染红（常驻气场），天魔降世附带战场震动+红色爆发。
- 瞄准锁定：锁定敌人时弧线/箭头红→亮金渐变+箭头 pop；目标四角框回弹收拢+呼吸脉冲。
- 焰轮新点亮色珠 1.7 倍放大回落+高亮闪烁（黑色魔焰有提亮兜底）。
- 功法（POWER）牌出牌演出：中央悬停后化金光飞向角色融入+金色爆发，与普通牌"上浮淡出"区分。
- 弃牌堆洗回抽牌堆：幽灵卡背错落飞向抽牌堆+计数 punch（原先是无提示暗改）。
- 胜负面板入场：淡入+标题回弹（树已暂停，tween 用 `TWEEN_PAUSE_PROCESS`）。

**战斗外**（`gold_ui.gd`、`run.gd`、`shop_card.gd`、`map.gd`）：

- 顶栏金币数字滚动（0.5s）+ 加钱闪金/花钱闪红，覆盖奖励/商店/事件；首次同步不滚。
- 商店购卡：幽灵卡从卡位飞向顶栏总牌库按钮（`DeckViewLayer`）+ 牌库计数 punch。
- 地图「当前位置」标记：`map.gd` 内部类 `PlayerMarker`（金色脉冲光环），落在最后走过的节点；点击新节点在 select 动画窗口内滑过去，本章首选原地弹出。

**调参入口**：各文件顶部常量——`hand.gd`（hover/让位/弹簧时长）、`floating_text.gd`（颜色/时长/字号）、`hit_pause.gd`（停顿时长/倍率）、`hit_effect.gd`（寿命/半径）、`battle_ui.gd`（横幅颜色/停留、辉光在 `card_visuals.gd` alpha 0.20）。

**节奏基线（2026-07-06 第二轮）**：试玩反馈"动画偏快"，已全局放慢约 35%（手牌布局 0.24s / 补位弹簧 0.48s / 飘字全程 ~1.05s / 命中特效 0.36s / 横幅停留 0.8s / 死亡溶解 0.62s / 金币滚动 0.7s 等）。再调快/慢按同比例缩放这批常量即可。

**第三轮补充（同日）**：

- **敌人攻击特效**（`enemy.gd _play_attack_telegraph`）：出攻击类意图（ATTACK/MULTI_ATTACK/ATTACK_DEFEND）的瞬间在其信息卡位置闪红色冲击特效。⚠️ 曾做过"位置突进前摇"但**无效**——当前战斗 UI 每帧隐藏世界立绘（`battle_ui._hide_legacy_combatant_overlays`），战斗单位只显示为信息卡，移动世界节点看不见；给战斗单位加表现一律作用到信息卡或经画布坐标锚定。
- **世界节点对齐信息卡（重要修复）**：`battle_ui._align_world_combatants`——布局后把敌人/玩家的世界 Area2D 移到各自信息卡中心（画布坐标反变换），碰撞体与四角选中框放大到卡尺寸（`enemy.align_feedback_to_card`），飘字/特效锚点走 `aligned_feedback_extents`。修掉了"选中框和怪物位置对不上（多怪更明显）"的 bug；新增战斗内世界定位逻辑时**必须**考虑这层对齐。
- **飘字再放慢一倍**（试玩反馈）：`floating_text.gd` 弹出 0.38 / 停留 0.76 / 淡出 0.96（全程 ~2.1s），`hit_effect.gd` 寿命 0.55。
- **飘字进一步放大放慢**（试玩反馈"看不清"）：`floating_text.gd` 字号伤害 38→52 / 格挡 30→42 / 自损 32→44 / 治疗 32→42，描边 6→9，文本框 180×48→280×80（防裁切），弹出改"过冲 1.25 倍再回落"，停留 0.76→1.30 / 淡出 0.96→1.20 / 上浮 62→72（全程 ~3s）。要再调只动这些顶部常量与 spawn_* 里的字号。
- **煞气常驻徽章**：玩家信息卡顶上方常驻「煞气 N」徽章（`battle_combatant_card._refresh_sha_badge`，0 层隐藏，按 3/6/10 档位变色发光、层数变化 punch）；档位气场染色改为染**信息卡立绘**（`set_aura_tint`，世界立绘隐藏染了白染）；档位横幅停留加长（升档 1.6s / 天魔降世 2.4s）。

**音频接入（同日，全部 CC0）**：

- **音效库** `global/game_sfx.gd`（`GameSfx` 静态类）：从 `art/audio/collected_dark_roguelike/` 精选 CC0 素材（来源/授权见该目录 `THIRD_PARTY_AUDIO.md`，CC-BY 素材刻意未用，零署名义务）。变体用 `randi` 随机——**不走 RNG autoload**，避免音效消耗存档种子影响战斗复现。`sound_player.gd play()` 新增 `volume_db` 参数。
- **挂点**：抽牌 card-slide×4 / 出牌 playcard / 弃牌 card-shove×4(-10dB) / 洗牌 shuffle / 结束回合 Passturn / 费用不足 error / 敌人受击 hit×4 / 玩家受击 slam×3 / 格挡 metal×3 / 敌人攻击挥砍 swish×3 / 敌人死亡 creature_die / 治疗 spell_01 / 功法吸收 spell_02 / 金币 item_coins×4 / 煞气升档锣 gong_01（天魔降世 gong_02）/ Boss 名牌钟 bell_03 / 地图选点 paper_01。
- **战斗 BGM**（`battle.gd _play_battle_music`）：普通/精英=`art/audio/battle_theme_normal.mp3`（Wolfgang_ Battle Theme，CC0），Boss（按敌群 id 检测）=`art/audio/battle_theme_boss.wav`（nene Boss Battle #2 Symphonic Metal，CC0）。两文件是从收集目录复制的干净命名副本（原 boss 文件名带 `#`，res:// 路径风险），`.import` 已开循环（mp3 `loop=true` / wav `edit/loop_mode=1`）。旧 `music` 导出字段保留作兜底。
- **音量基线**：BGM 原音量、SFX 按挂点 -2~-10dB（高频事件更低）。整体混音未精调，实际试玩后按需在 `GameSfx.play` 调用点改 dB。

**非战斗界面统一优化（同日）**：

- **全局按钮音**：`InkTheme.apply_screen_button` 自动给按钮挂 hover(tap -14dB)/点击(card-place -8dB)音，meta 标记幂等——所有走该函数的界面（主菜单/商店/奖励/篝火/祝福/暂停菜单/胜负面板/删升融牌等）一次覆盖，disabled 按钮不响。战斗蓝按钮（`apply_battle_blue_button`）未挂，结束回合有自己的音。
- **界面入场淡入**：新增 `InkTheme.animate_screen_entrance(root, duration)`，已应用：商店/战斗奖励/宝箱/篝火/祝福/胜利/图鉴（0.3s）、牌堆查看（0.2s）、主菜单（0.5s）。新界面记得加一行。
- **场景音**：宝箱开启=木箱开+宝石；篝火休整=治疗音、升级卡=书页；商店三类购买=铜钱（花钱侧，金币 UI 只响加钱侧）。
- **主菜单 BGM**：`dark_theme_jaggedstone.ogg`（CC0、循环）在 main_menu._ready 播放；进战斗被战斗曲替换，回主菜单再切回。地图/商店暂无独立 BGM（战斗曲会延续），备选 `vampires_piano_tad_cc0.mp3`（CC0）适合商店/营火，待定。

**非战斗界面视觉优化（同日第二批）**：

- **CardMenuUI 通用交互**（`card_menu_ui.gd`）：hover 浮起（scale 1.05 + z_index 抬高防邻卡遮挡）+ 错落 pop-in 入场（按容器下标延迟，封顶 20 个；先隐身等布局完成再弹，pivot 才正确）。商店卡/奖励三选一/牌堆网格/删牌/升牌/融合全部界面一次覆盖。
- **列表项错落淡入 helper**：`InkTheme.animate_item_entrance(item, stagger)`——已应用：奖励按钮（reward_button，含宝箱二选一）、商店三类货架（shop_card/relic/potion）、主菜单按钮。
- **选卡奖励飞向牌库**：`card_rewards.gd` 领取时发 `card_acquired_animation_requested`（从选中卡的位置起飞），与商店购卡共用 run.gd 的幽灵卡动画。
- **暂停菜单开启动画**：`pause_menu.gd` 新增 `open()`（run.gd 设置按钮已改走它），面板缩放回弹+淡入，tween 用 `TWEEN_PAUSE_PROCESS`。
- **事件界面淡入**：事件场景众多且各有 `_ready`，统一在 `run.gd._on_event_room_entered` 里做 `animate_screen_entrance`。

**地图杀戮尖塔化（同日第三批，`map.gd` / `map_room.gd`）**：

- **虚线路径**：连线改虚线贴图（运行时生成一次 dash 纹理 + `Line2D.LINE_TEXTURE_TILE`），颜色仍走 `default_color`（金=走过 / 暖亮脉冲=可选 / 近隐=错过 / 暗=未知）。
- **手绘弯曲**：直线改二次贝塞尔（8 段采样），弯度由端点坐标哈希决定——确定性、重建地图不变、不消耗 RNG。
- **错过支线变暗**：`row < floors_climbed` 且未选的节点压到 50% 灰 50% 透明，其连线加 "missed" 样式近乎隐去——在场分支一目了然。
- **节点 hover 放大**：可选节点悬停 1.18 倍回弹 + 轻音，移开缩回。⚠️ 与开图入场动画同用根节点 scale，入场期间 hover 可能打架（罕见，可接受）。
- **Boss 节点红光**：Boss 房常驻红色脉冲光环（仅 Boss 节点开 `_process`），隔半张地图可感。

**开局祝福 Neow 化重做（同日）**：详见第 4 节「祝福系统」条目。要点：跨来源四选一（每次必同台四种性格的取舍）、7 个新效果类型、消耗性法宝「破劫之印」、来源徽记配色、选定祝福锣声；`blessings.json` 全量重写，`blessing_table.py EFFECT_TYPES` 已登记，`game_data.xlsx` 已重导出。顺手修了选人界面初始灵石显示与实际不一致（99→70，实际值在 `run_stats.gd STARTING_GOLD`）。**平衡数值未实战校验**（如 -12~-16 最大生命的代价档、破劫之印 3 场七成血），试玩后按体感调 JSON 即可。

**地图卷轴拉高 + 主页动画增强（同日）**：

- **地图卷轴**：`map.gd SCROLL_FLOOR_CAPACITY` 15→**20**——卷轴背景按 20 层节点的高度绘制，`map_generator.gd FLOORS`（当前 13）拉到 20 以内都放得下，相机滚动范围自动跟随。要做 20 层章节直接改 FLOORS 即可。
- ~~主页动画增强~~（已按用户要求**回滚**：Ken Burns/鼠标视差/挂牌摇摆/龙饰呼吸/按钮hover放大全部移除，主页保持原有的灵光粒子+背景呼吸辉光+入场淡入）。

**Boss 专属出招 + 丹药目标选择 + 事件配平（同日）**：

- **Boss 出招差异化**：此前 4/5 Boss 共用小怪 AI（天阙镇将=crab 系、黑莲圣母/蚀日妖皇/骨龙=toxic_ghost 系），打起来只是大号小怪。已用 `fixed_sequence` 各建专属 AI 场景并改 `.tres` 指向：**天阙镇将**（镇守型：格挡30→戟击16→天雷26→戟击循环）、**黑莲圣母**（成长施法：+3力量→莲刺12(吃力量加成)→格挡22→莲刺循环，越拖越痛）、**蚀日妖皇**（蓄力大招：爪击14→蓄势(格挡15,CHARGE意图明牌)→**蚀日之啮34**三拍循环）、**骨龙**（猛攻型：2x11双爪→龙息18→双爪→骨甲18，几乎不防）。新场景在各 Boss 目录下；数值是基线，另有战斗 dmg_mult 1.15-1.25 与章节倍率叠加，**未实战校验**。
- **攻击符箓/丹药目标选择**（已知问题清偿）：`potion_handler.gd` 加瞄准模式——单体攻击丹药在**多敌**时点击后进入选目标状态（toast 提示 + 悬停亮敌人四角框 + 右键取消），单敌保持直接使用。命中测试用信息卡对齐后的画布矩形（`aligned_feedback_extents`）。
- **事件房配平**（40 个事件场景，含暂禁用的旧事件）：治疗 ×1.8、伤害代价 ×1.6、金币 ×1.2（取5倍数），生命上限不动；**选项文案数字与效果值脚本同步重写**；修复古战场"文案说失去 6 生命、效果却不扣血"的不符 bug。当前对 100 血：回血 14-29、代价 6-19、金币 30-110。

**战斗界面细节修缮（同日，用户选定"布局不动只抠细节"）**：

- **血量数字裁切 bug 修复**（`battle_combatant_card.gd`）：竖条底部的数字标签原先向卡外伸 23px，被 frame 的 `clip_contents` 裁切（"100/100"显示成"00/100"）。改为血条标签向卡内右伸、护体条标签向卡内左伸（`_layout_vertical_bar_label` 加 `align_right` 参数），字号 13→16。
- **卡内立绘放大**：左右边距从 44px 收到「条宽+4px」（约 34px），立绘占满卡窗，削弱黑盒感。
- **手牌防裁切**：`hand.gd HAND_Y_OFFSET` 50→26，卡底描述不再被屏幕边缘切掉。
- **英雄技能按钮代价角标**：魔焰焚心按钮右下角常驻红字「-2 生命」，不看 tooltip 也知道代价。
- **技能行移至角色牌下方**：右下角重排——玩家信息卡上移收窄（318×236，从底 124px），魔焰焚心（156×76）在其正下方偏左；右侧**留白**给未来第二技能（原「未悟」占位面板已按用户要求删除，加第二技能时放 from-right (70, 40) 尺寸 154×76 即可）。按钮边框与结束回合同款（`apply_battle_blue_button`）；「-2 生命」常驻角标已删，代价说明只在悬停 tooltip（文案：受到 2 点伤害，每回合限用一次）。
- **技能机制修订**：①**每回合限一次**——`player_handler._hero_skill_used_this_turn` 回合开始重置、施放置位（`can_use_hero_skill` 拦截），UI 侧经新信号 `Events.hero_skill_used` 同步禁用按钮到下回合；②代价改为**真实受到 2 点伤害**（`player.take_damage(2, DMG_TAKEN)`）——会被护体吸收（有护体时等于免费用）、吃伤害修正（**煞气≥6 时代价×2=4**）、命中会触发 player_hit（照常叠煞气）、受击演出（音效/震动/停顿）齐全；旧的直扣血函数 `_apply_hero_skill_self_damage` 已删除。致死由 take_damage 内部时序结算。
- 状态图标（32px）与玩家护体徽章隐藏逻辑此前已由另一轮改进覆盖，未重复改动。

**祝福平衡收口 + 随机效果播报（同日第二轮）**：

- **消除跨来源支配关系**：设计原则——同类效果跨来源必须有档位差，免费版永远是最小档。灵脉余泽**不再做任何牌组操作**（免费升1/删1会被补天盟的免费升2/删2严格支配），改纯资源（新增「行脚盘缠」金+丹药）；残仙遗蜕的付费档全部高于补天免费档一级（嗜血淬炼升 **3** 张 -8 血、蜕骨夺珍 **2** 张金卡 -14 血）；照命石审判豪赌档拉开（舍身得宝 **2** 件法宝 -16 血、富贵险中 250 灵石 -20 血）。
- **随机效果结果播报**：新信号 `Events.ui_notice_requested(text)` + `run.gd` 居中 toast（NoticeLayer，layer 21，逐条堆叠淡入淡出 ~3s）。祝福的随机突破/移除/复制/发牌/法宝/丹药、事件房（generic_event 的 upgrade_random/remove_random、helpful_boi 的复制）全部播报被随机到的名字，如「突破：『打击』『聚煞』」。以后任何随机效果都应发这个信号。

**图鉴 / 选人界面优化（同日第四批）**：

- **InkTheme.wire_button_sfx(button)**：给自定义贴图样式的按钮（不走 `apply_screen_button` 的）单独挂 hover/点击音，`apply_screen_button` 内部也改走它。
- **图鉴**（`codex.gd`）：条目切换时详情面板 0.18s 淡入 + 翻书音（`GameSfx.BOOK`，主题贴切）；返回按钮挂音；预览卡牌的 pop-in 由 CardMenuUI 组件自动带。
- **选人**（`character_selector.gd`）：入场淡入 0.4s（只动 modulate，不干扰异步背景加载）；切换角色时信息面板 0.24s 淡入过渡；新选中的角色卡 punch 弹跳（`_last_punched_index` 守卫防布局刷新重复弹）；角色/开始/返回按钮挂音；**开始修行按下时一记锣**（`GameSfx.GONG`）做仪式感。
- **地图视觉五连**（`map.gd`）：①走过的连线染金（"selected"态）、可选连线暖亮+呼吸脉冲（`_pulse_lines`）；②可选节点根节点 modulate 呼吸发光（与 AnimationPlayer 的 Visuals 子节点动画不冲突）；③开图演出——节点按层错落浮现（`_animate_map_entrance`，仅 create_map 时播，回图不重播）、连线淡入；④顶部「第X章 · 已登 Y/Z 层」进度牌（`progress_panel`，挂 tooltip 层，随地图显隐）；⑤滚轮平滑滚动（`_scroll_target_y` 目标值 + _process 插值，步长 ×2.4）。
- **测试地图已关**：`map.tscn` 的 `map_mode` 从 2（TEST_ELITE_LINEAR）改回 **1（ROGUELIKE）**，`free_navigation` 随之关闭，正式随机地图生效。要再进测试地图改回 0/2 即可。

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
- **新增 10 个重点事件**：事件场景位于 `scenes/event_rooms/`，插图位于 `art/event_illustrations/`；这些事件现已与旧事件一起纳入分章事件池。
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
- **手感优化已完成一轮（2026-07-06，见第 6 节「战斗手感优化专场」）**：tween/easing、hover/drag inertia、目标吸附反馈、命中停顿、屏幕震动、伤害数字等约 25 项已落地。新增 `game-demo/scenes/battle/floating_text.gd` / `hit_pause.gd` / `hit_effect.gd` 三个手感组件，新增 4 个 Events 信号（`card_discarded`/`deck_reshuffled`/`sha_qi_tier_changed`/`card_acquired_animation_requested`）。音效/BGM 已接入，下一步重点是实际试玩混音与节奏微调。
- ⚠️ 手感组件注意：`HitPause` 在无头模式必须保持跳过（smoke 计时器会被 time_scale 拖慢）；`battle_combatant_card` 有 0.12s 轮询，新加动画务必走 diff 检测，否则活不过一帧；胜负面板动画需 `TWEEN_PAUSE_PROCESS`（树已暂停）。

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

- `game-demo/scenes/event_rooms/event_room_pool.tres`（45 个事件，三章各 15 个）
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
- **事件池现状**：旧事件已恢复并完成三章分类；新增事件时应同步加入 `event_rooms` 总表和且仅一个章节数组，保持章节池互斥。
- **调试控制台快捷键**：使用 Ctrl + 反引号，不要再绑定 F8。F8 在 Godot 编辑器运行时会停止项目，看起来像“按控制台键直接退出”。
- **战斗 UI 手感已完成一轮（2026-07-06）**：手牌 hover/drag、瞄准吸附反馈、命中反馈、hit pause、伤害数字、回合/Boss/煞气演出、音效/BGM 等已落地（第 6 节专场小节）。动效节奏为静态验证 + smoke 通过，**整体叠加后的节奏与混音还需人工进战斗跑几场做主观校验**，参数入口见第 6 节「调参入口」。
- **单体攻击符箓/丹药目标选择仍偏简单**：无卡牌来源的攻击效果已能生效，但如果没有显式目标，当前主要走第一个存活敌人的兜底逻辑。若要做成品手感，建议后续给攻击丹药/符箓增加一次性目标选择状态。
- ~~**战斗数值待按 100 血重配平**~~（2026-07-06 已完成，见下）：
  - **基线**：三套共享 AI 脚本默认值上调——bat 系（银月狼/劫灰小鬼/雷羽鹰/血纹虎/劫雷鹏）攻 4→6（双击共12）格 4→9；crab 系（铜傀儡/幽暗鹰/玄铁傀/碧鳞蛟/寒潭蛇/天阙镇将/山魈石怪）攻 7→11 格 6→11 大格 15→26；toxic_ghost 系（黑莲圣母/蚀日妖皇/幽冢灯/碧玉蛛/摄魂影/骨龙/瘴毒蛾）攻 8→13 格 10→18。4 个固定套路场景：符纸兵 9/12、雾隐狼 10/7、牛魔 格18/重砸20/13、渊狱剑魂 15/格22/9/处决25。
  - **血量**：普通 ×~2.7-3.0（银月狼 20 … 铜傀儡 80）、精英 ×~2.7-3.0（牛魔 105 … 碧鳞蛟 155）、Boss ×~2.4-2.6（渊狱剑魂 235 / 黑莲圣母 245 / 天阙镇将 265 / 蚀日妖皇 290）；**骨龙 40→210**（原值严重偏低，同时其战斗 hp_mult 1.25→1.00 防双重加成）。
  - **精英每场伤害倍率**拉开档次：血纹虎群/劫雷鹏 1.35、玄铁傀/碧鳞蛟/摄魂影 1.30、牛魔 1.15。章节倍率（HP 1.0/1.3/1.65、伤害 1.0/1.15/1.3）保持不动。
  - **设计目标**：普通战 2-3 回合、耗 ~10-20 血；精英 4-6 回合、耗 ~25-40；Boss 6-10 回合。`game_data.xlsx` 已重导出同步。**未实战校验，需人工打一局按体感微调**——最快的调法是改三套共享脚本的 @export 默认值和精英战 .tres 倍率。
- **`character-selector` smoke 偶发 `Parameter "t" is null`**：该检查用 `--quit`（首帧即退），与入场 tween 拆场存在竞态，偶发红灯、重跑即过。与 run-flow 偶发同性质，上 CI 前一并处理。
- **`run-flow` 偶发 `Lambda capture freed`**：完整流程约 2/12 偶发，还有一处多回合补间回调来源未根除（疑似 `status_handler`/`relic_handler`/弃牌结算）。非功能 bug（逻辑仍通过，重跑即过），但将来上 CI 会随机红灯。修法：把 `tween.finished` 的 lambda 改为捕获 `get_instance_id()` / 加 `is_instance_valid` 守卫。
- **`validate_project.py` 仍有盲区**：查不出「文件在但未导入」（缺 `.import`）和字符串拼接路径。新增美术务必在编辑器导入。（注：默认值字段误报已修，现 0 error。）
- **存档跨资源移动会失效**：存档按路径内嵌资源引用，移动/重命名被引用资源后旧档加载失败（有自愈清档兜底，但丢进度）。彻底修复需改成"按 id 重建"（ROADMAP 阶段 0）。
- **魔修待办**：~~`demon_flame`/`demon_flame_heart` 重名~~、~~血祭白卡偏强~~、~~魔焰 rider 待细化~~、~~魂印引爆 payoff 偏少~~均已处理；当前 `demonic_cultivator_draftable_cards.tres` 含 75 个唯一魔修卡 ID，后续重点转为实战平衡与正式插画替换。
- **符箓丹药图标**：已接入 6 张专属图标到 `art/potions/icons/`（healing_pill/qi_pill/draw_talisman/flame_talisman/frost_talisman/blood_rite_talisman），替换原借用的通用图标。⚠️ 新增 PNG 务必在编辑器导入一次（`--headless --editor --quit`），否则潜在丹药 `.tres` 加载失败、`main/codex/run-flow/boss-battle` 全红。
- 调整卡牌比例时，要同步检查战斗手牌、奖励三选一、商店、图鉴/预览、升级、删除、融合界面（当前卡 224×322，详见第 6 节 1.4x 改动）。
- 主菜单标题已烤进背景图 `art/backgrounds/background1.png`（旧 `baijie_chengxian_title.png` 已删）；战斗/选人背景部分仍硬编码在项目根 `test1.png`/`test2.png`（见 `art/README.md`）。

## 9. 后续建议

1. 优先把魔修单职业 Demo 跑通：战斗、事件、商店、宝箱、篝火、Boss、失败/胜利、失败遗产都要完整体验一遍。
2. 下一轮重点建议人工试玩魔修完整流程，按实感微调战斗动效节奏、SFX/BGM 音量和地图/商店/奖励界面的视觉密度。
3. 为高频卡牌优先生成或绘制正式大插画，替换当前临时小图标；魔修卡面人物风格要统一。
4. 对卡牌标题字体、描述字体补充更有国风感的正式字体资源。
5. 对地图、商店、宝箱、祝福页面做一次统一视觉 QA，检查字体大小、按钮状态和不同分辨率下的遮挡。
6. 提交前重新运行 `validate_project.py`；较大系统改动后再跑 `run_godot_checks.py`，并人工进入战斗、商店、地图、奖励、主菜单确认视觉效果。

## 10. 魔修 Demo 内容深化（2026-07-11）

- 卡牌机制已扩展：临时、消耗、保留、固有、虚无、不可打出、状态/诅咒、弃牌触发、消耗触发、成长、固定卡池发现。
- 新机制已落到实牌：
  - `血偿`：弃牌时获得 4 护体。
  - `血膜`：消耗时获得 1 灵力。
  - `血祭斩`：每次打出后伤害 +2，本场最多成长 6。
  - 新金卡 `窥心魔典`：消耗；从 7 张固定禁术池随机展示 3 张，基础选 1，突破后选 2；加入手牌并参与本场抽弃循环。
- 新增 `心魔` 诅咒牌；黑莲圣母会把它塞入玩家弃牌堆，后续洗牌进入手牌形成牌库污染。
- 新增 `蚀痕` 状态牌（不可打出、虚无）；蚀日妖皇第二招“聚蚀”保留 15 护体并将其塞入弃牌堆，进入抽弃循环后若留在手中会于回合结束移除。复合动作位于 `enemies/shared/block_and_add_card_action.gd`，可供后续敌人复用。
- 三章遭遇已独立分池：
  - 第一章：普通 8 / 精英 3 / Boss 3。
  - 第二章：普通 8 / 精英 3 / Boss 3。
  - 第三章：普通 8 / 精英 3 / Boss 3。
  - 新增 14 个普通战混编：月狼群、灰烬狼、傀儡兵阵、灯蛾、蛇蛛、铜灯、石鹰、咒蚀前锋、狼蛛伏击、灰羽突袭、纸灯阵、铜傀毒蛾、蛇石同巢、鹰蛛猎群。
  - 新增 3 个战术精英：血月狼王令全队获得劲气；铜傀督军为全队提供护体；蚀魂祭司用蚀痕/毒念污染牌序并庇护同伴。三者复用现有美术，但拥有独立名称、属性和固定行动序列。
  - 各层级三章不重复，章节缩放仍保留。
- 修复 `crab_attack_action.gd` / `bat_attack_action.gd` 未读取敌方 `DMG_DEALT` 的问题：章节/精英伤害倍率和劲气现在同时影响实际伤害与意图数字。
- 9 个 Boss 均有数据驱动二阶段：血量阈值触发一次护体、永久增伤并切换后半程固定招式序列。
- 第一、二章 Boss 击败后不再直接跳章：现在进入 Boss 奖励页，包含金币、卡牌三选一、首领法宝三选一，丹药槽未满时追加丹药；退出奖励后再进入下一章，并按当前心魔规则恢复生命。
- 战斗卡牌奖励同一组三选一按卡牌 ID 去重，仍保留奖励池重复资源提供的首抽权重。
- 卡牌稀有度随章节提升：第一章 85/10/5/0，第二章 72/18/9/1，第三章 60/23/14/3（白/蓝/金/暗金，合计 100）。
- 新增自动化：
  - `card-mechanics`：成长上限、触发配置、发现池、发现升级、奖励池接入。
  - `content-progression`：三章遭遇数量、跨章不重复、随机抽取不越池。
  - `boss-battle`：新增二阶段、黑莲心魔污染、蚀日聚蚀/虚无状态污染断言。
  - `elite-tactics`：实跑三场新精英首回合，验证全队劲气、全队护体和蚀痕污染。
- `game_data.xlsx` 已重新导出同步。
- 2026-07-11 验证：`validate_project.py` 为 0 error / 0 warning；13 项 `run_godot_checks.py` 全绿。

## 11. 心魔难度系统（2026-07-11）

- 新增 0–15 级累计难度：凡境为标准规则，心魔 1–15 逐级叠加敌人生命、商店涨价、金币衰减、篝火削弱、敌人伤害、精英/Boss 专属强化、卡牌奖励二选一、初始灵石降低、跨章恢复削弱、初始伤血等规则。
- 规则集中在 `custom_resources/run_stats.gd`；地图、商店、篝火和章节推进调用统一计算接口，继续游戏会刷新规则但不会重置当前金币。
- 独立进度档为 `user://difficulty_profile.tres`，不随局内 `savegame.tres` 在胜利/失败时删除；通关当前等级解锁并默认选择下一等级，最高封顶 15。
- 选人页开始按钮上方新增最小难度下拉入口，只显示已解锁等级；每项 tooltip 显示该级新增规则。通关页显示本次克服等级与新解锁等级。
- 新增 `difficulty` smoke：覆盖凡境、心魔 8、心魔 15、普通/精英/Boss 地图缩放、金币/商店/恢复、加载不重置经济、进度保存/重载/封顶。

## 12. 魔修牌池达到 75 张（2026-07-11）

- 魔修唯一卡牌数从 68 补到 75，新增 7 张构筑桥梁牌：命血逆流、血债清算、血铸魔甲、煞刃、七焰回环、魂灯续燃、万印归墟。
- 自损路线新增回能过牌、保留防御和按本回合累计自损成长的终结技；煞气新增主动伤害消耗口；魔焰新增低费过牌衔接；魂印新增回能转化和多目标全量引爆。
- 新增通用效果 `configured_self_damage_scaling_damage_effect.gd` 与 `configured_consume_status_to_damage_effect.gd`，后续卡牌可以数据化复用。
- `card-mechanics` 验证 75 个唯一 ID、奖励池接入和全部新牌可突破；新增 `demonic-card-suite` 实战验证血债、自损计数、耗煞伤害和双敌魂印引爆。

## 13. 三章 Boss 达到 3 选 1（2026-07-11）

- Boss 总数从 5 扩充到 9，三章现在均为 3 名独立 Boss 随机轮换；`content-progression` 验证每章数量和跨章隔离。
- 第一章新增血月妖王（强化后连击）与铜甲尸王（结甲、蓄力重击）；第二章新增万蛊母皇（将 2 张浊气直接混入抽牌堆）；第三章新增幽冥判官（用持久状态牌“判牒”污染抽弃循环）。
- 新增通用敌方动作 `add_card_to_draw_action.gd` 和状态牌 `underworld_writ.tres`；Boss 音乐、开场名牌和大尺寸立绘识别列表均已同步。
- 4 名新 Boss 暂时复用既有敌人美术，但拥有独立名称、生命、AI、奖励、阶段阈值、阶段增伤和后半程行动序列；后续可同路径替换正式 Boss 美术。
- `boss-battle` 现逐场实跑 9 名 Boss，验证首回合专属机制、二阶段与胜利结算；单项超时上限为 90 秒，当前约 64 秒。

## 14. 魔修专属法宝套件（2026-07-11）

- 奖励法宝池从 39 件扩充到 45 件，魔修专属从 3 件扩充到 9 件；职业过滤保证其它职业不会抽到。
- 自损路线新增血炼炉（每次自损得 3 护体）与赤髓葫（每回合首次自损抽 1）；魂印路线新增摄魂铃（首次消费魂印回 1 灵力）与万鬼幡（首次消费魂印按层对全体补伤）；煞气/魔焰新增镇煞瓮（开战 2 煞气）与焰轮心核（首张魔焰抽 1）。
- 新增 `Events.soul_mark_spent` 与通用 `soul_mark_spent_relic.gd`；`card_play_draw_relic.gd` 支持按卡牌 ID 前缀匹配，后续可复用到其它成套卡牌。
- 新增 `demonic-relic` 实战测试，覆盖开战、重复自损、每回合一次、魂印消费、全体伤害、魔焰过牌、奖励池数量和职业过滤。

## 15. 法宝稀有度与奖励经济（2026-07-11）

- `Relic` 新增普通、少见、稀有、首领四档稀有度；45 件奖励池法宝已完成首轮分级，首领法宝不会进入普通奖励或商店。
- `RelicRewardPool` 改为按“章节 + 来源”加权且多选不重复。普通、精英、宝箱、首领、商店各自有三章权重；章节越后，少见/稀有占比越高。
- 精英奖励使用精英权重，宝箱使用宝箱权重，Boss 三选一固定为首领档；祈福保持普通来源，商店只展示非首领档。
- 商店法宝基础价按档位分层：普通 150–190、少见 210–260、稀有 300–380、首领 450–520；随后继续叠加折券和心魔商店倍率。
- `RunStats.current_chapter` 统一保存当前章节，使商店和奖励曲线与继续游戏保持一致。
- 新增 `relic-economy` smoke，覆盖四档池完整性、来源隔离、无重复多选、章节保存和价格阶梯；全量检查现为 14 项。

## 16. 三章事件生态（2026-07-11）

- 事件总量从临时启用的 10 个恢复并扩充到 45 个，按第一、二、三章各 15 个互不重叠的池配置。
- `EventRoomPool` 改为按章节使用洗牌袋；地图生成同章事件时，15 个事件耗尽前不会重复，避免多条路线出现相同机缘。
- 第一章偏资源恢复与低风险交易，第二章偏代价选择与牌组整理，第三章集中魔修、心魔、魂魄与天劫主题。
- 第三章新增血经石壁、幽都魂拍、天焰魔眼：可用生命或灵石换金卡、删牌、双突破、最大生命，也可能把心魔加入牌组。
- `GenericEvent` 新增随机职业牌、随机金卡和心魔诅咒效果，可供后续事件数据化复用。
- 新增 `event-progression` smoke，验证 45 个场景全部可实例化、三章各 15 个且互斥、洗牌袋无重复，以及新卡牌/诅咒奖励实际进入牌组；全量检查现为 15 项。

## 17. 魔修合炼丹方扩展（2026-07-11）

- 固定融合丹方从实际 4 个扩充到 20 个：保留 4 张手工融合产物，新增 16 个覆盖自损血契、煞气、魔焰、魂印和跨路线桥接的魔修丹方。
- 新丹方包括魔躯反刃、血甲魔刃、逆血魔炉、血债轮回、绝命血斩、煞刃凝罡、七煞焰轮、魔焰心莲、阴阳魔焰、黑白劫火、裂魂开冥、葬魂续灯、摄魂碎印、万魂归墟、血焰回天、煞魂灯刃。
- `CardFusionRecipe` 支持无独立结果资源的组合丹方：自动复制并合并双方主效果、弃牌触发、消耗触发和机制标签，按配方指定名称/费用生成确定性 `fusion_*` ID，不会共享或改写原牌效果资源。
- 合炼目标、类型、职业、元素和稀有度会从原料推导；只有两张原料都为消耗牌时产物才会消耗，降低组合后过度惩罚。
- 牌堆合炼仍是事务式操作：两张原料均成功移除后才加入产物，第二张移除失败会回滚第一张。
- 新增 `fusion-suite` smoke，逐一验证 20 个配方唯一、16 个魔修原料可获得、双向匹配、效果合并、资源隔离、旧产物兼容和实际牌堆替换；全量检查现为 16 项。

## 18. 遭遇洗牌袋与重复保护（2026-07-11）

- `BattleStatsPool` 的普通、精英、Boss 三档抽取从独立加权随机改为按权重生成顺序的洗牌袋。
- 权重仍决定每轮中较高权重遭遇更早出现的概率，但同章普通 8 场、精英 3 场、Boss 3 场各自耗尽前不会重复；耗尽后才重新装袋。
- 抽取统一改用项目 `RNG`，地图生成结果现在受局内种子/状态控制，可与存档随机状态保持一致。
- `content-progression` 新增首轮唯一性断言，覆盖三章 × 三档共 9 个遭遇袋；全量 16 项检查保持通过。

## 19. 符箓丹药奖励经济（2026-07-11）

- 现有符箓丹药共 26 种，实际分布为普通 5、少见 13、稀有 8；不再继续盲目扩数量，优先启用已有稀有度价值。
- 新增轻量 `PotionRewardPool`，统一维护奖励和商店使用的 26 条资源路径，避免 `Run` 与 `Shop` 两份清单长期分叉。
- 普通战、精英、Boss、商店分别使用三章权重：普通战偏基础应急品，精英提高少见/稀有概率，第三章 Boss 只掉少见或稀有，商店库存随章节改善。
- 抽取采用“先按稀有度、再在该档均匀选择”，不会因为少见档资源数量较多而额外挤压普通/稀有档；商店两件消耗品按无放回抽取，不会重复。
- 职业过滤保持生效，魔修不会抽到体修、剑修或驭兽专属丹药；血祭符、魔血丹、缚魂符、裂魂符仍只进入魔修池。
- 新增 `potion-economy` smoke，覆盖 26 资源完整性、5/13/8 分布、魔修过滤、第三章 Boss 排除普通档、商店去重和全部权重合计 100；全量检查现为 17 项。

## 20. 单局统计与轮回战绩（2026-07-12）

- `RunStats` 新增本局战斗胜场、精英/Boss、击杀、出牌、事件、商店消费和丹药使用统计；字段随现有局内存档保存，继续游戏不会丢失。
- `Run` 监听真实结算信号：打出卡牌、敌人死亡、战斗胜利、事件选择、商店购卡/法宝/丹药/删牌和丹药使用，不按 UI 点击或预览虚计。
- 新增 `RunHistory` 持久档 `user://run_history.tres`，累计总局数、胜负、最高章节/心魔、战斗/精英/Boss、击杀、出牌、事件、消费和丹药使用；胜利/失败都只结算一次。
- 胜利页与失败面板新增独立小字号“本轮记要”，展示章节、战斗/精英/Boss、击杀、出牌、事件、消费、丹药、最终牌组和法宝数；原标题与整体美术方向不变。
- 战斗死亡处理增加一次性守卫，连续死亡信号不会重复保存失败遗产或弹出多个结算。
- 新增 `run-history` smoke，验证失败后再胜利的保存/重载、最高纪录和所有累计字段；全量检查现为 18 项。

## 21. 首领法宝三选一（2026-07-12）

- Boss 法宝奖励从混合档位二选一改为纯首领档三选一，使每章 Boss 后形成明确的构筑转折。
- 摄魂铃由少见提升为首领档；魔修当前可用首领法宝达到 6 件：遮目符、雷火坛、灵泉葫、星斗盘、万鬼幡、摄魂铃。
- 普通、精英、宝箱、祈福和商店继续保持首领档权重为 0，首领法宝只从 Boss 奖励与失败遗产进入。
- `relic-economy` 现模拟先继承一件首领法宝，再连续完成三章；每章仍能提供 3 件唯一首领法宝，并在选取后正确排除已拥有项。

## 22. 魔修篝火血炼（2026-07-12）

- 篝火在“调息”“卡牌突破”之外新增“血炼术法”：选择并永久移除一张牌，支付 5 点最大生命。
- 血炼复用现有删牌选择界面；只有确认移除成功后才扣最大生命，取消返回篝火不会付出代价。
- 当牌组只剩一张牌，或最大生命不足以继续支付时，血炼按钮禁用，保证不会清空牌组或把最大生命降到非法值。
- 新增 `Events.campfire_card_removed`，后续法宝、成就或统计可以监听血炼行为；原余烬印仍只响应其说明中的调息/突破。
- 新增 `campfire-choices` smoke，实测打开选择、删牌、扣 5 最大生命、信号和两项边界；全量检查现为 19 项。

## 23. 卡牌奖励稀有保底（2026-07-12）

- 战斗卡牌奖励新增可存档的 `card_reward_miss_streak`：一组奖励若没有金卡/暗金卡则 +1，出现任一高稀有牌后归零。
- 每次连续未命中会把 2% 白卡权重转移给金卡，最多转移 12%；章节自身的白/蓝/金/暗金基础曲线仍然生效。
- 连续 6 组奖励未见金卡/暗金卡时，下一组第一张硬保证为金卡；生成后因已见高稀有立即重置，避免无限累积。
- 修复“跳过卡牌奖励后奖励按钮仍存在，可反复打开同一组三张牌”的问题；现在跳过会清空缓存并消费该奖励。
- `card-mechanics` 已覆盖权重转移、硬保底、见金重置、低稀有递增、奖励 ID 去重和跳过消费；全量检查保持 19 项通过。

## 24. 魔焰焚心分章成长（2026-07-12）

- 魔修英雄技能不再三章完全静态：第一章受到 2 点伤害并生成 1 张随机临时魔修非攻击牌；第二章生成牌会自动突破；第三章自伤降为 1，生成牌自动突破且本回合费用降低 1。
- 技能仍保持每回合一次，生成牌仍是临时牌，打出或回合结束都会移除，不会进入抽牌堆或弃牌堆循环。
- `CharacterStats.hero_skill_stage` 保存当前阶段；新开局、读档和跨章都会根据当前章节同步，旧存档读取时自动获得正确阶段。
- 技能按钮 tooltip 会显示当前阶数、实际自伤和本阶附加效果，避免第二、三章仍展示第一章说明。
- `card-mechanics` 新增三个阶段的随机池过滤、临时标记、突破、临时减费和最终阶段自伤验证；全量检查仍为 19 项。

## 25. 卡牌奖励流派协同（2026-07-12）

- 卡牌奖励仍先按章节曲线和稀有保底决定稀有度，再在同稀有度候选中按当前牌组做轻度流派加权，不会改变白/蓝/金/暗金出现率。
- 当前识别魔修三条主线：献祭/失去生命/血契、煞气/魔焰/焰轮、魂印；兼容机制标签、卡牌说明和旧资源 ID，未补标签的老牌也能参与。
- 牌组每有一张同流派牌，候选权重增加 18%，最多增加 90%（即 `1.9x`）；不匹配牌始终保留 `1.0x` 权重，因此可以继续拿通用牌或中途转型。
- 稀有硬保底、三选一 ID 去重和跳过奖励消费逻辑保持不变；`card-mechanics` 新增基础权重、封顶和未构筑流派不受罚的断言。

## 26. 地图路线节奏保底（2026-07-12）

- 20 层地图新增路径级约束：任意可达路线最多连续两场普通战/精英战，第三个连续战斗节点会重新抽取为非战斗房，避免一条支路连续耗血却没有恢复窗口。
- 每章地图至少生成 2 个商店和 2 个篝火；Boss 前一层仍保证所有可达节点都是篝火，中段固定宝箱和至少 1 个精英保持不变。
- 补给保底只会替换普通战或事件，不会覆盖精英、宝箱、Boss；新增补给会避开同类父/子节点，减少连续商店或连续篝火的无效路线。
- 修复房间类型被保底逻辑替换后仍残留旧 `battle_stats` / `event_scene` 引用的问题，房间数据现在与最终类型一致。
- 新增独立 `map-generation` smoke：三章各 12 个固定随机种子，共验证 36 张地图的层数、节点数量保底、Boss 前篝火、从赐福到 Boss 可达和连续战斗上限；全量检查增至 20 项。
- 修复 `character-selector` 在 headless 首帧退出时与异步背景纹理加载发生的竞态；headless 现在跳过动画帧预载，实际游戏显示不变，连续 8 次单场景启停和全量回归均稳定通过。

## 27. 商店半价与价格重算（2026-07-12）

- 每次进入商店，6 张卡牌中固定随机 1 张成为半价特惠；按钮显示“半价购买”并附带说明，实际价格在所有心魔/法宝修正完成后减半。
- 卡牌、法宝、丹药/符箓现在分别保存原始基价；商店价格刷新统一从基价重新计算，不再拿已经修改过的显示价继续叠乘。
- 修复在当前商店购买折价券后，心魔商店涨价倍率会被重复套用的问题；连续刷新价格现在保持稳定，不会形成意外复利。
- 修复折价券在当前商店购买后只刷新卡牌和法宝、漏掉丹药/符箓的问题；消耗品现在与其他库存同步享受折扣。
- 半价与折价券可以正常叠加为基础最终价的 25%，符合构筑型商店的稀有机会价值；原有每次净化后永久涨价 25 灵石规则保持不变。
- `run-flow` smoke 在真实商店中验证恰好一个半价商品、全部商品保存正基价、25% 心魔涨价 + 50% 折价券叠加，以及连续两次刷新价格不变。

## 28. 后期奖励牌自带突破（2026-07-12）

- 战斗卡牌奖励新增分章突破概率：第一章 0%、第二章 15%、第三章 30%；后期获得的新牌有机会直接进入构筑，不必每次再占用篝火突破。
- 每张候选牌独立判定，只有 `can_upgrade()` 的牌才参与；不可突破牌、已经突破牌和没有升级配置的牌不会进入错误状态。
- 判定发生在稀有度、稀有保底和流派协同选牌完成之后，因此不改变奖励稀有度分布、三选一去重或软流派权重。
- `card-mechanics` 用强制随机值精确验证第一章永不突破、第二章 `15%` 和第三章 `30%` 的命中/边界未命中行为。

## 29. 普通战消耗品掉落保底（2026-07-12）

- 普通战符箓/丹药掉落从固定 40% 改为动态保底：初始 40%，每次符合掉落条件但未掉落增加 15%，即 40% → 55% → 70%。
- 连续 3 次未掉落后，下一次普通战在槽位可用时必定掉落；这是显式硬保底，不会因随机值接近 1 而再次落空。
- 掉落成功后计数归零；消耗品槽位已满时不会进行判定，也不会消耗或推进保底，玩家不会因没空位白白损失累计机会。
- `potion_drop_miss_streak` 存入 `RunStats`，继续游戏后保底进度保留；精英/Boss 原有必掉规则不变。
- `potion-economy` smoke 精确覆盖 40% 边界未命中、55% 命中、成功重置、三次连空、100% 硬保底和再次重置。

## 30. 十张手牌上限（2026-07-12）

- 战斗手牌新增标准上限 10 张，过牌、保留和发现构筑不再无限堆叠手牌；`Hand.MAX_HAND_SIZE` 是统一规则源。
- 手牌已满时普通抽牌不会从抽牌堆移除，抽牌顺序保持不变；`CardPile.add_card_to_top()` 统一处理极端竞态下的抽牌回滚、绑定和计数信号。
- 魔焰焚心在满手时不可施放，按钮同步禁用，避免玩家先承受自伤却无法获得临时牌。
- 发现牌超过手牌容量时不会消失，而是进入弃牌堆并继续参与本场抽弃牌循环；界面会提示有多少张牌进入弃牌堆。
- 每回合首次尝试在满手状态抽牌时提示“手牌已满（最多 10 张）”，同回合后续失败不会重复刷屏。
- `card-mechanics` smoke 验证十张封顶、满手抽牌不丢牌和发现溢出进入弃牌堆。

## 31. 消耗品主动弃置（2026-07-12）

- 符箓/丹药槽新增右键弃置，玩家可以主动腾出 3 个槽位，不必因携带低价值物品而被迫放弃后续精英、Boss 或保底掉落。
- 悬停说明明确显示“左键使用 · 右键丢弃”；弃置后清空原槽位、发出 `potion_discarded` 信号并显示物品名称提示。
- 单体攻击符箓正在选择目标时，右键只取消瞄准且保留物品；恢复普通状态后再次右键才会弃置，避免取消操作误删资源。
- `potion-economy` smoke 实例化真实 `PotionHandler`，验证加入空槽、瞄准取消不丢失以及第二次右键清空槽位。

## 32. 地图消耗品即时存档（2026-07-12）

- 地图可见时使用或弃置符箓/丹药会立即刷新局内存档，直接退出再继续不会恢复旧物品；地图外回血后的生命值也随同保存。
- 自动保存严格限定在地图状态：战斗、商店、事件等房间内的消耗品变化仍在房间退出时统一保存，不会生成无法恢复的半场战斗存档。
- `run-flow` smoke 会在新局地图上丢弃起始消耗品并立刻重新加载 `SaveGame`，验证存档槽位数量同步减少。
- `run-flow` 的起手抽牌检查从固定等待 1.6 秒改为最多 3.5 秒的条件等待；状态一旦就绪立即继续，消除资源加载速度造成的历史偶发失败。

## 33. 随机敌人行动防三连（2026-07-12）

- 权重随机 AI 的每个行动新增 `max_consecutive_uses`，默认同一招最多连续使用 2 次；蝙蝠、蟹妖、毒鬼等不再可能无限连出同一种攻击或防御。
- 达到上限后只临时排除该行动，并在剩余正权重行动中重新归一化抽取；如果敌人确实只有一个可用行动，仍允许继续使用，不会产生空意图或卡住敌方回合。
- 条件技插入会重置随机行动连用记录；Boss 进入二阶段固定序列时也会重置。现有 Boss/精英固定行动套路完全不经过该限制。
- `elite-tactics` smoke 新增 3 个等权行动连续抽取 200 次的测试，验证始终能返回行动且不会出现三连；原三组真实战术精英战继续通过。

## 34. 抽牌堆检索与弃牌回收（2026-07-12）

- 新增数据驱动 `ConfiguredPileTutorEffect`，支持从抽牌堆或弃牌堆选择任意牌/攻击/技能/功法，并按配置数量加入手牌；效果数值可正常参与突破和 Excel 导出。
- 抽牌堆检索按牌堆顶部顺序取符合条件的牌；弃牌回收从最近弃置的牌开始。两者都遵守 10 张手牌上限，不会让非匹配牌改变相对顺序。
- 「影遁」重做为 1 费消耗：从抽牌堆检索最多 2 张技能牌，突破后 0 费；由原来的无差别抽 2 变为可围绕关键技能构筑的定向过牌。
- 「魂灯续燃」重做为 1 费消耗：消耗目标 1 层魂印，获得 1 灵气，从弃牌堆回收最近的 1 张技能牌，突破后 0 费；因自身消耗，不会形成自我回收无限循环。
- `demonic-card-suite` 在真实战斗中验证影遁只取两张技能并保留攻击牌、魂灯续燃只取最近技能并保留旧牌和非匹配牌。
- `card_table.py` 已登记“牌堆检索”效果，`game_data.xlsx` 已重导出；随后执行 Excel→Godot 回写为 0 文件变化，双向管线幂等。

## 35. 战斗内消耗牌堆（2026-07-12）

- `CharacterStats` 新增每场战斗独立的 `exhaust_pile`；开战时清空重建，并与角色所有权、临时费用重置和旧卡迁移流程统一绑定。
- 打出的消耗牌会在触发“消耗触发”后进入消耗牌堆；回合结束的虚无牌和其他由效果消耗的手牌也走同一路径，并发出 `Events.card_exhausted`。
- 功法仍在打出后留在场上逻辑中，不进入弃牌或消耗牌堆；临时牌仍直接移除，不进入任何循环或消耗区；普通攻击/技能照常进入弃牌堆。
- 修复 `ConfiguredExhaustRandomEffect` 名为“消耗随机牌”却实际调用普通弃牌的问题；现在真正触发消耗生命周期并进入消耗牌堆，说明同步改为“消耗”。
- `card-mechanics` smoke 验证消耗牌、功法、临时牌和普通技能四类去向互斥且正确。

## 36. 消耗区回收与血肉重生（2026-07-13）

- `ConfiguredPileTutorEffect.SourcePile` 扩展为抽牌堆/弃牌堆/消耗牌堆三种来源；消耗区按最近进入顺序取回，继续支持任意/攻击/技能/功法过滤与数量配置。
- 通用检索接口新增 `exclude_card`，当前正在结算的消耗牌即使已由 `card_played` 信号放入消耗区，也不会把自己取回形成无限循环。
- 「血肉重生」从普通 1 费回 8 的蓝卡提升为稀有消耗牌：回复 8 点生命，并从消耗牌堆取回最近的 1 张其他牌；突破后费用降为 0。
- `demonic-card-suite` 在真实战斗中模拟“自身先进入消耗区再执行效果”的实际时序，验证取回最近旧牌、自身排除、较早牌保留和治疗数值。
- `game_data.xlsx` 已重导出，Excel→Godot 回写为 0 文件变化。

## 37. 消耗流功法·血膜（2026-07-13）

- 魔修功法引擎新增 `EXHAUST_GUARD`，监听统一 `Events.card_exhausted`；打出消耗牌、虚无牌回合结束、随机消耗等所有合法来源都能触发一次。
- 「血膜」从一次性消耗技能重做为 1 费蓝色功法：失去 2 点生命、获得 6 点护体，此后本场每消耗一张牌再获得 2 点护体；突破后 0 费。
- 原「血膜」自带的“消耗触发：获得 1 灵气”迁移到一次性技能「归煞」，因此独立消耗触发机制仍在魔修卡池内可构筑，并与血膜的全局消耗护体形成联动。
- 功法尚未生效或角色不是魔修时不会响应；触发只增加护体，不改变卡牌进入消耗区的原始生命周期。
- `demonic-card-suite` 在真实战斗中先启用血膜，再消耗一张测试牌，验证护体精确 +2 且卡牌仍进入消耗牌堆。
- `game_data.xlsx` 已同步，Excel→Godot 回写为 0 文件变化。至此消耗路线具备消耗区记录、跨区回收和持续防御收益。

## 38. 消耗牌堆查看入口（2026-07-13）

- 战斗左下角在抽牌堆、弃牌堆之后新增“消耗”入口，实时显示本场消耗牌数量；复用现有 `CardPileOpener`，以紫色调区分，不引入新的 UI 体系。
- 点击后复用 `CardPileView` 展示完整消耗牌堆，按真实进入顺序排列，不随机打乱；玩家可以判断「血肉重生」下一张会取回什么。
- `BattleUI.initialize_card_pile_ui()` 统一绑定 `CharacterStats.exhaust_pile` 的按钮和查看器，计数随 `card_pile_size_changed` 即时更新。
- `demonic-card-suite` 在真实战斗消耗测试牌后打开查看器，验证按钮绑定、页面显示和卡牌数量完全一致。

## 39. 跳过卡牌奖励补偿（2026-07-13）

- 战斗卡牌奖励选择“跳过”时获得 10 灵石，为瘦牌组和主动放弃低协同牌提供小额正反馈；金额明显低于正常战斗金币主奖励，不替代拿牌决策。
- 跳过按钮直接显示“跳过 · +10 灵石”，结算后同时显示居中提示；玩家无需猜测隐藏收益。
- `_on_card_reward_taken` 只有在缓存奖励仍存在时才结算，跳过后立即清空并消费奖励按钮；重复信号或重复调用不会再次增加灵石。
- `card-mechanics` 验证首次跳过 +10、奖励缓存清空和第二次调用不加钱；`run-flow` 验证真实奖励页面文案。

## 40. 无相开局路线（2026-07-13）

- 灵根三选一新增第四项“无相之路”：主动放弃灵根、元素数值成长、圆满效果和灵根职业牌，换取开局最大生命 +8、80 灵石，并随机突破 1 张可突破的初始牌。
- `RunStartup.spirit_root_declined` 区分主动放弃与旧存档/调试场景的默认 `NONE`；角色选择页每次新开局都会重置该字段，避免单例资源残留上一次选择。
- `RunStats.apply_rootless_start()` 是补偿的唯一结算入口，并以 `CharacterStats.rootless_path` 防止重复发放；无相身份随角色存档保存，继续游戏不会丢失。
- 顶栏灵根徽章与悬停说明会显示“无相之路”及其开局补偿，不再误显示为“灵根未定”。
- `content-progression` smoke 覆盖无元素、最大生命、灵石、牌组张数、随机突破和重复发放保护；全量检查仍为 20 项。

## 41. 灵根卡池供给提示（2026-07-13）

- 每个灵根选项现在直接显示当前职业可选卡池中对应元素牌的准确数量，玩家可以同时权衡圆满效果与实际成型难度。
- 供给量由 `CharacterStats.count_draftable_cards_of_element()` 从职业 `draftable_cards` 实时统计，不维护第二份展示常数；换职业或调整卡池后自动同步。
- 中立牌和 `NONE` 不计入灵根供给，避免把无法推动灵根阶段的牌误算为构筑资源。
- `content-progression` smoke 逐元素与原始卡池交叉计数，验证展示数据不会随资源调整漂移。

## 42. 非战斗探索音乐（2026-07-13）

- 地图、商店、事件、篝火、宝箱和赐福房统一接入已有 CC0 曲目 `vampires_piano_tad_cc0.mp3`，不再让普通/精英/Boss 战斗曲延续到整段探索流程。
- 探索曲运行时显式循环并以 `-7 dB` 播放；进入战斗仍由 `Battle` 按普通/精英或 Boss 切换原有曲目，主菜单也保持自己的主题。
- `MusicPlayer.play()` 在单曲模式下检测到同一音频已播放时只更新音量、不停止重播，因此连续经过非战斗房间时音乐保持完整连续。
- 新开局、地图返回和读档恢复到非战斗房间都会进入探索音乐路径；不改动现有 UI 或房间结算逻辑。

## 43. 分层战斗卡牌奖励（2026-07-13）

- 普通战继续使用章节稀有度曲线；精英战在灵石、法宝、熔炼和消耗品之外新增一次标准选牌，并保证候选中至少出现 1 张蓝卡。
- Boss 战候选保证至少出现 1 张金卡，使每章终战在 Boss 法宝之外也能提供明确的卡组强度转折。
- 分层保底只固定第一张候选的最低品质，其余候选仍走章节权重、流派协同、稀有保底和后期自带突破；卡牌 ID 去重与跳过奖励保持不变。
- 奖励入口说明直接标注“至少一张蓝卡/金卡”，避免高风险战斗的隐藏规则；`card-mechanics` smoke 覆盖两档品质下限与说明同步。

## 44. 差异化诅咒池（2026-07-13）

- 事件诅咒从固定“心魔”扩展为三种等概率结果：心魔持续占据抽牌位；血债不可打出且每次弃置失去 2 点生命；业火可花 1 灵力、失去 3 点生命主动打出并消耗。
- 血债复用统一弃牌触发生命周期，因此回合末弃置与其他弃牌效果都会结算；业火复用可打出/消耗规则，焚除后进入消耗区且本场不再循环。
- `GenericEvent._add_random_curses()` 支持一次加入多张且首轮不重复，现有 `gain_curse:1` 事件自动从池中抽取，无需逐场景维护资源路径。
- 三种诅咒都是永久牌组污染，可在商店净化、篝火血炼或事件移牌中移除；`event-progression` smoke 覆盖资源标记、三种唯一结果和两张新诅咒的数值生命周期。
- `game_data.xlsx` 已重新导出并包含两张新诅咒；随后执行 Excel→Godot 回写为 0 文件变化，数值管线保持幂等。

## 45. 满药囊奖励替换流程（2026-07-13）

- 普通、精英和 Boss 战的符箓/丹药奖励在药囊已满时仍会生成，不再直接丢失高品质掉落或消耗保底机会。
- 满槽奖励会提示“右键丢弃已有物品后领取”；误点只弹出说明，不移除奖励。玩家腾出槽位后说明自动恢复，领取成功才消费奖励卡。
- 精英与 Boss 继续必掉消耗品；普通战继续使用 40% 起步、连续未掉递增和三次未掉硬保底，只是槽位状态不再阻断掉落判定。
- `potion-economy` smoke 覆盖满三槽、领取失败不吞奖励、右键弃置刷新、腾位后成功领取的完整替换流程。

## 46. 消耗流法宝·焚契灰炉（2026-07-13）

- 魔修稀有法宝池新增「焚契灰炉」：每回合第一次有卡牌进入消耗区时抽 1 张牌，为血膜、血肉重生、归煞和虚无牌构成的消耗路线补齐持续过牌支点。
- 法宝监听统一 `Events.card_exhausted`，因此打出的消耗牌、回合末虚无牌、随机消耗与其他合法消耗效果使用同一套规则；临时牌直接移除，不会错误触发。
- 每个玩家回合只触发一次，`Events.player_turn_started` 会重置次数；触发只抽牌，不会改变原卡进入消耗牌堆的生命周期。
- 「焚契灰炉」仅进入魔修奖励池，其他职业不会抽到；法宝总池由 45 件扩为 46 件，Boss 法宝数量和独立奖励档位保持不变。
- `demonic-relic` smoke 在真实战斗中验证首次消耗抽牌、同回合防重复、下回合重置与消耗区保留；`relic-economy` 同步验证 46 件法宝池和各稀有度供给。

## 47. 战斗计数与连锁终结牌（2026-07-13）

- `ClassMechanicHandler` 新增通用战斗计数层：可查询本回合总出牌、攻击/技能/功法、弃牌、消耗，以及本场累计消耗、当前弃牌堆和消耗牌堆数量；新战斗天然重建，回合开始只清空回合维度。
- 新增 `ConfiguredCountScalingEffect`，可按任一计数源动态计算伤害或护体，支持基础值、每层增量、最低预览层数、目标改写、灵根修正、突破成长与实时 `{count}/{total}` 描述占位符。
- 「百鬼留痕」从固定 4 点全体伤害改为每有 1 张本回合已打出的牌，对全体造成 2 点伤害，并仍施加魂印；自身计入连锁，鼓励先铺低费牌再收尾，突破后每张牌提升为 3 点。
- 「万祭归一」从半血爆伤改为消耗流终结牌：基础 10 点伤害，本场每消耗 1 张牌额外 +4，自身打出时也计入；仍失去 6 点生命并消耗，突破改为 2→1 费以避免数值乘区同时膨胀。
- `demonic-card-suite` 在真实战斗中验证三牌连锁伤害、卡牌类型拆分、弃牌计数、消耗累计、自身计入、牌堆实时数量、回合重置边界与两张牌原有生命周期。
- `game_data.xlsx` 已重新导出，`card_table.py` 能识别“计数增幅”效果；Excel→Godot 回写为 0 文件变化。

## 48. 三章五行灵根事件分支（2026-07-13）

- `GenericEvent` 新增数据驱动的灵根选项覆盖：事件可指定现有三个按钮中的一个，并按 `Card.Element` 为金木水火土分别配置文案、效果和数值；不增加控件，也不改变通用事件布局。
- 第一章「灵泉」、第二章「雷击木」、第三章「坠星石柱」各加入一组五行分支，使开局灵根每章至少有一次地图事件层面的专属反馈，而不再只影响战斗和卡牌奖励。
- 金灵偏向额外灵石，木灵兼顾治疗与少量生命上限，水灵提供高额恢复，火灵以生命换随机突破，土灵以较低净生命代价换更高上限；奖励随章节递增。
- 有灵根时专属分支替换指定的原选项；无相路线、未选灵根和旧调试场景继续使用事件原始文案与效果，不会误获得五行收益。
- `event-progression` smoke 验证三章事件均提供完整五行数据，并逐项实际结算灵泉的金币、治疗、生命上限、受伤和随机突破结果，同时验证无相默认回退。

## 49. 十二张通用构筑牌基线（2026-07-13）

- `common_cards/` 新增八张可主动构筑的跨职业牌：周天吐纳、流云护身、乘势追击、烬归灵台、回光返照、弃念成罡、灰烬护心、灵石飞针；连同基础打击/防御、墨流斩和劲气共鸣，通用构筑牌严格达到 12 张，敌人塞入的负面牌「浊气」不计数。
- 新牌覆盖固定攻防过牌、回合出牌连锁、攻击牌连锁、一次性抽牌护体、战斗治疗、弃牌堆规模、整场消耗累计和 0 费连锁启动，给魔修三条主路线之外提供可混搭的小组件。
- 八张牌全部加入魔修、体修、剑修和驭兽师的 `draftable_cards`；商店从当前职业池自动取牌，因此无需维护第二份商店名单。魔修池现有 83 个唯一 ID。
- `ConfiguredCountScalingEffect.exclude_current_card` 与 `ClassMechanicHandler.is_card_in_count_source()` 解决“牌先进入弃牌堆再执行效果”导致自身被计数的问题；弃念成罡按玩家实际可见的旧弃牌堆数量结算。
- `card-mechanics` smoke 验证八张资源 ID、通用职业归属、突破能力和四职业奖励池接入；`demonic-card-suite` 在真实战斗中验证七类数值公式、抽牌、治疗、0 费伤害与消耗去向。
- 新牌暂复用项目内已有高分辨率卡图，不使用低清占位图；后续替换独立插画不会改变卡牌 ID、牌池或存档语义。`game_data.xlsx` 已重新导出，Excel→Godot 回写为 0 文件变化。

## 50. 上一张牌复刻机制（2026-07-13）

- `ClassMechanicHandler` 维护本回合真实出牌历史，`get_previous_card_played(current_card)` 会跳过正在结算的牌；玩家回合开始时与其他回合计数一并清空，跨回合不能复刻。
- `Card.create_runtime_copy()` 只复制牌资源本身并解除 `spirit_root_owner`；`CultivationCard` 再独立深拷贝主效果、弃牌触发和消耗触发。这样副本数值可独立变化，同时不会沿角色所有权引用深拷贝整个战斗对象图。
- 新增数据驱动效果 `ConfiguredCopyPreviousCardEffect`：复制上一张可主动打出的牌，赋予临时标记、重置临时费用后降低指定费用，并通过 `PlayerHandler.add_temporary_cards_to_hand()` 加入手牌；手牌满时沿用统一提示。
- 魔修金色技能「魔影复刻」为 1 费消耗牌：把本回合上一张牌复制为费用 -1 的临时牌。副本打出或回合结束都会移除，不进入抽牌堆或弃牌堆；突破后本体费用降为 0。
- 「魔影复刻」已加入魔修奖励池，唯一 ID 数由 83 增至 84；`card_table.py` 和 `game_data.xlsx` 已识别“复刻”效果，Excel→Godot 回写为 0 文件变化。
- `demonic-card-suite` 在真实战斗中验证副本身份、临时生命周期、费用降低、本体消耗去向与新回合历史清空；`card-mechanics` 验证 84 张唯一奖励牌和新牌池接入。

## 51. 跨回合延迟施放（2026-07-13）

- 新增数据驱动 `ConfiguredDelayedEffect`：任意牌可配置等待回合数、目标模式和一组延迟效果；说明文本会展开嵌套效果，数值突破与成长也会递归传递到延迟效果。
- `ClassMechanicHandler` 维护战斗内延迟队列，保存来源牌的独立运行时快照、深拷贝效果、剩余回合和原目标实例 ID。玩家目标/全体敌人按生效时战场重新解析，单体目标则只在原对象仍有效时结算，死亡目标不会导致悬空引用或误伤替代目标。
- 延迟队列在玩家回合开始、基础资源重置后推进；到期条目只结算一次并立即移除。多条术法可以独立排队，战斗节点退出时队列随处理器释放，不会带入下一场战斗。
- 新增金色消耗技能「劫火魔胎」：1 费并立即失去 3 点生命，下回合开始抽 2 张牌、获得 2 点灵力；突破后 0 费。它把血契自损转化为明确的下一回合爆发窗口。
- 新增蓝色技能「伏魂咒」：1 费锁定一个敌人，下回合对原目标造成 12 点伤害并施加 1 层魂印；牌本身正常进入弃牌循环。突破会递归提高延迟伤害与魂印层数。
- 两张牌加入魔修奖励池，唯一 ID 数由 84 增至 86；`card_table.py` 与 `game_data.xlsx` 已识别“延迟施放”，Excel→Godot 回写为 0 文件变化。
- `demonic-card-suite` 在真实战斗中验证即时/延迟边界、自损产生煞气、抽牌与灵力、原目标保存、伤害与魂印、消耗/弃牌去向和队列清空；`card-mechanics` 验证 86 张唯一奖励牌及两张新牌接入。

## 52. 污染牌净化与消耗联动（2026-07-13）

- `PlayerHandler.exhaust_affliction_cards_from_hand()` 新增无选择界面的精确净化入口：只遍历当前手牌中的状态牌/诅咒牌，可配置最多数量并排除来源牌；普通攻击、技能和功法不会被误消耗。
- 新增数据驱动 `ConfiguredPurgeAfflictionEffect`：调用统一净化入口，并按实际焚化张数给予逐张护体。每张污染牌都通过原有 `exhaust_card_from_hand()` 进入消耗区，正常触发生命周期和 `Events.card_exhausted`，不会绕开血膜、焚契灰炉或战斗消耗计数。
- 「浊气」补齐“状态 / 可打出 / 消耗”机制标签，仍可支付 1 灵力自行消耗，同时现在能被状态牌净化准确识别；蚀痕、判牒、心魔及事件诅咒沿用各自原生命周期。
- 新增蓝色技能「焚秽诀」：1 费先获得 5 点护体，再消耗手牌中所有状态牌和诅咒牌，每张额外获得 4 点护体；自身不消耗，正常进入抽弃循环。突破后基础护体 8、逐张护体 6。
- 这张牌把敌人污染从单向卡手转化为可围绕的消耗资源：既是黑莲圣母、蚀日祭司、毒母和幽冥判官的构筑反制，也能推动万祭归一、灰烬护心等消耗规模收益。
- 「焚秽诀」已加入魔修奖励池，唯一 ID 数由 86 增至 87；`card_table.py` 与 `game_data.xlsx` 已识别“焚化污染”，Excel→Godot 回写为 0 文件变化。
- `demonic-card-suite` 在真实战斗中同时放入心魔、判牒、浊气和普通防御牌，验证三张污染精确进入消耗区、普通牌保留、护体精确 +17、本体进入弃牌堆；`card-mechanics` 验证 87 张唯一奖励牌和突破后的 8/6 数值。

## 53. 魔修卡池平衡护栏与第四流派供给（2026-07-13）

- 新增 `scripts/demonic_pool_balance.py` 与生成文件 `DEMONIC_BALANCE.md`。脚本从真实 `demonic_cultivator_draftable_cards.tres` 解析唯一 ID 和显式重复权重，不把目录中未进奖励池的牌误算为可获取内容。
- 报告固定输出稀有度供给、攻击/技能/功法比例、费用曲线、两张 X 费牌、血契/魔焰/魂印/消耗四路线分档供给和单卡重复权重；`python scripts/demonic_pool_balance.py --write --check` 可重建并验证。
- `validate_project.py` 已接入同一分析器：唯一池必须保持 75–100，白/蓝/金/暗金至少 24/24/12/4，类型与 1 费占比保持合理区间，X 费严格 2 张，单卡权重不超过 3；四条路线都要有至少 15 张总供给、5 张白卡启动件并覆盖白/蓝/金三档。报告过期也会直接报错。
- 分类器只读取卡牌 ID、名称、机制标签、效果脚本、状态引用、效果文案和真实消耗属性，不读取插画/音效路径，避免复用带 `blood/flame` 文件名的美术导致假流派归类。
- `BattleReward._get_card_archetypes()` 新增 `exhaust`：已有消耗/净化牌组会提高消耗、回收、污染净化候选权重，仍沿用每张 +18%、最多 +90%，不会改变先选稀有度的章节掉率。
- 首轮报告发现消耗路线虽有 27 张总供给，但白卡只有 3 张。将「焚秽诀」从蓝卡下调为白卡，并新增白色技能「灰烬障」：0 费获得 4 点护体后消耗，突破为 6；消耗路线白卡增至 5，第一章可以自然起步。
- 魔修奖励池由 87 增至 88 个唯一 ID，当前结构为白 32 / 蓝 33 / 金 18 / 暗金 5，攻击 37 / 技能 37 / 功法 14，1 费牌 57 张，X 费牌 2 张；完整数据见 `DEMONIC_BALANCE.md`。
- `card-mechanics` 验证消耗流三张支持牌带来精确 `1.54x` 候选权重、88 张唯一池和报告相关卡牌；`demonic-card-suite` 在真实战斗中验证灰烬障基础 4 护体、血膜额外 2 护体及消耗区去向。

## 54. 卡牌奖励运行时批量模拟（2026-07-13）

- 新增 `test_data/card_reward_simulation_smoke.gd/.tscn`，直接实例化 `BattleReward` 和魔修角色资源，调用正式 `_generate_card_reward_choices()`，不在测试中重写抽卡公式。
- 固定 RNG 种子 `20260713`，三章各模拟 180 组三选一，逐组验证数量、卡牌 ID 去重和稀有保底等待上限；第一章同时验证暗金掉率严格为 0。
- 当前确定性样本中，白卡占比为 `80.4% / 70.0% / 56.9%`，金卡及以上占比为 `9.3% / 12.8% / 20.2%`，最长连续未见金卡为 `6 / 6 / 5` 组；章节稀有度曲线和六次硬保底均按设计生效。
- 第二、三章候选自带突破比例为 `9.1% / 22.0%`（第一章为 0）；模拟检查后期突破供给必须增长，但允许不可突破卡牌使实际比例低于原始 15% / 30% 掷骰概率。
- 血契、魔焰、魂印、消耗四路线各执行 1200 次正式加权选择；在 1 张流派牌与 3 张中立牌的样本中命中率为 `39.5% / 39.8% / 37.0% / 39.4%`，相对等权 25% 有明确提升且保持在 1.9 倍上限范围内。
- `scripts/run_godot_checks.py` 已接入 `card-reward-simulation`，全量 Godot 检查由 20 项增至 21 项。后续调整章节权重、保底、候选数量、卡池流派标签或协同系数时，必须同步跑此检查观察真实分布。

## 55. 四路线阈值法宝与英雄技能自损联动（2026-07-13）

- 魔修新增四件需要安排回合内顺序的专属法宝：少见「血劫算盘」在本回合卡牌自损累计达到 4 点后返 1 灵力；稀有「三曜焰灯」在焰轮首次点亮 3 色时返 1 灵力；少见「渡魂香炉」在一次消费至少 3 层魂印时获得 6 护体；稀有「灰契残卷」在本回合第 3 张牌被消耗时返 1 灵力并抽 1 张。
- 新增可复用的 `SelfDamageThresholdRelic`、`FlameWheelThresholdRelic`、`CardExhaustThresholdRelic` 三种事件法宝脚本；`SoulMarkSpentRelic` 新增 `minimum_consumed`，默认值 1 保持摄魂铃、万鬼幡原行为不变。
- 四件法宝均是每回合一次且在 `player_turn_started` 独立重置。血契按实际生命损失累计；焰轮按不同颜色数量判断；魂印要求单次消费达到门槛而非跨次累加；消耗牌仍正常留在消耗区，法宝不改牌堆生命周期。
- 修复英雄技能「魔焰焚心」只走伤害动画却不发自损事件的问题。`Player.take_self_damage()` 复用护体、伤害修正、动画和死亡结算，伤害落地后仅按实际掉血发出 `player_self_damaged`；被护体完全挡住时不会误触发血契法宝或自损计数，也不会重复播放两套掉血飘字。
- 奖励法宝池由 46 件扩为 50 件，魔修专属达到 14 件，Boss 法宝仍为 6 件且不进入普通奖励或商店。四件新法宝都经过职业过滤，其他职业不会抽到。
- `demonic-relic` 在真实战斗中覆盖四类阈值前后、同回合防重复、跨回合重置、英雄技能式可格挡自损与消耗区保留；`relic-economy` 覆盖 50 件池、四档稀有度、来源分层、Boss 三选一、ID 去重和商店价阶。

## 56. 互斥路线魔契首领法宝（2026-07-13）

- 首领法宝新增三件魔修路线魔契，补齐原本只由魂印占据的职业首领档：血契「血海魔冠」要求每回合卡牌自损至少 4 点；魔焰「七曜魔轮」要求焰轮点亮至少 3 色；消耗「焚经天炉」要求每回合消耗至少 2 张牌。
- 三件魔契都令每回合灵力 +1；若回合结束仍未完成对应要求，则玩家获得 1 回合破绽，下一次敌方回合受到伤害提高 50%。收益足以改变费用曲线，但脱离对应构筑强拿会显著放大敌方压力。
- `Relic.exclusive_group` 为法宝提供通用互斥语义。三个魔契共享 `demonic_mana_pact`：同一组三选一最多出现一件，持有后其余成员不再进入后续奖励，调试、事件或遗产等直接 `add_relic()` 入口也不能绕过限制。
- 新增数据驱动 `DemonicPactRelic`，统一跟踪本回合实际自损、焰轮最大颜色数、魂印消费总量和消耗牌数量；当前三件使用血契/魔焰/消耗，魂印枚举保留给后续扩展。回合开始先清零计数并加灵力，回合结束再判定破绽。
- 奖励法宝池由 50 件扩为 53 件，魔修专属由 14 增至 17，首领法宝由 6 增至 9；非首领奖励和商店仍严格排除首领档，三章 Boss 即使携带失败遗产和前章选择也始终能给出 3 个唯一候选。
- 新增独立 `demonic-pact-relic` smoke，在真实 Player/StatusHandler 上逐件验证跨回合灵力、达标免罚和未达标破绽；`relic-economy` 新增候选内互斥、持有后过滤和直接装备拦截。全量 Godot 检查由 21 项增至 22 项。

## 57. 三章普通敌人战术扩充（2026-07-13）

- 三章普通遭遇由每章 8 场扩为 9 场，精英与 Boss 仍各为 3 场；总池新增锁灵灯童、噬经毒蛾、业债判吏，章节池继续互斥且同档洗牌袋首轮不重复。
- 第一章「锁灵灯童」按固定序列先施加锁灵、再进行两档攻击。锁灵在下个玩家回合重置灵力后扣除 1 点灵力，按持续回合叠加，意图与提示都使用中文名称。
- 第二章「噬经毒蛾」开场获得 10 护体并随机消耗玩家抽牌堆 1 张牌。该牌进入正式消耗区并触发消耗生命周期，玩家可以围绕抽牌堆顺序与消耗联动应对。
- 第三章「业债判吏」的收债攻击按玩家弃牌堆数量增加伤害，基础 8、每张 +2、额外伤害最多 16；固定序列穿插 14 护体与 20 点处决，使保留、消耗和主动清理弃牌堆都成为反制手段。
- 新增 `normal-tactics` 真实战斗 smoke，逐场验证敌人数、首个意图、锁灵扣费、随机牌进入消耗区、护体和弃牌增伤精确结算，以及首轮可生存性。`content-progression` 同步验证三章各 9/3/3；全量 Godot 检查由 22 项增至 23 项。

## 58. 普通遭遇数量达标与六种新战术（2026-07-13）

- 三章普通遭遇从每章 9 场扩为 11 场，精英/Boss 仍各 3 场；当前总池为 33 普通 + 9 精英 + 9 Boss，章节互斥和各档洗牌袋首轮不重复保持不变。敌人资源总数由 33 增至 39。
- 第一章新增「血祭童子」和「镇炉甲傀」：前者非致死地支付 4 点生命获得 2 劲气，再进入强化后的连击循环；后者用 8 点伤害 + 8 护体的攻防动作压缩玩家的进攻窗口。
- 第二章新增「剜心魅影」和「灰经邪僧」：魅影先施加一个完整敌方回合有效的破绽，再发动双击；邪僧分别向抽牌堆和弃牌堆写入蚀痕，形成可被消耗/净化构筑反制的持续污染。
- 第三章新增「饮血尸傀」和「天罚司吏」：尸傀攻击 14 并回复 10，要求玩家集中爆发；司吏按玩家已损生命比例在基础 10 点上追加最多 16 点伤害，残血贪攻的风险会直接显示在意图中。
- 新增共享动作 `self_sacrifice_buff_action`、`attack_and_block_action`、`drain_attack_action`、`missing_health_attack_action`，全部读取敌方伤害加成与玩家受伤修正。敌方意图现在会在出牌、弃牌、消耗和玩家受伤后延迟刷新，牌堆/血量联动数字不会停留在旧值。
- 敌方专用破绽资源使用 2 回合初始持续时间：施加后的下个玩家回合降为 1，随后完整覆盖一次敌方攻击，再在下一玩家回合移除；不改变玩家卡牌施加的原版 1 回合破绽。
- `normal-tactics` smoke 扩为 9 场真实战斗，新增验证血祭扣血与劲气、攻防同步、破绽窗口、污染牌跨牌堆计数、吸血和残血增伤/意图刷新；`content-progression` 同步验证三章各 11/3/3。全量检查仍为 23 项。

## 59. 三章精英动态召唤（2026-07-13）

- `EnemyHandler.summon_enemy()` 新增战斗中生成入口：动态敌人使用正式 `enemy.tscn`，复制独立 `EnemyStats`，继承当前战斗的生命/伤害倍率，连接状态回合信号并在下一敌方回合获得行动；新增子节点会沿现有 Battle/BattleUI 同步流程重排战场和信息卡。
- 新增共享 `summon_enemy_action.gd`，可配置随从资源、场上人数上限和满员回退护体。召唤意图使用 `SUMMON` 分类并明确写出随从名称；场上达到 3 名时不会继续生成，统领改为获得护体，避免固定序列空过。
- 第一章「血月狼王」在群体加劲气后召来第二只雾隐狼；第二章「铜傀督军」在结阵后补充第二名符纸兵；第三章「蚀魂祭司」在塞入蚀痕后召来第二只瘴毒蛾。三场都保留原首轮身份，第二回合开始形成必须处理统领或清理随从的目标优先级。
- `elite-tactics` smoke 从首轮验证扩展到第二个敌方回合，逐场确认动态敌人数从 2 增至 3、随从 ID 正确、所有增援拥有下一行动意图、战斗未误判胜利，以及直接生成入口严格执行三人上限。全量检查项目数保持 23。

## 60. 八件通用战术法宝（2026-07-13）

- 奖励法宝池由 53 件扩至 61 件，新增 3 普通、2 少见、3 稀有通用法宝；魔修专属仍为 17 件、首领档仍为 9 件。新法宝对所有职业开放，普通/精英/宝箱/商店按既有章节与来源权重自然获取，首领奖励隔离不变。
- 「战纹护腕」每回合首张攻击提供 4 护体；「流墨玉扣」每回合首张技能抽 1；「破阵战鼓」开战获得 1 劲气。这三件提供跨职业的攻击、技能和基础数值起点，不要求特定元素或职业牌标签。
- 「藏息玄炉」在回合结束时把最多 3 点未用灵力按每点 3 护体结算但不提前消耗灵力；「残月血戒」在生命不高于 50% 的回合开始额外提供 1 灵力，分别支持保守留费和魔修残血血契路线。
- 「轮回星砂」每回合第一次洗牌获得 1 灵力与 6 护体；「斩灵符」每回合首次击杀抽 1；「涅槃余烬」每次击杀回复 2，令小牌组循环、多敌人战和召唤精英产生新的法宝价值。
- `CardPlayDrawRelic` 新增可选 `match_type`，保留旧资源的标签/元素/职业/ID 前缀匹配；新增可复用 `CardPlayBlockRelic`、`UnspentManaBlockRelic`、`LowHealthManaRelic`、`DeckReshuffleRelic`，均使用统一事件和正式护体/抽牌/灵力结算。
- 新增 `universal-relic` 真实战斗 smoke，验证 8 件法宝均在奖励池且跨职业可用，并逐项覆盖开战劲气、攻击护体、技能抽牌、未用灵力上限、半血阈值、洗牌单回合限制、连续击杀抽牌/治疗；奖励池与魔修法宝检查同步更新为 61 件。全量检查由 23 项增至 24 项。

## 61. 负面状态法障（2026-07-13）

- `Status` 新增 `is_debuff` 数据字段，流血、破绽、敌方长时破绽、锁灵和魂印已明确标记为负面；劲气、煞气、气脉、灵息、金身和职业形态等正面状态保持原逻辑。以后新增控制/持续伤害时必须同步标记，才能参与法障交互。
- 新增可叠层状态「法障」：每层在负面状态进入 `StatusHandler` 前抵消一次并扣除，归零后图标自动移除；被挡状态不会初始化、叠层或触发后续效果。正面状态不消耗法障，抵消时通过统一随机结果提示显示“目标的法障抵消了一项负面状态”。
- `EnemyStats.starting_statuses` 提供通用数据化初始状态数组，Enemy 在实例化、召唤与章节倍率应用时只初始化一次并为每名敌人复制独立状态资源；后续可继续用于开局形态、特殊增益或挑战词缀。
- 六名中后期敌人获得递增法障：剜心魅影/天罚司吏/铜傀督军各 1 层，蚀魂祭司/万蛊母皇各 2 层，幽冥判官 3 层。魂印与破绽构筑需要先用低价值状态破障，纯伤害构筑不受额外限制。
- 新增 `status-ward` 真实精英战 smoke，验证 5 种负面资源标记、6 名敌人初始层数、正面劲气绕过法障、两次魂印抵消、归零清理和第三次魂印正常施加；精英召唤、9 Boss 与魔修牌组专项同步通过。全量检查由 24 项增至 25 项。
