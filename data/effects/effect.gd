class_name Effect extends Resource
# Base class for effect, overrided.

func resolve(_ctx: EffectContext) -> void:
	pass

func _to_string() -> String:
	return "Empty Effect class"
