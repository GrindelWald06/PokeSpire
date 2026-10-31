class_name StatusInstance extends RefCounted

var turns:int = 0
var intensity:int = 0

func _init(p_turns:int) -> void:
	turns = p_turns
	intensity = 1
