extends Node

func _ready() -> void:
	TestKit.reset()
	TestDamage.run()
	TestMoves.run()
	TestStatuses.run()
	TestAbilities.run()
	TestKit.summary()
