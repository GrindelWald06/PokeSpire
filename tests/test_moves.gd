class_name TestMoves
extends RefCounted

const FLY := "res://data/moves/fly.tres"

static func run() -> void:
	print("--- moves ---")
	super_effective_spill()
	resisted_hit()
	energy_rules()
	one_action_with_moves()
	aoe_types_and_no_spill()
	aoe_skips_nobody()
	bypass()
	hero_hit_ignores_types()

static func super_effective_spill() -> void:
	var c := TestKit.make_combat()
	var sq := TestKit.add_unit(c, "squirtle", 0)
	var ch := TestKit.add_unit(c, "charmander", 1)
	ch.current_hp = 4
	c.sides[0].energy = 3
	c.use_move(sq, ch)  # Water Gun 3, x2 = 6 vs 4 HP
	TestKit.check(not ch.is_alive(), "super effective kills")
	TestKit.check(c.sides[1].hero_hp == 28, "super effective hit spills more")
	TestKit.check(sq.current_hp == 4, "moves cause no retaliation")

static func resisted_hit() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	c.use_move(ch, sq)  # Ember (2) resisted -> 1
	TestKit.check(sq.current_hp == 3, "resisted hit deals 1")

static func energy_rules() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 0
	TestKit.check(c.use_move(ch, sq) == false, "move refused with no energy")
	TestKit.check(sq.current_hp == 4, "refused move deals no damage")
	c.sides[0].energy = 3
	c.use_move(ch, sq)
	TestKit.check(c.sides[0].energy == 2, "move spends its cost")

static func one_action_with_moves() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	c.use_move(ch, sq)
	TestKit.check(c.use_move(ch, sq) == false, "second move refused")
	TestKit.check(c.attack(ch, sq) == false, "attack after move refused")

static func aoe_types_and_no_spill() -> void:
	var c := TestKit.make_combat()
	var bulb := TestKit.add_unit(c, "bulbasaur", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	var ch := TestKit.add_unit(c, "charmander", 1)
	sq.current_hp = 2
	c.sides[0].energy = 3
	c.use_move(bulb, sq)  # Vine Whip 2: x2 vs water = 4 (overkill 2), x0.5 vs fire = 1
	TestKit.check(not sq.is_alive(), "AOE kills weak water target")
	TestKit.check(ch.current_hp == 1, "AOE resisted target takes 1")
	TestKit.check(c.sides[1].hero_hp == 30, "AOE never spills")

static func aoe_skips_nobody() -> void:
	var c := TestKit.make_combat()
	var bulb := TestKit.add_unit(c, "bulbasaur", 0)
	var p1 := TestKit.add_unit(c, "pikachu", 1)
	var p2 := TestKit.add_unit(c, "pikachu", 1)
	var p3 := TestKit.add_unit(c, "pikachu", 1)
	p1.current_hp = 1
	p2.current_hp = 2
	p3.current_hp = 5
	c.sides[0].energy = 3
	c.use_move(bulb, p1)
	TestKit.check(not p1.is_alive() and not p2.is_alive(), "AOE kills both weak units")
	TestKit.check(p3.current_hp == 3, "unit after the dead ones is still hit")
	TestKit.check(c.sides[1].discard.size() == 2, "both dead go to discard")
	TestKit.check(c.sides[1].hero_hp == 30, "no spill from AOE")

static func bypass() -> void:
	var c := TestKit.make_combat()
	var flyer := TestKit.add_unit_with_move(c, "charmander", 0, FLY)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	var fly_dmg: int = (flyer.data.move.effects[0] as DamageEffect).amount
	TestKit.check(c.use_move(flyer, null), "bypass move hits hero through a board")
	TestKit.check(c.sides[1].hero_hp == 30 - fly_dmg, "hero takes full bypass damage")
	TestKit.check(sq.current_hp == 4, "board untouched by bypass hit")

	var c2 := TestKit.make_combat()
	var gun := TestKit.add_unit(c2, "squirtle", 0)
	TestKit.add_unit(c2, "charmander", 1)
	c2.sides[0].energy = 3
	TestKit.check(c2.use_move(gun, null) == false, "non-bypass move on hero refused")
	TestKit.check(c2.sides[0].energy == 3, "refused move spends no energy")

static func hero_hit_ignores_types() -> void:
	var c := TestKit.make_combat()
	var gun := TestKit.add_unit(c, "squirtle", 0)
	c.sides[0].energy = 3
	c.use_move(gun, null)  # empty enemy board, so legal
	TestKit.check(c.sides[1].hero_hp == 27, "hero hit uses raw move damage")
