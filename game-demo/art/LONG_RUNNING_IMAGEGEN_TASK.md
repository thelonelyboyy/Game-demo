# 长周期生图任务：国风暗黑修仙美术统一工程

> 2026-07-17 用户方向覆盖：战斗人物与怪物继续使用成熟暗黑国风卡框插画；除此以外的普通卡牌插画统一参考 `art/cards/demonic_cultivator/ai/` 的精致 Q 版风格。卡牌生产仅处理魔修与通用卡，体修、驭兽和剑修暂缓。活动卡图按约 1:1 分为“有 Q 版角色动作”和“无角色的功法/法器/环境概念”，仍需适配现有中央横向插画窗。

## 可直接交给 Codex 的任务正文

你正在维护 Godot 项目 `E:/code/game-demo/game-demo`。请持续执行本任务，直到下面所有阶段完成、素材接入项目并通过验证。不要只给方案或生成少量样例后停止；应按批次不断推进，并把进度写入项目内的清单文件，使上下文压缩或任务恢复后仍能继续。

### 总目标

将当前混用的旧稿、复用图、低清占位图和风格不统一素材，逐步替换为统一的“国风修仙、暗黑肉鸽卡牌”正式美术。

整体视觉要求：

- 国风暗黑修仙，东方志怪和仙魔世界观，不要西式魔幻盔甲堆砌感。
- 画面干净，主体明确，轮廓清楚，背景不喧宾夺主。
- 色调鲜明，在暗色基底上使用朱红、暗金、幽紫、青蓝、翡翠绿等明确色彩重点。
- 高对比但不能一片死黑；缩小到游戏 UI 中仍能快速识别主体。
- 细节精致，材质可信，带水墨气韵、工笔细节与电影级光影，但不要脏乱、灰雾过重或过度写实。
- 所有插画禁止文字、伪文字、数字、Logo、水印、UI 按钮和烘焙边框。
- 不要无意义符文，不要现代物品，不要多余角色，不要畸形肢体和重复武器。

### 执行方式

1. 必须使用内置 `image_gen`，每个不同素材单独调用一次；不要用一张拼图代替多个正式素材。
2. 开始前完整读取 `imagegen` 技能说明，并遵守其保存路径、参考图和透明背景规则。
3. 每批处理 5–8 个素材。每批完成后立即检查画面、移动到项目目录、更新引用并运行验证，再继续下一批。
4. 先生成到带 `_v2` 的兄弟文件，不直接覆盖旧图。新图通过视觉检查和 Godot 加载验证后，才把资源引用切到 `_v2`。
5. 不删除旧图、用户修改或其他未提交文件。所有清理工作留到全部阶段完成后的独立清理步骤。
6. 不为了凑数量接受明显不合格图片。若主体错误、构图脏乱、色调浑浊、出现文字或裁切严重，应只针对失败原因再生成一次。
7. 除非需要启用 CLI 真透明模式、发现无法确定的角色设定或将进行破坏性操作，否则不要停下来等待用户确认。

### 持久化进度

创建并持续更新 `art/imagegen_production_manifest.md`，至少记录：

- `asset_id`
- 中文名称
- 类型
- 原素材路径
- 新素材路径
- 参考图路径
- 最终生图提示词
- 状态：`queued / generated / reviewed / wired / verified / blocked`
- 失败原因和重试次数
- 被哪些 `.tres`、`.tscn` 或 `.gd` 文件引用

每完成一个素材就更新一次状态，不要等整批结束才统一填写。恢复任务时先读取该清单，从第一个非 `verified` 项继续。

## 阶段 0：盘点和生产清单

先重新扫描当前工作区，不要假设旧审计完全正确：

- 用 `rg` 找出所有 `res://art/` 与 `res://assets/` 引用。
- 识别动态加载路径，尤其是 `frame_animation`、选人背景帧和 `CardStyle.FRAME_ROOT`，不得把它们误判为未使用。
- 从 EnemyStats、CharacterStats、Card、Relic、Status、事件场景中提取中文名称、描述、现有图片和引用关系。
- 检查工作区已有修改，绝不回滚用户改动。
- 把所有待生产素材写入 manifest，再开始生图。

## 阶段 1：战斗人物与怪物竖版图

### 范围

为 4 个玩家职业和所有当前 EnemyStats 生成统一的竖版战斗人物图，目标约 43 张。即使多个敌人当前共用一张立绘，也必须根据各自名称、描述、战斗机制生成独立形象。

优先拆分这些复用组：

- `shadow_reaper.png` 对应的 6 个不同敌人。
- `blood_tiger.png` 对应的 4 个不同敌人。
- `bronze_puppet.png` 对应的 3 个不同敌人。
- `paper_soldier.png`、`iron_golem.png`、`ash_imp.png`、`venom_moth.png`、`grave_lantern.png`、`jade_spider.png` 的复用对象。

### 参考图

风格参考：

- `art/ui/battle_cards/demonic_cultivator_card.png`
- `art/ui/battle_cards/abyssal_sword_soul_card.png`
- `art/ui/battle_cards/bull_demon_card.png`
- `art/characters_redesign/_character_redesign_contact_sheet.png`
- `art/enemies_redesign/_enemy_redesign_contact_sheet.png`

主体身份参考：

- 对应的 `art/enemies_redesign/*.png`
- 对应 EnemyStats 的 `display_name`、`description` 和战斗机制
- 对应 CharacterStats 的职业描述和现有立绘

### 输出

- 玩家：`art/combatants/players/<id>_battle_portrait_v2.png`
- 敌人：`art/combatants/enemies/<id>_battle_portrait_v2.png`
- 竖版 2:3，建议生成构图为 1024×1536。
- 完整主体占画面 55%–78%，脸部或核心特征清楚，头顶和武器不被裁断。
- 使用与角色相关的简洁暗色场景背景，不要透明底，不要画卡框。
- 给血量、护甲、状态和技能 UI 留出下方约 20% 的低细节区域。

### 单张提示词模板

```text
Use case: stylized-concept
Asset type: vertical battle combatant portrait for a dark Chinese xianxia roguelike card game
Primary request: 为“{中文名称}”绘制独立战斗人物插画；根据设定“{描述和机制摘要}”准确表现身份、武器、功法和气质
Input images: Image 1: subject identity reference; Image 2: battle portrait style reference
Scene/backdrop: 简洁、低细节的东方修仙战场或秘境背景，与角色属性呼应
Subject: 单一角色或怪物，完整轮廓，明确的东方修仙设计语言
Style/medium: 国风暗黑修仙卡牌插画，工笔细节结合水墨气韵，电影级游戏概念绘制
Composition/framing: 2:3 竖版，单一主体居中或轻微动态构图，主体占画面 55%–78%，下方保留低细节 UI 安全区
Lighting/mood: 暗色环境中有清晰轮廓光和属性色高光，威严、危险、磅礴
Color palette: 深墨黑和暗金为基底，使用与角色机制匹配的鲜明朱红、幽紫、青蓝或翡翠色重点
Constraints: 保持画面干净、色调鲜明、主体可读；无文字、无伪文字、无数字、无 Logo、无水印、无 UI、无卡框；不裁头、不裁核心武器
Avoid: 西式通用奇幻设计、多人场景、杂乱法阵、灰雾糊成一片、过暗看不清、畸形肢体、重复武器
```

### 接入要求

- 优先让 `battle_combatant_card.gd` 从 CharacterStats/EnemyStats 读取统一竖版图，减少针对少数 ID 的硬编码映射。
- 保留现有血量、护甲、状态、技能和意图 UI 行为。
- 战斗牌保持接近三国杀人物牌的纵向比例，不烘焙任何动态数据。
- 图鉴和战斗可共用同一张正式竖版人物图，但不同实体不能再共用同一张图。

## 阶段 2：体修与驭兽卡牌插画

### 范围

替换以下目录中约 40 张 256×256 低清占位图：

- `art/cards/body_cultivator/*.png`
- `art/cards/beastmaster/*.png`

### 参考图

- `art/cards/sword_cultivator/ai/*.png`
- `art/cards/demonic_cultivator/ai/*.png`
- 当前卡牌 `.tres` 的中文名称、描述、消耗和效果

### 输出

- `art/cards/body_cultivator/ai/<id>_v2.png`
- `art/cards/beastmaster/ai/<id>_v2.png`
- 竖版 3:4 或 2:3，优先 1024×1536，并确保核心动作在卡图裁切区域内。
- 每张卡表达一个清楚动作或概念，不要把卡牌说明文字画进图片。

体修视觉重点：肉身淬炼、金身、血气、骨骼、山岳、拳掌、护体罡气；避免现代健身和西式格斗。

驭兽视觉重点：御兽法印、灵兽协同、山林追猎、兽潮、灵契；灵兽必须是东方灵兽语汇，避免普通宠物照和西式驯兽师。

## 阶段 3：法宝独立图标

### 范围

86 个法宝当前只使用 44 张图标。为所有复用对象补独立图，预计约 42 张。

优先处理：

- 共用 `star_compass.png` 的 5 个法宝。
- 共用 `fire_spark_pearl.png` 的 5 个法宝。
- 共用 `fate_ledger.png`、`mana_potion.png`、`jade_abacus.png`、`lotus_mirror.png` 的各 4 个法宝。

### 参考图和输出

- 风格参考：`art/relics/icons/*.png`
- 设定来源：对应 `relics/*.tres` 的名称、描述和机制。
- 输出：`art/relics/icons/<id>_v2.png`
- 正方形 512×512 风格构图，单个法宝居中，轮廓清楚，暗色圆形或方形底，不要求透明。
- 同系列法宝可以共享材质语言，但形状、核心符号和主色必须可区分。
- 禁止文字、标签、手持人物和复杂场景。

## 阶段 4：事件共享插图拆分

为以下三个事件生成独立插图：

- `blood_script_wall_event`，不能继续使用 `silent_demon_sutra.png`。
- `soul_auction_event`，不能继续使用 `demon_market_dusk.png`。
- `heaven_flame_eye_event`，不能继续使用 `starfall_pillar.png`。

参考 `art/event_illustrations/` 中现有插图。输出 16:9 横版，目标 1672×941；继续遵守“画面干净、色调鲜明、主体明确、无文字无边框”。完成后更新对应事件场景的 `event_illustration`。

## 阶段 5：背景统一

至少生成并接入：

- 暗黑战斗背景，替代临时路径 `test2.png`。
- 通用选人背景，替代临时路径 `test1.png`。
- 体修职业选人背景。
- 驭兽职业选人背景。

输出到 `art/backgrounds/`，使用明确英文蛇形命名。背景为 16:9 横版，主体平台和角色站位区域必须干净，左右及底部留出 UI 安全区。禁止把标题、按钮、菜单或文字烘焙进图中。

战斗背景需要磅礴大气、暗黑、具有东方仙魔战场尺度，但亮度应足以衬托人物牌，不能与角色争夺视觉焦点。

## 阶段 6：意图和状态图标补全

检查 `Intent.Category` 和全部 Status：

- 为仍由 `intent_ui.gd` 代码画线的攻防、削弱、蓄力、召唤、治疗、逃跑、睡眠、未知等类别生成正式图标。
- 拆分明显语义不同却共用图标的状态，例如流血、煞气、虚弱，以及暴露、易伤、脆弱。
- 输出 196×196 或 256×256 的清晰小图标，使用统一暗金边框和鲜明属性色。
- 小图标允许使用不透明暗色徽章底，避免复杂透明抠图流程。

## 每张图的视觉验收

生成后必须实际查看图片，逐项检查：

- 主体与资源名称、描述和机制一致。
- 主体只有一个明确视觉焦点。
- 暗部仍有层次，缩略图中可辨识。
- 色彩重点鲜明，不是灰褐一片或全紫一片。
- 没有文字、伪文字、Logo、水印和 UI 元素。
- 没有畸形手脚、重复武器、断裂轮廓、错误物种或明显现代元素。
- 构图适合实际 UI 裁切，不遮挡动态信息区域。
- 同批素材风格一致，但不同实体仍有明确差异。

不合格时只改变一个主要问题再重试，并把失败原因写入 manifest。

## 工程接入与验证

每批图片通过视觉检查后：

1. 将最终图片保存到规定的项目路径，不能只留在 Codex 默认生成目录。
2. 保留原图，使用 `_v2` 路径更新相关 `.tres`、`.tscn` 或 `.gd`。
3. 运行 Godot 导入或无头编辑器导入，确保产生有效导入记录。
4. 运行 `python scripts/validate_project.py`；若脚本路径或运行方式变化，先检查仓库现状。
5. 运行对应 Godot 场景的无头加载检查。
6. 对战斗、选人、图鉴、事件至少各制作一次实际截图，检查缩放、裁切、重叠和风格一致性。
7. 检查 `git diff --check`，不得改动或回滚无关文件。
8. 将 manifest 中对应素材标为 `verified` 后继续下一项。

## 完成条件

只有同时满足以下条件才算完成任务：

- 4 个职业和所有敌人都有独立、统一规格的竖版战斗图。
- 体修和驭兽的 40 张低清卡图全部替换并接入。
- 所有当前复用法宝都有独立图标。
- 三个共享事件图已经拆分。
- `test1.png`、`test2.png` 不再被运行时代码引用。
- 主要意图和语义不同的状态不再依赖代码线条或错误共用图标。
- 所有新素材都存在于项目目录、已接入、可被 Godot 加载。
- 战斗、选人、图鉴、事件截图均通过视觉检查。
- manifest 中没有 `queued / generated / reviewed / wired` 项；只有 `verified`，或附带明确原因的 `blocked`。

完成后给出简洁总结：生成数量、替换数量、仍阻塞项、主要路径、验证结果和建议清理但尚未删除的旧素材。不要在任务完成前因为单批成功就结束。
