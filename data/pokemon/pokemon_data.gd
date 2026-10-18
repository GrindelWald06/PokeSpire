class_name PokemonData extends Resource

@export var id: StringName
@export var display_name: String
@export var cost: int
@export var attack: int
@export var max_hp: int
@export var types: Array[Types.Type]
@export var rarity: StringName
@export var evolves_into: Array[PokemonData]
@export var move: MoveData
@export var ability: StringName

func _to_string() -> String:
	return "PokemonData(id=%s, display_name=%s, cost=%d, attack=%d, max_hp=%d, types=%s, rarity=%s, evolves_into=%s, move=%s, ability=%s)" % [
		id,
		display_name,
		cost,
		attack,
		max_hp,
		str(types),
		rarity,
		str(evolves_into),
		str(move),
		ability
	]
