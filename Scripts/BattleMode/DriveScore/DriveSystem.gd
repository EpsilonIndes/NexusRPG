# DriveSystem.gd
# Recibe eventos resueltos del combate y centraliza puntaje total, resonancia, combos y feedback.

class_name DriveSystem
extends Node

signal score_changed(new_score, delta, event)
signal rank_changed(old_rank, new_rank)
signal combo_changed(combo_state)
signal feedback_requested(feedback)
signal action_registered(result)
signal resonance_reset(reason)
signal overdrive_meter_changed(value)
signal overdrive_started()
signal overdrive_ended()

var total_drive_score: int = 0
var current_resonance_score: int = 0
var current_resonance_rank: String = "Static Pulse"
var highest_resonance_rank: String = "Static Pulse"

# Alias de compatibilidad. No crear otra logica con estos nombres.
var score: int = 0
var rank: String = "Static Pulse"
var drive_score: int = 0
var drive_rank: String = "Static Pulse"

var last_roles: Array[String] = []
var last_technique_id: String = ""
var repeated_role_count: int = 0
var repeated_technique_count: int = 0
var combo_chain: int = 0
var combo_sequence: Array[String] = []
var max_combo_chain: int = 0
var feedback_log: Array[Dictionary] = []
var action_history: Array[Dictionary] = []
var active_rank_bonus: Dictionary = {}

var overdrive_meter: float = 0.0
var overdrive_active: bool = false
var damage_buffer: int = 0
var resonance_break_protection: int = 0
var combo_break_protection: int = 0
var combo_extension_bonus: int = 0

var max_overdrive_meter: float = 100.0
var spam_threshold: int = 2
var history_limit: int = 30
var feedback_limit: int = 20

const RANK_THRESHOLDS := [
	{"rank": "Static Pulse", "min": 0},
	{"rank": "Tandem Flow", "min": 1000},
	{"rank": "Overdrive Sync", "min": 1500},
	{"rank": "Harmonic Surge", "min": 2250},
	{"rank": "Soul Gear Resonance", "min": 3000},
	{"rank": "Nexus Ascent", "min": 5000}
]

const ROLE_FLOW := {
	"opener": ["linker", "support"],
	"linker": ["linker", "finisher", "support"],
	"support": ["opener", "linker", "finisher"],
	"finisher": ["opener", "support"]
}


func reset_battle() -> void:
	total_drive_score = 0
	current_resonance_score = 0
	current_resonance_rank = "Static Pulse"
	highest_resonance_rank = "Static Pulse"
	_sync_compat_aliases()
	last_roles.clear()
	last_technique_id = ""
	repeated_role_count = 0
	repeated_technique_count = 0
	combo_chain = 0
	combo_sequence.clear()
	max_combo_chain = 0
	feedback_log.clear()
	action_history.clear()
	active_rank_bonus.clear()
	overdrive_meter = 0.0
	overdrive_active = false
	damage_buffer = 0
	resonance_break_protection = 0
	combo_break_protection = 0
	combo_extension_bonus = 0
	emit_signal("score_changed", total_drive_score, 0, {})
	emit_signal("rank_changed", "Static Pulse", current_resonance_rank)
	emit_signal("combo_changed", get_combo_state())
	emit_signal("overdrive_meter_changed", overdrive_meter)


func register_action(action_event: Dictionary) -> Dictionary:
	if action_event.is_empty():
		return {}

	var role := str(action_event.get("role", action_event.get("rol_combo", "")))
	var technique_id := str(action_event.get("technique_id", action_event.get("tecnique_id", "")))
	var base_score := int(action_event.get("base_score", action_event.get("score_value", 0)))
	var damage_done := int(action_event.get("damage_done", 0))
	var healing_done := int(action_event.get("healing_done", 0))
	var defeated_count := int(action_event.get("defeated_count", 0))
	var targets_hit := int(action_event.get("targets_hit", 0))
	var valid_action := bool(action_event.get("valid_action", true))

	var role_delta := _evaluate_role(role)
	var combo_result := _evaluate_combo(role)
	if not valid_action:
		combo_result["broken"] = true
	var combo_delta := int(combo_result.get("delta", 0))
	var repeat_delta := _evaluate_technique_repeat(technique_id)
	var impact_delta := int(damage_done / 3.0) + int(healing_done / 4.0)
	var defeated_delta := defeated_count * 250
	var target_delta = max(0, targets_hit - 1) * 25
	var raw_action_score = base_score + role_delta + combo_delta + repeat_delta + impact_delta + defeated_delta + target_delta
	if not valid_action:
		raw_action_score = 0
	var action_score = max(0, raw_action_score)

	if overdrive_active and damage_done > 0:
		damage_buffer += damage_done

	var total_before := total_drive_score
	var resonance_before := current_resonance_score
	var rank_before := current_resonance_rank

	total_drive_score += action_score
	current_resonance_score += action_score
	_update_resonance_rank()
	_update_overdrive_meter(action_score)
	_sync_compat_aliases()

	var result := {
		"action_score": action_score,
		"raw_action_score": raw_action_score,
		"total_before": total_before,
		"total_after": total_drive_score,
		"resonance_before": resonance_before,
		"resonance_after": current_resonance_score,
		"rank_before": rank_before,
		"rank_after": current_resonance_rank,
		"highest_resonance_rank": highest_resonance_rank,
		"combo_finished": bool(combo_result.get("finished", false)),
		"combo_broken": bool(combo_result.get("broken", false)),
		"base_score": base_score,
		"role_delta": role_delta,
		"combo_delta": combo_delta,
		"repeat_delta": repeat_delta,
		"impact_delta": impact_delta,
		"defeated_delta": defeated_delta,
		"target_delta": target_delta,
		"event": action_event.duplicate(true),
		"feedback": _build_feedback(action_event, action_score, combo_delta, repeat_delta, defeated_count, combo_result)
	}

	_record_action(result)
	_register_feedback(result.feedback)
	emit_signal("score_changed", total_drive_score, action_score, action_event)
	emit_signal("combo_changed", get_combo_state())
	emit_signal("action_registered", result)
	return result


func end_combo(reason: String) -> void:
	if _consume_combo_break_protection():
		return
	reset_resonance(reason)


func break_combo(reason: String) -> void:
	if _consume_combo_break_protection():
		return
	reset_resonance(reason)


func add_drive(amount) -> void:
	var delta = max(0, int(amount))
	if delta <= 0:
		return

	total_drive_score += delta
	_update_overdrive_meter(delta)
	_sync_compat_aliases()
	emit_signal("score_changed", total_drive_score, delta, {"source": "effect", "effect": "drive:add"})


func add_resonance(amount) -> void:
	var delta = max(0, int(amount))
	if delta <= 0:
		return

	var previous_score := current_resonance_score
	current_resonance_score += delta
	_update_resonance_rank()
	_sync_compat_aliases()
	emit_signal("score_changed", total_drive_score, current_resonance_score - previous_score, {"source": "effect", "effect": "resonance:add"})


func reset_resonance(reason: String = "effect") -> void:
	if _consume_resonance_break_protection():
		return

	var previous_rank := current_resonance_rank
	current_resonance_score = 0
	current_resonance_rank = "Static Pulse"
	rank = current_resonance_rank
	drive_rank = current_resonance_rank
	active_rank_bonus.clear()
	combo_chain = 0
	combo_sequence.clear()
	combo_extension_bonus = 0
	emit_signal("combo_changed", get_combo_state())
	if previous_rank != current_resonance_rank:
		emit_signal("rank_changed", previous_rank, current_resonance_rank)
	emit_signal("resonance_reset", reason)


func protect_resonance_break(count: int = 1) -> void:
	resonance_break_protection += max(0, int(count))


func extend_combo(amount: int = 1) -> void:
	var delta = max(0, int(amount))
	if delta <= 0:
		return

	# Extension effect: incrementa la cadena de combo actual sin cambiar el flujo
	combo_extension_bonus += delta
	combo_chain += delta
	max_combo_chain = max(max_combo_chain, combo_chain)
	emit_signal("combo_changed", get_combo_state())


func protect_combo_break(count: int = 1) -> void:
	combo_break_protection += max(0, int(count))


func reset_combo(reason: String = "effect") -> void:
	if _consume_combo_break_protection():
		return
	reset_resonance(reason)


func get_battle_summary() -> Dictionary:
	return {
		"total_drive_score": total_drive_score,
		"drive_score": total_drive_score,
		"score": total_drive_score,
		"current_resonance_score": current_resonance_score,
		"current_resonance_rank": current_resonance_rank,
		"highest_resonance_rank": highest_resonance_rank,
		"drive_rank": highest_resonance_rank,
		"rank": current_resonance_rank,
		"combo": get_combo_state(),
		"active_rank_bonus": active_rank_bonus.duplicate(true),
		"overdrive_meter": overdrive_meter,
		"overdrive_active": overdrive_active,
		"damage_buffer": damage_buffer,
		"resonance_break_protection": resonance_break_protection,
		"combo_break_protection": combo_break_protection,
		"combo_extension_bonus": combo_extension_bonus,
		"feedback": feedback_log.duplicate(true),
		"actions": action_history.duplicate(true)
	}


func get_summary() -> Dictionary:
	return get_battle_summary()


func _evaluate_role(role: String) -> int:
	if role == "" or role == "enemy":
		return 0

	var value := 0
	if last_roles.is_empty():
		value = 25
	elif role != last_roles.back():
		value = 35
		repeated_role_count = 0
	else:
		repeated_role_count += 1
		if not overdrive_active and repeated_role_count >= spam_threshold:
			value = -35
		else:
			value = 10

	last_roles.append(role)
	if last_roles.size() > 5:
		last_roles.pop_front()

	return value


func _evaluate_technique_repeat(technique_id: String) -> int:
	if technique_id == "":
		return 0

	if technique_id == last_technique_id:
		repeated_technique_count += 1
	else:
		repeated_technique_count = 0

	last_technique_id = technique_id

	if repeated_technique_count <= 0:
		return 0
	return -min(80, 20 * repeated_technique_count)


func _evaluate_combo(role: String) -> Dictionary:
	if role == "" or role == "enemy":
		return {"delta": 0, "finished": false, "broken": false}

	if combo_sequence.is_empty():
		combo_sequence.append(role)
		combo_chain = 1
		max_combo_chain = max(max_combo_chain, combo_chain)
		return {"delta": 20 if role == "opener" else 0, "finished": false, "broken": false}

	var previous_role = combo_sequence.back()
	var allowed_next: Array = ROLE_FLOW.get(previous_role, [])
	var is_valid_flow := role in allowed_next
	var was_broken := false

	if is_valid_flow:
		combo_chain += 1
		combo_sequence.append(role)
	else:
		was_broken = true
		combo_chain = 1
		combo_sequence = [role]

	if combo_sequence.size() > 6:
		combo_sequence.pop_front()

	max_combo_chain = max(max_combo_chain, combo_chain)

	var delta := combo_chain * 15 if is_valid_flow else -10
	var finished := false
	if role == "finisher" and combo_chain >= 3:
		delta += combo_chain * 35
		finished = true

	return {
		"delta": delta,
		"finished": finished,
		"broken": was_broken,
		"valid_flow": is_valid_flow
	}


func _update_resonance_rank() -> void:
	var previous_rank := current_resonance_rank

	for threshold in RANK_THRESHOLDS:
		if current_resonance_score >= int(threshold["min"]):
			current_resonance_rank = str(threshold["rank"])

	active_rank_bonus = _build_rank_bonus_metadata(current_resonance_rank)
	highest_resonance_rank = _higher_rank(highest_resonance_rank, current_resonance_rank)
	_sync_compat_aliases()

	if current_resonance_rank != previous_rank:
		emit_signal("rank_changed", previous_rank, current_resonance_rank)


func _update_overdrive_meter(delta: int) -> void:
	if delta > 0:
		overdrive_meter += delta * 0.3

	overdrive_meter = clamp(overdrive_meter, 0, max_overdrive_meter)
	emit_signal("overdrive_meter_changed", overdrive_meter)


func _record_action(result: Dictionary) -> void:
	action_history.append(result)
	if action_history.size() > history_limit:
		action_history.pop_front()


func _register_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	feedback_log.append(feedback)
	if feedback_log.size() > feedback_limit:
		feedback_log.pop_front()
	emit_signal("feedback_requested", feedback)


func _build_feedback(event: Dictionary, action_score: int, combo_delta: int, repeat_delta: int, defeated_count: int, combo_result: Dictionary) -> Dictionary:
	var tags: Array[String] = []
	if bool(combo_result.get("finished", false)):
		tags.append("combo_finish")
	elif combo_delta > 0:
		tags.append("combo_flow")
	elif bool(combo_result.get("broken", false)):
		tags.append("combo_break")

	if repeat_delta < 0:
		tags.append("repeat_penalty")
	if defeated_count > 0:
		tags.append("defeat_bonus")

	var text := "+%d DriveScore" % action_score
	if tags.has("combo_finish"):
		text = "Combo cerrado: %s" % text
	elif tags.has("combo_flow"):
		text = "Flujo de combo: %s" % text
	elif tags.has("repeat_penalty"):
		text = "Repeticion detectada: %s" % text

	return {
		"text": text,
		"tags": tags,
		"delta": action_score,
		"total_drive_score": total_drive_score,
		"current_resonance_score": current_resonance_score,
		"current_resonance_rank": current_resonance_rank,
		"rank": current_resonance_rank,
		"combo_chain": combo_chain,
		"actor_id": event.get("actor_id", ""),
		"technique_id": event.get("technique_id", "")
	}


func _build_rank_bonus_metadata(rank_name: String) -> Dictionary:
	if rank_name == "Static Pulse":
		return {}

	return {
		"rank": rank_name,
		"source": "drive_resonance",
		"active": true
	}


func _sync_compat_aliases() -> void:
	score = total_drive_score
	drive_score = total_drive_score
	rank = current_resonance_rank
	drive_rank = current_resonance_rank


func _higher_rank(a: String, b: String) -> String:
	return b if _rank_index(b) > _rank_index(a) else a


func _rank_index(rank_name: String) -> int:
	for i in range(RANK_THRESHOLDS.size()):
		if str(RANK_THRESHOLDS[i]["rank"]) == rank_name:
			return i
	return 0


func _consume_resonance_break_protection() -> bool:
	if resonance_break_protection <= 0:
		return false

	resonance_break_protection -= 1
	emit_signal("combo_changed", get_combo_state())
	return true


func _consume_combo_break_protection() -> bool:
	if combo_break_protection <= 0:
		return false

	combo_break_protection -= 1
	emit_signal("combo_changed", get_combo_state())
	return true


func get_combo_state() -> Dictionary:
	return {
		"chain": combo_chain,
		"max_chain": max_combo_chain,
		"sequence": combo_sequence.duplicate(),
		"last_roles": last_roles.duplicate(),
		"last_technique_id": last_technique_id,
		"repeated_role_count": repeated_role_count,
		"repeated_technique_count": repeated_technique_count,
		"resonance_break_protection": resonance_break_protection,
		"combo_break_protection": combo_break_protection,
		"combo_extension_bonus": combo_extension_bonus
	}
