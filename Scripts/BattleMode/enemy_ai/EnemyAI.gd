extends RefCounted
class_name EnemyAI

const EnemyRoleBase = preload("res://Scripts/BattleMode/enemy_ai/roles/EnemyRole.gd")
const Targets = preload("res://Scripts/BattleMode/ActionTargets.gd")

var owner: EnemyCombatant
var role: EnemyRoleBase

func _init(owner_: EnemyCombatant = null, role_: EnemyRoleBase = null) -> void:
	owner = owner_
	role = role_ if role_ != null else EnemyRoleBase.new()
	role.setup(owner)


func decide_action(context: Dictionary) -> Dictionary:
	if not Targets.living(owner):
		return {}
	# Roles propose intent and a preferred target; only the AI selects techniques.
	var proposal := role.evaluate(context)
	var requested_intent := str(proposal.get("intent", EnemyRoleBase.Intent.ATTACK))
	var requested_role := str(proposal.get("tactical_role", "enemy_attack"))
	var roster: Array = context.get("allies", []) + context.get("opponents", [])
	var available: Array = context.get("available_techniques", [])
	var compatible: Array = []
	var attacks: Array = []
	var offensive: Array = []
	var usable: Array = []
	for technique in available:
		if not Targets.valid_technique(technique):
			continue
		if Targets.resolve(owner, technique, [], roster).is_empty():
			continue
		usable.append(technique)
		if _offensive_scope(technique):
			offensive.append(technique)
			if str(technique.get("rol_combo", "")) == "enemy_attack":
				attacks.append(technique)
		if str(technique.get("rol_combo", "")) == requested_role and _matches_intent(technique, requested_intent):
			compatible.append(technique)

	var technique: Dictionary = {}
	var fallback_reason := ""
	if not compatible.is_empty():
		technique = compatible.pick_random()
	elif not attacks.is_empty():
		technique = attacks.pick_random()
		fallback_reason = "attack_fallback"
	elif not offensive.is_empty():
		technique = offensive.pick_random()
		fallback_reason = "offensive_fallback"
	elif not usable.is_empty():
		technique = usable.pick_random()
		fallback_reason = "available_fallback"
	else:
		return fallback_decision("no_usable_technique", proposal)

	var preferred = proposal.get("target", null)
	var preferences: Array = preferred if preferred is Array else [preferred]
	if str(technique.get("target_scope", "")).begins_with("RANDOM_"):
		preferences = []
	var targets := Targets.resolve(owner, technique, preferences, roster)
	var intent := requested_intent if fallback_reason.is_empty() else _intent_for(technique)
	return _decision(technique, targets, intent, proposal, fallback_reason)


func fallback_decision(reason: String, proposal: Dictionary = {}) -> Dictionary:
	if not Targets.living(owner):
		return {}
	# Safe no-op, not a defensive buff. Do not change balance through recovery logic.
	var technique := {
		"personaje": owner.id,
		"tecnique_id": "%s_ai_wait" % owner.id,
		"nombre_tech": "Esperar",
		"rol_combo": "enemy_wait",
		"descripcion": "Sin tecnica ejecutable; consume el turno sin efectos.",
		"effect": [], "efectos": [], "target_scope": "SELF",
		"allow_target_switch": false, "animation_scene": null,
		"camera_profile": "default"
	}
	return _decision(technique, [owner], "WAIT", proposal, reason)


func _decision(technique: Dictionary, targets: Array, intent: String, proposal: Dictionary, fallback_reason: String) -> Dictionary:
	var scope := str(technique.get("target_scope", ""))
	return {
		"intent": intent,
		"tactical_role": str(technique.get("rol_combo", "")),
		"reason": str(proposal.get("reason", "base_attack")) if fallback_reason.is_empty() else fallback_reason,
		"requested_intent": str(proposal.get("intent", "")),
		"requested_tactical_role": str(proposal.get("tactical_role", "")),
		"requested_reason": str(proposal.get("reason", "")),
		"fallback_reason": fallback_reason,
		"technique": technique,
		"target": targets if scope.begins_with("ALL_") else (targets[0] if not targets.is_empty() else null),
		# Compatibility aliases for the existing battle pipeline.
		"tecnica": technique,
		"objetivos": targets
	}


func _offensive_scope(technique: Dictionary) -> bool:
	return str(technique.get("target_scope", "")) in ["SINGLE_ENEMY", "RANDOM_ENEMY", "ALL_ENEMIES"]


func _matches_intent(technique: Dictionary, intent: String) -> bool:
	var scope := str(technique.get("target_scope", ""))
	match intent:
		"DEFEND", "CHARGE":
			return scope == "SELF"
		"PROTECT":
			return scope in ["SELF", "SINGLE_ALLY", "ALL_ALLIES", "RANDOM_ALLY"]
		"ATTACK", "COUNTER", "CONTROL", "INTERRUPT", "SPECIAL":
			return _offensive_scope(technique)
	return false


func _intent_for(technique: Dictionary) -> String:
	var tactical := str(technique.get("rol_combo", ""))
	if not _offensive_scope(technique):
		return "CHARGE" if tactical == "enemy_charge" and technique.get("target_scope") == "SELF" else "PROTECT"
	match tactical:
		"enemy_counter": return "COUNTER"
		"enemy_control": return "CONTROL"
		"enemy_special": return "SPECIAL"
	return "ATTACK"
