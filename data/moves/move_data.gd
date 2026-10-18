class_name MoveData extends Resource

enum TargetMode { SINGLE_ENEMY, ALL_ENEMIES, SELF }

@export var id: StringName
@export var display_name: String
@export var cost: int
@export var type: Types.Type = Types.Type.NONE
@export var target_mode: TargetMode
@export var effects: Array[Effect]
@export var bypass: bool

func _to_string() -> String:
	return "MoveData(id=%s, display_name=%s, cost=%d, type=%s target_mode=%s, bypass=%s, effects=%s)" % [
		id,
		display_name,
		cost,
		str(type),
		target_mode,
		bypass,
		str(effects)
	]
