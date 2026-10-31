class_name Ability extends HookSource

@export var spill_divisor: int = 1
@export var attack_bonus: int = 0
@export var incoming_damage_reduction: int = 0

# Called when a unit is damaged
func modify_incoming_damage (state: CombatState, unit: Unit, amount: int) -> int:
	return max(0, amount - incoming_damage_reduction)

# Called when damage spilled
func modify_spill (state: CombatState, unit: Unit, spill: int) -> int:
	@warning_ignore("integer_division")
	var result := spill / maxi(1, spill_divisor)
	if result != spill:
		state.ability_triggered.emit(unit, self)
	return result

# Called when a unit attack
func modify_attack (state:CombatState, unit: Unit, value:int) -> int:
	return value + attack_bonus
