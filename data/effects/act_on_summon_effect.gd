class_name ActOnSummonEffect extends Effect

func resolve(ctx: EffectContext) -> void:
	if not ctx.target.has_status(Status.STATUS.PARALYSIS):
		ctx.target.can_act = true

func _to_string() -> String:
	return "ActOnSummonEffect"
