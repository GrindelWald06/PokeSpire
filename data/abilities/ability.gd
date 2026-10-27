class_name Ability extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var triggers: Array[AbilityTrigger]
@export var spill_divisor: int = 1
@export var attack_bonus: int = 0
@export var incoming_damage_reduction: int = 0

# Called when a unit is summoned
func on_summoned (state: CombatState, unit: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_SUMMONED, state, unit, null)

# Called when turn is tarted
func on_turn_start (state: CombatState, unit: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_TURN_START, state, unit, null)

# Called when turn is ended
func on_turn_end (state: CombatState, unit: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_TURN_END, state, unit, null)

# Called when a unit is attacked
func on_attacked (state: CombatState, unit: Unit, attacker: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_ATTACKED, state, unit, attacker)


# Called when a unit is dead
func on_death (state: CombatState, unit: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_DEATH, state, unit, null)


# Called when a unit is damaged
func modify_incoming_damage (_state: CombatState, _unit: Unit, amount: int) -> int:
	return amount - incoming_damage_reduction

# Called when damage spilled
func modify_spill (state: CombatState, unit: Unit, spill: int) -> int:
	@warning_ignore("integer_division")
	var result := spill / maxi(1, spill_divisor)
	if result != spill:
		state.ability_triggered.emit(unit, self)
	return result

# Called when a unit attack
func modify_attack (_state:CombatState, _unit: Unit, value) -> int:
	return value + attack_bonus

func _run_triggers(hook: AbilityTrigger.Hook, state: CombatState, unit: Unit, other: Unit = null) -> void:
	for trigger in triggers:
		if trigger.hook != hook:
			continue

		match trigger.target:
			AbilityTrigger.Target.SELF:
				state.ability_triggered.emit(unit, self)
				var effect_context = EffectContext.new(state, unit, unit, false)
				for effect in trigger.effects:
					effect.resolve(effect_context)

			AbilityTrigger.Target.ATTACKER:
				if other == null:
					continue
				if not other.is_alive():
					continue
				state.ability_triggered.emit(unit, self)
				var effect_context = EffectContext.new(state, unit, other, true)
				for effect in trigger.effects:
					effect.resolve(effect_context)

			AbilityTrigger.Target.ALL_ENEMIES:
				if not state.sides[state.opponent_of(state.active_side)].board.is_empty():
					state.ability_triggered.emit(unit, self)
				for enemy in state.sides[state.opponent_of(state.active_side)].board.duplicate():
					if not enemy.is_alive():
						continue
					var effect_context = EffectContext.new(state, unit, enemy, false)
					for effect in trigger.effects:
						effect.resolve(effect_context)

			AbilityTrigger.Target.ALL_ALLIES:
				if not state.sides[state.active_side].board.is_empty():
					state.ability_triggered.emit(unit, self)
				for ally in state.sides[state.active_side].board.duplicate():
					if not ally.is_alive():
						continue
					var effect_context = EffectContext.new(state, unit, ally, false)
					for effect in trigger.effects:
						effect.resolve(effect_context)
