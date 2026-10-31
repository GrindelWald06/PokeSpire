class_name HookSource extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var triggers: Array[AbilityTrigger]

# Called when a unit is summoned
func on_summoned (state: CombatState, unit: Unit) -> void:
	_run_triggers(AbilityTrigger.Hook.ON_SUMMONED, state, unit, null)

# Called when turn is started
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
func modify_incoming_damage (state: CombatState, unit: Unit, amount: int) -> int:
	return amount

# Called when damage spilled
func modify_spill (state: CombatState, unit: Unit, spill: int) -> int:
	return spill

# Called when a unit attacks
func modify_attack (state:CombatState, unit: Unit, value:int) -> int:
	return value

func _run_triggers(hook:AbilityTrigger.Hook, state:CombatState, unit:Unit, other:Unit):
	for trigger in triggers:
		if trigger.hook != hook: continue
		var targets = _collect_targets(trigger, state, unit, other)
		var announced = false
		for target in targets:
			if not _target_is_valid(trigger, target): continue
			if not announced:
				state.ability_triggered.emit(unit, self)
				announced = true
			var ctx = EffectContext.new(state, unit, target, false)
			for effect in trigger.effects:
				if not _target_is_valid(trigger, target): break   # point 6
				effect.resolve(ctx)

func _collect_targets(trigger, state, unit, other) -> Array[Unit]:
	match trigger.target:
		AbilityTrigger.Target.SELF: return [unit]
		AbilityTrigger.Target.ATTACKER: return [other] if other != null else []
		AbilityTrigger.Target.ALL_ENEMIES: return state.sides[state.opponent_of(unit.side_index)].board.duplicate()
		AbilityTrigger.Target.ALL_ALLIES:  return state.sides[unit.side_index].board.duplicate()
	return []

func _target_is_valid(trigger, target) -> bool:
	if target.is_alive(): return true
	return trigger.hook == AbilityTrigger.Hook.ON_DEATH and trigger.target == AbilityTrigger.Target.SELF
