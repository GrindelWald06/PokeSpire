class_name DamageEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	if ctx.target == null:
		ctx.state.damage_hero(ctx.state.opponent_of(ctx.source.side_index), amount)
	else:
		ctx.state.damage_unit(ctx.target, amount, ctx.allow_spill)

func _to_string() -> String:
	return "DamageEffect(amount=%d)" % amount
