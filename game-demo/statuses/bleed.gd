class_name BleedStatus
extends Status

const BLEED_DAMAGE := 3


func get_tooltip() -> String:
	return tooltip % duration


func apply_status(target: Node) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = BLEED_DAMAGE
	damage_effect.execute([target])
	status_applied.emit(self)
