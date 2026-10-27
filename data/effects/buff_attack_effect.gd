class_name BuffAttackEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	ctx.source.temp_attack_modifier += amount

func _to_string() -> String:
	return "BuffAttackEffect(amount=%d)" % amount
