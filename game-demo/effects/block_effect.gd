class_name BlockEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			var modified_amount := amount
			if target is Player and target.modifier_handler:
				modified_amount = target.modifier_handler.get_modified_value(amount, Modifier.Type.BLOCK_GAIN)
			target.stats.block += modified_amount
			SFXPlayer.play(sound)
