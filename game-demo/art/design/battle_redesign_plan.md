# Codex 目标模式任务卡：无人值守战斗界面重构

## 0. 给 Codex 目标模式的启动提示

把下面整段作为目标模式的目标描述使用：

```text
目标：参考 game-demo/art/design/now.png 和 game-demo/art/design/target.png，在无人值守情况下持续重构 Godot 战斗界面，使其尽量接近 target.png 的暗蓝魔修战斗 UI。

我会离开电脑，不能中途确认。请按 battle_redesign_plan.md 自动推进，不要因为普通设计选择、截图、资源命名、样式细节而停下来问我。

执行原则：
1. 分阶段推进，但不需要每阶段都等我确认。完成一个阶段后自动进入下一阶段。
2. 每次只改一个模块，避免大范围重写。
3. 保留现有战斗机制、卡牌机制、出牌逻辑、存档结构、角色/怪物站位和手牌核心布局。
4. 数字、文字、血量、护甲、意图、牌堆数量必须继续由 Godot 实时渲染；图片只做背景、底框、装饰、图标和按钮底图。
5. 优先使用现有资源和代码绘制样式；只有确实需要时才新增资源。
6. 如需新增 UI 图片，放到 game-demo/art/ui/battle_hud/demonic_blue/ 或已有合适目录，并导入 Godot。
7. 每完成一个阶段都运行：
   - python scripts/validate_project.py
   - python scripts/run_godot_checks.py --godot "<Godot exe>"
8. 如果能自动截图，请把阶段截图保存到 game-demo/art/design/progress/phase_X.png；如果不能自动截图，不要卡住，继续用代码检查和已有参考图推进。
9. 遇到小的视觉取舍，请自行做保守决定；遇到核心机制变更、会破坏存档、需要删除大量用户资源、或检查长期失败，才停止。
10. 最终输出一份完成报告：完成了哪些阶段、改了哪些文件、验证结果、剩余差距、建议我醒来后重点截图确认哪些地方。

最终验收：战斗界面整体更接近 target.png：暗蓝夜景、高对比战场、黑金 HUD、左下大型能量/焰轮区、清晰血条/护甲/状态、右下大号结束回合按钮、顶部信息分组清楚，且所有自动检查通过。
```

## 1. 无人值守执行协议

因为用户不会守在电脑前，Codex 必须默认自动决策。

### 可以自动决定

- 资源命名
- 颜色微调
- 面板尺寸微调
- HUD 位置小范围调整
- 使用 StyleBoxFlat、StyleBoxTexture 或 TextureRect 的实现方式
- 某一阶段完成后继续下一阶段
- 如果视觉截图工具不可用，继续做下一阶段
- 如果目标图某个细节无法完整复刻，做“神似”实现并记录差距

### 不要停下来问

- “是否继续下一阶段”
- “是否使用暗蓝还是暗红”
- “是否保存截图”
- “是否生成同风格底框”
- “按钮文案用不用结束回合”
- “能量区要不要更大一点”

这些都按本文默认规则处理。

### 必须停下来

- 需要改变战斗机制
- 需要改变卡牌尺寸或重写手牌系统
- 需要改变存档结构
- 需要大幅移动角色/怪物站位
- 需要删除或覆盖大量非本任务资源
- 新增单个资源超过 100MB
- `validate_project.py` 或 `run_godot_checks.py` 连续 3 次因同一问题失败且无法定位
- 需要联网获取授权不明确的商业素材

## 2. 视觉参考

源文件：

- 当前截图：`game-demo/art/design/now.png`
- 目标图：`game-demo/art/design/target.png`

目标不是像素级复刻，而是把当前 UI 推向 target.png 的视觉语言：

- 暗蓝夜色
- 月光和冷色战场
- 黑金/暗金 HUD 框体
- 紫色魔修能量氛围
- 左下角大型能量盘与焰轮
- 右下角大号红金结束回合按钮
- 顶部信息分组清晰
- 血条、护甲、状态、意图更接近目标图

## 3. 当前代码结构定位

修改前先读取相关文件，不要凭猜测改。

持久顶栏：

- `game-demo/scenes/run/run.tscn`
- `game-demo/scenes/run/run.gd`
- `HealthUI`
- `GoldUI`
- `SpiritRootBadge`
- `PotionHandler`
- `DeckButton`

战斗 HUD：

- `game-demo/scenes/battle/battle.tscn`
- `BattleUI`
- `ManaUI`
- `FlameWheelUI`
- `EndTurnButton`
- `DrawPileButton`
- `DiscardPileButton`
- `Hand`

关键 UI：

- 背景：`game-demo/scenes/battle/battle.tscn` 的 `Background`
- 血条/护甲：`game-demo/scenes/ui/stats_ui.gd`、`stats_ui.tscn`
- 怪物意图：`game-demo/scenes/ui/intent_ui.gd`、`intent_ui.tscn`
- 意图定位：`game-demo/scenes/enemy/enemy.gd`
- 样式 helper：`game-demo/scenes/ui/ink_theme.gd`
- 音乐：`game-demo/scenes/battle/battle.tscn` 的 `music`

## 4. 必须保留的现状

- `PotionHandler` 固定 3 槽，不要退回动态删除槽位。
- `FlameWheelUI.activate()`、`_active`、魔修常显逻辑必须保留。
- `FlameWheelUI` 必须继续监听 `Events.flame_wheel_changed`，并在 `_exit_tree()` 断开。
- `ManaUI` 必须继续通过 `CharacterStats.stats_changed` 更新。
- `StatsUI` 使用 ColorRect 手动缩放血条/护甲条，不要改成 ProgressBar。
- 护甲条 `block > 0` 显示，0 隐藏。
- `IntentUI` 的 icon/glyph 兜底必须保留。
- `EndTurnButton` 的 disabled/pressed 和 `Events.player_turn_ended` 逻辑必须保留。
- 不改战斗流程、卡牌效果、奖励逻辑、存档结构。

## 5. 阶段计划

每一阶段结束后自动运行检查。检查通过则继续下一阶段；检查失败先修复，最多连续尝试 3 次。

### Phase 0：视觉审计

目标：

- 对比 `now.png` 和 `target.png`
- 列出 P0/P1/P2 视觉差异
- 不改代码

无人值守规则：

- 完成审计后自动进入 Phase 1。
- 不等待用户确认。

### Phase 1：战斗背景和整体色调

目标：

- 把当前偏亮云海战场推向 target.png 的暗蓝夜战氛围。

允许做：

- 新增或替换夜色背景图
- 调整 `battle.tscn` 背景 modulate
- 增加轻量暗色遮罩

不要做：

- 移动角色/怪物站位
- 改手牌位置

验收：

- 背景明显变暗变冷
- HUD 更容易读
- 角色和怪物仍清楚

### Phase 2：左下能量区与焰轮

目标：

- 做出接近 target.png 左下角大型能量盘/法阵的视觉焦点。

涉及：

- `ManaUI`
- `FlameWheelUI`
- `battle.tscn` 中两者位置

实现建议：

- `ManaUI` 改为更大的圆形能量玉或法器底座。
- `FlameWheelUI` 改为圆盘或半圆盘布局，7 色焰点绕环排列。
- 继续支持空焰轮全暗、点亮颜色高亮。

验收：

- 魔修战斗开局空焰轮常显。
- 点亮状态可读。
- 不遮挡手牌和抽牌堆。

### Phase 3：顶部 HUD 分组

目标：

- 参考 target.png 顶部信息栏，做更清晰的左/中/右分区。

涉及：

- `run.gd _setup_top_bar()`
- `SpiritRootBadge`
- `PotionHandler`
- `DeckButton`
- 可能新增 `BattleUI` 顶部回合牌匾

实现建议：

- 左侧：生命、灵石、角色/功法/灵根。
- 中间：回合牌匾。如果没有可靠回合数据，不硬写假数字，先做静态外观或记录 TODO。
- 右侧：牌库入口或总牌库面板。
- 丹药 3 槽保留，只改善外观和间距。

验收：

- 战斗和地图顶栏都不拥挤。
- 丹药 0/1/3 槽显示正常。
- 顶部信息更接近 target.png 的黑金分组。

### Phase 4：血条、护甲条、状态图标

目标：

- 参考 target.png 脚下血条/护甲条/状态图标行。

涉及：

- `StatsUI`
- 玩家和怪物共用显示

实现建议：

- 调整血条框、护甲条框、fill/highlight 位置。
- 如需放大，同步调整 `HEALTH_FILL_WIDTH`、`BLOCK_FILL_WIDTH` 和 `.tscn` 尺寸。
- 增加状态图标行，优先复用现有 `status_*` 图标。

验收：

- 玩家和怪物血条都正常。
- 护甲 0 时隐藏。
- 护甲 > 0 时蓝条清晰。
- 状态图标不遮挡身体。

### Phase 5：怪物意图牌

目标：

- 让意图接近 target.png 的“强攻 18”标签。

涉及：

- `IntentUI`
- `enemy.gd` 定位常量

实现建议：

- 底框黑金/暗红。
- 攻击类显示图标、分类文字、数值。
- 其它类型保留 glyph/icon 兜底。
- 调整宽度、高度、字号和 y 偏移。

验收：

- 攻击、防御、攻击+防御、Buff/Debuff 都可读。
- 意图不贴进怪物身体。
- 多怪时不互相遮挡。

### Phase 6：右下操作区

目标：

- 参考 target.png 右下角大号红金结束回合按钮和牌堆面板。

涉及：

- `EndTurnButton`
- `DrawPileButton`
- `DiscardPileButton`
- `card_pile_opener`

实现建议：

- `EndTurnButton.text` 改为 `结束回合`。
- 使用大号红金底图或 StyleBoxTexture。
- 抽牌堆/弃牌堆改为黑金面板，显示标题和数量。

验收：

- 按钮 hover/pressed/disabled 正常。
- 点击仍触发回合结束。
- 抽弃牌堆数量正确。

### Phase 7：手牌区微调

目标：

- 让手牌区域更接近 target.png 的暗色、紫色发光、集中布局。

边界：

- 不重写手牌系统。
- 不改卡牌效果。
- 不强行改变卡牌尺寸。

允许做：

- 选中高亮
- 卡牌 glow
- 扇形间距小调
- 卡框贴图微调

验收：

- 卡牌可读。
- 拖拽、瞄准、释放正常。
- 出牌流程正常。

### Phase 8：总体验收与最终修补

目标：

- 对比最新画面和 target.png。
- 只修 P0/P1 问题。
- 不再做大范围重构。

验收：

- `validate_project.py` 通过。
- `run_godot_checks.py` 通过。
- 普通战斗可打开。
- 魔修真实战斗可打开。
- 空焰轮/点亮焰轮/护甲/无护甲/不同意图至少代码路径正常。

## 6. 资源规范

新增战斗 UI 资源优先放：

```text
game-demo/art/ui/battle_hud/demonic_blue/
```

若继续沿用已有目录，则放：

```text
game-demo/art/ui/battle_hud/demonic_red/
```

规则：

- HUD 图用透明 PNG。
- 背景图可用 PNG/JPG。
- 缩放显示的 HUD PNG 开启 mipmap。
- 数字、文字、血条、护甲、意图数值不要烘焙进图片。
- 贴图边角 alpha 要干净，避免白边。
- 不新增授权不明的网络素材。
- 单个资源超过 100MB 必须停止。

## 7. 自动截图规则

如果可以自动截图：

- 创建目录：`game-demo/art/design/progress/`
- 每阶段保存：

```text
game-demo/art/design/progress/phase_1.png
game-demo/art/design/progress/phase_2.png
...
```

如果自动截图失败：

- 不要停。
- 在最终报告里写清楚“需要用户醒来后手动截图确认”。

不要因为缺少截图而中断目标，除非视觉判断完全无法继续。

## 8. 每阶段报告格式

每阶段结束后在内部记录，最终统一汇总。最终报告格式：

```text
完成概览：
- Phase 0: ...
- Phase 1: ...

主要改动：
- ...

涉及文件：
- ...

验证结果：
- validate_project.py: ok / failed
- run_godot_checks.py: ok / failed

未完成或保守处理：
- ...

需要用户醒来后确认：
- 打开普通战斗截图
- 打开魔修真实战斗截图
- 对比 target.png 检查左下能量区、顶部 HUD、右下按钮
```

## 9. 最终停止标准

满足以下任一条件即可结束目标：

- Phase 1 到 Phase 8 全部完成，自动检查通过。
- 已完成主要视觉模块，剩余只是不需要无人值守继续猜测的 P3 微调。
- 遇到必须停下的问题，并已连续尝试 3 次无法解决。

结束前必须保证：

- 工作区改动清楚。
- 不留下运行中的服务或进程。
- 不自动提交或推送，除非用户另行明确要求。

## 10. 醒来后用户要做的事

用户醒来后建议：

1. 打开 Godot。
2. 进入普通战斗和魔修战斗。
3. 截图覆盖：

```text
game-demo/art/design/now.png
```

4. 对 Codex 说：

```text
我更新了 now.png，请继续根据 target.png 做 P1/P2 视觉微调。
```

这样后续可以继续精准迭代。
