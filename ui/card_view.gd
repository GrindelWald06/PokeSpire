class_name CardView extends Button

var hand_index:int

signal card_pressed(hand_index:int)

func setup(card:PokemonData, p_hand_index:int) -> void:
	hand_index = p_hand_index
	
	pressed.connect(func(): card_pressed.emit(hand_index))
	text = get_card_display(card)

func get_card_display(card:PokemonData) -> String:
	var result = ""
	result += "%s (%d)\n" % [card.display_name, card.cost]
	result += "ATK %d  HP %d" % [card.attack, card.max_hp]
	
	if card.move != null:
		result += "\n%s (%d)" % [card.move.display_name, card.move.cost]

	return result
