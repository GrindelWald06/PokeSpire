class_name ApplyStatusEffect extends Effect

@export var status: StatusData
@export var turns_override: int = 0
@export var stacks:int = 1

func resolve(ctx: EffectContext) -> void:
	if status == null:
		push_error("ApplyStatusEffect has no status assigned")
		return
	if ctx.target == null:
		print("Can't apply status to hero")
		return
	var turns: int = turns_override if turns_override != 0 else status.default_turns
	if ctx.target.add_status(status, turns, stacks):
		ctx.state.status_applied.emit(ctx.target, status)

func _to_string() -> String:
	if status == null:
		return "ApplyStatusEffect(status=<none>)"
	var turns: int = turns_override if turns_override != 0 else status.default_turns
	return "ApplyStatusEffect(status=%s, turns=%d, stacks=%d)" % [status.id, turns, stacks]
