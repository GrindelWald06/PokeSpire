class_name ActOnSummonEffect extends Effect

func resolve(ctx: EffectContext) -> void:
	if not ctx.target.has_status(load("res://data/statuses/paralysis.tres")):
		ctx.target.can_act = true

func _to_string() -> String:
	return "ActOnSummonEffect"
