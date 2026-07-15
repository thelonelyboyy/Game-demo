# 万劫求仙项目交接文档

更新时间：2026-07-15（卡牌标准化、统一数值表、战斗交互与地图体验收束）
项目根目录：`E:\code\game-demo`  
Godot 工程目录：`E:\code\game-demo\game-demo`  
Godot 版本：4.5.2 stable mono  
Godot 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe`
Godot Console 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64_console.exe`

## 1. 当前状态（2026-07-15）

- 稳定运行的杀戮尖塔式修仙卡牌肉鸽 Demo。当前焦点：**把魔修打磨成完整 Demo**。
- **2026-07-14 最新交接**：地图扩展为 20 层并调整节点分布；战斗人物/怪物卡面、状态栏、技能与结束回合布局完成一轮收束；临时、消耗、保留、固有、虚无及弃牌/消耗触发、成长、发现机制已接入；魔修灵根固定金/水/火，职业池按名称稳定均分为无属性/金/水/火四组（各 22 个权重条目），顶栏动态显示牌组主元素。
- **2026-07-14 UI/事件补充收束**：卡牌底部类型只显示攻击/技能/功法，卡框仍可保留职业与元素美术差异；商店标题与说明改用顶部安全锚点；45 个事件统一使用 `GenericEvent` 布局，32 个缺图事件暂用素材库默认插画；宝箱节点取消开箱演出，进入后直接显示法宝二选一。
- **2026-07-14 职业池与战斗响应修正**：修正 8 件职业机制法宝和金身丹的全职业误标，魔修池不再出现体修/剑修/驭兽专属物；魔修卡牌池已核对为“魔修+通用”。同时缩短起手抽牌、回合弃牌、手牌补位/hover/拖拽回正和出牌预览时长，提高连续出牌响应。
- **2026-07-14 图鉴词条释义**：图鉴“词条”改为玩家可读的分组术语表，收录基础战斗、卡牌关键词、通用状态以及体修/剑修/魔修/驭兽机制；灵息、劲气、金身、煞气、魂印、魔焰等均有固定规则释义与实战提示。数据源为 `scenes/ui/codex_glossary.gd`。
- **2026-07-15 统一数值表中文化并补齐效果/融合**：`game_data.xlsx` 的展示字段除资源路径和稳定 ID 外均已中文化；「卡牌效果」采用一行一个参数，覆盖打出/抽到/弃置/消耗/回合结束触发，「融合配方」覆盖全部 20 条配方（16 条动态合成、4 条固定成品卡）。随后已扩展为 14 页和 417 条当前有效参数，最新范围见下方“卡牌效果与关键词标准化”。
- **2026-07-15 Excel 数据验证兼容修复**：关卡设计“敌人1–3”原先将 39 个怪物 ID 写成超过 255 字符的内联下拉列表，Excel 打开时会修复并删除 sheet8 的数据验证；现改为引用 `怪物!B2:B40`。本机 Excel 只读验证 `RepairMode=False`，153 个敌人槽位下拉均保留，根目录工作簿已同步。
- **2026-07-15 火灵根圆满伤害修复**：首张火属性攻击牌的二选一现在先完成选择，再发出 `card_played` 启动攻击动画，避免玩家停留选择框时动画结束信号提前发出、卡牌永久卡在伤害结算前。新增 `spirit_root_fire_choice_smoke`，覆盖延迟选择后“伤害 ×1.5”仍正常造成 15 点伤害。
- **2026-07-15 其他灵根圆满核验**：新增 `spirit_root_other_perfect_smoke`。金/土验证每回合仅加 1 层劲气/真元且下回合重置；水验证抽 1、仅该次抽牌临时费用 -1、不串到后续抽牌；木验证受伤回 3、满血得 3 护体、未打木牌不触发。四类定向测试通过，运行逻辑无需改动。
- **2026-07-15 卡牌效果与关键词标准化**：192 张卡牌统一使用可复用效果组件；多段效果按自损、伤害、抽牌、护体、状态等拆成独立资源并按顺序结算。关键词从自由文本迁入强类型字段，支持一张牌同时配置消耗、保留、固有、检索X、取回X、归墟X、永恒、虚无、临时、周天、不可打出、状态牌、诅咒牌。冲突优先级固定为：打出时“临时 > 消耗 > 功法移出 > 周天 > 弃牌”，回合末“临时 > 虚无 > 保留 > 弃牌”；永恒始终禁止打出、永久删除、变化和合炼。`card_keyword_standardization_smoke` 覆盖组合冲突、固有起手、三类牌堆选择与永恒保护。
- **2026-07-15 game_data 关键词配置扩展**：`game_data.xlsx` 增至 **14 页**，新增「关键词标准」「效果标准」。卡牌页新增全部关键词“是/否”开关，以及检索/取回/归墟张数列（1~10）；关闭开关时回写自动归零。当前覆盖 192 张卡、417 条可调效果参数、30 类实际效果组件和 20 条融合配方；Excel 原样回写卡牌资源为 0 改动，关键词组合写回已做隔离变更验证。
- **2026-07-15 偶发结束回合失效修复**：根因是玩家打出卡牌后 `CardUI` 已进入 `queue_free`，但同帧快速点击结束回合时仍会被旧的手牌遍历绑定进弃牌补间，稍后回调访问已释放节点会打断回合清理。`Hand` 与 `PlayerHandler` 现统一只统计/清理有效且未排队释放的卡牌；`BattleUI` 每 0.2 秒按 `battle_active + battle_running + player_actions_enabled` 权威状态同步结束回合按钮，修复漏信号后的禁用残留。`battle_interaction_regression_smoke` 新增同帧释放卡牌后结束回合的真实轮转断言，连续 3 次通过；卡牌生命周期与关键词 smoke 同步通过。
- **2026-07-15 天路图例节点定位**：地图右侧八类图例现可鼠标悬停。悬停“精英”等图例行时，地图中全部同类型节点强制提亮，周围显示双层亮红脉冲圈并持续上下跳动；其他类型不受影响，移出图例或关闭地图后立即恢复。实现集中在 `map.gd` 的图例类型筛选和 `map_room.gd` 的独立绘制/位移动画，不影响节点可达状态、点击、地图入场动画、可选节点呼吸或 Boss 红光。新增 `map_legend_interaction_smoke`，并通过地图生成与地图场景加载定向检查。
- **2026-07-15 战斗数值反馈顺序化**：同一角色的护体损失、生命损失、自损与治疗不再同帧叠放。`FloatingCombatText` 按触发顺序每 0.34 秒启动一项表现，受击时固定先显示“护体 -X”、再显示实际扣血，命中特效和音效同步跟随；人物卡的护体条与生命条也按 `Stats` 产生的数值快照串行播放。`combat_feedback_sequence_smoke` 覆盖护体→生命→治疗飘字及护体条→生命条的顺序。
- **2026-07-15 game_data 突破与融合新增**：卡牌页新增“突破方向”下拉，可选不可突破、数值提高50%或费用减少1，并可回写 `upgrade_type`。融合配方页新增“启用”开关、原料与结果方式可编辑列和 20 行新增区；新行只需填写配方ID、两张原料卡ID及结果设置，回写器会创建配方 `.tres` 并自动登记到 `card_fusion_library.tres`。启用设为“否”只从游戏融合库停用，不删除配方文件；删除表中现有行也会在下次回写时移出融合库。`test_game_data_editing.py` 覆盖突破回写、无 `_recipe` 后缀的新配方创建和停用注册。
- **2026-07-15 game_data 最终 Excel 兼容修复**：移除卡牌页、融合配方页在扩列后残留的旧 Excel 表格元数据和重叠数据验证，避免打开 `game_data.xlsx` 时出现“部分内容有问题”的恢复提示；卡牌页现保留 18 组互不冲突的类别、目标、稀有度、元素、突破和关键词下拉，融合配方页保留启用/结果方式下拉及 20 行新增区。本机 Excel 正常模式只读打开 14 张工作表通过，公式错误扫描为 0。
- **2026-07-15 提交范围收束**：本批改动统一包含卡牌效果/关键词标准化、魔修与通用卡资源迁移、职业物品池修正、火及其他灵根圆满核验、结束回合竞态修复、战斗数值反馈顺序化、地图图例交互、事件插画与布局统一、图鉴术语表，以及 `game_data.xlsx` 的怪物/AI/关卡/突破/融合编辑链路。临时导出目录 `outputs/` 已加入忽略，不作为项目资产提交。
- **卡牌变更确认已统一**：开局灵根赠牌以及事件/祝福中的获得、移除、突破、复制、诅咒都会展示完整卡面并等待玩家点击确认。实现入口为 `scenes/ui/card_change_feedback.gd`，全局信号为 `Events.card_change_feedback_requested`。
- **卡牌元素徽记已强化**：卡面右上角的金/木/水/火/土文字现在带五行专属色圆形底章、亮色描边与阴影；统一由 `card_visuals.gd::_apply_element_badge_style()` 绘制，所有复用 `CardVisuals` 的战斗、商店、奖励、图鉴和事件弹窗同步生效。
- **当前开发策略**：暂时不继续精抠单个 UI，优先把魔修职业做成可完整通关、可调试、可扩展的 Demo 闭环。
- **Demo 职业范围已收束**：选人界面当前只开放魔修，体修/剑修/驭兽都暂时 disabled；代码和资源仍保留，后续可再恢复。
- **UI 风格统一已推进一轮**：`InkTheme` 扩展了暗黑修仙通用面板/按钮/标题样式，并已套到战斗奖励、商店、宝箱、祝福、篝火、删牌、升牌、融合、牌堆、胜负面板、暂停菜单、调试控制台、灵根选择等界面。后续新增页面应优先复用 `scenes/ui/ink_theme.gd`，不要各自重新写一套 StyleBox。
- **事件池已完成分章恢复**：45 个事件按三章各 15 个独立配置；每章地图使用洗牌袋抽取，袋内耗尽前不会重复。
- **地图已切回正式 ROGUELIKE 模式并扩展为 20 层**：`map.tscn` `map_mode = 1`，测试线性地图与自由导航已关闭；当前默认连接线为黑色、走过路径为红色，并保留可选节点/连线呼吸、开图错落浮现、章节层数进度牌、平滑滚动与位置标记。
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
- `run_godot_checks.py`：2026-07-15 卡牌标准化重构后完成 **39 项有效回归全部通过**。首次矩阵暴露魔修旧牌堆测试、无头选牌等待及 run-flow 退出后的蝙蝠意图释放竞态；修复后分别复跑全部失败项，无超时、无 `SCRIPT ERROR`。覆盖主流程、卡牌关键词/生命周期与牌库操控、三流派自动战斗/Boss 矩阵、法宝、状态、三章内容、地图、事件、合炼、经济、战绩和篝火。
- **2026-07-15 发布前验证**：`validate_project.py` 为 0 error / 0 warning，`validate_card_standardization.py` 验证 192 张卡、337 个效果组件与 417 条数值参数通过，`test_game_data_editing.py` 通过。完整 Godot 矩阵首次运行 38 项直接通过，唯一的 `card-mechanics` 失败来自测试夹具仍用普通 `Node` 模拟手牌，而运行时已只统计有效 `CardUI`；夹具改为 `CardUI` 后，`card-mechanics`、`card-lifecycle`、`card-keyword-standardization`、`pile-control` 定向复跑全部通过，当前 39 项有效检查均为通过状态。
- **统一 Excel 数值总表**：`game_data.xlsx`（卡牌/卡牌效果/关键词标准/效果标准/融合配方/祝福/事件/事件灵根/符箓丹药/怪物/怪物行动/关卡设计/商店价格 + 说明）——改表回写 `.tres`/`.json`/`.tscn`/`.gd`，一个文件调主要内容与数值平衡（见第 6、7 节）。旧的独立 `cards.xlsx` 已被它取代。
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
├─ game_data.xlsx             统一数值总表（14 页，含关键词/效果标准、融合配方、怪物行动）
├─ tmp\                       AI 出图工作流暂存（已 gitignore，不入库）
└─ HANDOFF.md                 本交接文档
```

## 4. 核心系统提醒

- Autoload：`Events`、`Shaker`、`MusicPlayer`、`SFXPlayer`、`RNG`。
- 卡牌资源：`res://custom_resources/card.gd`、`res://custom_resources/cultivation_card.gd`。
- 卡牌效果统一走 `configured_effects` 及抽到/弃置/消耗/回合结束四类触发数组：一个数组元素只表示一个可复用效果；自损、伤害、抽牌等复合描述必须拆成多个效果资源，禁止重新加入整张牌专用的旧字段分支。`validate_card_standardization.py` 会检查全部卡牌的效果引用、标准接口、游离效果、重复 ID、中文参数映射与旧关键词标签。
- 标准关键词以 `card.gd` 的显式字段为准，`mechanic_tags` 只保留流派/条件标签。新增或调整关键词时同步维护 `get_keyword_labels()`、`get_play_destination()`、`get_end_turn_destination()`、图鉴词条、`game_data` 导入导出和关键词 smoke；不要依赖中英文自由文本标签驱动生命周期。
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
- **怪物行动数据编辑**：`game_data.xlsx` 的「怪物行动」页覆盖全部 27 套实际行动配置；`使用怪物`列会标出共享者，修改共享配置会同时影响所有列出的怪物。`EnemyActionPicker.fixed_sequence` 非空时按回合循环固定出招、忽略权重/条件；空时保持权重/条件逻辑。表内行动名与参数名已中文化，路径和行动 ID 保留技术值。

## 5. 快速验证命令

在项目根目录 `E:\code\game-demo` 执行：

> **测试范围约定（用户明确要求，后续必须遵守）**：常规功能修复、局部 UI 调整和小规模内容修改，只运行与本次改动直接相关的定向 smoke/场景测试，不要每次执行完整回归。只有发生系统重构、跨多个核心模块的大量修改、准备重要发布，或用户明确要求时，才运行 `run_godot_checks.py` 全量检查。文档改动本身无需运行 Godot 测试。

```powershell
python scripts\validate_project.py
python scripts\validate_card_standardization.py
```

Godot 完整回归（仅限上述需要全量检查的场景）：

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
- `run_godot_checks.py`：2026-07-15 卡牌标准化重构后的当前全量基线为 39/39 有效通过；首次运行的失败项均已修复并单独复跑通过。后续常规修改仍按上方约定只跑定向测试。
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

- **统一 Excel 数值总表 `game_data.xlsx`**：一个文件集中维护卡牌基础、全部现有卡牌效果数值、20 条融合配方、祝福、事件、事件灵根、符箓丹药、怪物、怪物行动、关卡与商店价格。导出 `game_data_to_xlsx.py` / 回写 `xlsx_to_game_data.py`；中文映射集中在 `game_data_labels.py`，卡牌效果与融合分别由 `card_effect_table.py` / `fusion_table.py` 负责。
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

- `game_data.xlsx`（统一数值总表，项目根）——数据页：**卡牌 / 卡牌效果 / 关键词标准 / 效果标准 / 融合配方 / 祝福 / 事件 / 事件灵根 / 符箓丹药 / 怪物 / 怪物行动 / 关卡设计 / 商店价格** + 说明页。只改浅黄列，灰列只读。
- 导出：`python scripts/game_data_to_xlsx.py`（读 .tres/.json/.tscn → xlsx）
- 回写：`python scripts/xlsx_to_game_data.py`（xlsx → .tres/.json/.tscn），之后 Godot 导入一次。
- 模块：`scripts/card_table.py`（卡牌）/ `blessing_table.py`（祝福）/ `event_table.py`（45 个 GenericEvent 与 3 个灵根分支）/ `potion_table.py`（26 个符箓丹药）/ `enemy_table.py`（39 个怪物）/ `ai_table.py`（27 套 AI、83 个行动）/ `level_table.py`（51 个在用关卡）/ `shop_price_table.py`（卡牌、法宝、丹药售价与删牌服务）。
- **覆盖范围**：卡牌调基础属性和标准 amount 类效果；祝福调描述/命格/效果类型+值；事件调正文、选项与组合效果；符箓丹药调基础属性、说明和现有效果参数；怪物调生命、文案及二阶段；AI 调行动参数和序列；关卡调章节、权重、奖励、怪物倍率，并在现有槽位内替换怪物；商店调价格。
- **可调范围**：「卡牌效果」覆盖现有数值参数；效果类型、目标模式、魔焰颜色/附加类型等结构枚举仍在 Godot 改。「融合配方」的动态合成行可调结果名与结果费用；固定成品卡在「卡牌」「卡牌效果」调。关卡页暂不直接增减敌人槽位。全表无修改回写 = 改 0 文件（2026-07-15 已隔离验证），中文反向回写亦已覆盖多表变更测试。
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
- **单体攻击符箓/丹药目标选择已接入但仍需手感 QA**：多敌时进入一次性瞄准状态，右键取消且不消耗物品；单敌保持直接使用。后续主要检查信息卡命中区域、提示清晰度和取消反馈。
- ~~**战斗数值待按 100 血重配平**~~（2026-07-06 已完成，见下）：
  - **基线**：三套共享 AI 脚本默认值上调——bat 系（银月狼/劫灰小鬼/雷羽鹰/血纹虎/劫雷鹏）攻 4→6（双击共12）格 4→9；crab 系（铜傀儡/幽暗鹰/玄铁傀/碧鳞蛟/寒潭蛇/天阙镇将/山魈石怪）攻 7→11 格 6→11 大格 15→26；toxic_ghost 系（黑莲圣母/蚀日妖皇/幽冢灯/碧玉蛛/摄魂影/骨龙/瘴毒蛾）攻 8→13 格 10→18。4 个固定套路场景：符纸兵 9/12、雾隐狼 10/7、牛魔 格18/重砸20/13、渊狱剑魂 15/格22/9/处决25。
  - **血量**：普通 ×~2.7-3.0（银月狼 20 … 铜傀儡 80）、精英 ×~2.7-3.0（牛魔 105 … 碧鳞蛟 155）、Boss ×~2.4-2.6（渊狱剑魂 235 / 黑莲圣母 245 / 天阙镇将 265 / 蚀日妖皇 290）；**骨龙 40→210**（原值严重偏低，同时其战斗 hp_mult 1.25→1.00 防双重加成）。
  - **精英每场伤害倍率**拉开档次：血纹虎群/劫雷鹏 1.35、玄铁傀/碧鳞蛟/摄魂影 1.30、牛魔 1.15。章节倍率（HP 1.0/1.3/1.65、伤害 1.0/1.15/1.3）保持不动。
  - **设计目标**：普通战 2-3 回合、耗 ~10-20 血；精英 4-6 回合、耗 ~25-40；Boss 6-10 回合。`game_data.xlsx` 已重导出同步。**未实战校验，需人工打一局按体感微调**——最快的调法是改三套共享脚本的 @export 默认值和精英战 .tres 倍率。
- **历史偶发异步竞态需继续留意**：`character-selector` 的 headless 首帧竞态已修复，最近全量回归通过；若 `run-flow` 再出现 `Lambda capture freed`，优先检查跨场景 tween/timer 回调是否捕获节点本身，并改为 instance ID + `is_instance_valid` 守卫。
- **`validate_project.py` 仍有盲区**：查不出「文件在但未导入」（缺 `.import`）和字符串拼接路径。新增美术务必在编辑器导入。（注：默认值字段误报已修，现 0 error。）
- **存档跨资源移动会失效**：存档按路径内嵌资源引用，移动/重命名被引用资源后旧档加载失败（有自愈清档兜底，但丢进度）。彻底修复需改成"按 id 重建"（ROADMAP 阶段 0）。
- **魔修待办**：重名、早期血祭强度、魔焰 rider 和魂印 payoff 已处理；2026-07-14 最新牌池按无属性/金/水/火四组各 22 个权重条目重分组。后续重点是完整流程实战平衡、卡牌使用率分析与正式插画替换，数量口径以 `DEMONIC_BALANCE.md` 和实际资源为准。
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

## 10. 历史关键里程碑（2026-07-11 至 2026-07-14）

> 本节由原第 10–73 节逐条提交记录提炼而成。当前行为与数量以第 1、4、8 节及本节最新口径为准；被后续改动覆盖的旧数字不再保留。

### 内容规模与单局流程

- 魔修 Demo 已形成三章完整闭环：每章 11 个普通遭遇、3 个精英遭遇、3 个 Boss，合计 33 普通、9 精英、9 Boss；各章各档独立，使用洗牌袋保证首轮不重复。
- 事件池稳定为 45 个，三章各 15 个且互斥；同章事件也使用洗牌袋，耗尽前不重复。
- 地图扩展到 20 层，并加入路径节奏保底：连续战斗不超过两场、每章至少 2 个商店和 2 个篝火、Boss 前固定篝火、中段宝箱与精英保底。
- Boss 全部具备数据驱动二阶段；前两章 Boss 战后进入完整奖励页，再推进章节。Boss 奖励包含金币、卡牌、首领法宝三选一和符合条件的符箓丹药。
- 心魔难度已覆盖 0–15 级，规则、解锁进度和独立战绩档已接入；单局与累计战绩记录战斗、击杀、出牌、事件、消费和丹药使用等数据。

### 卡牌生命周期与魔修构筑

- 卡牌生命周期已覆盖临时、消耗、保留、固有、虚无、不可打出、状态/诅咒，以及抽牌、滞留、弃牌、消耗、成长和发现触发。
- 战斗牌堆形成完整闭环：抽牌堆、弃牌堆、消耗区均可查看或被效果检索；手牌上限统一为 10，满手抽牌不丢牌，发现溢出进入弃牌堆。
- 已落地牌顶污染过滤、主动弃牌、跨牌堆检索、消耗区回收、上一张牌复刻、跨回合延迟施放、污染净化和按战斗计数缩放等通用数据驱动效果。
- 魔修形成血契/煞气、魂印、魔焰和消耗四条可交叉构筑路线。三套代表构筑已接真实自动对战；消耗路线具备持续防御、过牌、回收、污染转化和终结牌。
- 奖励系统包含章节稀有度曲线、连续未见高稀有牌保底、流派轻度协同、精英至少蓝卡、Boss 至少金卡，以及第二、三章候选自带突破概率。
- 2026-07-14 对魔修职业池进行了最终重分组：按显示名称稳定分入无属性、金、水、火四组，每组 22 个权重条目；当前口径以该分组为准，不再沿用历史扩池过程中的中间数量。
- 英雄技能「焚心」生成随机非攻防魔修临时牌；临时牌打出或回合结束后移除，不进入抽弃循环。技能的实际阶段、伤害和费用说明应始终以运行时 tooltip 为准。

### 法宝、符箓丹药与奖励经济

- 奖励法宝池达到 80 件，其中首领档 12 件、魔修专属 17 件；普通、少见、稀有、首领四档及普通战、精英、宝箱、Boss、商店来源隔离均已数据化。
- 法宝已覆盖卡牌生命周期、手牌状态、牌组规模、出牌组合、洗牌、击杀、未用灵力和四条魔修路线阈值；互斥组用于阻止同类路线法宝或发现引导法宝叠加。
- Boss 固定提供首领法宝三选一；首领法宝不会进入普通奖励或商店，失败遗产仍可带入下一局。
- 符箓丹药共 26 种，统一由奖励池按章节、来源和职业筛选；普通战具有掉落递增与硬保底，精英/Boss 保持高价值供给。
- 药囊支持 3 槽、单体攻击目标选择、右键取消/弃置和满槽后腾位替换；地图状态下使用或弃置会立即存档。
- 商店已支持每次固定一张半价卡、折价券叠加和价格从基价重算；跳过卡牌奖励补偿 10 灵石，篝火包含魔修“血炼术法”删牌选项。

### 敌人战术、状态与战斗结算

- 普通敌人已加入锁灵、牌堆消耗、弃牌堆增伤、自损强化、攻防同步、污染、吸血和按已损生命增伤等战术；随机 AI 默认禁止同一行动连续使用三次。
- 三章战术精英均支持动态召唤，场上人数上限为 3；召唤物继承章节倍率并在下一敌方回合正常行动。
- 状态系统加入负面标记与「法障」抵消链；虚弱、碎甲、锁灵、魂印等均参与统一负面状态语义，净化牌、清心丹与澄神玉形成对应反制。
- 敌方攻击结算已统一修复：行动完成会等待玩家受击动画和伤害落地，意图与实际伤害不再重复应用承伤倍率；玩家死亡后不会继续推进残余回合。
- 战斗计数、牌堆变化、召唤、状态、法宝和奖励测试均走真实战斗逻辑，避免仅验证静态资源配置。

### 自动验证与平衡基线

- `validate_project.py` 已接入魔修卡池结构护栏，检查稀有度、卡牌类型、费用、X 费数量、四路线供给、单卡权重和报告是否过期。
- 卡牌奖励批量模拟使用正式奖励生成逻辑，覆盖章节分布、六次高稀有保底、后期突破率和四路线协同权重。
- 三套代表构筑的固定自动对战基线全部可胜；跨章 Boss 矩阵中，魂印与魔焰稳定性较高，血契对幽冥判官保持明确克制关系，后续平衡不应只看单一胜率。
- 最新全量回归为 36/36 通过，包含主流程、地图、三章内容、卡牌机制、牌堆控制、法宝、状态、奖励经济、事件、合炼、战绩、普通/精英/Boss 战术和自动对战矩阵。
- 2026-07-14 新增的五行元素圆章未在该次回归后重复运行测试；继续修改卡面视觉时至少人工检查战斗手牌、奖励、商店与卡牌变更确认层。

### 2026-07-14 最新收束

- 地图图例改为进入地图即显示；连接线最新视觉口径为默认黑色、已走路径红色。
- 战斗人物与怪物卡面移除冗余外框，血量/护体数字移至对应条下方，状态区只显示真实状态并支持悬停说明。
- 结束回合按钮移到人物卡左侧并放大；「焚心」位于人物卡左上方；人物和怪物插画区域可悬停查看名称与介绍。
- 顶栏元素徽章改为显示永久牌组中数量最多的元素及张数；并列时优先已选灵根，再按固定顺序决胜。
- 开局赠牌以及事件/祝福中的获得、移除、突破、复制、诅咒均统一进入 `CardChangeFeedback` 队列，展示完整卡面并等待确认。
- 五行徽记统一由 `CardVisuals._apply_element_badge_style()` 和 `SpiritRootText.element_color()` 绘制，禁止在战斗、商店、奖励或图鉴中各自复制样式。

## 11. 交接文档维护约定

- 新会话先更新第 1 节“当前状态”，再按需更新第 4、7、8 节；不要继续追加“一次提交一个章节”的流水账。
- 只有影响架构、内容规模、验证基线或后续决策的变化才写入第 10 节；纯视觉微调和单卡数值调整留在 Git 提交记录。
- 测试遵循“改哪里、测哪里”：常规修改只跑相关定向测试；仅系统重构、跨模块大改、重要发布或用户明确要求时跑完整回归，禁止把全量回归作为每次修改的默认收尾步骤。
- 数量发生变化时只保留最新口径，并同步更新相关 smoke 断言、`DEMONIC_BALANCE.md` 和 `game_data.xlsx`。
- 旧行为若被替换，应直接改写现有条目，不保留互相矛盾的历史描述。
