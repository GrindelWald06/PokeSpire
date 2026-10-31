class_name TestFireDeath
extends RefCounted

# A unit that dies DURING fire() stops running its remaining hook sources.
# A unit that was ALREADY dead when fire() started (on_death, a defender killed
# in a trade) still runs all of them.

static func run() -> void:
	print("--- death during fire ---")
	ability_skipped_after_status_kill()
	ability_runs_when_status_does_not_kill()
	aftermath_still_fires_after_status_kill()

# ON_TURN_END, SELF, 1 damage: kills from inside fire(), like burn will.
static func scorch() -> StatusData:
	var s := StatusData.new()
	s.id = &"scorch"
	s.display_name = "Scorch"
	s.default_turns = -1
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.SELF
	var dmg := DamageEffect.new()
	dmg.amount = 1
	trig.effects.append(dmg)
	s.triggers.append(trig)
	return s

# ON_TURN_END, ALL_ENEMIES, 1 damage.
static func spite() -> Ability:
	var a := Ability.new()
	a.id = &"spite"
	a.display_name = "Spite"
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.ALL_ENEMIES
	var dmg := DamageEffect.new()
	dmg.amount = 1
	trig.effects.append(dmg)
	a.triggers.append(trig)
	return a

static func spiteful_unit(c: CombatState, hp: int) -> Unit:
	var u := TestKit.add_unit(c, "bulbasaur", 0)  # 3 max HP, no ability of its own
	u.data = u.data.duplicate()  # keep the shared resource untouched
	u.data.ability = spite()
	u.current_hp = hp
	u.add_status_data(scorch(), -1)
	return u

static func ability_skipped_after_status_kill() -> void:
	var c := TestKit.make_combat()
	var u := spiteful_unit(c, 1)
	var enemy := TestKit.add_unit(c, "squirtle", 1)  # 4 HP
	var announced: Array = []
	c.ability_triggered.connect(func(_unit, source): if source == u.data.ability: announced.append(1))

	c.end_turn()
	TestKit.check(not u.is_alive(), "fire death: status killed its owner")
	TestKit.check(enemy.current_hp == 4, "fire death: dead unit's turn-end ability does not hit enemies")
	TestKit.check(announced.is_empty(), "fire death: dead unit's ability is not announced")
	TestKit.check(c.sides[0].discard.has(u.data), "fire death: owner still goes to discard")

# Control: proves the ability works, so the test above cannot pass by accident.
static func ability_runs_when_status_does_not_kill() -> void:
	var c := TestKit.make_combat()
	var u := spiteful_unit(c, 3)
	var enemy := TestKit.add_unit(c, "squirtle", 1)

	c.end_turn()
	TestKit.check(u.current_hp == 2, "fire death control: status ticks for 1")
	TestKit.check(enemy.current_hp == 3, "fire death control: living unit's ability hits enemies")

# on_death fires on an already dead unit, so it must not be cut short.
static func aftermath_still_fires_after_status_kill() -> void:
	var c := TestKit.make_combat()
	var k := TestKit.add_unit(c, "koffing", 0)
	k.current_hp = 1
	k.add_status_data(scorch(), -1)
	var enemy := TestKit.add_unit(c, "squirtle", 1)

	c.end_turn()
	TestKit.check(not k.is_alive(), "fire death: koffing killed by its status")
	TestKit.check(enemy.current_hp < 4, "fire death: Aftermath still fires after a status kill")
