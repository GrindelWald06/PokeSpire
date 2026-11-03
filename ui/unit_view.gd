class_name UnitView extends PanelContainer

var unit:Unit

signal body_pressed(unit)
signal move_pressed(unit)

func setup(state:CombatState, p_unit:Unit) -> void:
	unit = p_unit
	
	%BodyButton.pressed.connect(func(): body_pressed.emit(unit))
	%MoveButton.pressed.connect(func(): move_pressed.emit(unit))
	
	%BodyButton.text = get_unit_body_display(state)
	if unit.data.move != null:
		%MoveButton.visible = true
		%MoveButton.text = "%s (%d)" % [unit.data.move.display_name, unit.data.move.cost]
	else:
		%MoveButton.visible = false
	

func get_unit_body_display(state:CombatState) -> String:
	var result = ""
	result += unit.data.display_name + "\n"
	result += "ATK %d    HP %d/%d\n" % [state.get_attack(unit), unit.current_hp, unit.max_hp]
	result += "Current status:\n"
	for status in unit.statuses:
		result += "%s" % status.display_name
		var i = unit.get_intensity(status)
		if i > 1:
			result += " +%d" % i
		var t = unit.get_turns(status)
		if t > 0:
			result += " (%d)" % t
		result += "\n"
		
	return result
