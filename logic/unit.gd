class_name Unit extends RefCounted

var data: PokemonData
var side_index: int
var current_hp: int
var attack: int
var max_hp: int
var can_act: bool

func _init(p_data, p_side) -> void:
	data = p_data
	side_index = p_side
	current_hp = data.max_hp
	max_hp = data.max_hp
	attack = data.attack
	can_act = false

func is_alive() -> bool:
	if current_hp > 0:
		return true
	return false

func _to_string() -> String:
	return "Unit(name=%s, side_index=%d, hp=%d/%d, attack=%d, can_act=%s)" % [
		data.display_name,
		side_index,
		current_hp,
		max_hp,
		attack,
		str(can_act)
	]
