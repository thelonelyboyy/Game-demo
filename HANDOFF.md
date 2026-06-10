# 修真卡牌游戏项目交接文档

更新时间：2026-06-10  
项目路径：`E:\code\game-demo`  
Godot 工程路径：`E:\code\game-demo\game-demo`  
Godot 版本：`4.5.2 stable mono`

## 1. 项目概况

这是一个 Godot 4 修真题材卡牌爬塔 Demo，玩法目标接近《杀戮尖塔》：

- 主菜单、新开局、继续游戏、角色选择、灵根选择。
- 地图爬塔，包含普通战斗、精英、Boss、事件、商店、宝箱、篝火、祝福。
- 回合制卡牌战斗，支持抽牌、弃牌、消耗、费用、目标选择、敌人意图、胜负结算。
- 四个职业：体修、剑修、魔修、驭兽。
- 卡牌已统一到新效果机制 `configured_effects`。
- 图鉴已重构为“左侧目录 + 右侧详情”，接入卡牌、法宝、怪物、词条。
- 近期美术方向已偏向仙侠云海、偏写实/概念风背景，角色与怪物立绘已替换为较完整的透明 PNG。

## 2. 快速启动

推荐 Godot 可执行文件：

```powershell
F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe
```

打开工程：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe" --path "E:\code\game-demo\game-demo"
```

Headless 运行主场景：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe" --headless --path "E:\code\game-demo\game-demo" --quit
```

## 3. 常用验证命令

资源引用、卡牌配置、旧机制字段检查：

```powershell
python scripts\validate_project.py
```

完整 Godot smoke 测试：

```powershell
python scripts\run_godot_checks.py
```

当前 smoke 覆盖：

- `main`
- `character-selector`
- `codex`
- `battle`
- `map`
- `run-flow`
- `boss-battle`

最近一次验证结果：`validate_project.py` 0 error / 0 warning，`run_godot_checks.py` 全部 ok。

## 4. 目录结构

```text
E:\code\game-demo
├─ game-demo\                 Godot 工程根目录
│  ├─ project.godot           Godot 工程配置，主场景是 main_menu.tscn
│  ├─ art\                    背景、角色、怪物、卡牌、音频等美术资源
│  ├─ battles\                战斗配置 BattleStats
│  ├─ characters\             职业资源、初始牌组、职业卡牌
│  ├─ common_cards\           通用卡牌
│  ├─ custom_resources\       核心 Resource 类型
│  ├─ effects\                新卡牌效果资源脚本
│  ├─ enemies\                敌人资源、敌人场景、敌人行动
│  ├─ fusion_cards\           融合结果卡牌
│  ├─ fusion_recipes\         卡牌融合配方
│  ├─ global\                 Autoload，全局事件/音频/RNG
│  ├─ relics\                 法宝资源与法宝池
│  ├─ scenes\                 主要 UI、战斗、地图、商店、事件等场景
│  ├─ statuses\               词条/状态资源与脚本
│  └─ test_data\              Godot smoke 测试场景
├─ scripts\
│  ├─ validate_project.py     资源和内容校验脚本
│  ├─ run_godot_checks.py     Headless Godot smoke 测试
│  └─ process_enemy_alpha.py  现有图片 alpha 处理辅助脚本
└─ HANDOFF.md                 本交接文档
```

## 5. 当前内容规模

按 `.tres` 粗略统计：

- 卡牌：119 张
- 法宝：45 件
- 敌人：23 个
- 战斗配置：31 个
- 词条：14 个
- 融合配方：5 个
- 事件场景：33 个
- 职业：4 个，分别是 `body_cultivator`、`sword_cultivator`、`demonic_cultivator`、`beastmaster`

## 6. 主流程

入口场景：

```text
res://scenes/ui/main_menu.tscn
```

主流程：

```text
MainMenu
  ├─ 继续游戏 -> RunStartup.CONTINUED_RUN -> Run
  ├─ 新的轮回 -> CharacterSelector -> SpiritRootSelector -> Run
  ├─ 图鉴大全 -> CodexPanel
  └─ 退出
```

Run 内流程：

```text
Run
  ├─ 创建/读取 SaveGame
  ├─ 生成或恢复 Map
  ├─ 点击房间触发 Room.Type
  ├─ 战斗 / 奖励 / 商店 / 事件 / 篝火 / 宝箱 / 祝福
  ├─ 普通/精英奖励
  ├─ Boss 后推进章节
  └─ 第 3 章 Boss 后进入 WinScreen
```

## 7. 核心系统说明

### 7.1 Autoload

在 `project.godot` 中配置：

- `Events`：全局事件总线。
- `Shaker`：屏幕震动。
- `MusicPlayer`：音乐播放。
- `SFXPlayer`：音效播放。
- `RNG`：全局随机数，支持存档恢复。

### 7.2 角色

核心资源类型：

```text
res://custom_resources/character_stats.gd
```

每个职业位于：

```text
res://characters/<profession>/
```

职业资源包含：

- `character_name`
- `description`
- `portrait`
- `starting_deck`
- `draftable_cards`
- `cards_per_turn`
- `max_mana`
- `starting_relic`
- `spirit_root`

当前职业：

- 体修：偏护体、金身、回血、承伤反击。
- 剑修：偏过牌、铸剑、连招。
- 魔修：偏献祭、自伤换爆发、魂印。
- 驭兽：偏灵兽、兽群、召唤协同。

### 7.3 卡牌与效果

核心资源：

```text
res://custom_resources/card.gd
res://custom_resources/cultivation_card.gd
```

卡牌现在应优先使用：

```text
configured_effects: Array[Resource]
```

效果资源位于：

```text
res://effects/
```

重要约定：

- 不再使用旧字段驱动卡牌效果，例如 `base_damage`、`base_block`、`cards_to_draw` 等。
- `scripts\validate_project.py` 会检查旧字段残留。
- 新增卡牌时，建议基于现有 `.tres` 复制，再改 `id`、`display_name`、`cost`、`type`、`target`、`configured_effects`。
- 卡牌职业分类字段为 `Card.Profession`，同时也会根据资源路径推断职业。

### 7.4 战斗

核心场景：

```text
res://scenes/battle/battle.tscn
res://scenes/battle/battle.gd
```

战斗系统包含：

- 玩家与敌人生成。
- 卡牌手牌区、费用、回合结束按钮。
- 卡牌悬停放大。
- 左键拖拽目标选择。
- 红色箭头指向怪物。
- 怪物目标角标提示。
- 敌人意图显示。
- 敌人全部死亡后触发胜利结算。

相关节点/系统：

- `PlayerHandler`
- `EnemyHandler`
- `BattleUI`
- `ClassMechanicHandler`
- `SpiritRootHandler`
- `BattleOverPanel`

### 7.5 地图与房间

地图场景：

```text
res://scenes/map/map.tscn
```

房间类型包括：

- 普通战斗
- 精英
- Boss
- 商店
- 宝箱
- 篝火
- 事件
- 祝福

Run 通过 `Events.map_exited` 接收房间点击结果，再切换到对应场景。

### 7.6 奖励、商店、宝箱、篝火

奖励场景：

```text
res://scenes/battle_reward/battle_reward.tscn
```

奖励类型：

- 灵石
- 卡牌选择
- 法宝
- 卡牌融合

其他房间：

- 商店：`res://scenes/shop/shop.tscn`
- 宝箱：`res://scenes/treasure/treasure.tscn`
- 篝火：`res://scenes/campfire/campfire.tscn`
- 祝福：`res://scenes/blessing/blessing.tscn`

### 7.7 法宝

核心资源：

```text
res://custom_resources/relic.gd
```

资源目录：

```text
res://relics/
```

奖励池：

```text
res://relics/relic_reward_pool.tres
```

法宝可以按触发时机区分：

- 战斗开始
- 回合开始
- 回合结束
- 战斗结束
- 事件触发

### 7.8 怪物与战斗配置

敌人资源目录：

```text
res://enemies/
```

战斗配置目录：

```text
res://battles/
```

新增怪物一般需要：

1. 新建或复制敌人 `.tres`。
2. 配置 `EnemyStats`：生命、显示名、描述、立绘、AI。
3. 新建或复制敌人场景 `.tscn`。
4. 配置敌人行动脚本和意图。
5. 新建或修改 `BattleStats`。
6. 将战斗配置接入战斗池或地图生成逻辑。
7. 运行 `python scripts\run_godot_checks.py`。

### 7.9 词条/状态

资源目录：

```text
res://statuses/
```

核心资源：

```text
res://custom_resources/status.gd
```

当前词条包括破绽、劲气、灵息、剑意、剑阵、凝气、金身、魂印、灵兽、兽群等。

### 7.10 图鉴

图鉴场景：

```text
res://scenes/ui/codex.tscn
res://scenes/ui/codex.gd
```

当前图鉴结构：

```text
左侧目录
  ├─ 总览
  ├─ 卡牌
  │  ├─ 全部
  │  ├─ 通用
  │  ├─ 体修
  │  ├─ 剑修
  │  ├─ 魔修
  │  ├─ 驭兽
  │  └─ 融合
  ├─ 法宝
  ├─ 怪物
  └─ 词条

右侧详情
  ├─ 预览图
  ├─ 名称
  ├─ 元信息
  └─ 详细说明
```

图鉴数据目前通过递归扫描资源目录接入，新增卡牌、法宝、怪物、词条后通常不需要手动加到图鉴，但需要通过 smoke 测试确认。

图鉴 smoke：

```text
res://test_data/codex_smoke.tscn
res://test_data/codex_smoke.gd
```

## 8. 存档

Run 使用 `SaveGame` 保存：

- RNG seed/state
- RunStats
- CharacterStats
- 当前灵根
- 当前牌组
- 当前生命
- 当前法宝
- 当前地图
- 当前章节
- 是否停留在地图

注意：修改角色、牌组、法宝、地图结构时，要同时检查存档读写兼容性。

## 9. 美术资源现状

主要背景：

- 主菜单 / 选人：`res://test1.png`
- 战斗：`res://test2.png`

角色立绘：

```text
res://art/body_cultivator_portrait.png
res://art/sword_cultivator_portrait.png
res://art/demonic_cultivator_portrait.png
res://art/beastmaster_portrait.png
```

怪物立绘：

```text
res://art/abyssal_sword_soul.png
res://art/ash_imp.png
res://art/black_lotus_matriarch.png
res://art/blood_tiger.png
res://art/bronze_puppet.png
res://art/eclipse_tyrant.png
res://art/grave_lantern.png
res://art/iron_golem.png
res://art/jade_spider.png
res://art/jade_wyrm.png
res://art/mist_wolf.png
res://art/paper_soldier.png
res://art/river_serpent.png
res://art/shadow_reaper.png
res://art/sky_palace_guardian.png
res://art/stone_goblin.png
res://art/storm_hawk.png
res://art/thunder_roc.png
res://art/venom_moth.png
```

这些怪物图最近重新清理过透明背景，已去掉内部白底残块与边缘脏像素。

## 10. 当前工作区注意事项

当前工作区不是干净状态，已有若干修改和未跟踪文件。交接前建议执行：

```powershell
git status --short
```

最近可见的非本交接文档改动包括：

- `.gitignore`
- `game-demo/art/*.png`
- `game-demo/art/background.png`
- `game-demo/art/_alpha_backup/`
- `enemy_preview_before.jpg`
- `enemy_preview_after.jpg`
- `scripts/process_enemy_alpha.py`

这些多数来自近期美术与透明背景处理工作。不要随手回滚，除非确认不再需要。

## 11. 增加内容的推荐流程

### 新增卡牌

1. 复制同职业相近卡牌 `.tres`。
2. 修改 `id`，避免重复。
3. 设置 `display_name`、`cost`、`type`、`target`、`rarity`、`profession`。
4. 使用 `configured_effects` 接入效果。
5. 加入对应职业的 draftable card pile。
6. 运行：

```powershell
python scripts\validate_project.py
```

### 新增效果

1. 在 `res://effects/` 新建脚本。
2. 参考现有效果资源，例如 `damage_effect.gd`、`block_effect.gd`、`card_draw_effect.gd`。
3. 在卡牌 `.tres` 的 `configured_effects` 中挂载。
4. 用战斗 smoke 验证。

### 新增法宝

1. 在 `res://relics/` 新建 `.tres` 和脚本。
2. 设置 `id`、`relic_name`、`icon`、`tooltip`、触发类型和职业限制。
3. 加入 `relic_reward_pool.tres` 或角色初始法宝。
4. 验证奖励、商店、宝箱来源是否能抽到。

### 新增敌人

1. 新建 `EnemyStats`。
2. 新建或复用敌人场景。
3. 新建敌人行动脚本。
4. 配置 BattleStats。
5. 加入战斗池。
6. 运行 `boss-battle` 或完整 smoke。

### 新增事件

1. 在 `res://scenes/event_rooms/` 新建事件场景。
2. 继承或参考现有 EventRoom。
3. 配置按钮、奖励/惩罚、退出事件。
4. 加入事件池。
5. 运行 run-flow smoke。

## 12. 已知开发约定

- 不要直接提交 `git commit`，除非明确要求。
- 修改 `.tres` 资源后要注意 Godot 可能自动生成或更新 `.import`、`.uid`。
- Headless 测试退出时可能出现 Godot 的资源泄露提示，`run_godot_checks.py` 已过滤已知非阻断项。
- 资源路径一律使用 `res://`。
- 修改存档结构后要测试继续游戏。
- 修改主流程后必须跑 `run-flow`。
- 修改 Boss 或敌人后必须跑 `boss-battle`。
- 修改图鉴资源扫描后必须跑 `codex` smoke。

## 13. 后续改进方向

优先级从高到低：

1. 战斗 UI 继续打磨：血条、意图、状态图标、伤害数字、敌人选中反馈。
2. 选人界面再做一次视觉 QA：职业文案、立绘裁切、按钮状态。
3. 卡牌内容平衡：职业初始牌组、可选卡池、稀有度曲线。
4. 地图爬塔节奏：每章房间数量、Boss 强度、事件密度。
5. 法宝和融合系统平衡：避免奖励过强或无效。
6. 存档兼容和异常恢复：空存档、旧存档、资源缺失。
7. 图鉴细节：搜索、排序、稀有度/职业/敌人类型筛选。
8. 美术资源统一：压缩 PNG、统一立绘尺度、导入参数检查。

## 14. 最小交接检查清单

接手后先做：

```powershell
cd E:\code\game-demo
git status --short
python scripts\validate_project.py
python scripts\run_godot_checks.py
```

然后用 Godot 打开：

```powershell
& "F:\download\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64\Godot_v4.5.2-stable_mono_win64.exe" --path "E:\code\game-demo\game-demo"
```

手动确认：

- 主菜单显示正常。
- 新开局能进入角色选择。
- 角色选择能返回和进入灵根选择。
- 进入地图后能点普通战斗。
- 打完怪能进入奖励。
- 图鉴能打开，卡牌/法宝/怪物/词条能显示详情。
