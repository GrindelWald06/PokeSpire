class_name DamageEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	ctx.state.damage_unit(ctx.target, amount)

func _to_string() -> String:
	return "DamageEffect(amount=%d)" % amount
