extends EnemyRole
class_name ProtectorRole

func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.PROTECT,
		"tactical_role": TacticalRole.PROTECT,
		"target": _find_healthiest_ally(context),
		"reason": "protect_ally"
	}
