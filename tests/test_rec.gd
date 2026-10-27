class_name TestRec
extends RefCounted

var abilities := 0
var heals: Array = []
var statuses := 0
var drawn := 0
var ended: Array = []
var events: Array = []

func _init(c: CombatState) -> void:
	c.ability_triggered.connect(_on_ability)
	c.unit_healed.connect(_on_healed)
	c.status_applied.connect(_on_status)
	c.card_drawn.connect(_on_drawn)
	c.combat_ended.connect(_on_ended)
	c.unit_died.connect(_on_died)

func _on_ability(_u, _a) -> void:
	abilities += 1
	events.append("ability")

func _on_healed(_u, amount) -> void:
	heals.append(amount)

func _on_status(_u, _k) -> void:
	statuses += 1

func _on_drawn(_s, _c) -> void:
	drawn += 1
	events.append("drawn")

func _on_ended(winner) -> void:
	ended.append(winner)

func _on_died(_u) -> void:
	events.append("died")
