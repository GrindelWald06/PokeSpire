class_name StatusData extends Resource

@export var id:StringName
@export var display_name:String
@export var description:String

@export var default_turns:int = -1
@export var attackçmodifier:int = 0
@export var blocks_action:bool = false
@export var triggers:Array[AbilityTrigger]
@export var stacking:STACKING = STACKING.IGNORE

enum STACKING {IGNORE, REFRESH, ADD}
