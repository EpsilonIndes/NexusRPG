extends Control
class_name BattleResultsUI

const ACTION_HINT_SCENE: PackedScene = preload("res://Escenas/UserUI/Inventory/inventory_action_hint.tscn")
const TOUCH_ACTION_SCENE: PackedScene = preload("res://Escenas/UserUI/Inventory/inventory_touch_action.tscn")

@onready var summary_page: Control = $Pages/SummaryPage
@onready var exp_page: Control = $Pages/ExperiencePage
@onready var drive_score_label: Label = $Pages/SummaryPage/Panel/Margin/Content/DriveScore
@onready var drive_rank_label: Label = $Pages/SummaryPage/Panel/Margin/Content/DriveRank
@onready var items_list: VBoxContainer = $Pages/SummaryPage/Panel/Margin/Content/ItemsList
@onready var exp_list: VBoxContainer = $Pages/ExperiencePage/Panel/Margin/Content/ExperienceList
@onready var next_button: Button = $Pages/SummaryPage/Panel/Margin/Content/NextButton
@onready var continue_button: Button = $Pages/ExperiencePage/Panel/Margin/Content/ContinueButton
@onready var hints: HFlowContainer = $ActionHints

var rewards: Dictionary = {}
var _exp_rows: Array[Dictionary] = []
var _camera_pan_distance := 1.0
signal finished

func _ready() -> void:
	next_button.pressed.connect(_show_experience_page)
	continue_button.pressed.connect(func(): finished.emit())
	exp_page.visible = false
	$Pages.visible = false
	$ActionHints.visible = false
	set_process_unhandled_input(true)

func mostrar_recompensas(data: Dictionary) -> void:
	rewards = data.duplicate(true)
	_build_summary_page()
	_build_experience_page()
	_play_result_camera_intro()

func _play_result_camera_intro() -> void:
	var battle_scene := get_tree().current_scene
	var result_camera := battle_scene.get_node_or_null("Camera/BattleResultCam") as Camera3D
	if result_camera == null:
		_show_summary_page()
		return

	result_camera.make_current()
	var start_position := result_camera.global_position
	var target_position := start_position + Vector3.DOWN * _camera_pan_distance
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(result_camera, "global_position", target_position, 1.0)
	await tween.finished
	_show_summary_page()

func _build_summary_page() -> void:
	var score := int(rewards.get("total_drive_score", rewards.get("drive_score", 0)))
	var bonus: Dictionary = rewards.get("drive_bonus", {}) if rewards.get("drive_bonus", {}) is Dictionary else {}
	drive_score_label.text = "%d" % score
	drive_rank_label.text = str(bonus.get("rank", rewards.get("drive_rank", "Static Pulse")))
	for child in items_list.get_children():
		child.queue_free()
	var items: Array = rewards.get("items", [])
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No se obtuvieron ítems"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_list.add_child(empty_label)
		return
	for item in items:
		var item_label := Label.new()
		item_label.text = "%s  x%d" % [str(item.get("item_id", "Item")), int(item.get("amount", 1))]
		items_list.add_child(item_label)

func _build_experience_page() -> void:
	for child in exp_list.get_children():
		child.queue_free()
	_exp_rows.clear()
	for detail in rewards.get("exp_detalle", []):
		var row := _create_exp_row(detail)
		exp_list.add_child(row.root)
		_exp_rows.append(row)

func _create_exp_row(detail: Dictionary) -> Dictionary:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(0, 86)
	var title := Label.new()
	title.text = "%s   +%d EXP" % [str(detail.get("id", "Personaje")), int(detail.get("exp_ganada", 0))]
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 24)
	bar.max_value = max(1, int(detail.get("exp_para_siguiente_final", 100)))
	bar.value = int(detail.get("exp_inicial", 0))
	bar.show_percentage = false
	var progress := Label.new()
	progress.text = "%d / %d" % [int(detail.get("exp_inicial", 0)), int(detail.get("exp_para_siguiente_inicial", 100))]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(title)
	root.add_child(bar)
	root.add_child(progress)
	return {"root": root, "bar": bar, "progress": progress, "detail": detail}

func _show_summary_page() -> void:
	summary_page.visible = true
	exp_page.visible = false
	$Pages.visible = true
	$ActionHints.visible = true
	next_button.grab_focus()
	_update_presentation()

func _show_experience_page() -> void:
	summary_page.visible = false
	exp_page.visible = true
	continue_button.grab_focus()
	_update_presentation()
	_animate_experience()

func _animate_experience() -> void:
	for row in _exp_rows:
		var detail: Dictionary = row.detail
		var bar: ProgressBar = row.bar
		var progress: Label = row.progress
		var target: int = int(detail.get("exp_final", 0))
		var target_max: int = maxi(1, int(detail.get("exp_para_siguiente_final", 100)))
		bar.max_value = target_max
		var tween: Tween = create_tween()
		tween.tween_method(func(value: float):
			bar.value = value
			progress.text = "%d / %d" % [int(value), target_max], bar.value, target, 0.7)

func _action_caption(action: StringName) -> String:
	var family: StringName = &"gamepad" if DeviceManager.input_method == DeviceManager.InputMethod.GAMEPAD else &"keyboard"
	return InputDisplayHelper.action_to_text(action, family)

func _update_presentation() -> void:
	for child in hints.get_children():
		child.queue_free()
	_hint(_action_caption("ui_accept"), "Continuar", func():
			if summary_page.visible: _show_experience_page()
			else: finished.emit())
	_hint(_action_caption("ui_cancel"), "Volver", func():
			if exp_page.visible: _show_summary_page())
	if DeviceManager.uses_touch():
		return

func _hint(key: String, caption: String, action: Callable) -> void:
	if DeviceManager.uses_touch():
		var button := TOUCH_ACTION_SCENE.instantiate() as Button
		button.text = caption
		button.pressed.connect(action)
		hints.add_child(button)
		return
	var legend = ACTION_HINT_SCENE.instantiate()
	hints.add_child(legend)
	legend.configure(key, caption)
	legend.activated.connect(action)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") and exp_page.visible:
		_show_summary_page()
		get_viewport().set_input_as_handled()
