extends Node

func _ready() -> void:
	test_win_condition()


func test_win_condition():
	var combat = make_combat()
	var unit = add_unit(combat, "res://data/pokemon/charmander.tres", 0)
	combat.sides[0].energy = 3
	combat.sides[1].hero_hp = 1
	combat.attack(unit, null)

	unit.can_act = true
	print("attack: ", combat.attack(unit, null))
	print("use_move: ", combat.use_move(unit, null))
	print("play_card: ", combat.play_card(0, 0))
	#print("end_turn: ", combat.end_turn())



func make_combat() -> CombatState:
	var combat = CombatState.new()

	combat.damage_dealt.connect(_on_damage_dealt)
	combat.unit_died.connect(_on_unit_died)
	combat.hero_damaged.connect(_on_hero_damaged)
	combat.card_drawn.connect(_on_card_drawn)
	combat.unit_summoned.connect(_on_unit_summoned)
	combat.unit_attacked.connect(_on_unit_attacked)
	combat.turn_started.connect(_on_turn_started)
	combat.move_used.connect(_on_move_used)
	combat.combat_ended.connect(_on_combat_ended)
	
	return combat

func add_unit(combat: CombatState, path: String, side: int) -> Unit:
	var u := Unit.new(load(path), side)
	u.can_act = true
	combat.sides[side].board.append(u)
	return u


func _on_damage_dealt(unit: Unit, amount: int) -> void:
	print("%s took %d damage" % [unit.data.display_name, amount])


func _on_unit_died(unit: Unit) -> void:
	print("Unit died: %s" % str(unit))


func _on_hero_damaged(side_index: int, amount: int) -> void:
	print("Hero on side %d took %d damage" % [side_index, amount])


func _on_card_drawn(side_index: int, _card: PokemonData) -> void:
	print("Side %d drew a card" % side_index)


func _on_unit_summoned(unit: Unit) -> void:
	print("Unit summoned: %s" % str(unit))


func _on_unit_attacked(attacker: Unit, target: Unit) -> void:
	print("Unit attacked: %s -> %s" % [str(attacker), str(target)])


func _on_turn_started(side_index: int) -> void:
	print("Turn started for side %d" % side_index)


func _on_move_used(user:Unit, move:MoveData, target:Unit) -> void:
	var t:String
	if target == null:
		t = "Hero"
	else:
		t = target.data.display_name
	print("%s used %s on %s" % [user.data.display_name, move.display_name, t])


func _on_combat_ended(winner_side: int) -> void:
	print("Side %d won!" % winner_side)
