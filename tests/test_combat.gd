extends Node

func _ready() -> void:
	var combat = CombatState.new()
	
	var deck = []
	for i in range(5):
		combat.sides[0].deck.append(load("res://data/pokemon/charmander.tres"))
		combat.sides[1].deck.append(load("res://data/pokemon/squirtle.tres"))
	for i in range(5):
		combat.sides[1].deck.append(load("res://data/pokemon/charmander.tres"))
		combat.sides[0].deck.append(load("res://data/pokemon/squirtle.tres"))


	combat.damage_dealt.connect(_on_damage_dealt)
	combat.unit_died.connect(_on_unit_died)
	combat.hero_damaged.connect(_on_hero_damaged)
	combat.card_drawn.connect(_on_card_drawn)
	combat.unit_summoned.connect(_on_unit_summoned)
	combat.unit_attacked.connect(_on_unit_attacked)
	combat.turn_started.connect(_on_turn_started)

	combat.start_combat()
	combat.play_card(0, 0)
	for i in range(20):
		combat.end_turn()


func _on_damage_dealt(unit: Unit, amount: int) -> void:
	print("Damage dealt: %s took %d damage" % [str(unit), amount])


func _on_unit_died(unit: Unit) -> void:
	print("Unit died: %s" % str(unit))


func _on_hero_damaged(side_index: int, amount: int) -> void:
	print("Hero on side %d took %d damage" % [side_index, amount])


func _on_card_drawn(side_index: int, card: PokemonData) -> void:
	print("Side %d drew a card" % side_index)


func _on_unit_summoned(unit: Unit) -> void:
	print("Unit summoned: %s" % str(unit))


func _on_unit_attacked(attacker: Unit, target: Unit) -> void:
	print("Unit attacked: %s -> %s" % [str(attacker), str(target)])


func _on_turn_started(side_index: int) -> void:
	print("Turn started for side %d" % side_index)
