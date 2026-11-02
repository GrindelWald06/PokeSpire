class_name TestPlay
extends RefCounted

# play_error(side_index, hand_index) -> String: "" when the card can be played,
# otherwise a refusal message. It has no side effects, so the UI can ask freely.
# play_card must refuse exactly when play_error is not "".
# Checks test "" vs not "", never the exact wording, so messages can change.

static func run() -> void:
	print("--- play ---")
	playable_card()
	query_has_no_side_effects()
	wrong_side()
	bad_index()
	negative_index()
	not_enough_energy()
	exact_energy()
	full_board()
	combat_over()
	play_card_follows_play_error()

# Side 0 active with 3 energy, hand = names.
static func setup(names: Array) -> CombatState:
	var c := TestKit.make_combat()
	TestKit.set_hand(c, 0, names)
	c.sides[0].energy = 3
	return c

static func playable_card() -> void:
	var c := setup(["charmander"])
	TestKit.check(c.play_error(0, 0) == "", "play_error: a playable card returns empty")

static func query_has_no_side_effects() -> void:
	var c := setup(["charmander"])
	c.play_error(0, 0)
	c.play_error(0, 5)
	TestKit.check(c.sides[0].hand.size() == 1 and c.sides[0].energy == 3 and c.sides[0].board.is_empty(), "play_error: asking changes nothing")

static func wrong_side() -> void:
	var c := setup(["charmander"])
	TestKit.set_hand(c, 1, ["squirtle"])
	c.sides[1].energy = 3
	TestKit.check(c.play_error(1, 0) != "", "play_error: refuses the inactive side")

static func bad_index() -> void:
	var c := setup(["charmander"])
	TestKit.check(c.play_error(0, 1) != "", "play_error: refuses an index past the hand")
	var empty := setup([])
	TestKit.check(empty.play_error(0, 0) != "", "play_error: refuses any index on an empty hand")

static func negative_index() -> void:
	# GDScript arrays accept negative indexes (-1 = last), so a missing check
	# would silently play the last card.
	var c := setup(["charmander", "squirtle"])
	TestKit.check(c.play_error(0, -1) != "", "play_error: refuses a negative index")
	TestKit.check(c.play_card(0, -1) == false and c.sides[0].hand.size() == 2, "play_card: a negative index plays nothing")

static func not_enough_energy() -> void:
	var c := setup(["pikachu"])  # cost 3
	c.sides[0].energy = 2
	TestKit.check(c.play_error(0, 0) != "", "play_error: refuses when cost > energy")

static func exact_energy() -> void:
	var c := setup(["pikachu"])  # cost 3
	TestKit.check(c.play_error(0, 0) == "", "play_error: cost == energy is playable")

static func full_board() -> void:
	var c := setup(["bulbasaur"])
	for i in range(Side.BOARD_LIMIT):
		TestKit.add_unit(c, "squirtle", 0)
	TestKit.check(c.play_error(0, 0) != "", "play_error: refuses on a full board")

static func combat_over() -> void:
	var c := setup(["charmander"])
	c.damage_hero(1, 30)
	TestKit.check(c.is_over, "play_error setup: combat ended")
	TestKit.check(c.play_error(0, 0) != "", "play_error: refuses once combat is over")

static func play_card_follows_play_error() -> void:
	# One playable and one unplayable card in the same hand.
	var c := setup(["pikachu", "charmander"])
	c.sides[0].energy = 1
	TestKit.check(c.play_error(0, 0) != "" and c.play_card(0, 0) == false, "play_card: refused when play_error refuses")
	TestKit.check(c.sides[0].hand.size() == 2 and c.sides[0].energy == 1, "play_card: a refusal keeps hand and energy")
	TestKit.check(c.play_error(0, 1) == "" and c.play_card(0, 1), "play_card: plays when play_error is empty")
	TestKit.check(c.sides[0].board.size() == 1 and c.sides[0].energy == 0, "play_card: the card lands and costs energy")
