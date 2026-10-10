class_name MoveData extends Resource

@export var id: StringName
@export var display_name: String
@export var cost: int
@export var target_mode: StringName
@export var effects: Array[Effect]

func _to_string() -> String:
	return "MoveData(id=%s, display_name=%s, cost=%d, target_mode=%s, effects=%s)" % [
		id,
		display_name,
		cost,
		target_mode,
		str(effects)
	]
