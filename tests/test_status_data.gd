class_name TestStatusData
extends RefCounted

static func run() -> void:
	print("--- status data ---")
	add_has_remove()
	ignore_stacking()
	refresh_stacking()
	add_stacking_not_implemented()
	literal_minus_one()
	units_are_isolated()
	old_system_untouched()
	hook_sources()

static func make_status(stacking: StatusData.STACKING, default_turns: int = 1) -> StatusData:
	var s := StatusData.new()
	s.id = &"test_status"
	s.display_name = "Test"
	s.stacking = stacking
	s.default_turns = default_turns
	return s

static func unit() -> Unit:
	return TestKit.add_unit(TestKit.make_combat(), "charmander", 0)

static func add_has_remove() -> void:
	var u := unit()
	var s := make_status(StatusData.STACKING.IGNORE)
	TestKit.check(not u.has_status_data(s), "new unit has no status data")
	TestKit.check(u.add_status_data(s, 2), "adding a new status returns true")
	TestKit.check(u.has_status_data(s), "has_status_data true after add")
	TestKit.check(u.status_effects[s] == 2, "turns stored as given")
	u.remove_status_data(s)
	TestKit.check(not u.has_status_data(s), "has_status_data false after remove")
	u.remove_status_data(s)
	TestKit.check(not u.has_status_data(s), "removing an absent status is harmless")

static func ignore_stacking() -> void:
	var u := unit()
	var s := make_status(StatusData.STACKING.IGNORE)
	u.add_status_data(s, 3)
	TestKit.check(u.add_status_data(s, 1) == false, "IGNORE refuses a duplicate")
	TestKit.check(u.status_effects[s] == 3, "IGNORE keeps the original turns")

static func refresh_stacking() -> void:
	var u := unit()
	var s := make_status(StatusData.STACKING.REFRESH)
	u.add_status_data(s, 1)
	TestKit.check(u.add_status_data(s, 3), "REFRESH accepts a duplicate")
	TestKit.check(u.status_effects[s] == 3, "REFRESH overwrites the turns")

static func add_stacking_not_implemented() -> void:
	# Documents current behavior. Update this test when ADD is implemented for Poison.
	var u := unit()
	var s := make_status(StatusData.STACKING.ADD)
	u.add_status_data(s, 1)
	TestKit.check(u.add_status_data(s, 1) == false, "ADD is not implemented yet (returns false)")
	TestKit.check(u.status_effects[s] == 1, "ADD leaves turns unchanged for now")

static func literal_minus_one() -> void:
	var u := unit()
	var s := make_status(StatusData.STACKING.IGNORE, 5)
	u.add_status_data(s, -1)
	TestKit.check(u.status_effects[s] == -1, "-1 is stored literally, not replaced by default_turns")

static func units_are_isolated() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	var b := TestKit.add_unit(c, "squirtle", 1)
	var s := make_status(StatusData.STACKING.IGNORE)
	a.add_status_data(s, 2)
	TestKit.check(not b.has_status_data(s), "status data is per unit")
	TestKit.check(b.add_status_data(s, 1), "other unit can still receive it")

static func old_system_untouched() -> void:
	var u := unit()
	var s := make_status(StatusData.STACKING.IGNORE)
	u.add_status_data(s, 1)
	TestKit.check(u.statuses.is_empty(), "new system does not write to the old dictionary")
	u.add_status(Status.STATUS.BURN, -1)
	TestKit.check(u.status_effects.size() == 1, "old system does not write to the new dictionary")

static func hook_sources() -> void:
	# A unit with NO ability still gets its statuses as hook sources.
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "charmander", 0)  # no ability
	var s := StatusData.new()
	s.stacking = StatusData.STACKING.IGNORE
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.SELF
	var dmg := DamageEffect.new()
	dmg.amount = 1
	trig.effects.append(dmg)
	s.triggers.append(trig)
	u.add_status_data(s, -1)
	TestKit.check(u.get_hook_sources().has(s), "status is a hook source without an ability")
	c.end_turn()
	TestKit.check(u.current_hp == 1, "status trigger fires at owner's turn end")

	# Order: status before ability.
	var t := TestKit.add_unit(c, "tangela", 0)
	t.add_status_data(s, -1)
	var sources := t.get_hook_sources()
	TestKit.check(sources[0] == s and sources[1] == t.data.ability, "statuses come before the ability")
