class_name TestLog
extends RefCounted

# Records every CombatState signal, in order, as one readable string each.
# The UI will animate from this sequence, so its order is the contract.

var events: Array[String] = []

func _init(c: CombatState) -> void:
	c.turn_started.connect(func(s): events.append("turn %d" % s))
	c.card_drawn.connect(func(s, _card): events.append("drawn %d" % s))
	c.unit_summoned.connect(func(u): events.append("summoned %s" % _n(u)))
	c.unit_attacked.connect(func(a, t): events.append("attacked %s %s" % [_n(a), _n(t)]))
	c.move_used.connect(func(u, _m, t): events.append("move %s %s" % [_n(u), _n(t)]))
	c.damage_dealt.connect(func(u, amount): events.append("damage %s %d" % [_n(u), amount]))
	c.hero_damaged.connect(func(s, amount): events.append("hero %d %d" % [s, amount]))
	c.unit_died.connect(func(u): events.append("died %s" % _n(u)))
	c.unit_healed.connect(func(u, amount): events.append("healed %s %d" % [_n(u), amount]))
	c.status_applied.connect(func(u, _s): events.append("status %s" % _n(u)))
	c.ability_triggered.connect(func(u, _src): events.append("ability %s" % _n(u)))
	c.combat_ended.connect(func(w): events.append("ended %d" % w))

func clear() -> void:
	events.clear()

static func _n(u: Unit) -> String:
	return "hero" if u == null else u.data.display_name
