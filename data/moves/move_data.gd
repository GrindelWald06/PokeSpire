class_name MoveData extends Resource

enum TargetMode { SINGLE_ENEMY, ALL_ENEMIES, SELF }

@export var id: StringName
@export var display_name: String
@export var cost: int
@export var target_mode: TargetMode = TargetMode.SINGLE_ENEMY
@export var effects: Array[Effect]
@export var bypass: bool

func _to_string() -> String:
	return "MoveData(id=%s, display_name=%s, cost=%d, target_mode=%s, bypass=%s, effects=%s)" % [
		id,
		display_name,
		cost,
		target_mode,
		bypass,
		str(effects)
	]
