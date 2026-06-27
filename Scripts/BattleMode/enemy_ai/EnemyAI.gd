extends RefCounted
class_name EnemyAI

const EnemyRoleBase = preload("res://Scripts/BattleMode/enemy_ai/roles/EnemyRole.gd")

var owner: EnemyCombatant = null
var role: EnemyRoleBase = null


func _init(owner_: EnemyCombatant = null, role_: EnemyRoleBase = null) -> void:
	owner = owner_
	role = role_
	if role != null and role.has_method("setup"):
		role.setup(owner)


func decide_action(context: Dictionary) -> Dictionary:
	if owner == null:
		return _empty_decision("missing_owner")
		
	var active_role := role
	if active_role == null:
		active_role = EnemyRoleBase.new()

	var role_decision := active_role.evaluate(context)
	var intent := str(role_decision.get("intent", EnemyRoleBase.Intent.ATTACK))
	var technique: Dictionary = role_decision.get("technique", {})
	var target = role_decision.get("target", null)

	if technique.is_empty():
		technique = _select_default_technique(context, intent)

	if technique.is_empty():
		return _empty_decision("missing_technique")

	if target == null:
		target = _select_default_target(context, technique)

	if _needs_living_target(technique) and _normalize_targets(target).is_empty():
		var alternative := _select_non_offensive_technique(context)
		if not alternative.is_empty():
			technique = alternative
			target = _select_default_target(context, technique)
			if _needs_living_target(technique) and _normalize_targets(target).is_empty():
				return _defend_decision("missing_living_targets")
		else:
			return _defend_decision("missing_living_targets")

	return {
		"intent": intent,
		"technique": technique,
		"target": target,
		"reason": str(role_decision.get("reason", "default_attack")),
		"tecnica": technique,
		"objetivos": _normalize_targets(target)
	}


func _select_default_technique(context: Dictionary, intent: String) -> Dictionary:
	var techniques: Array = context.get("available_techniques", [])
	if techniques.is_empty():
		return {}

	var preferred := _filter_techniques_for_intent(techniques, intent)
	if not preferred.is_empty():
		return preferred.pick_random()

	return techniques.pick_random()


func _select_non_offensive_technique(context: Dictionary) -> Dictionary:
	var techniques: Array = context.get("available_techniques", [])
	for technique in techniques:
		if not technique is Dictionary:
			continue

		var scope := str(technique.get("target_scope", "SINGLE_ENEMY"))
		if scope in ["SELF", "SINGLE_ALLY", "ALL_ALLIES", "RANDOM_ALLY"]:
			return technique

	return {}


func _filter_techniques_for_intent(techniques: Array, intent: String) -> Array:
	var result: Array = []
	for technique in techniques:
		if not technique is Dictionary:
			continue

		var scope := str(technique.get("target_scope", "SINGLE_ENEMY"))
		match intent:
			EnemyRoleBase.Intent.DEFEND, EnemyRoleBase.Intent.CHARGE:
				if scope == "SELF":
					result.append(technique)
			EnemyRoleBase.Intent.PROTECT:
				if scope in ["SINGLE_ALLY", "ALL_ALLIES", "SELF"]:
					result.append(technique)
			_:
				if scope in ["SINGLE_ENEMY", "RANDOM_ENEMY", "ALL_ENEMIES"]:
					result.append(technique)

	return result


func _select_default_target(context: Dictionary, technique: Dictionary):
	var scope := str(technique.get("target_scope", "SINGLE_ENEMY"))
	var allies: Array = context.get("allies", [])
	var opponents: Array = context.get("opponents", [])

	match scope:
		"ALL_ENEMIES":
			return opponents.duplicate()
		"ALL_ALLIES":
			return allies.duplicate()
		"SINGLE_ALLY", "RANDOM_ALLY":
			return _pick_lowest_hp_ratio(allies)
		"SELF":
			return owner
		_:
			return _pick_lowest_hp_ratio(opponents)


func _needs_living_target(technique: Dictionary) -> bool:
	var scope := str(technique.get("target_scope", "SINGLE_ENEMY"))
	return scope in ["SINGLE_ENEMY", "RANDOM_ENEMY", "ALL_ENEMIES", "SINGLE_ALLY", "RANDOM_ALLY", "ALL_ALLIES"]


func _pick_lowest_hp_ratio(candidates: Array):
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


func _normalize_targets(target) -> Array:
	if target == null:
		return []
	if target is Array:
		return target.filter(func(t): return t != null and is_instance_valid(t) and t.has_method("esta_vivo") and t.esta_vivo())
	if target != null and is_instance_valid(target) and target.has_method("esta_vivo") and target.esta_vivo():
		return [target]
	return []


func _defend_decision(reason: String) -> Dictionary:
	var owner_id := ""
	if owner != null:
		owner_id = owner.id
	var technique_id := "enemy_ai_defend"
	if owner_id != "":
		technique_id = "%s_ai_defend" % owner_id

	var technique := {
		"personaje": owner_id,
		"tecnique_id": technique_id,
		"nombre_tech": "Defensa",
		"rol_combo": "enemy",
		"descripcion": "Fallback defensivo de IA enemiga.",
		"costo_drive": 0,
		"score_value": 0,
		"arma": "natural",
		"effect": [],
		"efectos": [],
		"target_scope": "SELF",
		"allow_target_switch": false,
		"tipo_dano": "",
		"visual_tipo": "",
		"animation_scene": null
	}
	return {
		"intent": EnemyRoleBase.Intent.DEFEND,
		"technique": technique,
		"target": owner,
		"reason": reason,
		"tecnica": technique,
		"objetivos": [owner] if owner != null else []
	}


func _empty_decision(reason: String) -> Dictionary:
	return {
		"intent": EnemyRoleBase.Intent.NONE,
		"technique": {},
		"target": null,
		"reason": reason,
		"tecnica": {},
		"objetivos": []
	}
