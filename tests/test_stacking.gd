class_name TestStacking
extends RefCounted

# Step 8: per-status stacking on two independent axes.
#   Duration (duration_stacking): KEEP, REFRESH, ADD
#   Intensity (stack_intensity, max_intensity): +stacks per application, capped when max_intensity > 0
# A reapplication returns true when either axis changed something.

const POISON: StatusData = preload("res://data/statuses/poison.tres")

static func run() -> void:
	print("--- stacking ---")
	fresh_status()
	duration_keep()
	duration_refresh()
	duration_add()
	duration_add_permanent()
	duration_add_same_amount()
	intensity_adds()
	intensity_cap()
	both_axes()
	duration_change_at_intensity_cap()
	apply_effect_passes_stacks()
	context_intensity_defaults_to_one()
	per_stack_damage()
	flat_damage_ignores_intensity()
	poison_payoff()

static func make(duration: StatusData.DurationStacking, stack_intensity := false, max_intensity := 0) -> StatusData:
	var s := StatusData.new()
	s.id = &"stack_test"
	s.display_name = "Stack Test"
	s.default_turns = 2
	s.duration_stacking = duration
	s.stack_intensity = stack_intensity
	s.max_intensity = max_intensity
	return s

static func unit() -> Unit:
	return TestKit.add_unit(TestKit.make_combat(), "squirtle", 0)  # 4 HP, no ability

static func dot(per_stack: bool) -> StatusData:
	# ON_TURN_END, SELF, 1 damage; intensity stacking on, permanent.
	var s := make(StatusData.DurationStacking.KEEP, true)
	s.default_turns = -1
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.SELF
	var dmg := DamageEffect.new()
	dmg.amount = 1
	dmg.per_stack = per_stack
	trig.effects.append(dmg)
	s.triggers.append(trig)
	return s

static func fresh_status() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.KEEP)
	TestKit.check(u.get_turns(s) == 0 and u.get_intensity(s) == 0, "stacking: absent status reads 0 turns, 0 intensity")
	u.add_status(s, 2)
	TestKit.check(u.get_turns(s) == 2 and u.get_intensity(s) == 1, "stacking: new status starts at intensity 1")
	var t := make(StatusData.DurationStacking.KEEP)
	u.add_status(t, 2, 3)
	TestKit.check(u.get_intensity(t) == 3, "stacking: new status takes the stacks passed in")

static func duration_keep() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.KEEP)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 5) == false, "KEEP: reapplication changes nothing, returns false")
	TestKit.check(u.get_turns(s) == 2 and u.get_intensity(s) == 1, "KEEP: turns and intensity untouched")

static func duration_refresh() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.REFRESH)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 5), "REFRESH: returns true")
	TestKit.check(u.get_turns(s) == 5, "REFRESH: overwrites turns")
	u.add_status(s, 1)
	TestKit.check(u.get_turns(s) == 1, "REFRESH: overwrites even with fewer turns")
	TestKit.check(u.get_intensity(s) == 1, "REFRESH: intensity untouched without stack_intensity")

static func duration_add() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.ADD)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 3), "ADD: returns true")
	TestKit.check(u.get_turns(s) == 5, "ADD: 2 + 3 = 5 turns")

static func duration_add_permanent() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.ADD)
	u.add_status(s, -1)
	TestKit.check(u.add_status(s, 3) == false, "ADD: adding to a permanent status changes nothing")
	TestKit.check(u.get_turns(s) == -1, "ADD: permanent stays permanent")
	var t := make(StatusData.DurationStacking.ADD)
	u.add_status(t, 2)
	TestKit.check(u.add_status(t, -1), "ADD: a permanent application changes a timed one")
	TestKit.check(u.get_turns(t) == -1, "ADD: a permanent application makes it permanent")

static func duration_add_same_amount() -> void:
	# The return value compares before and after, not the incoming turns with the old ones.
	var u := unit()
	var s := make(StatusData.DurationStacking.ADD)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 2), "ADD: 2 + 2 is a change, returns true")
	TestKit.check(u.get_turns(s) == 4, "ADD: 2 + 2 = 4 turns")

static func intensity_adds() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.KEEP, true)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 2), "intensity: reapplication returns true even with KEEP")
	TestKit.check(u.get_intensity(s) == 2, "intensity: 1 + 1 = 2")
	TestKit.check(u.get_turns(s) == 2, "intensity: KEEP still keeps the turns")
	u.add_status(s, 2, 3)
	TestKit.check(u.get_intensity(s) == 5, "intensity: adds the stacks passed in (2 + 3)")

static func intensity_cap() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.KEEP, true, 3)
	u.add_status(s, 2, 2)
	u.add_status(s, 2, 2)
	TestKit.check(u.get_intensity(s) == 3, "cap: 2 + 2 clamps to max_intensity 3")
	TestKit.check(u.add_status(s, 2) == false, "cap: at the cap with KEEP, reapplication returns false")
	var t := make(StatusData.DurationStacking.KEEP, true, 2)
	u.add_status(t, 2, 5)
	TestKit.check(u.get_intensity(t) == 2, "cap: a fresh application is capped too")

static func both_axes() -> void:
	var u := unit()
	var s := make(StatusData.DurationStacking.ADD, true)
	u.add_status(s, 2)
	u.add_status(s, 3)
	TestKit.check(u.get_turns(s) == 5 and u.get_intensity(s) == 2, "both: turns 2 + 3 and intensity 1 + 1")

static func duration_change_at_intensity_cap() -> void:
	# An unchanged intensity must not hide a duration change.
	var u := unit()
	var s := make(StatusData.DurationStacking.ADD, true, 1)
	u.add_status(s, 2)
	TestKit.check(u.add_status(s, 3), "both: duration change at the intensity cap still returns true")
	TestKit.check(u.get_turns(s) == 5 and u.get_intensity(s) == 1, "both: turns added, intensity held at cap 1")

static func apply_effect_passes_stacks() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var src := TestKit.add_unit(c, "charmander", 0)
	var target := TestKit.add_unit(c, "squirtle", 1)
	var s := make(StatusData.DurationStacking.KEEP, true)
	var effect := ApplyStatusEffect.new()
	effect.status = s
	effect.stacks = 2
	var ctx := EffectContext.new(c, src, target)
	effect.resolve(ctx)
	effect.resolve(ctx)
	TestKit.check(target.get_intensity(s) == 4, "apply effect: stacks 2 applied twice = 4")
	TestKit.check(rec.statuses == 2, "apply effect: an intensity-only change still emits status_applied")

static func context_intensity_defaults_to_one() -> void:
	var c := TestKit.make_combat()
	var ctx := EffectContext.new(c, null, null)
	TestKit.check(ctx.intensity == 1, "context: intensity defaults to 1 (moves and abilities unaffected)")

static func per_stack_damage() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "squirtle", 0)
	var s := dot(true)
	u.add_status(s, -1, 3)
	c.end_turn()
	TestKit.check(u.current_hp == 1, "per stack: 3 stacks x 1 damage = 3 (4 -> 1)")

static func flat_damage_ignores_intensity() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "squirtle", 0)
	var s := dot(false)
	u.add_status(s, -1, 3)
	c.end_turn()
	TestKit.check(u.current_hp == 3, "flat: damage ignores intensity without per_stack (4 -> 3)")

# The payoff: Poison exists only as a .tres and needs no engine code of its own.
static func poison_payoff() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "squirtle", 0)  # 4 HP
	u.add_status(POISON, POISON.default_turns)
	u.add_status(POISON, POISON.default_turns)
	TestKit.check(u.get_intensity(POISON) == 2, "poison: two applications stack to intensity 2")
	TestKit.check(u.get_turns(POISON) == -1, "poison: permanent")
	c.end_turn()
	TestKit.check(u.current_hp == 2, "poison: deals 2 at owner's turn end (4 -> 2)")
	c.end_turn()
	TestKit.check(u.current_hp == 2, "poison: no tick at the opponent's turn end")
	c.end_turn()
	TestKit.check(not u.is_alive(), "poison: still there next owner turn and kills (2 -> 0)")
	TestKit.check(c.sides[0].hero_hp == 30, "poison: never spills")
