extends RefCounted
## Shared scope validation. Candidates always come from the current battle roster.

const SCOPES := ["SELF", "SINGLE_ENEMY", "RANDOM_ENEMY", "ALL_ENEMIES", "SINGLE_ALLY", "RANDOM_ALLY", "ALL_ALLIES"]

static func living(value) -> bool:
	return is_instance_valid(value) and value is Combatant and value.esta_vivo()


static func valid_technique(value) -> bool:
	if not value is Dictionary or str(value.get("tecnique_id", "")).is_empty():
		return false
	if str(value.get("target_scope", "")) not in SCOPES:
		return false
	var effects = value.get("efectos", null)
	if not effects is Array:
		return false
	for effect in effects:
		if not effect is Array or effect.is_empty() or not effect[0] is String:
			return false
	var animation = value.get("animation_scene", null)
	return animation == null or animation is PackedScene


static func resolve(actor, technique: Dictionary, preferred: Array, roster: Array, replace_missing: bool = true) -> Array:
	if not living(actor):
		return []
	var scope := str(technique.get("target_scope", ""))
	if scope not in SCOPES:
		return []
	if scope == "SELF":
		return [actor]
	var allies := scope in ["SINGLE_ALLY", "RANDOM_ALLY", "ALL_ALLIES"]
	var candidates: Array = []
	for candidate in roster:
		if living(candidate) and (candidate.es_jugador == actor.es_jugador) == allies and candidate not in candidates:
			candidates.append(candidate)
	if scope.begins_with("ALL_"):
		return candidates
	if scope.begins_with("RANDOM_"):
		# Preserve a previously rolled valid target when revalidating an action.
		if preferred.size() == 1 and preferred[0] in candidates:
			return [preferred[0]]
		return [candidates.pick_random()] if not candidates.is_empty() else []
	for target in preferred:
		if target in candidates:
			return [target]
	if not replace_missing or candidates.is_empty():
		return []
	var best = candidates[0]
	for candidate in candidates:
		if float(candidate.hp) / max(1, candidate.hp_max) < float(best.hp) / max(1, best.hp_max):
			best = candidate
	return [best]
