# Imagegen Production Manifest

> 恢复规则：优先读取 `art/q_card_imagegen_manifest.md` 并继续魔修与通用 Q 版卡图；本文件旧 P2 体修/驭兽段已被用户暂停，不再作为恢复入口。每项生成后立即填入最终提示词并更新状态。

## Summary

| Phase | Scope | Queued | Verified | Blocked |
|---|---|---:|---:|---:|
| P1 | 战斗人物与敌人卡框插画 | 0 | 42 | 1 |
| P2 | 体修与驭兽卡图（用户暂停） | 0 | 0 | 40 |
| P2Q | 魔修与通用Q版卡图（见独立清单） | 0 | 50 | 0 |
| P3 | 法宝独立图标 | 0 | 42 | 0 |
| P4 | 事件共享插图拆分 | 0 | 3 | 0 |
| P5 | 背景统一 | 0 | 4 | 0 |
| P6 | 意图与状态图标 | 0 | 16 | 0 |
| **Total** |  | **0** | **157** | **41** |

字段缩写：`old` 原素材，`new` 新素材，`ref` 风格参考，`use` 消费资源，`prompt` 最终提示词。

### Final Consolidated Verification

- 执行策略：按用户要求停止每五张小测，全部生成与接入完成后统一测试。
- 静态资源审计：P3-P6 共 65 项，文件、引用与尺寸检查 `ROWS=65 FAIL=0`。
- Godot 验证：两轮资源导入、无头运行、`git diff --check` 均返回 0；活动代码无 `test1.png` / `test2.png` 临时引用。
- 运行截图：`art/qa/final_selector_runtime.png`、`art/qa/final_battle_runtime.png`、`art/qa/final_compendium_runtime.png`、`art/qa/final_event_runtime.png`。
- 审计日志：`art/qa/final_active_asset_audit.log`、`art/qa/final_import.log`、`art/qa/final_runtime.log`、`art/qa/final_diff_check.log`。
- 建议清理但尚未删除：`test1.png`、`test2.png`，以及 `art/tmp/` 下 400 张无活动引用的过程 PNG；删除前建议保留最终 QA 联系表和失败重试稿。
- 暂停项草稿：`art/cards/body_cultivator/ai/` 下 8 张图片无活动引用，可在确认不恢复 P2 后归档或删除。
- 不可直接删除：`art/characters_redesign/` 与 `art/enemies_redesign/` 仍有 43 处活动资源引用，继续供图鉴或基础立绘使用。

### P1 Shared Prompt Rule

P1 是放入战斗人物牌和怪物牌框内部的插画，不是独立全身立绘。统一采用类似三国杀人物牌的半身或三分之二身构图：头脸或核心特征清晰放大，主体占画面 72%–88%，头部位于上方 12%–22%，四周预留 8%–12% 裁切余量；武器、手势、角、耳、翅膀等识别特征必须收在中央 80% 安全区。画面保持国风修仙暗黑、色调鲜明、背景简洁干净；不得烘焙卡框、UI、文字、标志或水印，不保留旧版底部 UI 空区，也不得生成主体偏小的全身海报构图。

## P1 Combatant Portraits

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| beastmaster | 驭兽师 | player | `art/characters_redesign/beastmaster_portrait.png` | `art/combatants/players/beastmaster_card_portrait_v3.png` | `art/ui/battle_cards/demonic_cultivator_card.png` | verified | 0 | `characters/beastmaster/beastmaster.tres` | 三国杀式卡框内三分之二身；保留绿白汉服、皮毛披肩、铜铃链与翡翠灵契，脸部和双手放大，核心道具全部收在中央安全区，月夜山林背景简洁鲜明。 |
| body_cultivator | 体修 | player | `art/characters_redesign/body_cultivator_portrait.png` | `art/combatants/players/body_cultivator_card_portrait_v3.png` | `art/ui/battle_cards/demonic_cultivator_card.png` | verified | 0 | `characters/body_cultivator/body_cultivator.tres` | 三国杀式卡框内半身；赤黑战衣、双拳与金色淬体裂纹近景突出，脸部和双拳均在中央安全区，夜山炼体台背景压低细节。 |
| demonic_cultivator | 魔修 | player | `art/characters/demonic_cultivator_portrait.png` | `art/combatants/players/demonic_cultivator_card_portrait_v3.png` | `art/ui/battle_cards/demonic_cultivator_card.png` | verified | 0 | `characters/demonic_cultivator/demonic_cultivator.tres` | 三国杀式卡框内三分之二身；银黑冠、紫黑朱红魔门礼服与掌中紫焰近景突出，头冠和施法手完整收在中央安全区，祭坛背景简洁。 |
| sword_cultivator | 剑修 | player | `art/characters/sword_cultivator_portrait.png` | `art/combatants/players/sword_cultivator_card_portrait_v3.png` | `art/ui/battle_cards/demonic_cultivator_card.png` | verified | 0 | `characters/sword_cultivator/sword_cultivator.tres` | 三国杀式卡框内三分之二身；银发白蓝剑装近景，握剑手、剑柄和竖向冰蓝长剑完整可读，月夜高山剑台背景简洁。 |
| abyssal_sword_soul | 渊狱剑魂 | enemy | `art/enemies_redesign/abyssal_sword_soul.png` | `art/combatants/enemies/abyssal_sword_soul_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/abyssal_sword_soul/abyssal_sword_soul_enemy.tres` | 首稿背景出现伪书法后重试；卡框内近景半身，黑漆魂甲、鬼面盔与单柄幽蓝巨剑占满中央，纯雾化剑冢背景无文字。 |
| ash_imp | 劫灰小鬼 | enemy | `art/enemies_redesign/ash_imp.png` | `art/combatants/enemies/ash_imp_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/ash_imp/ash_imp_enemy.tres` | 怪物卡框内近景三分之二身；焦炭岩皮、橙色眼、尖耳与双前爪占满画面，炼丹炉窟背景简洁，黑灰与余烬橙对比鲜明。 |
| ash_sutra_monk | 灰经邪僧 | enemy | `art/enemies_redesign/paper_soldier.png` | `art/combatants/enemies/ash_sutra_monk_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/ash_sutra_monk/ash_sutra_monk_enemy.tres` | 怪物卡框内三分之二身；破斗笠、焦黑袈裟、灰金胸蚀、经笔与念珠近景完整，烧毁石庭背景无文字且低细节。 |
| silver_moon_wolf | 银月狼 | enemy | `art/enemies_redesign/silver_moon_wolf.png` | `art/combatants/enemies/silver_moon_wolf_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/bat/bat_enemy.tres` | 兽类卡框近景；银白狼首、弯月额印、冰蓝眼、胸肩与双前爪占满画面，后躯自然裁出，月夜寒林背景干净鲜明。 |
| black_lotus_matriarch | 黑莲圣母 | enemy | `art/enemies_redesign/black_lotus_matriarch.png` | `art/combatants/enemies/black_lotus_matriarch_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/black_lotus_matriarch/black_lotus_matriarch_enemy.tres` | 卡框内三分之二身；黑紫莲冠、胸口黑莲与双手业火近景完整，血月莲池背景简洁，紫红金三色鲜明。 |
| blood_moon_alpha | 血月狼王 | enemy | `art/enemies_redesign/blood_tiger.png` | `art/combatants/enemies/blood_moon_alpha_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/blood_moon_alpha/blood_moon_alpha_enemy.tres` | 兽类卡框近景；黑狼王仰首长啸，暗红鬃毛、猩红眼与血气声浪突出，血月山岭背景低细节。 |
| blood_moon_demon_king | 血月妖王 | enemy | `art/enemies_redesign/blood_tiger.png` | `art/combatants/enemies/blood_moon_demon_king_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/blood_moon_demon_king/blood_moon_demon_king_enemy.tres` | Boss卡框内三分之二身；黑狼妖皇、暗金骨冠、黑甲血袍与双爪血气完整，血月妖宫背景简洁。 |
| blood_revenant | 饮血尸傀 | enemy | `art/enemies_redesign/blood_tiger.png` | `art/combatants/enemies/blood_revenant_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/blood_revenant/blood_revenant_enemy.tres` | 卡框内近景半身；青灰炼尸、黑红裹尸战袍、胸口吸血核心与双骨爪完整，墓道背景无文字。 |
| blood_rite_acolyte | 血祭童子 | enemy | `art/enemies_redesign/ash_imp.png` | `art/combatants/enemies/blood_rite_acolyte_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/blood_rite_acolyte/blood_rite_acolyte_enemy.tres` | 卡框内动态半身；成年祭侍、黑红祭服、额心血珠与双拳血气近景突出，血祭石坛背景干净。 |
| blood_tiger | 血纹虎 | enemy | `art/enemies_redesign/blood_tiger.png` | `art/combatants/enemies/blood_tiger_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/blood_tiger/blood_tiger_enemy.tres` | 兽类卡框近景；黑红血纹巨虎、猩红眼、发光抓痕与双前爪占满画面，夜山古道背景简洁。 |
| bronze_corpse_king | 铜甲尸王 | enemy | `art/enemies_redesign/iron_golem.png` | `art/combatants/enemies/bronze_corpse_king_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/bronze_corpse_king/bronze_corpse_king_enemy.tres` | Boss卡框内近景半身；尸王冠、铜黑重甲、翡翠尸火、熔甲裂光与巨大双拳完整，地下王陵背景无字。 |
| bronze_overseer | 铜傀督军 | enemy | `art/enemies_redesign/bronze_puppet.png` | `art/combatants/enemies/bronze_overseer_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/bronze_overseer/bronze_overseer_enemy.tres` | 机关卡框内三分之二身；高冠铜傀督军、猩红胸核、巨大双拳与两面无字短旗清晰，军阵背景压低细节。 |
| bronze_puppet | 铜傀儡 | enemy | `art/enemies_redesign/bronze_puppet.png` | `art/combatants/enemies/bronze_puppet_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/bronze_puppet/bronze_puppet_enemy.tres` | 机关卡框内半身；平顶盔、朴素铜甲、翡翠胸核与交叠防御双臂占满画面，宗门石门背景干净。 |
| bull_demon | 牛魔 | enemy | `art/enemies_redesign/bull_demon.png` | `art/combatants/enemies/bull_demon_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/bull_demon/bull_demon.tres` | 怪物卡框内半身；赤红牛首、完整双角、岩甲肩臂与双拳近景突出，山关熔岩背景简洁。 |
| dark_eagle | 幽暗鹰 | enemy | `art/enemies_redesign/dark_eagle.png` | `art/combatants/enemies/dark_eagle_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/crab/crab_enemy.tres` | 首稿翼尖触边后重试；飞禽卡框近景，黑紫鹰首、紧凑后掠双翼、紫眼与双爪完整，月夜远山背景低细节。 |
| eclipse_priest | 蚀魂祭司 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/eclipse_priest_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/eclipse_priest/eclipse_priest_enemy.tres` | 卡框内三分之二身；黯日面具、宽袖祭袍、半月肩饰、单根翡翠魂灯杖与施法手完整，蚀日祭台无字。 |
| eclipse_tyrant | 蚀日妖皇 | enemy | `art/enemies_redesign/eclipse_tyrant.png` | `art/combatants/enemies/eclipse_tyrant_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/eclipse_tyrant/eclipse_tyrant_enemy.tres` | Boss卡框内半身；黑红帝冠、完整蚀日圆环、龙鳞帝甲、胸口日冕核心与抬手姿态清晰。 |
| grave_lantern | 幽冢灯 | enemy | `art/enemies_redesign/grave_lantern.png` | `art/combatants/enemies/grave_lantern_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/grave_lantern/grave_lantern_enemy.tres` | 首稿出现副钩后重试；单一亭檐魂灯、一根S形吊钩、完整底坠与紫色阴火居中，古墓背景无字。 |
| heartpiercer_shade | 剜心魅影 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/heartpiercer_shade_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/heartpiercer_shade/heartpiercer_shade_enemy.tres` | 卡框内三分之二身；银色鬼面、黑红纱衣、恰好两柄穿心刃与双手完整，月夜回廊背景简洁。 |
| heavenly_clerk | 天罚司吏 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/heavenly_clerk_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/heavenly_clerk/heavenly_clerk_enemy.tres` | 卡框内三分之二身；天庭司吏、展翼官帽、雷印与双指雷链近景完整，天罚石阶背景无牌匾文字。 |
| iron_golem | 玄铁傀 | enemy | `art/enemies_redesign/iron_golem.png` | `art/combatants/enemies/iron_golem_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/iron_golem/iron_golem_enemy.tres` | 机关卡框内近景；玄铁圆筒头、炉心、厚肩甲与巨大双拳突出，废弃锻炉背景干净。 |
| jade_spider | 碧玉蛛 | enemy | `art/enemies_redesign/jade_spider.png` | `art/combatants/enemies/jade_spider_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/jade_spider/jade_spider_enemy.tres` | 蛛类卡框近景；碧玉甲壳、毒眼、螯肢与八条节肢围绕主体，紫毒丝和暗洞背景保持低细节。 |
| jade_wyrm | 碧鳞蛟 | enemy | `art/enemies_redesign/jade_wyrm.png` | `art/combatants/enemies/jade_wyrm_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/jade_wyrm/jade_wyrm_enemy.tres` | 蛟类卡框近景；碧鳞蛟首、双角、须髯、前爪与S形盘身完整，紫毒珠与瀑洞色调鲜明。 |
| karma_collector | 业债判吏 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/karma_collector_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/karma_collector/karma_collector_enemy.tres` | 卡框内三分之二身；业债判吏、铁面官帽、空白债牌业环与魂链近景完整，阴司档库无文字。 |
| mist_wolf | 雾隐狼 | enemy | `art/enemies_redesign/mist_wolf.png` | `art/combatants/enemies/mist_wolf_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/mist_wolf/mist_wolf_enemy.tres` | 兽类卡框近景；紫黑雾狼头胸、荧紫眼与双前爪占满画面，后躯消散于山雾。 |
| paper_soldier | 符纸兵 | enemy | `art/enemies_redesign/paper_soldier.png` | `art/combatants/enemies/paper_soldier_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/paper_soldier/paper_soldier_enemy.tres` | 卡框内三分之二身；空白黄纸甲、破纸斗笠、影面双眼、纸爪与短竹枪完整，所有纸面无字。 |
| river_serpent | 寒潭蛇 | enemy | `art/enemies_redesign/river_serpent.png` | `art/combatants/enemies/river_serpent_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/river_serpent/river_serpent_enemy.tres` | 蛇类卡框近景；青碧寒蛇头颈、冰晶、紫舌与紧凑盘身清晰，无角无爪，寒潭背景简洁。 |
| scripture_moth | 噬经毒蛾 | enemy | `art/enemies_redesign/venom_moth.png` | `art/combatants/enemies/scripture_moth_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | blocked | 2 | `enemies/scripture_moth/scripture_moth_enemy.tres` | 两次重试仍未通过硬条件：首稿背景伪刻文；重试1烘焙卡框；重试2翅面出现伪文字。未接入错误稿，需后续定向修图或人工清理。 |
| shadow_reaper | 摄魂影 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/shadow_reaper_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/shadow_reaper/shadow_reaper_enemy.tres` | 首稿镰刃贴边后重试；摄魂影卡框半身，兜帽独眼、黑紫魂袍、短柄竖向镰刀与骨手完整。 |
| sky_palace_guardian | 天阙镇将 | enemy | `art/enemies_redesign/sky_palace_guardian.png` | `art/combatants/enemies/sky_palace_guardian_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 2 | `enemies/sky_palace_guardian/sky_palace_guardian_enemy.tres` | 前两稿分别兵器贴边和背景伪字；最终金甲镇将、龙盔、胸拳与短柄月戟完整，纯雷云山海背景。 |
| spirit_leech | 锁灵灯童 | enemy | `art/enemies_redesign/grave_lantern.png` | `art/combatants/enemies/spirit_leech_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/spirit_leech/spirit_leech_enemy.tres` | 卡框内半身；锁灵灯童为非人面具幽灵，双手抱魂灯，灯内碧绿灵蛭与锁链核心清晰。 |
| stone_goblin | 山魈石怪 | enemy | `art/enemies_redesign/stone_goblin.png` | `art/combatants/enemies/stone_goblin_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/stone_goblin/stone_goblin_enemy.tres` | 怪物卡框近景；山岩猿形头肩、琥珀眼、苔藓与巨大双拳占满画面，月夜山谷背景简洁。 |
| storm_hawk | 雷羽鹰 | enemy | `art/enemies_redesign/storm_hawk.png` | `art/combatants/enemies/storm_hawk_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/storm_hawk/storm_hawk_enemy.tres` | 首稿翼尖触边后重试；雷羽鹰收翼俯冲，蓝黑鹰首、双爪与电羽完整，体型敏捷区别于劫雷鹏。 |
| thunder_roc | 劫雷鹏 | enemy | `art/enemies_redesign/thunder_roc.png` | `art/combatants/enemies/thunder_roc_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/thunder_roc/thunder_roc_enemy.tres` | 首稿冠羽与外翼贴边后重试；劫雷鹏巨型冠羽、厚胸、收拢双翼与巨大雷爪完整，雷云海背景。 |
| bone_dragon | 骨龙 | enemy | `art/enemies_redesign/bone_dragon.png` | `art/combatants/enemies/bone_dragon_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/toxic_ghost/toxic_ghost.tres` | 骨龙卡框盘曲近景；龙首、长角、脊椎、肋骨、双前爪与幽绿魂火完整，暗洞无文字。 |
| underworld_judge | 幽冥判官 | enemy | `art/enemies_redesign/shadow_reaper.png` | `art/combatants/enemies/underworld_judge_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/underworld_judge/underworld_judge_enemy.tres` | Boss卡框半身；赤面长髯判官、黑冠、判笔与完全空白判牒近景完整，双魂灯背景无文字。 |
| venom_broodmother | 万蛊母皇 | enemy | `art/enemies_redesign/jade_spider.png` | `art/combatants/enemies/venom_broodmother_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/venom_broodmother/venom_broodmother_enemy.tres` | Boss蛛类卡框近景；黑紫母皇甲壳、冠刺毒眼、三枚荧绿毒囊、螯肢与前腿完整，巢穴背景简洁；批次6卡框裁切、导入与绑定通过。 |
| venom_moth | 瘴毒蛾 | enemy | `art/enemies_redesign/venom_moth.png` | `art/combatants/enemies/venom_moth_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 0 | `enemies/venom_moth/venom_moth_enemy.tres` | 毒蛾卡框近景；橄榄绿绒身、酸绿复眼、卷曲口器、双翼眼斑与六足完整，毒沼雾背景无字；批次6卡框裁切、导入与绑定通过。 |
| warded_husk | 镇炉甲傀 | enemy | `art/enemies_redesign/bronze_puppet.png` | `art/combatants/enemies/warded_husk_card_portrait_v3.png` | `art/ui/battle_cards/abyssal_sword_soul_card.png` | verified | 1 | `enemies/warded_husk/warded_husk_enemy.tres` | 首稿玉盾出现伪字纹后重试；镇炉甲傀、橙色炉心、交叉双臂与三面纯净无纹六边玉盾完整；批次6卡框裁切、导入与绑定通过。 |

## P2 Body And Beastmaster Cards

> 用户最新要求：本阶段 40 项全部暂停，视为 `blocked`，不再生成或接入。此前生成的 8 张成熟比例体修稿保留为未采用草稿；已接入的 5 张资源引用已恢复旧图。新活动范围转移到 `art/q_card_imagegen_manifest.md`。

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| body_arhat_form | 罗汉法相 | card_body_cultivator | `art/cards/body_cultivator/body_arhat_form.png` | `art/cards/body_cultivator/ai/body_arhat_form_v2.png` | `art/cards/sword_cultivator/ai/sword_furnace_open.png` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_arhat_form.tres` | 成熟光头体修结不动护体式，背后单一巨型暗金罗汉法相展开双掌；实际卡窗裁切、Godot 导入、绑定与运行时加载通过。 |
| body_battle_trance | 浴血战狂 | card_body_cultivator | `art/cards/body_cultivator/body_battle_trance.png` | `art/cards/body_cultivator/ai/body_battle_trance_v2.png` | `art/cards/sword_cultivator/ai/sword_furnace_open.png` | blocked | 1 | `characters/body_cultivator/cards/phase3/body_battle_trance.tres` | 首稿头部高于实际横向卡图裁切区后重构；战吼面部、双拳、赤红血气与暗金裂光进入中央横窗；Godot 导入、绑定与运行时加载通过。 |
| body_blood_collapse | 血崩掌 | card_body_cultivator | `art/cards/body_cultivator/body_blood_collapse.png` | `art/cards/body_cultivator/ai/body_blood_collapse_v2.png` | `art/cards/sword_cultivator/ai/sword_guard_formation.png` | blocked | 2 | `characters/body_cultivator/cards/phase3/body_blood_collapse.tres` | 首稿面部、重试1掌心先后落出卡窗；最终斜推崩掌的面部、护肋手、完整五指与崩岩冲击同窗；Godot 导入、绑定与运行时加载通过。 |
| body_blood_god_body | 血神不灭 | card_body_cultivator | `art/cards/body_cultivator/body_blood_god_body.png` | `art/cards/body_cultivator/ai/body_blood_god_body_v2.png` | `art/cards/sword_cultivator/ai/sword_heart.png` | blocked | 1 | `characters/body_cultivator/cards/phase3/body_blood_god_body.tres` | 首稿头部高于实际卡窗后重构；面部、暗金胸臂、双手和赤红气幕进入中央横窗；Godot 导入、绑定与运行时加载通过。 |
| body_blood_punch | 血炼拳 | card_body_cultivator | `art/cards/body_cultivator/body_blood_punch.png` | `art/cards/body_cultivator/ai/body_blood_punch_v2.png` | `art/cards/sword_cultivator/ai/sword_guard_formation.png` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_blood_punch.tres` | 黑衣体修在山峡侧身出拳，赤红血气紧裹前拳并震裂黑岩，后拳护颌；实际卡窗裁切、Godot 导入、绑定与运行时加载通过。 |
| body_blood_roar | 血吼 | card_body_cultivator | `art/cards/body_cultivator/body_blood_roar.png` | `art/cards/body_cultivator/ai/body_blood_roar_v2.png` | `art/cards/sword_cultivator/ai/sword_guard_formation.png` | blocked | 1 | `characters/body_cultivator/cards/phase3/body_blood_roar.tres` | 首稿误出横版后重试竖版；红黑体修向右怒吼，赤红血气声压横贯中央并震裂城墙，双拳、面部和冲击完整无字。 |
| body_bone_resonance | 筋骨齐鸣 | card_body_cultivator | `art/cards/body_cultivator/body_bone_resonance.png` | `art/cards/body_cultivator/ai/body_bone_resonance_v2.png` | `art/cards/sword_cultivator/ai/sword_heart.png` | blocked | 1 | `characters/body_cultivator/cards/phase3/body_bone_resonance.tres` | 首稿背景出现伪铭牌后定向清除；黑衣体修马步交臂，体内暗金筋骨与青蓝灵息波清楚，纯净木殿无字无符。 |
| body_burn_blood_guard | 燃血护体 | card_body_cultivator | `art/cards/body_cultivator/body_burn_blood_guard.png` | `art/cards/body_cultivator/ai/body_burn_blood_guard_v2.png` | `art/cards/sword_cultivator/ai/sword_guard_formation.png` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_burn_blood_guard.tres` | 红黑体修交臂护胸，燃血裂光沿双臂收束为贴身不对称护罡，面部与交叉前臂居中，夜崖背景干净无字。 |
| body_colossus_gold | 丈六金身 | card_body_cultivator | `art/cards/body_cultivator/body_colossus_gold.png` | `art/cards/body_cultivator/ai/body_colossus_gold_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_colossus_gold.tres` | 待生成 |
| body_copper_skin | 铜皮功 | card_body_cultivator | `art/cards/body_cultivator/body_copper_skin.png` | `art/cards/body_cultivator/ai/body_copper_skin_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_copper_skin.tres` | 待生成 |
| body_crimson_rebirth | 赤血回环 | card_body_cultivator | `art/cards/body_cultivator/body_crimson_rebirth.png` | `art/cards/body_cultivator/ai/body_crimson_rebirth_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_crimson_rebirth.tres` | 待生成 |
| body_golden_bell_step | 金钟步 | card_body_cultivator | `art/cards/body_cultivator/body_golden_bell_step.png` | `art/cards/body_cultivator/ai/body_golden_bell_step_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_golden_bell_step.tres` | 待生成 |
| body_guard_meridian | 护脉手 | card_body_cultivator | `art/cards/body_cultivator/body_guard_meridian.png` | `art/cards/body_cultivator/ai/body_guard_meridian_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_guard_meridian.tres` | 待生成 |
| body_immovable_king | 不动明王 | card_body_cultivator | `art/cards/body_cultivator/body_immovable_king.png` | `art/cards/body_cultivator/ai/body_immovable_king_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_immovable_king.tres` | 待生成 |
| body_iron_bone | 铁骨立 | card_body_cultivator | `art/cards/body_cultivator/body_iron_bone.png` | `art/cards/body_cultivator/ai/body_iron_bone_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_iron_bone.tres` | 待生成 |
| body_life_furnace | 命炉吐纳 | card_body_cultivator | `art/cards/body_cultivator/body_life_furnace.png` | `art/cards/body_cultivator/ai/body_life_furnace_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_life_furnace.tres` | 待生成 |
| body_mountain_stance | 山岳立身 | card_body_cultivator | `art/cards/body_cultivator/body_mountain_stance.png` | `art/cards/body_cultivator/ai/body_mountain_stance_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_mountain_stance.tres` | 待生成 |
| body_rebound_guard | 护体反震 | card_body_cultivator | `art/cards/body_cultivator/body_rebound_guard.png` | `art/cards/body_cultivator/ai/body_rebound_guard_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_rebound_guard.tres` | 待生成 |
| body_red_marrow | 赤髓劲 | card_body_cultivator | `art/cards/body_cultivator/body_red_marrow.png` | `art/cards/body_cultivator/ai/body_red_marrow_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_red_marrow.tres` | 待生成 |
| body_wound_power | 伤势化劲 | card_body_cultivator | `art/cards/body_cultivator/body_wound_power.png` | `art/cards/body_cultivator/ai/body_wound_power_v2.png` | `art/cards/sword_cultivator/ai` | blocked | 0 | `characters/body_cultivator/cards/phase3/body_wound_power.tres` | 待生成 |
| beast_all_king | 百兽朝宗 | card_beastmaster | `art/cards/beastmaster/beast_all_king.png` | `art/cards/beastmaster/ai/beast_all_king_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_all_king.tres` | 待生成 |
| beast_alpha_order | 兽王号令 | card_beastmaster | `art/cards/beastmaster/beast_alpha_order.png` | `art/cards/beastmaster/ai/beast_alpha_order_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_alpha_order.tres` | 待生成 |
| beast_ancestor_arrives | 祖灵降临 | card_beastmaster | `art/cards/beastmaster/beast_ancestor_arrives.png` | `art/cards/beastmaster/ai/beast_ancestor_arrives_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_ancestor_arrives.tres` | 待生成 |
| beast_call_fox | 唤狐 | card_beastmaster | `art/cards/beastmaster/beast_call_fox.png` | `art/cards/beastmaster/ai/beast_call_fox_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_call_fox.tres` | 待生成 |
| beast_crane_wing | 鹤翼引 | card_beastmaster | `art/cards/beastmaster/beast_crane_wing.png` | `art/cards/beastmaster/ai/beast_crane_wing_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_crane_wing.tres` | 待生成 |
| beast_double_summon | 双灵并起 | card_beastmaster | `art/cards/beastmaster/beast_double_summon.png` | `art/cards/beastmaster/ai/beast_double_summon_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_double_summon.tres` | 待生成 |
| beast_fang_chain | 连牙 | card_beastmaster | `art/cards/beastmaster/beast_fang_chain.png` | `art/cards/beastmaster/ai/beast_fang_chain_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_fang_chain.tres` | 待生成 |
| beast_feed_spirit | 饲灵 | card_beastmaster | `art/cards/beastmaster/beast_feed_spirit.png` | `art/cards/beastmaster/ai/beast_feed_spirit_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_feed_spirit.tres` | 待生成 |
| beast_horn_line | 兽角阵 | card_beastmaster | `art/cards/beastmaster/beast_horn_line.png` | `art/cards/beastmaster/ai/beast_horn_line_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_horn_line.tres` | 待生成 |
| beast_moon_swarm | 月下兽潮 | card_beastmaster | `art/cards/beastmaster/beast_moon_swarm.png` | `art/cards/beastmaster/ai/beast_moon_swarm_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_moon_swarm.tres` | 待生成 |
| beast_mount_charge | 御兽冲阵 | card_beastmaster | `art/cards/beastmaster/beast_mount_charge.png` | `art/cards/beastmaster/ai/beast_mount_charge_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_mount_charge.tres` | 待生成 |
| beast_pack_guard | 兽群护阵 | card_beastmaster | `art/cards/beastmaster/beast_pack_guard.png` | `art/cards/beastmaster/ai/beast_pack_guard_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_pack_guard.tres` | 待生成 |
| beast_pack_howl | 群嚎 | card_beastmaster | `art/cards/beastmaster/beast_pack_howl.png` | `art/cards/beastmaster/ai/beast_pack_howl_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_pack_howl.tres` | 待生成 |
| beast_pack_pounce | 群兽扑击 | card_beastmaster | `art/cards/beastmaster/beast_pack_pounce.png` | `art/cards/beastmaster/ai/beast_pack_pounce_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_pack_pounce.tres` | 待生成 |
| beast_sacred_nest | 灵巢护主 | card_beastmaster | `art/cards/beastmaster/beast_sacred_nest.png` | `art/cards/beastmaster/ai/beast_sacred_nest_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_sacred_nest.tres` | 待生成 |
| beast_spirit_tide | 万灵潮 | card_beastmaster | `art/cards/beastmaster/beast_spirit_tide.png` | `art/cards/beastmaster/ai/beast_spirit_tide_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_spirit_tide.tres` | 待生成 |
| beast_ten_thousand_charge | 万兽奔雷 | card_beastmaster | `art/cards/beastmaster/beast_ten_thousand_charge.png` | `art/cards/beastmaster/ai/beast_ten_thousand_charge_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_ten_thousand_charge.tres` | 待生成 |
| beast_track_hunt | 寻迹猎杀 | card_beastmaster | `art/cards/beastmaster/beast_track_hunt.png` | `art/cards/beastmaster/ai/beast_track_hunt_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_track_hunt.tres` | 待生成 |
| beast_turtle_guard | 玄龟守 | card_beastmaster | `art/cards/beastmaster/beast_turtle_guard.png` | `art/cards/beastmaster/ai/beast_turtle_guard_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_turtle_guard.tres` | 待生成 |
| beast_wolf_call | 啸月唤狼 | card_beastmaster | `art/cards/beastmaster/beast_wolf_call.png` | `art/cards/beastmaster/ai/beast_wolf_call_v2.png` | `art/cards/demonic_cultivator/ai` | blocked | 0 | `characters/beastmaster/cards/phase3/beast_wolf_call.tres` | 待生成 |

## P3 Relic Icons

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| affliction_binding_clip | 镇魔经夹 | relic | `art/relics/icons/ink_guard_talisman.png` | `art/relics/icons/affliction_binding_clip_v2.png` | `art/relics/icons/ink_guard_talisman.png` | verified | 0 | `relics/affliction_binding_clip.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；双负面牌转护体完整。 |
| blessing_broken_seal | 破劫之印 | relic | `art/relics/icons/campfire_ember_seal.png` | `art/relics/icons/blessing_broken_seal_v2.png` | `art/relics/icons/campfire_ember_seal.png` | verified | 0 | `relics/blessing_broken_seal.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；三场寿命完整。 |
| clarified_spirit_jade | 澄神玉 | relic | `art/relics/icons/lotus_mirror.png` | `art/relics/icons/clarified_spirit_jade_v2.png` | `art/relics/icons/lotus_mirror.png` | verified | 0 | `relics/clarified_spirit_jade.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；单层法障完整。 |
| cleansing_jade_page | 涤尘玉页 | relic | `art/relics/icons/lotus_mirror.png` | `art/relics/icons/cleansing_jade_page_v2.png` | `art/relics/icons/lotus_mirror.png` | verified | 0 | `relics/cleansing_jade_page.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；负面过牌完整。 |
| demon_ash_furnace | 焚契灰炉 | relic | `art/relics/icons/fire_spark_pearl.png` | `art/relics/icons/demon_ash_furnace_v2.png` | `art/relics/icons/fire_spark_pearl.png` | verified | 0 | `relics/demon_ash_furnace.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；首次消耗抽牌完整。 |
| demon_ash_ledger | 灰契残卷 | relic | `art/relics/icons/fate_ledger.png` | `art/relics/icons/demon_ash_ledger_v2.png` | `art/relics/icons/fate_ledger.png` | verified | 0 | `relics/demon_ash_ledger.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；第三次消耗奖励完整。 |
| demon_ash_pact_scripture | 焚经天炉 | relic | `art/relics/icons/fate_ledger.png` | `art/relics/icons/demon_ash_pact_scripture_v2.png` | `art/relics/icons/fate_ledger.png` | verified | 0 | `relics/demon_ash_pact_scripture.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；双灰供奉与契约风险完整。 |
| demon_blood_crucible | 血炼炉 | relic | `art/relics/icons/blood_jade.png` | `art/relics/icons/demon_blood_crucible_v2.png` | `art/relics/icons/blood_jade.png` | verified | 0 | `relics/demon_blood_crucible.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；自伤转护体完整。 |
| demon_blood_pact_crown | 血海魔冠 | relic | `art/relics/icons/demon_blood_oath_mirror.png` | `art/relics/icons/demon_blood_pact_crown_v2.png` | `art/relics/icons/demon_blood_oath_mirror.png` | verified | 1 | `relics/demon_blood_pact_crown.tres` | 二稿 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；四血阈值完整。 |
| demon_blood_tally | 血劫算盘 | relic | `art/relics/icons/jade_abacus.png` | `art/relics/icons/demon_blood_tally_v2.png` | `art/relics/icons/jade_abacus.png` | verified | 0 | `relics/demon_blood_tally.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；四血回灵完整。 |
| demon_crimson_gourd | 赤髓葫 | relic | `art/relics/icons/spirit_spring_gourd.png` | `art/relics/icons/demon_crimson_gourd_v2.png` | `art/relics/icons/spirit_spring_gourd.png` | verified | 0 | `relics/demon_crimson_gourd.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；首次自伤抽牌完整。 |
| demon_flame_lantern | 三曜焰灯 | relic | `art/relics/icons/fire_spark_pearl.png` | `art/relics/icons/demon_flame_lantern_v2.png` | `art/relics/icons/fire_spark_pearl.png` | verified | 0 | `relics/demon_flame_lantern.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；三色点亮回灵完整。 |
| demon_flame_pact_wheel | 七曜魔轮 | relic | `art/relics/icons/fire_spark_pearl.png` | `art/relics/icons/demon_flame_pact_wheel_v2.png` | `art/relics/icons/fire_spark_pearl.png` | verified | 0 | `relics/demon_flame_pact_wheel.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；七曜与三色条件完整。 |
| demon_flame_wheel_core | 焰轮心核 | relic | `art/relics/icons/fire_spark_pearl.png` | `art/relics/icons/demon_flame_wheel_core_v2.png` | `art/relics/icons/fire_spark_pearl.png` | verified | 0 | `relics/demon_flame_wheel_core.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；首次魔焰抽牌完整。 |
| demon_sha_urn | 镇煞瓮 | relic | `art/relics/icons/demon_heart_seal.png` | `art/relics/icons/demon_sha_urn_v2.png` | `art/relics/icons/demon_heart_seal.png` | verified | 0 | `relics/demon_sha_urn.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；双煞完整。 |
| demon_soul_bell | 摄魂铃 | relic | `art/relics/icons/stone_heart_bell.png` | `art/relics/icons/demon_soul_bell_v2.png` | `art/relics/icons/stone_heart_bell.png` | verified | 0 | `relics/demon_soul_bell.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；魂印回灵完整。 |
| demon_soul_censer | 渡魂香炉 | relic | `art/relics/icons/soul_lantern.png` | `art/relics/icons/demon_soul_censer_v2.png` | `art/relics/icons/soul_lantern.png` | verified | 0 | `relics/demon_soul_censer.tres` | 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；三魂护体完整。 |
| demon_wraith_banner | 万鬼幡 | relic | `art/relics/icons/pack_banner.png` | `art/relics/icons/demon_wraith_banner_v2.png` | `art/relics/icons/pack_banner.png` | verified | 1 | `relics/demon_wraith_banner.tres` | 二稿 512 方图、缩略检查、Godot 导入、绑定和无头运行通过；魂印范围伤害完整。 |
| discard_guard_ring | 弃锋玉环 | relic | `art/relics/icons/ink_guard_talisman.png` | `art/relics/icons/discard_guard_ring_v2.png` | `art/relics/icons/discard_guard_ring_v2.png` | verified | 0 | `relics/discard_guard_ring.tres` | 黑玉环、断刃与金色护盾弧；批次联系表、导入、绑定与运行验证通过 |
| ember_ink_measure | 焚简墨斗 | relic | `art/relics/icons/stone_heart_bell.png` | `art/relics/icons/ember_ink_measure_v2.png` | `art/relics/icons/ember_ink_measure_v2.png` | verified | 0 | `relics/ember_ink_measure.tres` | 黑铜墨斗、燃烧空白竹片与护盾弧；批次联系表、导入、绑定与运行验证通过 |
| empty_breath_seal | 守一铜印 | relic | `art/relics/icons/mana_potion.png` | `art/relics/icons/empty_breath_seal_v2.png` | `art/relics/icons/empty_breath_seal_v2.png` | verified | 0 | `relics/empty_breath_seal.tres` | 素面铜印、空玉碗与层叠金盾；批次联系表、导入、绑定与运行验证通过 |
| empty_mind_jade_slip | 空明玉简 | relic | `art/relics/icons/lotus_mirror.png` | `art/relics/icons/empty_mind_jade_slip_v2.png` | `art/relics/icons/empty_mind_jade_slip_v2.png` | verified | 1 | `relics/empty_mind_jade_slip.tres` | 重试去除云纹；素面白玉简与双层青色护罩；导入、绑定与运行验证通过 |
| formation_breaker_drum | 破阵战鼓 | relic | `art/relics/icons/pack_banner.png` | `art/relics/icons/formation_breaker_drum_v2.png` | `art/relics/icons/formation_breaker_drum_v2.png` | verified | 0 | `relics/formation_breaker_drum.tres` | 黑红战鼓、交叉鼓槌、碎阵与金色劲力珠；导入、绑定与运行验证通过 |
| formless_heavenly_tome | 无相天书 | relic | `art/relics/icons/star_compass.png` | `art/relics/icons/formless_heavenly_tome_v2.png` | `art/relics/icons/formless_heavenly_tome_v2.png` | verified | 0 | `relics/formless_heavenly_tome.tres` | 空白黑玉天书、金卡与两张蚀痕卡；批次联系表、导入、绑定与运行验证通过 |
| gilded_archive_mite | 点金书蠹 | relic | `art/relics/icons/jade_abacus.png` | `art/relics/icons/gilded_archive_mite_v2.png` | `art/relics/icons/gilded_archive_mite_v2.png` | verified | 0 | `relics/gilded_archive_mite.tres` | 玉金书蠹盘踞无字古书，金边页表现发现后升级；导入、绑定与运行通过 |
| growth_echo_stone | 养刃灵石 | relic | `art/relics/icons/wood_earth_seed.png` | `art/relics/icons/growth_echo_stone_v2.png` | `art/relics/icons/growth_echo_stone_v2.png` | verified | 0 | `relics/growth_echo_stone.tres` | 暗玉生长石、翠晶种核与双层回响波；导入、绑定与运行通过 |
| heaven_devouring_core | 吞天气海 | relic | `art/relics/icons/spirit_spring_gourd.png` | `art/relics/icons/heaven_devouring_core_v2.png` | `art/relics/icons/heaven_devouring_core_v2.png` | verified | 0 | `relics/heaven_devouring_core.tres` | 黑紫魔核吞入灵力珠，下方两枚赤焰表现敌方增益代价；导入、绑定与运行通过 |
| hidden_breath_seal | 归藏玉玺 | relic | `art/relics/icons/mana_potion.png` | `art/relics/icons/hidden_breath_seal_v2.png` | `art/relics/icons/hidden_breath_seal_v2.png` | verified | 0 | `relics/hidden_breath_seal.tres` | 素面黑铜匣封存两枚青色灵力珠；导入、绑定与运行通过 |
| inkflow_jade_clasp | 流墨玉扣 | relic | `art/relics/icons/water_moon_bottle.png` | `art/relics/icons/inkflow_jade_clasp_v2.png` | `art/relics/icons/inkflow_jade_clasp_v2.png` | verified | 0 | `relics/inkflow_jade_clasp.tres` | 双环黑玉扣承接青墨并引出一张空白金卡；导入、绑定与运行通过 |
| light_step_abacus | 轻身算珠 | relic | `art/relics/icons/jade_abacus.png` | `art/relics/icons/light_step_abacus_v2.png` | `art/relics/icons/light_step_abacus_v2.png` | verified | 2 | `relics/light_step_abacus.tres` | 两次重试校正计数；三枚高亮算珠触发一张空白金卡；导入、绑定与运行通过 |
| myriad_archive_tally | 万象残签 | relic | `art/relics/icons/star_compass.png` | `art/relics/icons/myriad_archive_tally_v2.png` | `art/relics/icons/myriad_archive_tally_v2.png` | verified | 0 | `relics/myriad_archive_tally.tres` | 黑玉残签展开常规空白候选，额外金色候选突出 |
| myriad_scroll_case | 万卷经匣 | relic | `art/relics/icons/fate_ledger.png` | `art/relics/icons/myriad_scroll_case_v2.png` | `art/relics/icons/myriad_scroll_case_v2.png` | verified | 0 | `relics/myriad_scroll_case.tres` | 经匣满载无字卷简，层叠玉盾表现大牌库起始格挡 |
| nirvana_ember | 涅槃余烬 | relic | `art/relics/icons/healing_potion.png` | `art/relics/icons/nirvana_ember_v2.png` | `art/relics/icons/nirvana_ember_v2.png` | verified | 0 | `relics/nirvana_ember.tres` | 残甲上的凤凰余烬与两滴翠色生机修复玉心 |
| phantom_bookmark | 幻生书签 | relic | `art/relics/icons/star_compass.png` | `art/relics/icons/phantom_bookmark_v2.png` | `art/relics/icons/phantom_bookmark_v2.png` | verified | 0 | `relics/phantom_bookmark.tres` | 紫晶书签触碰虚幻临时卡并引出实体金卡 |
| retained_edge_tassel | 留锋剑穗 | relic | `art/relics/icons/wind_sword_tassel.png` | `art/relics/icons/retained_edge_tassel_v2.png` | `art/relics/icons/retained_edge_tassel_v2.png` | verified | 0 | `relics/retained_edge_tassel.tres` | 黑红剑穗、三张保留卡与三层金盾片 |
| samsara_star_sand | 轮回星砂 | relic | `art/relics/icons/star_compass.png` | `art/relics/icons/samsara_star_sand_v2.png` | `art/relics/icons/samsara_star_sand_v2.png` | verified | 0 | `relics/samsara_star_sand.tres` | 星砂漏与回流卡环，青色灵力珠和金盾同时触发 |
| spirit_cleaver_talisman | 斩灵符 | relic | `art/relics/icons/sword_execution_tally.png` | `art/relics/icons/spirit_cleaver_talisman_v2.png` | `art/relics/icons/spirit_cleaver_talisman_v2.png` | verified | 0 | `relics/spirit_cleaver_talisman.tres` | 素面刃形黑玉佩斩散影魂并引出一张金卡 |
| stored_breath_furnace | 藏息玄炉 | relic | `art/relics/icons/mana_potion.png` | `art/relics/icons/stored_breath_furnace_v2.png` | `art/relics/icons/stored_breath_furnace_v2.png` | verified | 0 | `relics/stored_breath_furnace.tres` | 玄炉收纳三枚灵力珠并展开三层金盾 |
| tempered_scripture_seal | 百炼经印 | relic | `art/relics/icons/metal_edge_ring.png` | `art/relics/icons/tempered_scripture_seal_v2.png` | `art/relics/icons/tempered_scripture_seal_v2.png` | verified | 0 | `relics/tempered_scripture_seal.tres` | 素面玄铜印淬炼金边空白卡并激活盾牌 |
| three_forms_crucible | 三相熔炉 | relic | `art/relics/icons/wood_earth_seed.png` | `art/relics/icons/three_forms_crucible_v2.png` | `art/relics/icons/three_forms_crucible_v2.png` | verified | 0 | `relics/three_forms_crucible.tres` | 赤剑、青玉简与紫焰三相入炉，产出灵力珠与金盾 |
| waning_moon_ring | 残月血戒 | relic | `art/relics/icons/blood_jade.png` | `art/relics/icons/waning_moon_ring_v2.png` | `art/relics/icons/waning_moon_ring_v2.png` | verified | 0 | `relics/waning_moon_ring.tres` | 残月环悬半暗裂心，低血量触发一枚灵力珠 |
| war_pattern_bracer | 战纹护腕 | relic | `art/relics/icons/metal_edge_ring.png` | `art/relics/icons/war_pattern_bracer_v2.png` | `art/relics/icons/war_pattern_bracer_v2.png` | verified | 0 | `relics/war_pattern_bracer.tres` | 黑铜护腕首次撞击赤刃时展开金盾 |

## P4 Event Illustrations

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| blood_script_wall | 血经石壁 | event | `art/event_illustrations/silent_demon_sutra.png` | `art/event_illustrations/blood_script_wall_v2.png` | `art/event_illustrations/blood_script_wall_v2.png` | verified | 0 | `scenes/event_rooms/blood_script_wall_event.tscn` | 无字黑岩巨壁、血色矿脉与青光门扉，构图干净鲜明 |
| soul_auction | 魂魄拍卖 | event | `art/event_illustrations/demon_market_dusk.png` | `art/event_illustrations/soul_auction_v2.png` | `art/event_illustrations/soul_auction_v2.png` | verified | 0 | `scenes/event_rooms/soul_auction_event.tscn` | 地下拍卖厅、面具拍卖师、魂焰瓶与三名竞价者 |
| heaven_flame_eye | 天焰之眼 | event | `art/event_illustrations/starfall_pillar.png` | `art/event_illustrations/heaven_flame_eye_v2.png` | `art/event_illustrations/heaven_flame_eye_v2.png` | verified | 0 | `scenes/event_rooms/heaven_flame_eye_event.tscn` | 天穹金焰眼与孤立祭台，金蓝黑红层次鲜明 |

## P5 Backgrounds

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| dark_battle_arena | 暗黑仙魔战场 | background | `test2.png` | `art/backgrounds/dark_xianxia_battle_arena_v2.png` | `art/backgrounds/dark_xianxia_battle_arena_v2.png` | verified | 0 | `scenes/battle/battle.gd` | 月夜宗门废墟战场，玩家侧青蓝、敌侧绯红，中央和下方低细节 |
| selector_common | 通用选人背景 | background | `test1.png` | `art/backgrounds/character_selector_common_v2.png` | `art/backgrounds/character_selector_common_v2.png` | verified | 0 | `scenes/ui/character_selector.gd` | 四类修行地域远景汇合，中央和底部为通用 UI 安全区 |
| selector_body | 体修选人背景 | background | `test1.png` | `art/backgrounds/body_cultivator_selector_v2.png` | `art/backgrounds/body_cultivator_selector_v2.png` | verified | 0 | `scenes/ui/character_selector.gd` | 冷蓝山夜与赤金熔瀑构成炼体宗门庭院 |
| selector_beastmaster | 驭兽选人背景 | background | `test1.png` | `art/backgrounds/beastmaster_selector_v2.png` | `art/backgrounds/beastmaster_selector_v2.png` | verified | 0 | `scenes/ui/character_selector.gd` | 月下灵兽山林、翠色瀑布与远景灯火，前景低细节 |

## P6 Intent And Status Icons

| asset_id | 中文名称 | 类型 | old | new | ref | 状态 | 重试 | use | prompt |
|---|---|---|---|---|---|---|---:|---|---|
| intent_attack_defend | 攻防 | intent | `code-drawn` | `art/ui/icons/intent_attack_defend_v2.png` | `art/ui/icons/intent_attack_defend_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 赤刃交叠金盾，红金双语义 |
| intent_debuff | 削弱 | intent | `code-drawn` | `art/ui/icons/intent_debuff_v2.png` | `art/ui/icons/intent_debuff_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 紫黑枯莲与翠色毒滴 |
| intent_charge | 蓄力 | intent | `code-drawn` | `art/ui/icons/intent_charge_v2.png` | `art/ui/icons/intent_charge_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 黑铜拳甲内聚橙红气旋 |
| intent_unknown | 未知 | intent | `code-drawn` | `art/ui/icons/intent_unknown_v2.png` | `art/ui/icons/intent_unknown_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 烟幕遮蔽闭合之眼 |
| intent_summon | 召唤 | intent | `code-drawn` | `art/ui/icons/intent_summon_v2.png` | `art/ui/icons/intent_summon_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 黑玉门开启并升起三簇无脸魂焰 |
| intent_heal | 治疗 | intent | `code-drawn` | `art/ui/icons/intent_heal_v2.png` | `art/ui/icons/intent_heal_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 青色灵露修复翠玉心 |
| intent_escape | 逃跑 | intent | `code-drawn` | `art/ui/icons/intent_escape_v2.png` | `art/ui/icons/intent_escape_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 黑靴与袍摆穿门而出，青风拖尾 |
| intent_sleep | 沉睡 | intent | `code-drawn` | `art/ui/icons/intent_sleep_v2.png` | `art/ui/icons/intent_sleep_v2.png` | verified | 0 | `scenes/ui/intent_ui.gd` | 新月下闭眼与柔和靛青云气 |
| status_bleed | 流血 | status | `art/ui/icons/attack_negative.png` | `art/ui/icons/status_bleed_v2.png` | `art/ui/icons/status_bleed_v2.png` | verified | 0 | `statuses/bleed.tres` | 黑玉三道裂痕与一滴鲜红血珠 |
| status_sha_qi | 煞气 | status | `art/ui/icons/attack_negative.png` | `art/ui/icons/status_sha_qi_v2.png` | `art/ui/icons/status_sha_qi_v2.png` | verified | 0 | `statuses/sha_qi.tres` | 黑红煞焰凝成锐利烟刃 |
| status_weak | 虚弱 | status | `art/ui/icons/attack_negative.png` | `art/ui/icons/status_weak_v2.png` | `art/ui/icons/status_weak_v2.png` | verified | 0 | `statuses/weak.tres` | 裂纹拳甲垂落三滴黯淡力量 |
| status_enemy_exposed | 敌方破绽 | status | `art/ui/icons/expose.png` | `art/ui/icons/status_enemy_exposed_v2.png` | `art/ui/icons/status_enemy_exposed_v2.png` | verified | 0 | `statuses/enemy_exposed.tres` | 黑色敌甲向外裂开，猩红核心暴露 |
| status_exposed | 破绽 | status | `art/ui/icons/expose.png` | `art/ui/icons/status_exposed_v2.png` | `art/ui/icons/status_exposed_v2.png` | verified | 0 | `statuses/exposed.tres` | 青玉护盾被紫裂贯穿，琥珀内核暴露 |
| status_frail | 脆弱 | status | `art/ui/icons/expose.png` | `art/ui/icons/status_frail_v2.png` | `art/ui/icons/status_frail_v2.png` | verified | 0 | `statuses/frail.tres` | 灰白薄甲碎裂并向下崩解 |
| status_mana_seal | 灵力封禁 | status | `art/ui/icons/status_qi_flow.png` | `art/ui/icons/status_mana_seal_v2.png` | `art/ui/icons/status_mana_seal_v2.png` | verified | 0 | `statuses/mana_seal.tres` | 青色灵力珠被交叉黑铜箍锁住 |
| status_spell_ward | 法障 | status | `art/ui/icons/status_sword_guard.png` | `art/ui/icons/status_spell_ward_v2.png` | `art/ui/icons/status_spell_ward_v2.png` | verified | 0 | `statuses/spell_ward.tres` | 青紫法障保护白蓝灵焰并击碎来袭术光 |

## Shared Prompt Rules

- 国风暗黑修仙；画面干净、色调鲜明、暗部可读。
- 禁止文字、伪文字、数字、Logo、水印、UI 和烘焙边框。
- 每个素材单独调用一次 `image_gen`，生成后逐张查看并更新状态。
- 不覆盖旧图；新文件使用 `_v2`，通过视觉与 Godot 加载验证后接入。
