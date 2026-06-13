# 百劫成仙项目交接文档

更新时间：2026-06-13  
项目根目录：`E:\code\game-demo`  
Godot 工程目录：`E:\code\game-demo\game-demo`  
Godot 版本：4.5.2 stable mono  
Godot 可执行文件：`F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe`

## 1. 当前状态

- 工作区存在一批未提交改动，主要集中在 UI、美术资源和卡牌显示组件。
- 最近一次项目静态校验和 Godot headless 检查均已通过。
- 原交接文档存在编码乱码问题，本文件已重写为可读中文版本。

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
│  ├─ art\                    背景、角色、怪物、卡牌框、标题图、遗物图标等美术资源
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
└─ HANDOFF.md                 本交接文档
```

## 4. 核心系统提醒

- Autoload：`Events`、`Shaker`、`MusicPlayer`、`SFXPlayer`、`RNG`。
- 卡牌资源：`res://custom_resources/card.gd`、`res://custom_resources/cultivation_card.gd`。
- 卡牌效果优先使用 `configured_effects`，不要回退到旧字段驱动。
- 新增卡牌后要检查职业卡池、图鉴扫描、奖励/商店来源。
- 修改主流程后必须跑 `run-flow`。
- 修改 Boss、敌人或战斗配置后必须跑 `boss-battle`。
- 修改图鉴资源扫描后必须跑 `codex` smoke。
- 修改存档字段后要测试继续游戏。

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

最近通过的检查结果：

- `validate_project.py`：0 error(s), 0 warning(s)
- `run_godot_checks.py`：`main`、`character-selector`、`codex`、`battle`、`map`、`run-flow`、`boss-battle` 全部 ok

## 6. 最近改动摘要

### 游戏名与主页

- 游戏名已改为 `百劫成仙`。
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

## 8. 当前注意事项

- 当前卡牌整体已经使用真实卡框，但中间仍是原有低分辨率小图标，因此和宣传图的大插画质感仍有明显差距。
- 要进一步接近宣传图，需要后续为每张卡或每类卡补齐真正的卡牌插画，而不是只替换卡框。
- 当前卡框资源是 AI 生成贴图，已能作为临时美术资源使用；若后续有正式美术，应保持相同布局区域，避免重改 UI 坐标。
- 卡牌显示逻辑没有修改 `Card` 数据结构，也没有改卡牌效果逻辑。
- 战斗手牌尺寸仍偏紧凑，主要是为了避免遮挡战斗场景。
- 如果再调整卡牌比例，要同步检查战斗手牌、奖励三选一、商店、图鉴/预览、升级、删除、融合界面。

## 9. 后续建议

1. 为高频卡牌优先生成或绘制正式大插画，替换当前临时小图标。
2. 对卡牌标题字体、描述字体补充更有国风感的正式字体资源。
3. 给主页按钮增加轻微 hover 音效、灵光粒子或水墨扩散效果。
4. 对地图、商店、宝箱、祝福页面做一次统一视觉 QA，检查字体大小、按钮状态和不同分辨率下的遮挡。
5. 在提交前重新运行 `validate_project.py` 和 `run_godot_checks.py`，并人工进入战斗、商店、地图、奖励、主菜单确认视觉效果。
