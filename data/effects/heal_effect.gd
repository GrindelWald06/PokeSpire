class_name HealEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	if not ctx.target.is_alive():
		return
	ctx.state.heal_unit(ctx.target, amount)

func _to_string() -> String:
	return "HealEffect(amount=%d)" % amount
