extends RefCounted
class_name EnemyRole

var owner: EnemyCombatant = null

class Intent:
	const NONE := "NONE"
	const ATTACK := "ATTACK"
	const COUNTER := "COUNTER"
	const DEFEND := "DEFEND"
	const CHARGE := "CHARGE"
	const INTERRUPT := "INTERRUPT"
	const PROTECT := "PROTECT"
	const CONTROL := "CONTROL"
	const SPECIAL := "SPECIAL"


class TacticalRole:
	const ATTACK := "enemy_attack"
	const COUNTER := "enemy_counter"
	const CONTROL := "enemy_control"
	const PROTECT := "enemy_protect"
	const CHARGE := "enemy_charge"
	const SPECIAL := "enemy_special"


func setup(owner_: EnemyCombatant) -> void:
	owner = owner_


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.ATTACK,
		"tactical_role": TacticalRole.ATTACK,
		"technique": _find_attack_technique(context),
		"target": _find_vulnerable_opponent(context),
		"reason": "base_attack"
	}


func _find_attack_technique(context: Dictionary) -> Dictionary:
	var tactical := _find_tactical_technique(context, [TacticalRole.ATTACK])
	if not tactical.is_empty():
		return tactical

	var scoped := _find_technique_by_scope(context, ["SINGLE_ENEMY", "RANDOM_ENEMY", "ALL_ENEMIES"])
	if not scoped.is_empty():
		return scoped

	var techniques: Array = context.get("available_techniques", [])
	return techniques[0] if not techniques.is_empty() and techniques[0] is Dictionary else {}


func _find_tactical_technique(context: Dictionary, tactical_roles: Array) -> Dictionary:
	var techniques: Array = context.get("available_techniques", [])
	for role_name in tactical_roles:
		for technique in techniques:
			if technique is Dictionary and str(technique.get("rol_combo", "")) == str(role_name):
				return technique
	return {}


func _find_technique_by_scope(context: Dictionary, scopes: Array) -> Dictionary:
	var techniques: Array = context.get("available_techniques", [])
	for technique in techniques:
		if technique is Dictionary and str(technique.get("target_scope", "")) in scopes:
			return technique
	return {}


func _find_vulnerable_opponent(context: Dictionary):
	return _find_lowest_hp_ratio(context.get("opponents", []))


func _find_lowest_hp_ratio(candidates: Array):
	var best = null
	var best_ratio := INF
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate) or not candidate.has_method("esta_vivo") or not candidate.esta_vivo():
			continue

		var max_hp = max(1.0, float(candidate.get("hp_max")))
		var ratio = float(candidate.get("hp")) / max_hp
		if ratio < best_ratio:
			best_ratio = ratio
			best = candidate

	return best


func _find_healthiest_ally(context: Dictionary):
	var allies: Array = context.get("allies", [])
	var best = null
	var best_ratio := -1.0
	for ally in allies:
		if ally == null or not is_instance_valid(ally) or not ally.has_method("esta_vivo") or not ally.esta_vivo():
			continue

		var max_hp = max(1.0, float(ally.get("hp_max")))
		var ratio = float(ally.get("hp")) / max_hp
		if ratio > best_ratio:
			best_ratio = ratio
			best = ally

	return best
