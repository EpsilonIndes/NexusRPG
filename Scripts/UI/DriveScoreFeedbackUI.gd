class_name DriveScoreFeedbackUI
extends Control

@export var max_feedback_lines: int = 4
@export var auto_flush_delay: float = 0.35

var drive_system: DriveSystem = null
var score_label: Label
var rank_label: Label
var combo_label: Label
var sequence_label: Label
var feedback_list: VBoxContainer
var layout_built := false
var pending_score: Variant = null
var pending_rank: Variant = null
var pending_combo: Dictionary = {}
var pending_feedback: Array[Dictionary] = []
var has_pending_combo := false
var auto_flush_scheduled := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_layout()
	if drive_system != null and is_instance_valid(drive_system):
		var summary := drive_system.get_battle_summary()
		_set_score(int(summary.get("total_drive_score", summary.get("score", 0))))
		_set_rank(str(summary.get("current_resonance_rank", summary.get("rank", "Static Pulse"))))
		_set_combo(summary.get("combo", {}))
	else:
		_reset_view()


func bind_drive_system(system: DriveSystem) -> void:
	_ensure_layout()

	if drive_system == system:
		if drive_system != null:
			var summary = drive_system.get_battle_summary()
			_set_score(int(summary.get("total_drive_score", summary.get("score", 0))))
			_set_rank(str(summary.get("current_resonance_rank", summary.get("rank", "Static Pulse"))))
			_set_combo(summary.get("combo", {}))
		return

	if drive_system != null and is_instance_valid(drive_system):
		_disconnect_drive_system()

	drive_system = system
	if drive_system == null:
		_reset_view()
		return

	var score_callable := Callable(self, "_on_score_changed")
	var rank_callable := Callable(self, "_on_rank_changed")
	var combo_callable := Callable(self, "_on_combo_changed")
	var feedback_callable := Callable(self, "_on_feedback_requested")

	if not drive_system.score_changed.is_connected(score_callable):
		drive_system.score_changed.connect(score_callable)
	if not drive_system.rank_changed.is_connected(rank_callable):
		drive_system.rank_changed.connect(rank_callable)
	if not drive_system.combo_changed.is_connected(combo_callable):
		drive_system.combo_changed.connect(combo_callable)
	if not drive_system.feedback_requested.is_connected(feedback_callable):
		drive_system.feedback_requested.connect(feedback_callable)

	var new_summary = drive_system.get_battle_summary()
	_set_score(int(new_summary.get("total_drive_score", new_summary.get("score", 0))))
	_set_rank(str(new_summary.get("current_resonance_rank", new_summary.get("rank", "Static Pulse"))))
	_set_combo(new_summary.get("combo", {}))


func _disconnect_drive_system() -> void:
	var score_callable := Callable(self, "_on_score_changed")
	var rank_callable := Callable(self, "_on_rank_changed")
	var combo_callable := Callable(self, "_on_combo_changed")
	var feedback_callable := Callable(self, "_on_feedback_requested")

	if drive_system.score_changed.is_connected(score_callable):
		drive_system.score_changed.disconnect(score_callable)
	if drive_system.rank_changed.is_connected(rank_callable):
		drive_system.rank_changed.disconnect(rank_callable)
	if drive_system.combo_changed.is_connected(combo_callable):
		drive_system.combo_changed.disconnect(combo_callable)
	if drive_system.feedback_requested.is_connected(feedback_callable):
		drive_system.feedback_requested.disconnect(feedback_callable)


func _ensure_layout() -> void:
	if layout_built:
		return
	score_label = $Root/Score
	rank_label = $Root/Rank
	combo_label = $Root/Combo
	sequence_label = $Root/Sequence
	feedback_list = $Root/FeedbackList
	layout_built = true


func _reset_view() -> void:
	if score_label == null or feedback_list == null:
		return

	_clear_pending_drive_updates()
	_set_score(0)
	_set_rank("Static Pulse")
	_set_combo({})
	for child in feedback_list.get_children():
		child.queue_free()


func _on_score_changed(new_score: int, _delta: int, _event: Dictionary) -> void:
	queue_drive_update({"score": new_score})


func _on_rank_changed(_old_rank: String, new_rank: String) -> void:
	queue_drive_update({"rank": new_rank})


func _on_combo_changed(combo_state: Dictionary) -> void:
	queue_drive_update({"combo": combo_state})


func _on_feedback_requested(feedback: Dictionary) -> void:
	queue_drive_update({"feedback": feedback})


func queue_drive_update(data: Dictionary) -> void:
	if data.has("score"):
		pending_score = int(data.get("score", 0))
	if data.has("rank"):
		pending_rank = str(data.get("rank", "Static Pulse"))
	if data.has("combo"):
		pending_combo = data.get("combo", {}).duplicate(true)
		has_pending_combo = true
	if data.has("feedback"):
		var feedback: Dictionary = data.get("feedback", {})
		if not feedback.is_empty():
			pending_feedback.append(feedback.duplicate(true))

	_schedule_auto_flush()


func show_pending_drive_feedback() -> void:
	_ensure_layout()

	if pending_score != null:
		_set_score(int(pending_score))
	if pending_rank != null:
		_set_rank(str(pending_rank))
	if has_pending_combo:
		_set_combo(pending_combo)

	for feedback in pending_feedback:
		_show_feedback_line(feedback)

	_clear_pending_drive_updates()


func flush_drive_feedback() -> void:
	show_pending_drive_feedback()


func _show_feedback_line(feedback: Dictionary) -> void:
	var text := str(feedback.get("text", ""))
	if text == "":
		return

	var label := preload("res://Escenas/Battle/battle_ui/drive_feedback_line.tscn").instantiate() as Label
	label.text = text
	label.modulate = _feedback_color(feedback)
	feedback_list.add_child(label)
	_trim_feedback()

	var tween := create_tween()
	label.modulate.a = 0.0
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(label, "queue_free"))


func _schedule_auto_flush() -> void:
	if auto_flush_delay < 0.0 or auto_flush_scheduled:
		return
	if not is_inside_tree():
		return

	auto_flush_scheduled = true
	await get_tree().create_timer(auto_flush_delay).timeout
	auto_flush_scheduled = false
	show_pending_drive_feedback()


func _clear_pending_drive_updates() -> void:
	pending_score = null
	pending_rank = null
	pending_combo.clear()
	pending_feedback.clear()
	has_pending_combo = false


func _set_score(value: int) -> void:
	score_label.text = "%06d" % value


func _set_rank(value: String) -> void:
	rank_label.text = value


func _set_combo(combo_state: Dictionary) -> void:
	var chain := int(combo_state.get("chain", 0))
	var max_chain := int(combo_state.get("max_chain", 0))
	combo_label.text = "Combo x%d  Max x%d" % [chain, max_chain]

	var sequence: Array = combo_state.get("sequence", [])
	var parts: Array[String] = []
	for item in sequence:
		parts.append(str(item))
	sequence_label.text = " > ".join(parts) if not parts.is_empty() else ""


func _trim_feedback() -> void:
	while feedback_list.get_child_count() > maxi(0, max_feedback_lines):
		var oldest := feedback_list.get_child(0)
		feedback_list.remove_child(oldest)
		oldest.queue_free()


func _feedback_color(feedback: Dictionary) -> Color:
	var tags: Array = feedback.get("tags", [])
	if "combo_finish" in tags:
		return Color(1.0, 0.86, 0.32)
	if "repeat_penalty" in tags or "combo_break" in tags:
		return Color(1.0, 0.42, 0.38)
	if "combo_flow" in tags:
		return Color(0.45, 0.9, 1.0)
	return Color(0.92, 0.95, 1.0)
