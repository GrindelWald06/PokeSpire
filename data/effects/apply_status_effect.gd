class_name ApplyStatusEffect extends Effect

@export var status: StatusData
@export var turns_override: int = 0
@export var stacks:int = 1

func resolve(ctx: EffectContext) -> void:
	if ctx.target == null:
		print("Can't apply status to hero")
		return
	var turn_to_consider = turns_override if turns_override != 0 else status.default_turns
	if ctx.target.add_status(status, turn_to_consider, stacks):
		ctx.state.status_applied.emit(ctx.target, status)

func _to_string() -> String:
	var turn_to_consider = turns_override if turns_override != 0 else status.default_turns
	return "ApplyStatusEffect(status=%s, turns=%s)" % [status, turn_to_consider]
