class_name AbilityTrigger extends Resource

enum Hook { ON_SUMMONED, ON_TURN_START, ON_TURN_END, ON_ATTACKED, ON_DEATH }

enum Target { SELF, ATTACKER, ALL_ENEMIES, ALL_ALLIES }

@export var hook:Hook
@export var target:Target
@export var effects:Array[Effect]
