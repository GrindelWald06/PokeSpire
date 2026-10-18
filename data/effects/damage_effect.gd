class_name DamageEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	if ctx.target == null:
		ctx.state.damage_hero(ctx.state.opponent_of(ctx.source.side_index), amount)
	else:
		var damage = TypeChart.apply(amount, TypeChart.step(ctx.move_type, ctx.target.data.types))
		ctx.state.damage_unit(ctx.target, damage, ctx.allow_spill)

func _to_string() -> String:
	return "DamageEffect(amount=%d)" % amount
