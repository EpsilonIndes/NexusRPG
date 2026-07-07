extends EnemyRole
class_name ProtectorRole


func evaluate(context: Dictionary) -> Dictionary:
	var protect_technique := _find_tactical_technique(context, [TacticalRole.PROTECT])
	if protect_technique.is_empty():
		protect_technique = _find_technique_by_scope(context, ["SINGLE_ALLY", "ALL_ALLIES", "SELF"])
	if not protect_technique.is_empty():
		return {
			"intent": Intent.PROTECT,
			"tactical_role": TacticalRole.PROTECT,
			"technique": protect_technique,
			"target": _find_healthiest_ally(context),
			"reason": "protect_ally"
		}

	return super.evaluate(context)
