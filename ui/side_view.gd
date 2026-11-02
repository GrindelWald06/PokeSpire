class_name SideView extends VBoxContainer

@export var info_below:bool = false

func _ready() -> void:
	if info_below:
		move_child($Info, -1)

func refresh(state:CombatState, side_index:int) -> void:
	%HeroLabel.text = "Hero: %d/%d" % [state.sides[side_index].hero_hp, state.sides[side_index].hero_max_hp]
	%EnergyLabel.text = "Energy: %d/%d" % [state.sides[side_index].energy, state.sides[side_index].max_energy]
