class_name Side extends RefCounted

const BOARD_LIMIT := 5
const HAND_LIMIT := 10

var hero_hp: int = 30
var hero_max_hp: int = 30
var deck: Array[PokemonData] = []
var hand: Array[PokemonData] = []
var discard: Array[PokemonData] = []
var board: Array[Unit] = []
var energy: int = 0
var max_energy: int = 3

func draw_card() -> PokemonData:
	if deck.is_empty():
		deck = discard
		discard.clear()
		deck.shuffle()

	if deck.is_empty():
		return null

	var drawn_card = deck.pop_back()
	if hand.size() < HAND_LIMIT:
		hand.append(drawn_card)
	else:
		discard.append(drawn_card)
	
	return drawn_card
