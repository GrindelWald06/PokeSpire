class_name Unit extends RefCounted

var data: PokemonData
var side_index: int
var current_hp: int
var attack: int
var max_hp: int
var can_act: bool
var temp_attack_modifier: int = 0
var statuses: Dictionary[StatusData, StatusInstance] = {}

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

func get_turns(status:StatusData) -> int:
	if not has_status(status):
		return 0
	return statuses[status].turns
	
func get_intensity(status:StatusData) -> int:
	if not has_status(status):
		return 0
	return statuses[status].intensity

func decrement_status_turn() -> void:
	for status in statuses.keys():
		if statuses[status].turns >= 1:
			statuses[status].turns -= 1
			if statuses[status].turns == 0:
				statuses.erase(status)

func has_status(status: StatusData) -> bool:
	return statuses.has(status)

func add_status(status: StatusData, turns: int, stacks: int = 1) -> bool:
	if not has_status(status):
		var fresh := StatusInstance.new(turns)
		fresh.intensity = _cap_intensity(status, stacks)
		statuses[status] = fresh
		return true

	var instance: StatusInstance = statuses[status]
	var old_turns := instance.turns
	var old_intensity := instance.intensity

	match status.duration_stacking:
		StatusData.DurationStacking.KEEP:
			pass
		StatusData.DurationStacking.REFRESH:
			instance.turns = turns
		StatusData.DurationStacking.ADD:
			if instance.turns == -1 or turns == -1:
				instance.turns = -1
			else:
				instance.turns += turns

	if status.stack_intensity:
		instance.intensity = _cap_intensity(status, instance.intensity + stacks)

	return instance.turns != old_turns or instance.intensity != old_intensity

func _cap_intensity(status: StatusData, value: int) -> int:
	if status.max_intensity > 0:
		return mini(value, status.max_intensity)
	return value

func remove_status(status: StatusData) -> void:
	statuses.erase(status)

func is_blocked() -> bool:
	return get_blocker() != null

func get_blocker() -> StatusData:
	for status in statuses.keys():
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
	for status in statuses:
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
