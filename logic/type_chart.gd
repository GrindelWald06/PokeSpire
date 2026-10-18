class_name TypeChart extends RefCounted

const SUPER = {
	Types.Type.NORMAL: [],
	Types.Type.FIRE: [Types.Type.GRASS, Types.Type.BUG],
	Types.Type.WATER: [Types.Type.FIRE, Types.Type.GROUND, Types.Type.ROCK],
	Types.Type.GRASS: [Types.Type.WATER, Types.Type.GROUND, Types.Type.ROCK],
	Types.Type.ELECTRIC: [Types.Type.WATER, Types.Type.FLYING],
	Types.Type.GROUND: [Types.Type.FIRE, Types.Type.ELECTRIC, Types.Type.ROCK, Types.Type.POISON],
	Types.Type.ROCK: [Types.Type.FIRE, Types.Type.FLYING, Types.Type.BUG],
	Types.Type.FLYING: [Types.Type.GRASS, Types.Type.FIGHTING, Types.Type.BUG],
	Types.Type.FIGHTING: [Types.Type.NORMAL, Types.Type.ROCK],
	Types.Type.BUG: [Types.Type.GRASS],
	Types.Type.POISON: [Types.Type.GRASS],
}

const RESIST = {
	Types.Type.NORMAL: [Types.Type.ROCK],
	Types.Type.FIRE: [Types.Type.FIRE, Types.Type.WATER, Types.Type.ROCK],
	Types.Type.WATER: [Types.Type.WATER, Types.Type.GRASS],
	Types.Type.GRASS: [Types.Type.GRASS, Types.Type.FIRE, Types.Type.FLYING, Types.Type.BUG, Types.Type.POISON],
	Types.Type.ELECTRIC: [Types.Type.ELECTRIC, Types.Type.GRASS, Types.Type.GROUND],
	Types.Type.GROUND: [Types.Type.GRASS, Types.Type.BUG, Types.Type.FLYING],
	Types.Type.ROCK: [Types.Type.GROUND, Types.Type.FIGHTING],
	Types.Type.FLYING: [Types.Type.ELECTRIC, Types.Type.ROCK],
	Types.Type.FIGHTING: [Types.Type.FLYING, Types.Type.BUG, Types.Type.POISON],
	Types.Type.BUG: [Types.Type.BUG, Types.Type.FIRE, Types.Type.FLYING, Types.Type.POISON, Types.Type.FIGHTING],
	Types.Type.POISON: [Types.Type.POISON, Types.Type.GROUND, Types.Type.ROCK],
}

static func step(attack_type: Types.Type, defender_types: Array[Types.Type]) -> int:
	if attack_type == Types.Type.NONE:
		return 0
	
	var total = 0
	for def_type in defender_types:
		if def_type in SUPER.get(attack_type, []):
			total += 1
		elif def_type in RESIST.get(attack_type, []):
			total -= 1
	
	return clampi(total, -1, 1)

static func apply(amount:int, _step:int) -> int:
	if _step == 1:
		return amount * 2
	elif _step == -1:
		@warning_ignore("integer_division")
		return max(1, amount/2)
	else:
		return amount
