class_name SideView extends VBoxContainer

@export var info_below:bool = false

func _ready() -> void:
	if info_below:
		move_child($Info, -1)
