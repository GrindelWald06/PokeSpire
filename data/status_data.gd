class_name StatusData extends HookSource

enum STACKING {IGNORE, REFRESH, ADD}

@export var default_turns:int = -1
@export var attack_modifier:int = 0
@export var blocks_action:bool = false
@export var stacking:STACKING = STACKING.IGNORE

# Called when a unit attacked
func modify_attack (state:CombatState, unit: Unit, value:int) -> int:
	return value + attack_modifier
