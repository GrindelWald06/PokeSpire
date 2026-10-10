extends Node

func _ready() -> void:
	var p: PokemonData = load("res://data/pokemon/charmander.tres")
	print(p.display_name)
	print(p.move.display_name)
	for e in p.move.effects:
		e.resolve(null)
