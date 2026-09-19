extends Control

signal closed
@onready var title_label: Label = $Panel/Margin/Column/Title
@onready var slots_list: ItemList = $Panel/Margin/Column/Slots
@onready var name_edit: LineEdit = $Panel/Margin/Column/Name
@onready var status: Label = $Panel/Margin/Column/Status
@onready var new_button: Button = $Panel/Margin/Column/Actions/New
@onready var save_button: Button = $Panel/Margin/Column/Actions/Save
@onready var load_button: Button = $Panel/Margin/Column/Actions/Load
@onready var back_button: Button = $Panel/Margin/Column/Actions/Back
@onready var confirmation: ConfirmationDialog = $Confirmation
var slots: Array[Dictionary] = []
var allow_save := false
var pending_action := ""
var working := false

func _ready() -> void:
	hide()
	new_button.pressed.connect(_new_save)
	save_button.pressed.connect(_confirm.bind("save"))
	load_button.pressed.connect(_confirm.bind("load"))
	back_button.pressed.connect(close)
	confirmation.confirmed.connect(_execute)
	slots_list.item_selected.connect(_selected)
	set_process_unhandled_input(false)
	SaveManager.load_failed.connect(_on_load_failed)

func _on_load_failed(message: String) -> void:
	working = false
	status.text = message

func open(with_save: bool = false) -> void:
	allow_save = with_save
	show()
	GameManager.push_ui()
	title_label.text = "Guardar / cargar partida" if allow_save else "Cargar partida"
	name_edit.visible = allow_save
	new_button.visible = allow_save
	save_button.visible = allow_save
	status.text = ""
	_refresh()
	set_process_unhandled_input(true)
	back_button.grab_focus() if slots.is_empty() else slots_list.grab_focus()

func close() -> void:
	if working:
		return
	hide()
	set_process_unhandled_input(false)
	GameManager.pop_ui()
	closed.emit()

func _refresh() -> void:
	slots = SaveManager.get_existing_slots()
	slots_list.clear()
	for slot in slots:
		var data: Dictionary = slot.data
		if data.is_empty():
			slots_list.add_item("Archivo no disponible — " + slot.filename)
			continue
		var elapsed := int(data.play_seconds)
		var date := Time.get_datetime_string_from_unix_time(int(data.timestamp)).replace("T", " ")
		var party_text := ", ".join(data.party)
		var level := int(data.characters[data.leader].stats.get("nivel", 1))
		slots_list.add_item("%s   |   %s UTC   |   %02d:%02d\nMapa: Nivel 1 · %s · Líder Nv. %d" % [data.title, date, elapsed / 3600, (elapsed / 60) % 60, party_text, level])
	save_button.disabled = true
	load_button.disabled = true
	new_button.disabled = not SaveManager.can_save()
	if slots.is_empty():
		status.text = "Todavía no hay partidas guardadas."

func _selected(index: int) -> void:
	var data: Dictionary = slots[index].data
	load_button.disabled = data.is_empty()
	save_button.disabled = data.is_empty() or not SaveManager.can_save()
	if data.is_empty():
		status.text = slots[index].error
	else:
		name_edit.text = data.title
		status.text = ""

func _new_save() -> void:
	if working:
		return
	if SaveManager.save_game(name_edit.text):
		_refresh()
		status.text = "Partida guardada en un archivo nuevo."
	else:
		status.text = SaveManager.last_error

func _confirm(action: String) -> void:
	if working or slots_list.get_selected_items().is_empty():
		return
	pending_action = action
	var slot: Dictionary = slots[slots_list.get_selected_items()[0]]
	confirmation.dialog_text = '¿Sobrescribir "%s"?' % slot.data.title if action == "save" else '¿Cargar "%s"? Se perderá el progreso sin guardar.' % slot.data.title
	confirmation.popup_centered()

func _execute() -> void:
	if working or slots_list.get_selected_items().is_empty():
		return
	var filename: String = slots[slots_list.get_selected_items()[0]].filename
	if pending_action == "save":
		if SaveManager.save_game(name_edit.text, filename):
			_refresh()
			status.text = "Partida actualizada."
		else:
			status.text = SaveManager.last_error
	else:
		working = true
		# This panel is freed on successful scene replacement.
		SaveManager.load_game(filename)
		if not SaveManager.busy:
			working = false
			status.text = SaveManager.last_error

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmation.visible:
		get_viewport().set_input_as_handled()
		close()
