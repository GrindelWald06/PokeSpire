class_name DamageEffect extends Effect

@export var amount: int
@export var per_stack: bool

func resolve(ctx: EffectContext) -> void:
	var damage = amount * ctx.intensity if per_stack else amount
	if ctx.target == null:
		ctx.state.damage_hero(ctx.state.opponent_of(ctx.source.side_index), amount)
	else:
		damage = TypeChart.apply(amount, TypeChart.step(ctx.move_type, ctx.target.data.types))
		ctx.state.damage_unit(ctx.target, damage, ctx.allow_spill)

func _to_string() -> String:
	return "DamageEffect(amount=%d)" % amount
