class_name TestDamage
extends RefCounted

static func run() -> void:
	print("--- damage ---")
	spill()
	exact_kill_no_spill()
	no_spill_flag()
	basic_trade()
	retaliation_never_spills()
	taunt_rule()
	empty_board_hero_attack()
	summoning_sickness()
	one_action_per_turn()
	turn_number()
	win_condition()
	reshuffle()
	type_chart()

static func spill() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "charmander", 1)  # 2 HP
	c.damage_unit(u, 3)
	TestKit.check(c.sides[1].hero_hp == 29, "overkill spills to hero")
	TestKit.check(c.sides[1].board.is_empty(), "dead unit leaves board")
	TestKit.check(c.sides[1].discard.size() == 1, "dead unit goes to discard")

static func exact_kill_no_spill() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "charmander", 1)
	c.damage_unit(u, 2)
	TestKit.check(c.sides[1].hero_hp == 30, "exact kill has no spill")

static func no_spill_flag() -> void:
	var c := TestKit.make_combat()
	var u := TestKit.add_unit(c, "charmander", 1)
	c.damage_unit(u, 5, false)
	TestKit.check(c.sides[1].hero_hp == 30, "allow_spill=false blocks spill")

static func basic_trade() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)  # atk 2, hp 2
	var d := TestKit.add_unit(c, "squirtle", 1)    # atk 1, hp 4
	TestKit.check(c.attack(a, d), "attack succeeds")
	TestKit.check(d.current_hp == 2, "defender takes attacker's attack")
	TestKit.check(a.current_hp == 1, "attacker takes retaliation")

static func retaliation_never_spills() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	a.current_hp = 1
	var d := TestKit.add_unit(c, "pikachu", 1)  # atk 3
	d.current_hp = 5
	c.attack(a, d)
	TestKit.check(not a.is_alive(), "attacker dies to retaliation")
	TestKit.check(c.sides[0].hero_hp == 30, "retaliation does not spill")

static func taunt_rule() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	TestKit.add_unit(c, "squirtle", 1)
	TestKit.check(c.attack(a, null) == false, "cannot hit hero through a board")
	TestKit.check(c.sides[1].hero_hp == 30, "hero untouched after refused attack")

static func empty_board_hero_attack() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	TestKit.check(c.attack(a, null), "hero attack allowed on empty board")
	TestKit.check(c.sides[1].hero_hp == 28, "hero takes attack damage")

static func summoning_sickness() -> void:
	var c := TestKit.make_combat()
	TestKit.set_hand(c, 0, ["charmander"])
	c.sides[0].energy = 3
	TestKit.check(c.play_card(0, 0), "play_card succeeds")
	TestKit.check(c.sides[0].energy == 2, "play_card spends cost")
	var u: Unit = c.sides[0].board[0]
	TestKit.check(c.attack(u, null) == false, "summoned unit cannot attack")

static func one_action_per_turn() -> void:
	var c := TestKit.make_combat()
	var a := TestKit.add_unit(c, "charmander", 0)
	c.attack(a, null)
	TestKit.check(c.attack(a, null) == false, "second attack refused")

static func turn_number() -> void:
	var c := TestKit.make_combat()
	TestKit.check(c.turn_number == 1, "starts at turn 1")
	c.end_turn()
	TestKit.check(c.turn_number == 1, "turn 1 after first end_turn")
	c.end_turn()
	TestKit.check(c.turn_number == 2, "turn 2 when control returns to side 0")
	c.end_turn()
	TestKit.check(c.turn_number == 2, "turn 2 after third end_turn")

static func win_condition() -> void:
	var c := TestKit.make_combat()
	var rec := TestRec.new(c)
	var u := TestKit.add_unit(c, "charmander", 0)
	c.sides[1].hero_hp = 1
	c.attack(u, null)
	TestKit.check(rec.ended == [0], "combat_ended fires once with winner 0")
	u.can_act = true
	TestKit.check(c.attack(u, null) == false, "attack refused after win")
	TestKit.check(c.use_move(u, null) == false, "use_move refused after win")
	TestKit.check(c.play_card(0, 0) == false, "play_card refused after win")
	c.end_turn()
	TestKit.check(c.active_side == 0, "end_turn does nothing after win")
	c.damage_hero(1, 5)
	TestKit.check(rec.ended.size() == 1, "combat_ended never fires twice")

static func reshuffle() -> void:
	var c := TestKit.make_combat()
	var s := c.sides[0]
	s.deck.clear()
	s.discard.append(TestKit.data("charmander"))
	s.discard.append(TestKit.data("squirtle"))
	var card = s.draw_card()
	TestKit.check(card != null, "draw reshuffles discard into deck")
	TestKit.check(s.deck.size() == 1 and s.discard.is_empty(), "discard moved to deck")
	TestKit.check(s.hand.size() == 1, "drawn card is in hand")

static func type_chart() -> void:
	var T := Types.Type
	TestKit.check(TypeChart.step(T.FIRE, [T.GRASS]) == 1, "fire > grass")
	TestKit.check(TypeChart.step(T.FIRE, [T.WATER]) == -1, "fire < water")
	TestKit.check(TypeChart.step(T.FIRE, [T.NORMAL]) == 0, "fire vs normal")
	TestKit.check(TypeChart.step(T.FIRE, [T.GRASS, T.POISON]) == 1, "fire vs bulbasaur")
	TestKit.check(TypeChart.step(T.GROUND, [T.FLYING]) == -1, "ground < flying")
	TestKit.check(TypeChart.step(T.WATER, [T.FIRE, T.ROCK]) == 1, "double weakness clamps to +1")
	TestKit.check(TypeChart.step(T.GRASS, [T.GRASS, T.GROUND]) == 0, "resist + weak cancel")
	TestKit.check(TypeChart.step(T.NONE, [T.FIRE]) == 0, "NONE is neutral")
	TestKit.check(TypeChart.apply(3, 1) == 6, "apply +1 doubles")
	TestKit.check(TypeChart.apply(3, -1) == 1, "apply -1 halves")
	TestKit.check(TypeChart.apply(1, -1) == 1, "apply -1 minimum is 1")
	TestKit.check(TypeChart.apply(3, 0) == 3, "apply 0 unchanged")
