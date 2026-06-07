extends Control

#Signal value_changed
signal closed

@onready var tabs := $PanelRoot/MarginContainer/VBoxMain/Tabs
@onready var reset_button := $BottomBar/ResetButton
@onready var apply_button := $BottomBar/ApplyButton
@onready var accept_button := $BottomBar/AcceptButton
@onready var controls_capture_panel := $ControlsCapturePanel

var _snapshot := {}
var _dirty := false
var _closing_accept := false


func _ready():
	#_setup_all_option_rows()
	#_hide_unimplemented_tabs()
	if not get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	# Conectar botones
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	accept_button.pressed.connect(_on_accept_pressed)

func _hide_unimplemented_tabs() -> void:
	for tab_name in ["Gameplay", "Controls"]:
		var tab := tabs.get_node_or_null(tab_name)
		if tab == null:
			continue
		var index = tabs.get_tab_idx_from_control(tab)
		if index >= 0:
			tabs.set_tab_hidden(index, true)

func open():
	set_process_unhandled_input(true)
	GameManager.push_ui()
	
	_snapshot = SettingsManager.settings.duplicate(true)
	_setup_all_option_rows()
	_dirty = false
	apply_button.disabled = true
	visible = true
	await get_tree().process_frame
	_focus_first_slider()
	



func close():
	if not _closing_accept:
		SettingsManager.settings = _snapshot.duplicate(true)
		SettingsManager.apply_all()
	
	set_process_unhandled_input(false)
	GameManager.pop_ui()
	_closing_accept = false
	visible = false
	emit_signal("closed")

func _setup_all_option_rows():
	for tab in tabs.get_children():
		var focusables: Array[Control] = []
		var scroll := tab as ScrollContainer
		if scroll == null:
			continue

		var container := scroll.get_child(0)
		for row in container.get_children():
			if row.has_method("setup"):
				row.setup()
			_hook_dirty_from_row(row)
			_hook_binding_request_from_row(row)
			
			var focus_control := _get_row_focus_control(row)
			if focus_control:
				focusables.append(focus_control)
	
		_setup_focus_chain(focusables)
	
	reset_button.focus_neighbor_right = apply_button.get_path()
	
	apply_button.focus_neighbor_left = reset_button.get_path()
	apply_button.focus_neighbor_right = accept_button.get_path()
	
	accept_button.focus_neighbor_left = apply_button.get_path()

func _hook_dirty_from_row(row):
	if row.has_signal("value_changed"):
		if not row.value_changed.is_connected(_on_any_option_changed):
			row.value_changed.connect(_on_any_option_changed)

func _hook_binding_request_from_row(row):
	if row.has_signal("binding_requested"):
		if not row.binding_requested.is_connected(_on_binding_requested):
			row.binding_requested.connect(_on_binding_requested)

func _get_row_focus_control(row: Node) -> Control:
	for node_name in ["Slider", "Control", "OptionButton", "KeyboardButton", "GamepadButton"]:
		if row.has_node(node_name):
			var control := row.get_node(node_name) as Control
			if control and control.focus_mode != Control.FOCUS_NONE:
				return control
	return null

func _setup_focus_chain(focusables: Array[Control]) -> void:
	if focusables.is_empty():
		return

	for i in focusables.size():
		var current := focusables[i]
		if i > 0:
			current.focus_neighbor_top = focusables[i - 1].get_path()
		if i < focusables.size() - 1:
			current.focus_neighbor_bottom = focusables[i + 1].get_path()

	focusables[-1].focus_neighbor_bottom = reset_button.get_path()


"""
Input básico
"""
func _unhandled_input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		if accept_button.has_focus():
			_on_accept_pressed()
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		return
	
	if event.is_action_released("L1"):
		_change_tab(-1)
	elif event.is_action_released("R1"):
		_change_tab(1)

func _cancel():
	close()

"""
Botones
"""
func _on_any_option_changed():
	_dirty = true
	apply_button.disabled = false

func _on_binding_requested(action: StringName, family: StringName) -> void:
	controls_capture_panel.start_capture(action, family)

func _on_focus_changed(control: Control) -> void:
	if not visible or control == null:
		return

	var scroll := _get_current_scroll_container()
	if scroll == null:
		return

	if scroll.is_ancestor_of(control):
		scroll.ensure_control_visible(control)

func _get_current_scroll_container() -> ScrollContainer:
	var tab = tabs.get_current_tab_control()
	return tab as ScrollContainer

func _on_reset_pressed():
	SettingsManager.reset_to_defaults()
	SettingsManager.apply_all()
	_setup_all_option_rows()
	_dirty = true
	apply_button.disabled = false

func _on_apply_pressed():
	if not _dirty:
		return
	
	SettingsManager.apply_all()
	_dirty = false
	apply_button.disabled = true

func _on_accept_pressed():
	_closing_accept = true
	SettingsManager.apply_all()
	SettingsManager.save_settings()
	close()

func _change_tab(dir: int):
	var new_tab = clamp(
		tabs.current_tab + dir,
		0,
		tabs.get_tab_count() - 1
	)

	if new_tab == tabs.current_tab:
		return

	tabs.current_tab = new_tab
	await get_tree().process_frame
	_focus_first_row()
	_focus_first_slider()

func _focus_first_row():
	var tab = tabs.get_current_tab_control()
	if tab == null:
		return

	var scroll := tab as ScrollContainer
	if scroll == null:
		return

	var container := scroll.get_child(0)
	
	for row in container.get_children():
		var ctrl := _get_row_focus_control(row)
		if ctrl:
			ctrl.grab_focus()
			return

func _focus_first_slider():
	var tab = tabs.get_current_tab_control()
	if tab == null:
		return

	var scroll := tab as ScrollContainer
	if scroll == null:
		return

	var container := scroll.get_child(0) # AudioOptions (VBoxContainer)
	var last_focusable: Control = null

	for row in container.get_children():
		var ctrl := _get_row_focus_control(row)
		if ctrl:
			if last_focusable == null:
				ctrl.grab_focus()
			last_focusable = ctrl

	if last_focusable:
		reset_button.focus_neighbor_top = last_focusable.get_path()
		return

	for row in container.get_children():
		var ctrl := _get_row_focus_control(row)
		if ctrl:
			ctrl.grab_focus()
			return
