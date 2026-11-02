class_name UICombat extends Control

@export var deck0:Array[PokemonData]
@export var deck1:Array[PokemonData]

var combat_state:CombatState

func _ready() -> void:
	combat_state = CombatState.new()
	connect_signals(combat_state)
	combat_state.start_combat(deck0, deck1)


func connect_signals(state:CombatState):
	state.damage_dealt_to.connect(_on_damage_dealt_to)
	state.unit_died.connect(_on_unit_died)
	state.hero_damaged.connect(_on_hero_damaged)
	state.card_drawn.connect(_on_card_drawn)
	state.unit_summoned.connect(_on_unit_summoned)
	state.unit_attacked.connect(_on_unit_attacked)
	state.turn_started.connect(_on_turn_started)
	state.move_used.connect(_on_move_used)
	state.combat_ended.connect(_on_combat_ended)
	state.status_applied.connect(_on_status_applied)
	state.ability_triggered.connect(_on_ability_triggered)
	state.unit_healed.connect(_on_unit_healed)

func _on_damage_dealt_to(unit: Unit, amount: int) -> void:
	print(_get_target_name(unit), " took ", amount, " damage.")

func _on_unit_died(unit: Unit) -> void:
	print("Unit died: ", _get_target_name(unit))

func _on_hero_damaged(side_index: int, amount: int) -> void:
	print("Hero damaged: Side ", side_index, " took ", amount, " damage.")

func _on_card_drawn(side_index: int, card: PokemonData) -> void:
	print("Card drawn: Side ", side_index, " drew ", card.display_name)

func _on_unit_summoned(unit: Unit) -> void:
	print("Unit summoned: ", _get_target_name(unit))

func _on_unit_attacked(attacker: Unit, target: Unit) -> void:
	print("Unit attacked: ", _get_target_name(attacker), " attacked ", _get_target_name(target))

func _on_turn_started(side_index: int) -> void:
	print("Turn started: Side ", side_index)

func _on_move_used(user: Unit, move: MoveData, target: Unit) -> void:
	print("Move used: ", _get_target_name(user), " used ", move.display_name, " on ", _get_target_name(target))

func _on_combat_ended(winner_side: int) -> void:
	print("Combat ended: Winner is side ", winner_side)

func _on_status_applied(unit: Unit, status: StatusData) -> void:
	print("Status applied: ", status.display_name, " applied to ", _get_target_name(unit))

func _on_ability_triggered(unit: Unit, ability: HookSource) -> void:
	print("Ability triggered: ", _get_target_name(unit), " triggered ", ability.display_name)

func _on_unit_healed(unit: Unit, amount: int) -> void:
	print("Unit healed: ", _get_target_name(unit), " recovered ", amount, " HP.")

func _get_target_name(unit:Unit) -> String:
	if unit != null:
		return unit.data.display_name
	return "Hero"
