class_name Intent
extends Resource

# 意图分类：决定意图气泡的配色与图标（颜色即语义）。
# 红=伤害，青=防御，金=自身增益，紫=对你减益，暗红=大招预警，绿=召唤，灰=中性。
enum Category {
	ATTACK,          # 攻击：造成单体伤害
	MULTI_ATTACK,    # 连击：多段伤害（文字用 "8×3"）
	DEFEND,          # 护体：获得格挡
	ATTACK_DEFEND,   # 攻防兼备
	BUFF,            # 强化：提升自身（凶性/铸剑等）
	DEBUFF,          # 诅咒：对你施加减益（破绽/中毒）
	CHARGE,          # 蓄力：下回合强力一击
	UNKNOWN,         # 未知意图
	SUMMON,          # 唤兽：召唤助战
	HEAL,            # 回血：恢复自身生命
	ESCAPE,          # 遁走：准备逃离
	SLEEP,           # 沉睡：本回合不行动
}

@export var base_text: String
@export var icon: Texture
@export var category: Category = Category.ATTACK

var current_text: String
