class_name SideView extends VBoxContainer

@export var info_below:bool = false

const UNIT_VIEW := preload("res://ui/unit_view.tscn")

func _ready() -> void:
	if info_below:
		move_child($Info, -1)

func refresh(state:CombatState, side_index:int) -> void:
	var side := state.sides[side_index]
	%HeroLabel.text = "Hero: %d/%d" % [side.hero_hp, side.hero_max_hp]
	%EnergyLabel.text = "Energy: %d/%d" % [side.energy, side.max_energy]

	#clear board
	for uv in %Board.get_children():
		remove_child(uv)
		uv.free()
	
	#repopulate board
	for u in side.board:
		var uv = UNIT_VIEW.instantiate()
		%Board.add_child(uv)
		uv.setup(state, u)
