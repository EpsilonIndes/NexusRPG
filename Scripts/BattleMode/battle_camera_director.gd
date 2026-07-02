extends Node
class_name BattleCameraDirector

enum BattleCameraMode {
	FIXED = 0,
	REDUCED = 1,
	DYNAMIC = 2
}

const PROFILE_DEFAULT := "default"
const PROFILE_MELEE := "melee"
const PROFILE_RANGED := "ranged"
const PROFILE_SUPPORT := "support"
const PROFILE_HEAL := "heal"
const PROFILE_AREA := "area"
const PROFILE_FINISHER := "finisher"
const PROFILE_ENEMY := "enemy"
const PCAM_FOLLOW_NONE := 0
const PCAM_FOLLOW_SIMPLE := 2
const PCAM_LOOK_NONE := 0
const PCAM_LOOK_SIMPLE := 2

@export var overview_pcam: Node3D
@export var action_pcam: Node3D
@export var impact_pcam: Node3D

@export var player_view_slots: Array[Node3D] = []
@export var enemy_view_slots: Array[Node3D] = []

@export var overview_priority := 1
@export var turn_focus_priority := 8
@export var target_focus_priority := 9
@export var action_priority := 10
@export var impact_priority := 20

@export var overview_fov := 60.0
@export var turn_focus_fov := 56.0
@export var target_focus_fov := 50.0
@export var action_fov := 55.0
@export var impact_fov := 48.0
@export var finisher_fov := 42.0

@export var look_height_offset := Vector3(0.0, 1.2, 0.0)
@export var fallback_player_camera_offset := Vector3(3.0, 2.1, -3.4)
@export var fallback_enemy_camera_offset := Vector3(-3.0, 2.1, 3.4)
@export_group("Dynamic Profile Offsets")
@export var dynamic_default_offset := Vector3(0.0, 1.2, -3.2)
@export var dynamic_melee_offset := Vector3(0.8, 1.25, -2.4)
@export var dynamic_ranged_offset := Vector3(1.4, 1.45, -3.8)
@export var dynamic_support_offset := Vector3(0.0, 1.7, -4.4)
@export var dynamic_area_offset := Vector3(0.0, 2.8, -5.2)
@export var dynamic_finisher_offset := Vector3(0.55, 1.05, -2.0)
@export var dynamic_enemy_offset := Vector3(0.0, 1.35, 3.2)

@export_group("Dynamic Profile FOV")
@export var dynamic_default_fov := 52.0
@export var dynamic_melee_fov := 48.0
@export var dynamic_ranged_fov := 56.0
@export var dynamic_support_fov := 58.0
@export var dynamic_area_fov := 62.0
@export var dynamic_finisher_fov := 40.0

@export_group("Impact")
@export var impact_push_distance := 0.45
@export var shake_distance := 0.08
@export var reduced_uses_impact_camera := false
@export var ignore_unmoved_slots := true

var battle_camera_mode := BattleCameraMode.DYNAMIC
var shake_enabled := true
var current_actor: Node3D = null
var current_targets: Array = []
var current_profile := PROFILE_DEFAULT
var _look_target_marker: Node3D
var _shake_tween: Tween


func _ready() -> void:
	add_to_group("battle_camera")
	_ensure_runtime_nodes()
	_resolve_scene_references()
	_apply_settings()
	show_overview()


func show_overview() -> void:
	_resolve_scene_references()
	_set_fov(overview_pcam, overview_fov)
	_activate_pcam(overview_pcam, overview_priority)


func show_turn_actor(actor: Node3D) -> void:
	current_actor = actor
	current_targets.clear()
	current_profile = PROFILE_DEFAULT

	if battle_camera_mode == BattleCameraMode.FIXED:
		show_overview()
		return

	var pcam := action_pcam if action_pcam != null else overview_pcam
	if pcam == null or actor == null or not is_instance_valid(actor):
		return

	var target_position := actor.global_position + look_height_offset
	_clear_follow(pcam)
	_place_action_camera(pcam, actor, target_position, false)
	_set_fov(pcam, turn_focus_fov)
	_look_at_position(pcam, target_position)
	_activate_pcam(pcam, turn_focus_priority)


func focus_target(actor: Node3D, target: Node3D) -> void:
	if battle_camera_mode == BattleCameraMode.FIXED:
		return
	if target == null or not is_instance_valid(target):
		return

	var pcam := action_pcam if action_pcam != null else overview_pcam
	if pcam == null:
		return

	var source := actor if actor != null and is_instance_valid(actor) else current_actor
	var target_position := target.global_position + look_height_offset
	_clear_follow(pcam)
	if source != null and is_instance_valid(source):
		_place_action_camera(pcam, source, target_position, false)
	else:
		pcam.global_position = target_position + fallback_player_camera_offset

	_set_fov(pcam, target_focus_fov)
	_look_at_position(pcam, target_position)
	_activate_pcam(pcam, target_focus_priority)


func begin_action(actor: Node3D, tecnica: Dictionary, objetivos: Array) -> void:
	current_actor = actor
	current_targets = objetivos.duplicate()
	current_profile = str(tecnica.get("camera_profile", PROFILE_DEFAULT))

	if battle_camera_mode == BattleCameraMode.FIXED:
		show_overview()
		return

	var pcam := action_pcam if action_pcam != null else overview_pcam
	if pcam == null or actor == null or not is_instance_valid(actor):
		return

	var target_position := _get_action_look_position(actor, current_targets)
	if battle_camera_mode == BattleCameraMode.DYNAMIC:
		_configure_dynamic_action_camera(pcam, actor, target_position)
		_set_fov(pcam, _get_dynamic_action_fov(current_profile))
	else:
		_clear_follow(pcam)
		_place_action_camera(pcam, actor, target_position, false)
		_set_fov(pcam, _get_action_fov(current_profile))
	_look_at_position(pcam, target_position)
	_activate_pcam(pcam, action_priority)


func show_impact(actor: Node3D, objetivos: Array) -> void:
	if battle_camera_mode == BattleCameraMode.FIXED:
		return
	if battle_camera_mode == BattleCameraMode.REDUCED and not reduced_uses_impact_camera:
		_play_impact_shake(action_pcam)
		return

	var pcam := impact_pcam if impact_pcam != null else action_pcam
	if pcam == null:
		return

	var source := actor if actor != null else current_actor
	var target_position := _get_action_look_position(source, objetivos)
	_clear_follow(pcam)
	if source != null and is_instance_valid(source):
		_place_action_camera(pcam, source, target_position, true)
	else:
		pcam.global_position = target_position + Vector3(0.0, 1.2, -2.0)

	_set_fov(pcam, _get_impact_fov(current_profile))
	_look_at_position(pcam, target_position)
	_activate_pcam(pcam, impact_priority)
	_play_impact_shake(pcam)


func end_action() -> void:
	_clear_follow(action_pcam)
	_clear_follow(impact_pcam)
	current_actor = null
	current_targets.clear()
	current_profile = PROFILE_DEFAULT
	show_overview()


func set_battle_camera_mode(mode: int) -> void:
	battle_camera_mode = clampi(mode, BattleCameraMode.FIXED, BattleCameraMode.DYNAMIC)
	if battle_camera_mode == BattleCameraMode.FIXED:
		show_overview()


func set_shake_enabled(enabled: bool) -> void:
	shake_enabled = enabled


func _ensure_runtime_nodes() -> void:
	if _look_target_marker == null:
		_look_target_marker = Node3D.new()
		_look_target_marker.name = "RuntimeLookTarget"
		add_child(_look_target_marker)


func _resolve_scene_references() -> void:
	var camera_root := get_parent()
	if camera_root == null:
		return

	if overview_pcam == null:
		overview_pcam = camera_root.get_node_or_null("OverviewPCam")
	if overview_pcam == null:
		overview_pcam = camera_root.get_node_or_null("PhantomCamera3D")
	if action_pcam == null:
		action_pcam = camera_root.get_node_or_null("ActionPCam")
	if impact_pcam == null:
		impact_pcam = camera_root.get_node_or_null("ImpactPCam")

	if player_view_slots.is_empty() or enemy_view_slots.is_empty():
		var rig_points := camera_root.get_node_or_null("CameraRigPoints")
		if rig_points != null:
			if player_view_slots.is_empty():
				player_view_slots = _collect_slots(rig_points, "PlayerViewSlot")
			if enemy_view_slots.is_empty():
				enemy_view_slots = _collect_slots(rig_points, "EnemyViewSlot")


func _apply_settings() -> void:
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		return

	var graphics: Dictionary = settings_manager.settings.get("graphics", {})
	set_battle_camera_mode(int(graphics.get("battle_camera_mode", BattleCameraMode.DYNAMIC)))
	set_shake_enabled(bool(graphics.get("camera_shake", true)))


func _collect_slots(root: Node, prefix: String) -> Array[Node3D]:
	var slots: Array[Node3D] = []
	for i in range(1, 5):
		var slot := root.get_node_or_null("%s%d" % [prefix, i])
		if slot is Node3D:
			slots.append(slot)
	return slots


func _place_action_camera(pcam: Node3D, actor: Node3D, target_position: Vector3, is_impact: bool) -> void:
	var slot := _get_slot_for_actor(actor)
	if slot != null:
		pcam.global_transform = slot.global_transform
	else:
		var offset := fallback_player_camera_offset if _is_player_actor(actor) else fallback_enemy_camera_offset
		pcam.global_position = actor.global_position + offset

	if is_impact:
		var direction := (target_position - pcam.global_position).normalized()
		if direction.length() > 0.0:
			pcam.global_position += direction * impact_push_distance


func _configure_dynamic_action_camera(pcam: Node3D, actor: Node3D, target_position: Vector3) -> void:
	var offset := _get_dynamic_follow_offset(current_profile, actor)
	if pcam.has_method("set_follow_target"):
		pcam.set("follow_mode", PCAM_FOLLOW_SIMPLE)
		pcam.set("follow_offset", offset)
		pcam.call("set_follow_target", actor)
	else:
		pcam.global_position = actor.global_position + offset

	if pcam.global_position.distance_to(target_position) > 0.01:
		pcam.look_at(target_position, Vector3.UP)


func _clear_follow(pcam: Node) -> void:
	if pcam == null or not is_instance_valid(pcam):
		return
	if pcam.has_method("erase_follow_target"):
		pcam.call("erase_follow_target")
		pcam.set("follow_mode", PCAM_FOLLOW_NONE)


func _get_slot_for_actor(actor: Node3D) -> Node3D:
	if actor == null or not is_instance_valid(actor):
		return null

	var slot_index := _get_actor_slot_index(actor)
	var slots := player_view_slots if _is_player_actor(actor) else enemy_view_slots
	if slot_index >= 0 and slot_index < slots.size() and _is_slot_usable(slots[slot_index]):
		return slots[slot_index]
	return null


func _get_actor_slot_index(actor: Node3D) -> int:
	var team := actor.get_parent()
	if team == null:
		return -1

	var index := 0
	for child in team.get_children():
		if child == actor:
			return index
		if child is Node3D:
			index += 1
	return -1


func _is_player_actor(actor: Node) -> bool:
	return actor != null and is_instance_valid(actor) and actor.get("es_jugador") == true


func _is_slot_usable(slot: Node3D) -> bool:
	if slot == null or not is_instance_valid(slot):
		return false
	return not ignore_unmoved_slots or slot.global_position.length() > 0.001


func _get_action_look_position(actor: Node3D, targets: Array) -> Vector3:
	var valid_targets := _get_valid_targets(targets)
	if valid_targets.is_empty():
		return actor.global_position + look_height_offset if actor != null else look_height_offset

	if current_profile in [PROFILE_AREA, PROFILE_SUPPORT, PROFILE_HEAL]:
		return _get_targets_center(valid_targets)

	return valid_targets[0].global_position + look_height_offset


func _get_valid_targets(targets: Array) -> Array[Node3D]:
	var valid: Array[Node3D] = []
	for target in targets:
		if target is Node3D and is_instance_valid(target):
			valid.append(target)
	return valid


func _get_targets_center(targets: Array[Node3D]) -> Vector3:
	var center := Vector3.ZERO
	for target in targets:
		center += target.global_position + look_height_offset
	return center / float(max(1, targets.size()))


func _look_at_position(pcam: Node3D, position: Vector3) -> void:
	if pcam == null:
		return

	_look_target_marker.global_position = position
	if pcam.has_method("set_look_at_target"):
		pcam.set("look_at_mode", PCAM_LOOK_SIMPLE)
		pcam.call("set_look_at_target", _look_target_marker)
	elif pcam.global_position.distance_to(position) > 0.01:
		pcam.look_at(position, Vector3.UP)


func _activate_pcam(active: Node3D, priority: int) -> void:
	for pcam in [overview_pcam, action_pcam, impact_pcam]:
		if pcam != null and is_instance_valid(pcam):
			_set_priority(pcam, 0)

	if active != null and is_instance_valid(active):
		_set_priority(active, priority)


func _set_priority(pcam: Node, priority: int) -> void:
	if pcam.has_method("set_priority"):
		pcam.call("set_priority", priority)
	else:
		pcam.set("priority", priority)


func _set_fov(pcam: Node, fov: float) -> void:
	if pcam == null:
		return
	if pcam.has_method("set_fov"):
		pcam.call("set_fov", fov)
	else:
		pcam.set("fov", fov)


func _get_action_fov(profile: String) -> float:
	match profile:
		PROFILE_FINISHER:
			return finisher_fov
		PROFILE_SUPPORT, PROFILE_HEAL, PROFILE_AREA, PROFILE_RANGED:
			return overview_fov
		_:
			return action_fov


func _get_dynamic_action_fov(profile: String) -> float:
	match profile:
		PROFILE_FINISHER:
			return dynamic_finisher_fov
		PROFILE_MELEE:
			return dynamic_melee_fov
		PROFILE_RANGED:
			return dynamic_ranged_fov
		PROFILE_SUPPORT, PROFILE_HEAL:
			return dynamic_support_fov
		PROFILE_AREA:
			return dynamic_area_fov
		_:
			return dynamic_default_fov


func _get_dynamic_follow_offset(profile: String, actor: Node3D) -> Vector3:
	if not _is_player_actor(actor):
		return dynamic_enemy_offset

	match profile:
		PROFILE_FINISHER:
			return dynamic_finisher_offset
		PROFILE_MELEE:
			return dynamic_melee_offset
		PROFILE_RANGED:
			return dynamic_ranged_offset
		PROFILE_SUPPORT, PROFILE_HEAL:
			return dynamic_support_offset
		PROFILE_AREA:
			return dynamic_area_offset
		_:
			return dynamic_default_offset


func _get_impact_fov(profile: String) -> float:
	match profile:
		PROFILE_FINISHER:
			return finisher_fov
		PROFILE_SUPPORT, PROFILE_HEAL:
			return action_fov
		PROFILE_AREA:
			return overview_fov
		_:
			return impact_fov


func _play_impact_shake(pcam: Node3D) -> void:
	if not shake_enabled or pcam == null or battle_camera_mode != BattleCameraMode.DYNAMIC:
		return

	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	var start_position := pcam.global_position
	_shake_tween = create_tween()
	_shake_tween.tween_property(pcam, "global_position", start_position + Vector3(shake_distance, 0.0, 0.0), 0.04)
	_shake_tween.tween_property(pcam, "global_position", start_position - Vector3(shake_distance, 0.0, 0.0), 0.04)
	_shake_tween.tween_property(pcam, "global_position", start_position, 0.05)
