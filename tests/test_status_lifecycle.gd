class_name TestStatusLifecycle
extends RefCounted

# Covers Step 5a-5c of the data-driven status refactor:
# duration countdown, attack_modifier through CombatState.get_attack(), and blocks_action.

static func run() -> void:
	print("--- status lifecycle ---")
	countdown_fires_on_last_turn()
	attack_modifier_stacks_with_ability()
	blocker_freezes_unit()
	quick_respects_any_blocker()

static func make_status(display_name: String, default_turns: int) -> StatusData:
	var s := StatusData.new()
	s.id = StringName(display_name.to_lower())
	s.display_name = display_name
	s.default_turns = default_turns
	return s

# 5a: a 2-turn status fires at the end of each owner turn, including the last one,
# and is erased only after its last trigger.
static func countdown_fires_on_last_turn() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "bulbasaur", 0)  # no ability, so only the status announces
	var s := make_status("Countdown", 2)
	var trig := AbilityTrigger.new()
	trig.hook = AbilityTrigger.Hook.ON_TURN_END
	trig.target = AbilityTrigger.Target.SELF  # no effects needed: the announcement is what we count
	s.triggers.append(trig)
	u.add_status(s, s.default_turns)

	var fired: Array = []  # array, because lambdas capture locals by value
	c.ability_triggered.connect(func(_unit, source): if source == s: fired.append(1))

	c.end_turn()  # owner turn 1 ends
	TestKit.check(fired.size() == 1, "countdown: fires on first owner turn end")
	TestKit.check(u.get_turns(s) == 1, "countdown: 2 -> 1 after first owner turn")
	c.end_turn()  # opponent turn ends
	TestKit.check(u.get_turns(s) == 1, "countdown: opponent turn end does not tick it")
	c.end_turn()  # owner turn 2 ends (last turn)
	TestKit.check(fired.size() == 2, "countdown: fires on its last turn (trigger before decrement)")
	TestKit.check(not u.has_status(s), "countdown: erased after its last turn")
	c.end_turn()
	c.end_turn()  # owner turn 3 ends
	TestKit.check(fired.size() == 2, "countdown: does not fire once gone")

	var p := make_status("Permanent", -1)
	u.add_status(p, p.default_turns)
	c.end_turn()
	c.end_turn()
	TestKit.check(u.get_turns(p) == -1, "countdown: -1 never ticks down")

# 5b: modifiers add up unclamped, and the single clamp sits at the end of CombatState.get_attack().
static func attack_modifier_stacks_with_ability() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "bulbasaur", 0)
	u.data = u.data.duplicate()  # keep the shared resource untouched
	u.data.ability = Ability.new()
	u.data.ability.attack_bonus = 2
	u.attack = 0
	var weak := make_status("Weak", -1)
	weak.attack_modifier = -1

	TestKit.check(c.get_attack(u) == 2, "attack mod: base 0 + ability 2 = 2")
	u.add_status(weak, -1)
	# Statuses run before the ability. A per-step clamp would give max(0, 0 - 1) + 2 = 2.
	TestKit.check(c.get_attack(u) == 1, "attack mod: 0 - 1 + 2 = 1, no clamp in between")

	u.data.ability = null
	TestKit.check(c.get_attack(u) == 0, "attack mod: 0 - 1 clamps to 0 at the end")

	u.attack = 3
	u.data.ability = Ability.new()
	u.data.ability.attack_bonus = 2
	TestKit.check(c.get_attack(u) == 4, "attack mod: 3 - 1 + 2 = 4")

# 5c: a blocks_action status stops attacks and moves with a message naming it,
# and lifts after its duration.
static func blocker_freezes_unit() -> void:
	var c := TestKit.make_combat()
	var target := TestKit.add_unit(c, "squirtle", 0)
	var u := TestKit.add_unit(c, "charmander", 1)  # has a move (Ember)
	var block := make_status("Frozen Test", 1)
	block.blocks_action = true
	u.add_status(block, block.default_turns)

	TestKit.check(u.get_blocker() == block, "blocker: get_blocker returns the status")
	TestKit.check(u.is_blocked(), "blocker: is_blocked true")

	c.end_turn()  # start_turn(1)
	TestKit.check(u.can_act == false, "blocker: start_turn leaves the unit unable to act")
	TestKit.check(c._attack_error(u, target).contains(block.display_name), "blocker: attack refusal names the status")
	TestKit.check(c._attack_error(u, target).contains(u.data.display_name), "blocker: attack refusal names the unit")
	TestKit.check(c._move_error(u, target).contains(block.display_name), "blocker: move refusal names the status")
	var hp_before := target.current_hp
	TestKit.check(c.attack(u, target) == false, "blocker: attack refused")
	TestKit.check(c.use_move(u, target) == false, "blocker: move refused")
	TestKit.check(target.current_hp == hp_before, "blocker: target untouched")

	c.end_turn()  # side 1 ends: 1 -> 0, erased
	TestKit.check(not u.has_status(block), "blocker: gone after its turn")
	TestKit.check(u.get_blocker() == null, "blocker: get_blocker null when nothing blocks")
	c.end_turn()  # start_turn(1) again
	TestKit.check(u.can_act == true, "blocker: unit acts again the next turn")
# Quick checks is_blocked(), not paralysis specifically.
static func quick_respects_any_blocker() -> void:
	var c := TestKit.make_combat()
	var p := TestKit.add_unit(c, "pidgey", 0)  # Quick Feet
	var freeze := make_status("Frozen Test", 1)
	freeze.blocks_action = true
	p.add_status(freeze, 1)
	p.can_act = false
	c.fire(&"on_summoned", p)
	TestKit.check(p.can_act == false, "blocker: Quick respects any blocks_action status")
