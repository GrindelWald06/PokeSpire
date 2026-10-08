class_name PokemonData extends Resource

@export var id: StringName
@export var display_name: String
@export var cost: int
@export var attack: int
@export var max_hp: int
@export var types: Array[StringName]
@export var rarity: StringName
@export var evolves_into: Array[PokemonData]
@export var move: MoveData
@export var ability: StringName
