class_name DrawEffect extends Effect

@export var amount: int

func resolve(ctx: EffectContext) -> void:
	ctx.state.draw_cards(ctx.source.side_index, amount)

func _to_string() -> String:
	return "DrawEffect(amount=%d)" % amount
