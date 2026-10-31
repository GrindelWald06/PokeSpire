class_name TestAbilities
extends RefCounted

const PAR: StatusData = preload("res://data/statuses/paralysis.tres")
const BURN: StatusData = preload("res://data/statuses/burn.tres")

static func run() -> void:
	print("--- abilities ---")
	quick()
	sturdy()
	static_ability()
	regenerator()
	pickup()
	missing_hook_is_skipped()
	aftermath_side()

static func quick() -> void:
	var c := TestKit.make_combat()
	TestKit.set_hand(c, 0, ["pidgey", "bulbasaur"])
	c.sides[0].energy = 3
	c.play_card(0, 0)
	c.play_card(0, 0)
	var pidgey: Unit = c.sides[0].board[0]
	var bulb: Unit = c.sides[0].board[1]
	TestKit.check(pidgey.can_act, "Quick unit can act on summon")
	TestKit.check(not bulb.can_act, "normal unit cannot")
	TestKit.check(c.attack(pidgey, null), "Quick unit attacks the same turn")
	TestKit.check(c.sides[1].hero_hp == 30 - pidgey.get_attack(), "Quick attack hits hero")
	TestKit.check(c.attack(bulb, null) == false, "control unit refused")

	var c2 := TestKit.make_combat()
	var p := TestKit.add_unit(c2, "pidgey", 0)
	p.add_status(PAR, 1)
	p.can_act = false
	c2.fire(&"on_summoned", p)
	TestKit.check(p.can_act == false, "Quick respects paralysis")

static func sturdy() -> void:
	for case in [[5, 29, 1], [4, 30, 1], [2, 30, 0]]:
		var c := TestKit.make_combat()
		var rec := TestRec.new(c)
		var g := TestKit.add_unit(c, "geodude", 1)  # 3 HP
		c.damage_unit(g, case[0])
		TestKit.check(c.sides[1].hero_hp == case[1], "sturdy: %d damage -> hero %d" % [case[0], case[1]])
		TestKit.check(rec.abilities == case[2], "sturdy: %d damage announces %d time(s)" % [case[0], case[2]])

static func static_ability() -> void:
	# Normal: both survive, attacker paralyzed for 2 ticks
	var c := TestKit.make_combat()
	var pika := TestKit.add_unit(c, "pikachu", 1)
	var pidgey := TestKit.add_unit(c, "pidgey", 0)
	pika.current_hp = 5
	pidgey.current_hp = 6
	c.attack(pidgey, pika)
	TestKit.check(pidgey.status_effects.get(PAR, 0) == 2, "Static paralyzes with 2 turns")
	c.end_turn()
	TestKit.check(pidgey.status_effects.get(PAR, 0) == 1, "tick: 2 -> 1")
	c.end_turn()
	TestKit.check(pidgey.can_act == false, "attacker loses its next turn")
	c.end_turn()
	TestKit.check(not pidgey.has_status(PAR), "paralysis expires")

	# Dead attacker is not paralyzed
	var c2 := TestKit.make_combat()
	var rec2 := TestRec.new(c2)
	var pk2 := TestKit.add_unit(c2, "pikachu", 1)
	var pg2 := TestKit.add_unit(c2, "pidgey", 0)  # 2 HP, dies to retaliation
	c2.attack(pg2, pk2)
	TestKit.check(not pg2.is_alive(), "attacker died")
	TestKit.check(rec2.statuses == 0, "no paralysis on a corpse")

	# Dead owner still reacts
	var c3 := TestKit.make_combat()
	var pk3 := TestKit.add_unit(c3, "pikachu", 1)
	var pg3 := TestKit.add_unit(c3, "pidgey", 0)
	pk3.current_hp = 1
	pg3.current_hp = 6
	c3.attack(pg3, pk3)
	TestKit.check(not pk3.is_alive() and pg3.has_status(PAR), "dead Static owner still paralyzes")

	# A move does not trigger it
	var c4 := TestKit.make_combat()
	var rec4 := TestRec.new(c4)
	var ch := TestKit.add_unit(c4, "charmander", 0)
	var pk4 := TestKit.add_unit(c4, "pikachu", 1)
	c4.sides[0].energy = 3
	c4.use_move(ch, pk4)
	TestKit.check(not ch.has_status(PAR), "moves don't trigger Static")
	TestKit.check(rec4.abilities == 0, "no ability announced for a move")

	# No stacking
	var c5 := TestKit.make_combat()
	var pk5 := TestKit.add_unit(c5, "pikachu", 1)
	var pg5 := TestKit.add_unit(c5, "pidgey", 0)
	pg5.add_status(PAR, 1)
	c5.fire(&"on_attacked", pk5, [pg5])
	TestKit.check(pg5.status_effects.get(PAR, 0) == 1, "Static doesn't overwrite existing paralysis")

static func regenerator() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var t := TestKit.add_unit(c, "tangela", 0)  # 7 HP
	c.damage_unit(t, 5)
	c.end_turn()
	TestKit.check(t.current_hp == 4, "Regenerator heals 2 at owner's turn end")
	TestKit.check(rec.heals == [2], "unit_healed carries the amount")

	var c2 := TestKit.make_combat()
	var rec2 := TestRec.new(c2)
	var t2 := TestKit.add_unit(c2, "tangela", 0)
	t2.current_hp = 6
	c2.end_turn()
	TestKit.check(t2.current_hp == 7 and rec2.heals == [1], "heal is capped at max HP")

	var c3 := TestKit.make_combat()
	var rec3 := TestRec.new(c3)
	TestKit.add_unit(c3, "tangela", 0)
	c3.end_turn()
	TestKit.check(rec3.heals.is_empty(), "no unit_healed at full HP")

	var c4 := TestKit.make_combat()
	var t4 := TestKit.add_unit(c4, "tangela", 0)
	t4.current_hp = 1
	t4.add_status(BURN, -1)
	c4.end_turn()
	TestKit.check(not t4.is_alive(), "burn kills before Regenerator")

	var c5 := TestKit.make_combat()
	var t5 := TestKit.add_unit(c5, "tangela", 0)
	t5.current_hp = 3
	t5.add_status(BURN, -1)
	c5.end_turn()
	TestKit.check(t5.current_hp == 4, "burn 1 then heal 2")

	var c6 := TestKit.make_combat()
	var t6 := TestKit.add_unit(c6, "tangela", 0)
	c6.damage_unit(t6, 5)
	c6.active_side = 1
	c6.end_turn()
	TestKit.check(t6.current_hp == 2, "no heal at the opponent's turn end")

static func pickup() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var m := TestKit.add_unit(c, "meowth", 0)  # 3 HP
	c.sides[0].deck.append(TestKit.data("charmander"))
	c.damage_unit(m, 5)
	TestKit.check(c.sides[0].hand.size() == 1, "Pickup draws a card")
	TestKit.check(c.sides[0].hero_hp == 28, "overkill still spills")
	TestKit.check(rec.events == ["died", "ability", "drawn"], "order: died, ability, drawn")

	# Empty deck: must not crash. A dying Pickup unit can redraw itself from the discard.
	var c2 := TestKit.make_combat()
	var m2 := TestKit.add_unit(c2, "meowth", 0)
	c2.damage_unit(m2, 5)
	TestKit.check(c2.sides[0].hand.size() <= 1, "Pickup with an empty deck doesn't crash")

static func missing_hook_is_skipped() -> void:
	var c := TestKit.make_combat()
	var g := TestKit.add_unit(c, "geodude", 0)
	c.fire(&"on_missing_hook", g)
	TestKit.check(g.is_alive(), "fire skips a missing hook")
	TestKit.check(c.modify(&"modify_missing_hook", g, 5) == 5, "modify keeps value on a missing hook")

static func aftermath_side() -> void:
	# Owner (side 1) is NOT the active side when Koffing dies.
	var c := TestKit.make_combat()
	c.active_side = 0
	var koffing := TestKit.add_unit(c, "koffing", 1)   # 4 HP
	var ally := TestKit.add_unit(c, "squirtle", 1)     # owner's own team, 4 HP
	var foe_a := TestKit.add_unit(c, "charmander", 0)  # 2 HP
	var foe_b := TestKit.add_unit(c, "bulbasaur", 0)   # 3 HP
	c.damage_unit(koffing, 4)                          # exact kill, no spill
	TestKit.check(not koffing.is_alive(), "aftermath: koffing died")
	TestKit.check(foe_a.current_hp == 1 and foe_b.current_hp == 2, "aftermath hits the opponent's board, not the active side's")
	TestKit.check(ally.current_hp == 4, "aftermath never hits the owner's own team")
	TestKit.check(c.sides[0].hero_hp == 30 and c.sides[1].hero_hp == 30, "aftermath damage causes no hero damage")

	# Owner IS the active side: same result, mirrored.
	var c2 := TestKit.make_combat()
	c2.active_side = 1
	var koffing2 := TestKit.add_unit(c2, "koffing", 1)
	var ally2 := TestKit.add_unit(c2, "squirtle", 1)
	var foe2 := TestKit.add_unit(c2, "charmander", 0)
	c2.damage_unit(koffing2, 4)
	TestKit.check(foe2.current_hp == 1, "aftermath hits enemies when the owner is active")
	TestKit.check(ally2.current_hp == 4, "owner's team untouched when the owner is active")

	# Announced once, even with several targets.
	var c3 := TestKit.make_combat()
	var rec := TestRec.new(c3)
	var k3 := TestKit.add_unit(c3, "koffing", 1)
	TestKit.add_unit(c3, "charmander", 0)
	TestKit.add_unit(c3, "squirtle", 0)
	c3.damage_unit(k3, 4)
	TestKit.check(rec.abilities == 1, "aftermath announced once for multiple targets")

	# No enemies: nothing to hit, nothing announced.
	var c4 := TestKit.make_combat()
	var rec4 := TestRec.new(c4)
	var k4 := TestKit.add_unit(c4, "koffing", 1)
	c4.damage_unit(k4, 4)
	TestKit.check(rec4.abilities == 0, "aftermath with no enemies is not announced")
