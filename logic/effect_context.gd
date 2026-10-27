class_name EffectContext extends RefCounted

var state: CombatState
var source: Unit
var target: Unit
var allow_spill: bool = true
var move_type: Types.Type = Types.Type.NONE

func _init(p_state:CombatState, p_source:Unit, p_target:Unit, p_allow_spill:bool = true, p_move_type:Types.Type = Types.Type.NONE) -> void:
	state = p_state
	source = p_source
	target = p_target
	allow_spill = p_allow_spill
	move_type = p_move_type
