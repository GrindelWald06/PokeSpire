class_name ApplyStatusEffect extends Effect

@export var status: Status.STATUS
@export var turns: int = -1

func resolve(ctx: EffectContext) -> void:
	if ctx.target == null:
		print("Can't apply status to hero")
		return
	if ctx.target.add_status(status, turns):
		ctx.state.status_applied.emit(ctx.target, status)
