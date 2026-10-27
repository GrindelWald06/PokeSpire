class_name TestKit
extends RefCounted

static var passed := 0
static var failed := 0

static func reset() -> void:
	passed = 0
	failed = 0

static func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)

static func summary() -> void:
	print("=== %d passed, %d failed ===" % [passed, failed])

static func data(pokemon_name: String) -> PokemonData:
	return load("res://data/pokemon/%s.tres" % pokemon_name)

static func make_combat() -> CombatState:
	return CombatState.new()

# Puts a unit on a board with can_act = true. side_index always matches the board.
static func add_unit(combat: CombatState, pokemon_name: String, side: int) -> Unit:
	var u := Unit.new(data(pokemon_name), side)
	u.can_act = true
	combat.sides[side].board.append(u)
	return u

# Same, but with a different move. Duplicates the data so shared resources stay untouched.
static func add_unit_with_move(combat: CombatState, pokemon_name: String, side: int, move_path: String) -> Unit:
	var d: PokemonData = data(pokemon_name).duplicate()
	d.move = load(move_path)
	var u := Unit.new(d, side)
	u.can_act = true
	combat.sides[side].board.append(u)
	return u

static func set_hand(combat: CombatState, side: int, names: Array) -> void:
	combat.sides[side].hand.clear()
	for n in names:
		combat.sides[side].hand.append(data(n))
