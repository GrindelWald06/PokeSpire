class_name DamageEffect extends Effect

@export var ammount: int

func resolve(_context) -> void:
	print("Dealt %s damage"%ammount)
