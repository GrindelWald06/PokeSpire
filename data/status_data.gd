class_name StatusData extends HookSource

enum DurationStacking { KEEP, REFRESH, ADD }

@export var default_turns:int = -1
@export var attack_modifier:int = 0
@export var blocks_action:bool = false
@export var duration_stacking:DurationStacking = DurationStacking.KEEP
@export var stack_intensity:bool = false
@export var max_intensity:int = 0

# Called when a unit attacked
func modify_attack (state:CombatState, unit: Unit, value:int) -> int:
	return value + attack_modifier

func _intensity_for(unit) -> int:
	return unit.get_intensity(self)
