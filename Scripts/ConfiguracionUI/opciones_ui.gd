extends Control

#Signal value_changed
signal closed

@onready var tabs := $PanelRoot/MarginContainer/VBoxMain/Tabs
@onready var reset_button := $PanelRoot/MarginContainer/BottomBar/ResetButton
@onready var apply_button := $PanelRoot/MarginContainer/BottomBar/ApplyButton
@onready var accept_button := $PanelRoot/MarginContainer/BottomBar/AcceptButton

var _snapshot := {}
var _dirty := false
var _closing_accept := false


func _ready():
	#_setup_all_option_rows()
	
	# Conectar botones
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	accept_button.pressed.connect(_on_accept_pressed)

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
	var focusables: Array[Control] = []

	for tab in tabs.get_children():
		var scroll := tab as ScrollContainer
		if scroll == null:
			continue

		var container := scroll.get_child(0)
		for row in container.get_children():
			if row.has_method("setup"):
				row.setup()
				_hook_dirty_from_row(row)
			
			if row.has_node("Slider"):
				var slider = row.get_node("Slider") as Control
				if slider and slider.focus_mode != Control.FOCUS_NONE:
					focusables.append(slider)
	
	if focusables.is_empty():
		return

	# Conectar navegación vertical
	for i in focusables.size():
		var current := focusables[i]
		if i > 0:
			current.focus_neighbor_top = focusables[i - 1].get_path()
		if i < focusables.size() - 1:
			current.focus_neighbor_bottom = focusables[i + 1].get_path()

	# Último slider → Reset
	
	focusables[-1].focus_neighbor_bottom = reset_button.get_path()

	reset_button.focus_neighbor_top = focusables[-1].get_path()
	reset_button.focus_neighbor_right = apply_button.get_path()
	
	apply_button.focus_neighbor_left = reset_button.get_path()
	apply_button.focus_neighbor_right = accept_button.get_path()
	
	accept_button.focus_neighbor_left = apply_button.get_path()

func _hook_dirty_from_row(row):
	if row.has_signal("value_changed"):
		if not row.value_changed.is_connected(_on_any_option_changed):
			row.value_changed.connect(_on_any_option_changed)


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
	print("DIRTY!")
	_dirty = true
	apply_button.disabled = false

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

	var scroll := tab.get_child(0) as ScrollContainer
	if scroll == null:
		return

	var container := scroll.get_child(0)
	
	for row in container.get_children():
		if row.has_node("Control"):
			var ctrl = row.get_node("Control") as Control
			if ctrl.focus_mode == Control.FOCUS_ALL:
				row.grab_focus()
				return

func _focus_first_slider():
	var tab = tabs.get_current_tab_control()
	if tab == null:
		return

	var scroll := tab as ScrollContainer
	if scroll == null:
		return

	var container := scroll.get_child(0) # AudioOptions (VBoxContainer)

	for row in container.get_children():
		if row.has_node("Slider"):
			var slider := row.get_node("Slider") as Control
			if slider.focus_mode != Control.FOCUS_NONE:
				slider.grab_focus()
				return
	
			print("Foco en:", slider.name)
			slider.grab_focus()
