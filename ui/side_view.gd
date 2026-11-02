class_name SideView extends VBoxContainer

@export var info_below:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if info_below:
		move_child($Info, -1)
