class_name Unit extends RefCounted

var data: PokemonData
var side_index: int
var current_hp: int
var attack: int
var max_hp: int
var can_act: bool
var temp_attack_modifier: int = 0
var status_effects: Dictionary[StatusData, int] = {}

func _init(p_data:PokemonData, p_side:int) -> void:
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

func has_status(status: StatusData) -> bool:
	return status_effects.has(status)

func add_status(status: StatusData, turns: int) -> bool:
	if not has_status(status):
		status_effects[status] = turns
		return true

	if status.stacking == StatusData.STACKING.IGNORE:
		return false
	if status.stacking == StatusData.STACKING.REFRESH:
		status_effects[status] = turns
		return true
	else:
		push_warning("ADD not implemented")
		return false
	

func remove_status(status: StatusData) -> void:
	status_effects.erase(status)

func is_blocked() -> bool:
	return get_blocker() != null

func get_blocker() -> StatusData:
	for status in status_effects.keys():
		if status.blocks_action:
			return status
	return null

func get_attack() -> int:
	var amount = attack + temp_attack_modifier
	for source in get_hook_sources():
		amount = source.modify_attack(null, self, amount)
	return max(0, amount)

func get_hook_sources() -> Array[HookSource]:
	var sources: Array[HookSource] = []
	# Statuses first, so they trigger before abilities (burn before Regenerator).
	for status in status_effects:
		sources.append(status)
	if data.ability != null:
		sources.append(data.ability)
	return sources

func _to_string() -> String:
	return "Unit(name=%s, side_index=%d, hp=%d/%d, attack=%d, can_act=%s)" % [
		data.display_name,
		side_index,
		current_hp,
		max_hp,
		attack,
		str(can_act)
	]
