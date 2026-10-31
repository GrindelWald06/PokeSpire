class_name TestStatusData
extends RefCounted

static func run() -> void:
	print("--- status data ---")
	add_has_remove()
	keep_stacking()
	refresh_stacking()
	literal_minus_one()
	units_are_isolated()
	hook_sources()

static func make_status(stacking: StatusData.DurationStacking, default_turns: int = 1) -> StatusData:
	var s := StatusData.new()
	s.id = &"test_status"
	s.display_name = "Test"
	s.duration_stacking = stacking
	s.default_turns = default_turns
	return s

static func unit() -> Unit:
	return TestKit.add_unit(TestKit.make_combat(), "charmander", 0)

static func add_has_remove() -> void:
	var u := unit()
	var s := make_status(StatusData.DurationStacking.KEEP)
	TestKit.check(not u.has_status(s), "new unit has no status data")
	TestKit.check(u.add_status(s, 2), "adding a new status returns true")
	TestKit.check(u.has_status(s), "has_status true after add")
	TestKit.check(u.get_turns(s) == 2, "turns stored as given")
	u.remove_status(s)
	TestKit.check(not u.has_status(s), "has_status false after remove")
	u.remove_status(s)
	TestKit.check(not u.has_status(s), "removing an absent status is harmless")

static func keep_stacking() -> void:
	var u := unit()
	var s := make_status(StatusData.DurationStacking.KEEP)
	u.add_status(s, 3)
	TestKit.check(u.add_status(s, 1) == false, "KEEP refuses a duplicate")
	TestKit.check(u.get_turns(s) == 3, "KEEP keeps the original turns")

static func refresh_stacking() -> void:
	var u := unit()
	var s := make_status(StatusData.DurationStacking.REFRESH)
	u.add_status(s, 1)
	TestKit.check(u.add_status(s, 3), "REFRESH accepts a duplicate")
	TestKit.check(u.get_turns(s) == 3, "REFRESH overwrites the turns")

static func literal_minus_one() -> void:
	var u := unit()
	var s := make_status(StatusData.DurationStacking.KEEP, 5)
	u.add_status(s, -1)
	TestKit.check(u.get_turns(s) == -1, "-1 is stored literally, not replaced by default_turns")

static func units_are_isolated() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	var b := TestKit.add_unit(c, "squirtle", 1)
	var s := make_status(StatusData.DurationStacking.KEEP)
	a.add_status(s, 2)
	TestKit.check(not b.has_status(s), "status data is per unit")
	TestKit.check(b.add_status(s, 1), "other unit can still receive it")

static func hook_sources() -> void:
	# A unit with NO ability still gets its statuses as hook sources.
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "charmander", 0)  # no ability
	var s := StatusData.new()
	s.duration_stacking = StatusData.DurationStacking.KEEP
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.SELF
	var dmg := DamageEffect.new()
	dmg.amount = 1
	trig.effects.append(dmg)
	s.triggers.append(trig)
	u.add_status(s, -1)
	TestKit.check(u.get_hook_sources().has(s), "status is a hook source without an ability")
	c.end_turn()
	TestKit.check(u.current_hp == 1, "status trigger fires at owner's turn end")

	# Order: status before ability.
	var t := TestKit.add_unit(c, "tangela", 0)
	t.add_status(s, -1)
	var sources := t.get_hook_sources()
	TestKit.check(sources[0] == s and sources[1] == t.data.ability, "statuses come before the ability")
