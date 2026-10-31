class_name TestStatuses
extends RefCounted

const BURN: StatusData = preload("res://data/statuses/burn.tres")
const PAR: StatusData = preload("res://data/statuses/paralysis.tres")

static func run() -> void:
	print("--- statuses ---")
	burn_applies_and_ticks()
	burn_reduces_attack()
	burn_kill()
	no_stacking()
	dead_target_not_burned()
	paralysis_lifecycle()
	paralysis_on_summoned_unit()
	burn_keeps_ability_bonus()

static func burn_applies_and_ticks() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	c.use_move(ch, sq)
	TestKit.check(sq.has_status(BURN), "Ember burns")
	TestKit.check(sq.current_hp == 3, "Ember damage applied")
	c.end_turn()  # side 0 ends: Squirtle belongs to side 1
	TestKit.check(sq.current_hp == 3, "no burn tick at the attacker's turn end")
	c.end_turn()  # side 1 ends
	TestKit.check(sq.current_hp == 2, "burn ticks at owner's turn end")

static func burn_reduces_attack() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	ch.add_status(BURN, -1)
	sq.add_status(BURN, -1)
	TestKit.check(ch.get_attack() == 1, "burn gives -1 attack")
	TestKit.check(sq.get_attack() == 0, "attack never below 0")

static func burn_kill() -> void:
	var c := TestKit.make_combat()
	var sq := TestKit.add_unit(c, "squirtle", 1)
	sq.current_hp = 1
	sq.add_status(BURN, -1)
	c.active_side = 1
	c.end_turn()
	TestKit.check(not sq.is_alive(), "burn kills at end of owner's turn")
	TestKit.check(c.sides[1].discard.size() == 1, "burned unit goes to discard")
	TestKit.check(c.sides[1].hero_hp == 30, "burn never spills")

static func no_stacking() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var a := TestKit.add_unit(c, "charmander", 0)
	var b := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	c.use_move(a, sq)
	c.use_move(b, sq)
	TestKit.check(rec.statuses == 1, "burn announced once")
	TestKit.check(sq.current_hp == 2, "second Ember still deals damage")

static func dead_target_not_burned() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	sq.current_hp = 1
	c.sides[0].energy = 3
	c.use_move(ch, sq)
	TestKit.check(not sq.is_alive(), "Ember killed the target")
	TestKit.check(rec.statuses == 0, "no burn applied to a corpse")

static func paralysis_lifecycle() -> void:
	var c := TestKit.make_combat()
	var pika := TestKit.add_unit(c, "pikachu", 0)
	var bulb := TestKit.add_unit(c, "bulbasaur", 1)
	c.sides[0].energy = 3
	c.use_move(pika, bulb)  # Thunder Shock
	TestKit.check(bulb.status_effects.get(PAR, 0) == 1, "paralysis applied for 1 turn")
	c.end_turn()  # side 1's turn starts
	TestKit.check(bulb.can_act == false, "paralyzed unit cannot act")
	TestKit.check(c.attack(bulb, null) == false, "paralyzed attack refused")
	TestKit.check(c.use_move(bulb, null) == false, "paralyzed move refused")
	c.end_turn()  # side 1 ends: tick removes it
	TestKit.check(not bulb.has_status(PAR), "paralysis expires")
	c.end_turn()  # side 1 starts again
	TestKit.check(bulb.can_act == true, "unit acts again afterwards")

static func paralysis_on_summoned_unit() -> void:
	var c := TestKit.make_combat()
	var pika := TestKit.add_unit(c, "pikachu", 0)
	c.end_turn()
	TestKit.set_hand(c, 1, ["bulbasaur"])
	c.sides[1].energy = 3
	c.play_card(1, 0)
	var summoned: Unit = c.sides[1].board[0]
	c.end_turn()
	c.sides[0].energy = 3
	c.use_move(pika, summoned)
	TestKit.check(summoned.can_act == false and summoned.has_status(PAR), "summoned + paralyzed")
	c.end_turn()
	TestKit.check(summoned.can_act == false, "still frozen on its first turn")
	c.end_turn()
	TestKit.check(not summoned.has_status(PAR), "status gone")
	c.end_turn()
	TestKit.check(summoned.can_act == true, "acts the turn after")

static func burn_keeps_ability_bonus() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)  # 2 attack
	ch.data = ch.data.duplicate()
	ch.data.ability = Ability.new()
	ch.data.ability.attack_bonus = 2
	TestKit.check(ch.get_attack() == 4, "ability bonus applies")
	ch.add_status(BURN, -1)
	TestKit.check(ch.get_attack() == 3, "burn keeps ability bonus (2 + 2 - 1)")
