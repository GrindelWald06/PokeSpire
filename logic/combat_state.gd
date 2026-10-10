class_name CombatState extends RefCounted

var sides: Array[Side]
var active_side: int = 0
var turn_number: int = 1

signal damage_dealt(unit:Unit, amount:int)
signal unit_died(unit:Unit)
signal hero_damaged(side_index:int, amount:int)
signal card_drawn(side_index:int, card:PokemonData)
signal unit_summoned(unit:Unit)
signal unit_attacked(attacker:Unit, target:Unit)
signal turn_started(side_index:int)

func _init() -> void:
	sides.append(Side.new())
	sides.append(Side.new())

func opponent_of(side_index:int) -> int:
	return 1 - side_index

func damage_hero(side_index, amount) -> void:
	sides[side_index].hero_hp -= amount
	hero_damaged.emit(side_index, amount)

func damage_unit(unit:Unit, amount:int, allow_spill:=true) -> void:
	var overkill = max (0, amount - unit.current_hp)
	# deal damage
	unit.current_hp = max(0, unit.current_hp - amount)
	damage_dealt.emit(unit, amount)
	
	# deal with overkill
	if overkill > 0 and allow_spill:
		damage_hero(unit.side_index, overkill)

	# manage death
	if not unit.is_alive():
		sides[unit.side_index].board.erase(unit)
		unit_died.emit(unit)

func start_combat() -> void:
	# draw 5 cards for each side
	var drawn:PokemonData
	for side_index in range(2):
		sides[side_index].deck.shuffle()
		for i in range(5):
			drawn = sides[side_index].draw_card()
			card_drawn.emit(side_index, drawn)
	
	start_turn(0)

func start_turn(side_index:int) -> void:
	turn_started.emit(side_index)

	# set active side
	active_side = side_index
	
	# fill energy
	sides[side_index].energy = sides[side_index].max_energy
	
	# allow units to act
	for unit in sides[side_index].board:
		unit.can_act = true

	# draw a card
	var drawn = sides[side_index].draw_card()
	if drawn:
		card_drawn.emit(side_index, drawn)

func end_turn() -> void:
	start_turn(opponent_of(active_side))
	turn_number += 1

func play_card(side_index:int, hand_index:int) -> bool:
	if side_index != active_side:
		print("Not the active player")
		return false

	var side = sides[side_index]
	if hand_index >= side.hand.size():
		print("Card index out of range")
		return false

	var card_to_play = side.hand[hand_index]
	if card_to_play.cost > side.energy:
		print("Not enough energy to play")
		return false
	if side.board.size() > side.BOARD_LIMIT:
		print("Not enough slots in the board to play")
		return false
	
	side.hand.erase(card_to_play)
	side.energy -= card_to_play.cost
	var unit = Unit.new(card_to_play, side_index)
	side.board.append(unit)
	unit_summoned.emit(unit)
	return true

func _attack_error(attacker:Unit, target:Unit) -> String:
	if not attacker in sides[active_side].board:
		return "Attacker not in the active side"
	if not attacker.can_act:
		return "Attacker can't act"
	if target == null:
		if not sides[opponent_of(active_side)].board.is_empty():
			return "Can't attack hero if board is not empty"
		return ""
	if not target.is_alive():
		return "Target is not alive"
	if not target in sides[opponent_of(active_side)].board:
		return "Target is not in the opposing board"
	return ""
	
func attack(attacker:Unit, target:Unit) -> bool:
	var attack_error = _attack_error(attacker, target)
	if attack_error != "":
		print(attack_error)
		return false
	
	attacker.can_act = false
	unit_attacked.emit(attacker, target)
	if target == null:
		damage_hero(opponent_of(active_side), attacker.attack)
	else:
		# Trade handling
		var damage_taken = target.attack
		damage_unit(target, attacker.attack)
		damage_unit(attacker, damage_taken, false)
	return true
