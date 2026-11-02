class_name TestSignals
extends RefCounted

# The UI redraws only from signals, so these tests pin down which signals fire
# and in what order. Each expected list is the whole sequence for one action.
# Also covers turn setup, the hand limit and own-side targeting.

const BURN: StatusData = preload("res://data/statuses/burn.tres")

static func run() -> void:
	print("--- signals ---")
	summon()
	summon_quick()
	trade()
	kill_with_spill()
	hero_attack_wins()
	move_with_status()
	burn_tick_then_next_turn()
	regenerator_heal()
	aftermath_order()
	turn_started_sees_new_turn()
	start_combat()
	start_turn_setup()
	hand_limit()
	own_side_targets()

static func expect(rec: TestLog, expected: Array, label: String) -> void:
	var ok := rec.events == expected
	TestKit.check(ok, label)
	if not ok:
		print("    expected: ", expected)
		print("    got:      ", rec.events)

static func summon() -> void:
	var c := TestKit.make_combat()
	TestKit.set_hand(c, 0, ["charmander"])
	c.sides[0].energy = 3
	var rec := TestLog.new(c)
	c.play_card(0, 0)
	expect(rec, ["summoned Charmander"], "signals: summon")

static func summon_quick() -> void:
	var c := TestKit.make_combat()
	TestKit.set_hand(c, 0, ["pidgey"])
	c.sides[0].energy = 3
	var rec := TestLog.new(c)
	c.play_card(0, 0)
	expect(rec, ["summoned Pidgey", "ability Pidgey"], "signals: summon, then its on-summon ability")

static func trade() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)  # 2/2
	var d := TestKit.add_unit(c, "squirtle", 1)    # 1/4
	var rec := TestLog.new(c)
	c.attack(a, d)
	expect(rec, ["attacked Charmander Squirtle", "damage Squirtle 2", "damage Charmander 1"],
		"signals: trade = attacked, defender damage, then retaliation")

static func kill_with_spill() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)  # attack 2
	var d := TestKit.add_unit(c, "bulbasaur", 1)   # attack 1
	d.current_hp = 1
	var rec := TestLog.new(c)
	c.attack(a, d)
	# Retaliation still lands: its damage was read before the defender died.
	expect(rec, ["attacked Charmander Bulbasaur", "damage Bulbasaur 2", "hero 1 1", "died Bulbasaur", "damage Charmander 1"],
		"signals: damage, spill, death, then retaliation")

static func hero_attack_wins() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	c.sides[1].hero_hp = 2
	var rec := TestLog.new(c)
	c.attack(a, null)
	expect(rec, ["attacked Charmander hero", "hero 1 2", "ended 0"], "signals: lethal hero hit ends combat last")

static func move_with_status() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var sq := TestKit.add_unit(c, "squirtle", 1)
	c.sides[0].energy = 3
	var rec := TestLog.new(c)
	c.use_move(ch, sq)  # Ember: 2 resisted to 1, then burn
	expect(rec, ["move Charmander Squirtle", "damage Squirtle 1", "status Squirtle"],
		"signals: move, its damage, then its status")

static func burn_tick_then_next_turn() -> void:
	var c := TestKit.make_combat()
	var sq := TestKit.add_unit(c, "squirtle", 1)
	sq.add_status(BURN, -1)
	c.active_side = 1
	c.sides[0].deck.append(TestKit.data("charmander"))
	var rec := TestLog.new(c)
	c.end_turn()
	expect(rec, ["ability Squirtle", "damage Squirtle 1", "turn 0", "drawn 0"],
		"signals: end of turn ticks, then the next turn starts and draws")

static func regenerator_heal() -> void:
	var c := TestKit.make_combat()
	var t := TestKit.add_unit(c, "tangela", 0)
	t.current_hp = 3
	c.active_side = 0
	var rec := TestLog.new(c)
	c.end_turn()
	expect(rec, ["ability Tangela", "healed Tangela 2", "turn 1"], "signals: Regenerator announces, then heals")

static func aftermath_order() -> void:
	var c := TestKit.make_combat()
	var k := TestKit.add_unit(c, "koffing", 1)
	TestKit.add_unit(c, "charmander", 0)
	var rec := TestLog.new(c)
	c.damage_unit(k, 4)
	expect(rec, ["damage Koffing 4", "died Koffing", "ability Koffing", "damage Charmander 1"],
		"signals: death before its on-death ability")

# Bug check: a turn_started handler must see the new turn's state.
static func turn_started_sees_new_turn() -> void:
	var c := TestKit.make_combat()
	c.sides[1].energy = 0
	var seen: Array = []
	c.turn_started.connect(func(s): seen.append([s, c.active_side, c.sides[s].energy]))
	c.end_turn()  # side 0 -> side 1
	TestKit.check(seen.size() == 1 and seen[0][0] == 1, "turn_started: fires once for the new side")
	TestKit.check(seen.size() == 1 and seen[0][1] == 1, "turn_started: active_side is already the new side")
	TestKit.check(seen.size() == 1 and seen[0][2] == c.sides[1].max_energy, "turn_started: energy is already refilled")

static func start_combat() -> void:
	var c := TestKit.make_combat()
	var deck0: Array[PokemonData] = []
	var deck1: Array[PokemonData] = []
	for i in range(10):
		deck0.append(TestKit.data("charmander"))
		deck1.append(TestKit.data("squirtle"))
	var rec := TestLog.new(c)
	c.start_combat(deck0, deck1)
	var expected: Array = []
	for i in range(5): expected.append("drawn 0")
	for i in range(5): expected.append("drawn 1")
	expected.append_array(["turn 0", "drawn 0"])
	expect(rec, expected, "start_combat: 5 each, then turn 0 and its draw")
	TestKit.check(c.sides[0].hand.size() == 6 and c.sides[1].hand.size() == 5, "start_combat: hands are 6 and 5")
	TestKit.check(c.active_side == 0 and c.turn_number == 1 and c.sides[0].energy == 3, "start_combat: side 0, turn 1, 3 energy")
	TestKit.check(deck0.size() == 10 and deck1.size() == 10, "start_combat: the decks passed in are copied, not consumed")

static func start_turn_setup() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "squirtle", 1)
	u.can_act = false
	c.sides[1].energy = 0
	c.sides[1].deck.append(TestKit.data("charmander"))
	c.end_turn()  # side 1 starts
	TestKit.check(c.sides[1].energy == c.sides[1].max_energy, "start_turn: energy refilled")
	TestKit.check(u.can_act, "start_turn: units can act again")
	TestKit.check(c.sides[1].hand.size() == 1, "start_turn: draws 1")

static func hand_limit() -> void:
	# A draw into a full hand goes to the discard. (TODO: a card_burned signal.)
	var c := TestKit.make_combat()
	var names: Array = []
	for i in range(Side.HAND_LIMIT): names.append("charmander")
	TestKit.set_hand(c, 0, names)
	c.sides[0].deck.append(TestKit.data("squirtle"))
	c.draw_cards(0, 1)
	TestKit.check(c.sides[0].hand.size() == Side.HAND_LIMIT, "hand limit: hand stays at 10")
	TestKit.check(c.sides[0].discard.size() == 1 and c.sides[0].deck.is_empty(), "hand limit: the extra card is discarded")

static func own_side_targets() -> void:
	var c := TestKit.make_combat()
	var ch := TestKit.add_unit(c, "charmander", 0)
	var ally := TestKit.add_unit(c, "squirtle", 0)
	var foe := TestKit.add_unit(c, "bulbasaur", 1)
	c.sides[0].energy = 3
	foe.can_act = true
	TestKit.check(c.attack_error(ch, ally) != "", "targets: can't attack your own unit")
	TestKit.check(c.move_error(ch, ally) != "", "targets: can't aim a move at your own unit")
	TestKit.check(c.attack_error(foe, ch) != "", "targets: the inactive side can't attack")