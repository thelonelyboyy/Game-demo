# 《万劫求仙》调试控制台使用手册

更新时间：2026-07-16
适用工程：`E:\code\game-demo\game-demo`

## 1. 开启与关闭

进入一局游戏的 Run 场景后，按：

```text
Ctrl + `（反引号）
```

即可打开或关闭调试控制台。

> 不要使用 F8。Godot 编辑器运行游戏时，F8 会直接停止项目。

输入 `help` 或 `帮助` 可以在控制台内查看命令概要。

### 输入框快捷键

| 快捷键 | 功能 |
|---|---|
| `↑` / `↓` | 浏览最近输入过的命令 |
| `Tab` | 补全命令；有多个候选时显示候选列表 |
| `Ctrl + L` | 清空控制台输出 |
| `Esc` | 关闭控制台 |
| `Ctrl + 反引号` | 打开或关闭控制台 |

## 2. 使用约定

- 命令、ID 和参数之间使用空格分隔。
- 卡牌、手牌和敌人的序号从 `0` 开始。
- 资源操作优先使用稳定 ID；中文名称也可使用。
- 模糊搜索只有在结果唯一时才会自动匹配。结果不唯一时，先用资源库命令筛选。
- 大部分修改立即作用于当前游戏状态，但不会自动保存；需要保留时执行 `save`。
- 控制台不会绕过所有游戏规则。例如重复法宝、互斥法宝和已满的丹药栏仍会受到原规则限制。

## 3. 运行状态与基础资源

### 查看当前状态

```text
status
状态
```

显示角色生命、护体、灵力、灵根阶段、牌组、灵石、难度、章节、地图进度和战斗牌堆状态。

### 生命

```text
hp set 80
hp add 10
hp heal 10
hp damage 20
hp max 120
```

中文示例：

```text
生命 设置 80
生命 治疗 10
生命 伤害 20
生命 上限 120
```

说明：

- `set`：直接设置当前生命。
- `add` / `heal`：恢复生命。
- `damage`：扣除生命，但调试命令本身不会把角色降到 0。
- `max`：修改最大生命；最大生命增加时当前生命也会同步增加差值。

### 护体

```text
block set 20
block add 10
block clear
```

中文示例：

```text
护体 设置 20
护体 增加 10
护体 清空
```

### 灵力

```text
mana set 5
mana add 2
mana fill
```

中文示例：

```text
灵力 设置 5
灵力 增加 2
灵力 填满
```

`fill` 会恢复到角色的正常灵力上限；`set` 可以用于测试超出正常上限的情况。

### 灵石

```text
gold set 500
gold add 100
gold remove 50
```

中文示例：

```text
灵石 设置 500
灵石 增加 100
灵石 减少 50
```

## 4. 卡牌与牌组

### 查看当前牌组

```text
deck
card list
牌组
```

输出格式为：

```text
[序号] 卡牌ID  卡牌中文名
```

### 搜索卡牌库

```text
cards
cards demon
cards 血
卡牌库 火
```

卡牌库会显示卡牌 ID、中文名、费用、类型、元素和关键词。结果超过 60 条时应增加筛选词。

### 向永久牌组加入卡牌

```text
card add demon_strike
card add demon_strike 3
卡牌 添加 demon_strike 3
```

此命令修改角色的永久牌组。若正在战斗，新卡不会自动出现在当前手牌或已生成的抽牌堆中；战斗内测试请使用 `hand add`。

### 删除牌组卡牌

```text
card remove 0
card remove demon_strike 2
卡牌 删除 0
```

可以使用牌组序号、卡牌 ID 或完整中文名。带有“永恒”等禁止删除规则的卡牌仍不会被删除。

### 突破卡牌

```text
card upgrade 0
card upgrade demon_strike 2
卡牌 突破 0
```

只会选择仍可突破的卡牌。已经突破或配置为不可突破的卡牌不会再次突破。

### 融合卡牌

```text
card fuse 0 1
card fuse demon_strike demon_defend
卡牌 融合 0 1
```

融合仍遵循当前融合配方、职业和关键词限制。

## 5. 战斗手牌

这些命令只在战斗中可用。

### 查看手牌

```text
hand list
手牌 列表
```

### 直接加入手牌

```text
hand add demon_strike
hand add demon_strike 3
手牌 添加 demon_strike 3
```

加入的卡牌只存在于当前战斗手牌，不会自动加入永久牌组。

### 从抽牌堆抽牌

```text
hand draw 1
hand draw 5
手牌 抽牌 5
```

仍受 10 张手牌上限、抽牌堆和弃牌堆洗牌规则影响。

### 弃置手牌

```text
hand discard 0
hand discard demon_strike
hand discard all
手牌 弃置 全部
```

此命令会把卡牌放入弃牌堆，并触发正常的弃置生命周期效果。

### 无效果清空手牌

```text
hand clear
手牌 清空
```

该命令仅移除当前手牌，不触发弃置效果，适合快速布置测试场景。

## 6. 敌人与回合

### 查看敌人

```text
enemy list
敌人 列表
```

显示敌人序号、ID、中文名、生命、护体和当前意图。

### 对敌人造成伤害

```text
enemy damage 0 20
enemy damage all 20
敌人 伤害 0 20
敌人 伤害 全部 20
```

该伤害经过敌人的现行承伤修正，并播放正常受击、飘字和死亡表现。

### 击杀敌人

```text
enemy kill 0
enemy kill all
敌人 击杀 全部
```

击杀会沿用正常敌人死亡和战斗胜利结算流程。

### 刷新敌人意图

```text
enemy intent
敌人 意图
```

重新选择并刷新全部存活敌人的当前行动意图。

### 检查回合状态

```text
turn status
回合 状态
```

显示战斗是否运行、玩家操作是否解锁，以及抽牌/弃牌动画是否仍在执行。

### 恢复玩家操作

```text
turn unlock
回合 解锁
回合 开启操作
```

用于调试结束回合按钮或手牌意外锁定的情况。它会重新启用玩家操作和手牌，但不会伪造新的回合开始事件。

### 结束玩家回合

```text
turn end
回合 结束
```

按正常回合信号结束当前玩家回合。若当前回合仍处于锁定状态，应先检查 `turn status`，必要时使用 `turn unlock`。

## 7. 下一次伤害修正

### 修改下一次造成的伤害

```text
next dealt set 30
next dealt add 10
```

- `set 30`：下一次伤害直接设为 30。
- `add 10`：下一次伤害在原数值基础上增加 10。

### 修改下一次受到的伤害

```text
next taken set 30
next taken add 10
```

### 查看或清除设置

```text
next
next clear
```

“下一次”修正成功应用一次后会自动清除。它适合验证伤害倍率、护体、灵根圆满和法宝触发。

## 8. 法宝与丹药符箓

### 法宝

```text
relic list
relic library
relic library 魔
relic add demon_soul_censer
relic remove demon_soul_censer
```

中文命令：

```text
法宝 列表
法宝 资源库 魔
法宝 添加 demon_soul_censer
法宝 删除 demon_soul_censer
```

说明：

- `list` 查看当前持有法宝。
- `library [筛选]` 查看全部法宝 ID 和中文名。
- `add` 仍遵循重复法宝和互斥组限制。
- `remove` 可以使用持有法宝的 ID 或完整中文名。

### 丹药与符箓

```text
potion list
potion library
potion library 丹
potion add healing_pill
potion remove 0
potion clear
```

中文命令：

```text
丹药 列表
符箓 资源库 火
丹药 添加 healing_pill
丹药 删除 0
丹药 清空
```

丹药栏仍受 3 个槽位的上限限制。

## 9. 地图

### 查看地图状态

```text
map status
地图 状态
```

### 解锁节点

```text
map unlock
map unlock 5
map unlock all
地图 解锁 全部
```

- 不填写参数时解锁当前层。
- 数字参数使用内部层索引，从 `0` 开始。
- `all` / `全部` 解锁当前章节的全部地图节点。

### 自由导航

```text
map free on
map free off
地图 自由 开
地图 自由 关
```

开启后所有节点可以直接选择，适合测试商店、事件、精英或 Boss。关闭自由导航不会自动重新锁回已经解锁的节点；需要验证正式路线时建议重新开局或重新生成地图。

### 返回地图

```text
map show
地图 显示
```

关闭当前房间界面并返回地图。

## 10. 事件

### 查看事件库

```text
event list
event list 1
event list 2
event list 3
event list 血
事件 列表 3
```

控制台索引当前全部 45 个事件，显示章节、稳定 ID 和中文标题。

### 直接打开指定事件

```text
event open helpful_boi
event open 血月祭坛
事件 打开 blood_moon_shrine
```

建议优先使用 `event list` 输出的稳定 ID。直接打开事件不会增加地图层数；它只用于测试事件界面、选项和效果。

### 随机打开某章事件

```text
event random
event random 2
事件 随机 3
```

不填写章节时使用当前章节。

## 11. 难度、资源刷新与保存

### 查看或设置难度

```text
difficulty
difficulty set 10
难度 设置 10
```

范围为 `0–15`。中途修改只影响之后生成的敌人和房间，不会回溯修改已经生成的当前敌人。

### 刷新资源索引

```text
reload
刷新
```

新增或修改卡牌、法宝、丹药、符箓、事件资源后，可用此命令重新扫描，无需重开整局。新增文件仍需先由 Godot 完成资源导入。

### 手动保存

```text
save
保存
```

把当前角色、牌组、法宝、丹药、地图和轮回状态写入继续游戏存档。

### 清空控制台输出

```text
clear
清屏
```

只清空屏幕输出，不会撤销任何调试修改，也不会清除命令历史。

## 12. 常用测试流程

### 快速测试某张卡牌

```text
cards 关键词或名称
hand clear
hand add 卡牌ID
mana fill
turn unlock
```

### 测试护体后扣血的飘字顺序

```text
护体 设置 10
next taken set 15
```

随后让敌人攻击。应依次播放“护体 -10”和实际扣血数字。

### 快速进入某个事件

```text
event list 章节号
event open 事件ID
```

### 快速验证 Boss 或精英路线

```text
map show
map free on
```

然后直接选择目标节点。

### 排查结束回合失效

```text
turn status
turn unlock
```

先记录 `turn status` 的输出，再使用 `turn unlock` 恢复操作。若问题可以稳定复现，应保留复现步骤，不要只依赖解锁命令掩盖问题。

## 13. 相关文件

- 控制台实现：`game-demo/scenes/debug/debug_console.gd`
- 跨系统调试状态：`game-demo/custom_resources/debug_console_state.gd`
- 控制台定向测试：`game-demo/test_data/debug_console_smoke.gd`
- Run 接入位置：`game-demo/scenes/run/run.gd`
- 项目交接文档：`HANDOFF.md`
