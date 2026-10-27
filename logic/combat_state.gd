class_name CombatState extends RefCounted

var sides: Array[Side]
var active_side: int = 0
var turn_number: int = 1
var is_over:bool = false

signal damage_dealt(unit:Unit, amount:int)
signal unit_died(unit:Unit)
signal hero_damaged(side_index:int, amount:int)
signal card_drawn(side_index:int, card:PokemonData)
signal unit_summoned(unit:Unit)
signal unit_attacked(attacker:Unit, target:Unit)
signal turn_started(side_index:int)
signal move_used(user:Unit, move:MoveData, target:Unit)
signal combat_ended(winner_side:int)
signal status_applied(unit:Unit, status:Status.STATUS)
signal status_damage(unit:Unit, amount:int)
signal ability_triggered(unit:Unit, ability:Ability)
signal unit_healed(unit:Unit, amount:int)

func _init() -> void:
	sides.append(Side.new())
	sides.append(Side.new())

func opponent_of(side_index:int) -> int:
	return 1 - side_index

func damage_hero(side_index, amount) -> void:
	sides[side_index].hero_hp -= amount
	hero_damaged.emit(side_index, amount)
	if sides[side_index].hero_hp <= 0 and not is_over:
		is_over = true
		combat_ended.emit(opponent_of(side_index))

func damage_unit(unit:Unit, amount:int, allow_spill:=true) -> void:
	amount = modify(&"modify_incoming_damage", unit, amount)
	var overkill = max (0, amount - unit.current_hp)
	overkill = modify(&"modify_spill", unit, overkill)
	# deal damage
	unit.current_hp = max(0, unit.current_hp - amount)
	damage_dealt.emit(unit, amount)
	
	# deal with overkill
	if overkill > 0 and allow_spill:
		damage_hero(unit.side_index, overkill)

	# manage death
	if not unit.is_alive():
		sides[unit.side_index].board.erase(unit)
		sides[unit.side_index].discard.append(unit.data)
		unit_died.emit(unit)
		fire(&"on_death", unit)

func heal_unit(unit:Unit, amount:int) -> void:
	if amount <= 0:
		return
	var heal_amount = min(amount, unit.data.max_hp - unit.current_hp)
	if heal_amount > 0:
		unit.current_hp += heal_amount
		unit_healed.emit(unit, heal_amount)

func start_combat() -> void:
	# draw 5 cards for each side
	for side_index in range(2):
		sides[side_index].deck.shuffle()
		draw_cards(side_index, 5)

	start_turn(0)

func start_turn(side_index:int) -> void:
	turn_started.emit(side_index)
	# set active side
	active_side = side_index
	
	# fill energy
	sides[side_index].energy = sides[side_index].max_energy
	
	# allow units to act
	for unit in sides[side_index].board:
		unit.can_act = not unit.has_status(Status.STATUS.PARALYSIS)
		fire(&"on_turn_start", unit)

	# draw a card
	draw_cards(side_index, 1)

func end_turn() -> void:
	if is_over:
		print("Combat is over")
		return
	
	# Apply end of turn effects:
	for unit in sides[active_side].board.duplicate():
		# Apply burn damage
		if unit.has_status(Status.STATUS.BURN):
			status_damage.emit(unit, Status.STATUS.BURN)
			damage_unit(unit, 1, false)
		if not unit.is_alive():
			continue
		fire(&"on_turn_end", unit)
		if not unit.is_alive():
			continue
		# Decremente remaining turns for statuses
		for status in unit.statuses.keys():
			if unit.statuses[status] >= 1:
				unit.statuses[status] -= 1
				if unit.statuses[status] == 0:
					unit.statuses.erase(status)

	if is_over:
		print("Combat is over")
		return

	var next_side := opponent_of(active_side)
	if next_side == 0:
		turn_number += 1
	start_turn(next_side)

func draw_cards(side_index:int, amount:int) -> void:
	for i in range(amount):
		var drawn = sides[side_index].draw_card()
		if drawn:
			card_drawn.emit(side_index, drawn)

func play_card(side_index:int, hand_index:int) -> bool:
	if is_over:
		print("Combat is over")
		return false

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
	fire(&"on_summoned", unit)
	return true

func _attack_error(attacker:Unit, target:Unit) -> String:
	if not attacker in sides[active_side].board:
		return "%s not in the active side" % attacker.data.display_name
	if attacker.has_status(Status.STATUS.PARALYSIS):
		return "%s is Paralyzed and can not attack" % attacker.data.display_name
	if not attacker.can_act:
		return "%s can't act" % attacker.data.display_name
	if target == null:
		if not sides[opponent_of(active_side)].board.is_empty():
			return "Can't attack hero if board is not empty"
		return ""
	if not target.is_alive():
		return "%s is not alive" % target.data.display_name
	if not target in sides[opponent_of(active_side)].board:
		return "%s is not in the opposing board" % target.data.display_name
	return ""

func attack(attacker:Unit, target:Unit) -> bool:
	if is_over:
		print("Combat is over")
		return false

	var attack_error = _attack_error(attacker, target)
	if attack_error != "":
		print(attack_error)
		return false
	
	attacker.can_act = false
	unit_attacked.emit(attacker, target)
	if target == null:
		damage_hero(opponent_of(active_side), attacker.get_attack())
	else:
		# Trade handling
		var damage_taken = target.get_attack()
		damage_unit(target, attacker.get_attack())
		damage_unit(attacker, damage_taken, false)
		fire(&"on_attacked", target, [attacker])
	return true

func _move_error(user:Unit, target:Unit) -> String:
	if not user.is_alive():
		return "%s is not alive" % user.data.display_name
	if user.side_index != active_side:
		return "Can't use moves out of turn"
	if user.has_status(Status.STATUS.PARALYSIS):
		return "%s is Paralyzed and can not use move" % user.data.display_name
	if not user.can_act:
		return "%s can't act" % user.data.display_name
	var move_to_use = user.data.move
	if move_to_use == null:
		return "%s has no move to use" % user.data.display_name
	if move_to_use.cost > sides[active_side].energy:
		return "Not enough energy to use"
	if move_to_use.target_mode == MoveData.TargetMode.SINGLE_ENEMY:
		# target is the hero
		if target == null:
			if not sides[opponent_of(active_side)].board.is_empty() and not move_to_use.bypass:
				return "Can't target hero if board is not empty"
			return ""
		# target is a pokemon
		if not target.is_alive():
			return "%s is dead" % target.data.display_name
		if target.side_index != opponent_of(user.side_index):
			return "Can only target opponent's pokemons"
	return ""

func use_move(user:Unit, target:Unit) -> bool:
	if is_over:
		print("Combat is over")
		return false

	var move_error = _move_error(user, target)
	if move_error != "":
		print(move_error)
		return false

	var move_to_use = user.data.move
	sides[active_side].energy -= move_to_use.cost
	user.can_act = false
	move_used.emit(user, move_to_use, target)

	var context = EffectContext.new(self, user, target, true, user.data.move.type)

	if move_to_use.target_mode == MoveData.TargetMode.SINGLE_ENEMY:
		context.target = target
		for effect in move_to_use.effects:
			if context.target == null or context.target.is_alive():
				effect.resolve(context)
	elif move_to_use.target_mode == MoveData.TargetMode.ALL_ENEMIES:
		context.allow_spill = false
		for effect in move_to_use.effects:
			for unit in sides[opponent_of(active_side)].board.duplicate():
				context.target = unit
				if context.target.is_alive():
					effect.resolve(context)
	else: # case target is self
		context.target = user
		for effect in move_to_use.effects:
			if context.target.is_alive():
				effect.resolve(context)
	return true

# Ability hooks
func fire(hook:StringName, unit:Unit, args:Array = []) -> void:
	for source in unit.get_hook_sources():
		if not source.has_method(hook):
			push_error("No hook named %s found" % hook)
		source.callv(hook, [self, unit] + args)

func modify(hook:StringName, unit:Unit, value:int, args:Array = []) -> int:
	for source in unit.get_hook_sources():
		if not source.has_method(hook):
			push_error("No hook named %s found" % hook)
		value = source.callv(hook, [self, unit] + args + [value])
	return value
