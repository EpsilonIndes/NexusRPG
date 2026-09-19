extends Control

signal closed
@onready var title_label: Label = $Panel/Margin/Column/Title
@onready var mode_tabs: TabBar = $Panel/Margin/Column/Modes
@onready var slots_list: ItemList = $Panel/Margin/Column/Slots
@onready var status: Label = $Panel/Margin/Column/Status
@onready var hints: Label = $Panel/Margin/Column/Hints
@onready var confirmation: ConfirmationDialog = $Confirmation
@onready var new_dialog: ConfirmationDialog = $NewSave
@onready var name_edit: LineEdit = $NewSave/Name
var slots: Array[Dictionary] = []
var allow_save := false
var pending_action := ""
var pending_filename := ""
var pending_title := ""
var working := false
var touch_view: ScrollContainer

func _ready() -> void:
	hide()
	touch_view = preload("res://Scripts/UI/SaveSlotsTouchView.gd").new()
	touch_view.name = "TouchFiles"
	slots_list.get_parent().add_child(touch_view)
	slots_list.get_parent().move_child(touch_view, slots_list.get_index() + 1)
	touch_view.activated.connect(_touch_activate)
	touch_view.delete_requested.connect(_touch_delete)
	DeviceManager.presentation_changed.connect(_update_presentation)
	mode_tabs.add_tab("Guardar")
	mode_tabs.add_tab("Cargar")
	mode_tabs.tab_changed.connect(_mode_changed)
	confirmation.confirmed.connect(_execute)
	confirmation.canceled.connect(_focus_list)
	new_dialog.confirmed.connect(_new_save)
	new_dialog.canceled.connect(_focus_list)
	name_edit.text_submitted.connect(func(_text: String): new_dialog.hide(); _new_save())
	slots_list.item_selected.connect(_selected)
	slots_list.item_activated.connect(_activate)
	slots_list.gui_input.connect(_list_input)
	slots_list.item_clicked.connect(_clicked)
	set_process_unhandled_input(false)
	SaveManager.load_failed.connect(_on_load_failed)
	_update_presentation()

func _touch_activate(index: int) -> void:
	slots_list.select(index)
	_activate(index)

func _touch_delete(index: int) -> void:
	slots_list.select(index)
	_confirm("delete")

func _update_presentation() -> void:
	var touch := DeviceManager.uses_touch()
	var compact := DeviceManager.mobile_layout or touch
	slots_list.visible = not touch
	touch_view.visible = touch
	$Panel.anchor_left = 0.02 if compact else 0.06
	$Panel.anchor_right = 0.98 if compact else 0.94
	$Panel.anchor_top = 0.03 if compact else 0.08
	$Panel.anchor_bottom = 0.97 if compact else 0.92
	mode_tabs.custom_minimum_size.y = 56 if compact else 0
	slots_list.add_theme_constant_override("v_separation", 24 if compact else 16)
	for dialog in [confirmation, new_dialog]:
		for button in [dialog.get_ok_button(), dialog.get_cancel_button()]:
			button.custom_minimum_size.y = 56 if compact else 0
	var action := "guardar" if _saving() else "cargar"
	if touch:
		hints.text = "Tocá una partida para %s. Usá Eliminar para borrar un archivo." % action
	elif DeviceManager.input_method == DeviceManager.InputMethod.GAMEPAD:
		hints.text = "Aceptar: %s · Triángulo / Y: eliminar · Cancelar: volver" % action
		if allow_save:
			hints.text += " · L1/R1: Guardar / Cargar"
	else:
		hints.text = "Aceptar / doble clic: %s · R / clic derecho: eliminar · Esc: volver" % action
		if allow_save:
			hints.text += " · Q/W: Guardar / Cargar"
	if visible and not confirmation.visible and not new_dialog.visible:
		_focus_list()

func _on_load_failed(message: String) -> void:
	working = false
	status.text = message
	_focus_list()

func open(with_save: bool = false) -> void:
	if visible:
		return
	allow_save = with_save
	mode_tabs.visible = allow_save
	mode_tabs.current_tab = 0 if allow_save else 1
	show()
	GameManager.push_ui()
	title_label.text = "Guardar / cargar partida" if allow_save else "Cargar partida"
	status.text = ""
	_refresh()
	set_process_unhandled_input(true)
	_focus_list()

func close() -> void:
	if working:
		return
	hide()
	set_process_unhandled_input(false)
	GameManager.pop_ui()
	closed.emit()

func _saving() -> bool:
	return allow_save and mode_tabs.current_tab == 0

func _mode_changed(_index: int) -> void:
	if is_node_ready() and visible:
		_refresh()
		_focus_list()

func _refresh() -> void:
	slots = SaveManager.get_existing_slots()
	slots_list.clear()
	if _saving():
		slots_list.add_item("+ Crear un nuevo guardado")
		slots_list.set_item_metadata(0, "new")
	for slot in slots:
		var data: Dictionary = slot.data
		var text := "Archivo no disponible — " + str(slot.filename)
		if not data.is_empty():
			var elapsed := int(data.play_seconds)
			var date := Time.get_datetime_string_from_unix_time(int(data.timestamp)).replace("T", " ")
			var party_text := ", ".join(data.party)
			var level := int(data.characters[data.leader].stats.get("nivel", 1))
			text = "%s   |   %s UTC   |   %02d:%02d\nMapa: Nivel 1 · %s · Líder Nv. %d" % [data.title, date, elapsed / 3600, (elapsed / 60) % 60, party_text, level]
		var index := slots_list.add_item(text)
		slots_list.set_item_metadata(index, slot.filename)
	var back_index := slots_list.add_item("← Volver")
	slots_list.set_item_metadata(back_index, "back")
	slots_list.select(0)
	_selected(0)
	touch_view.rebuild(slots_list)
	_update_presentation()
	if slots.is_empty():
		status.text = "Todavía no hay partidas guardadas."

func _slot_at(index: int) -> Dictionary:
	if index < 0 or index >= slots_list.item_count:
		return {}
	var filename: String = slots_list.get_item_metadata(index)
	for slot in slots:
		if slot.filename == filename:
			return slot
	return {}

func _selected(index: int) -> void:
	var slot := _slot_at(index)
	status.text = slot.error if not slot.is_empty() and slot.data.is_empty() else ""

func _activate(index: int) -> void:
	if working or confirmation.visible or new_dialog.visible:
		return
	var kind: String = slots_list.get_item_metadata(index)
	if kind == "back":
		close()
	elif kind == "new":
		name_edit.text = ""
		new_dialog.popup_centered()
		# A controller can accept the default name without typing.
		new_dialog.get_ok_button().grab_focus()
	else:
		_confirm("save" if _saving() else "load")

func _new_save() -> void:
	if working:
		return
	if SaveManager.save_game(name_edit.text):
		_refresh()
		status.text = "Partida guardada en un archivo nuevo."
	else:
		status.text = SaveManager.last_error
	_focus_list()

func _confirm(action: String) -> void:
	if working or confirmation.visible or new_dialog.visible or slots_list.get_selected_items().is_empty():
		return
	var slot := _slot_at(slots_list.get_selected_items()[0])
	if slot.is_empty():
		return
	if action != "delete" and slot.data.is_empty():
		status.text = slot.error
		return
	pending_action = action
	pending_filename = slot.filename
	pending_title = slot.data.get("title", slot.filename)
	match action:
		"save":
			confirmation.dialog_text = '¿Sobrescribir "%s"?' % pending_title
		"load":
			confirmation.dialog_text = '¿Cargar "%s"? Se perderá el progreso sin guardar.' % pending_title
		"delete":
			confirmation.dialog_text = '¿Eliminar "%s" y su respaldo? Esta acción no se puede deshacer.' % pending_title
	confirmation.popup_centered()
	confirmation.get_cancel_button().grab_focus()

func _execute() -> void:
	if working or pending_filename.is_empty():
		return
	if pending_action == "delete":
		var old_index := slots_list.get_selected_items()[0]
		if SaveManager.delete_save(pending_filename):
			_refresh()
			var index := mini(old_index, slots_list.item_count - 1)
			slots_list.select(index)
			status.text = "Guardado eliminado."
		else:
			status.text = SaveManager.last_error
		_focus_list()
	elif pending_action == "save":
		if SaveManager.save_game(pending_title, pending_filename):
			_refresh()
			status.text = "Partida actualizada."
		else:
			status.text = SaveManager.last_error
		_focus_list()
	else:
		working = true
		SaveManager.load_game(pending_filename)
		if not SaveManager.busy:
			_on_load_failed(SaveManager.last_error)

func _focus_list() -> void:
	if visible and not DeviceManager.uses_touch():
		slots_list.grab_focus()

func _clicked(index: int, _position: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		slots_list.select(index)
		_confirm("delete")

func _list_input(event: InputEvent) -> void:
	if working or confirmation.visible or new_dialog.visible:
		return
	var delete_pressed: bool = (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_R or event.keycode == KEY_R)) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y)
	if delete_pressed:
		slots_list.accept_event()
		_confirm("delete")
	elif allow_save and (event.is_action_pressed("L1") or event.is_action_pressed("R1")):
		slots_list.accept_event()
		mode_tabs.current_tab = 1 - mode_tabs.current_tab
	elif event.is_action_pressed("arriba") or event.is_action_pressed("abajo"):
		slots_list.accept_event()
		var selected := slots_list.get_selected_items()
		var index := selected[0] if not selected.is_empty() else 0
		index = wrapi(index + (1 if event.is_action_pressed("abajo") else -1), 0, slots_list.item_count)
		slots_list.select(index)
		slots_list.ensure_current_is_visible()
		_selected(index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmation.visible and not new_dialog.visible:
		get_viewport().set_input_as_handled()
		close()
