extends Control

signal closed

const CATEGORIES := ["consumible", "equipo", "clave"]
@export_group("Componentes visuales")
@export var action_hint_scene: PackedScene = preload("res://Escenas/UserUI/Inventory/inventory_action_hint.tscn")
@export var touch_action_scene: PackedScene = preload("res://Escenas/UserUI/Inventory/inventory_touch_action.tscn")
@export var character_card_scene: PackedScene = preload("res://Escenas/UserUI/Inventory/inventory_character_card.tscn")
var is_open := false
var current_category := "consumible"
var selected_item_id := ""
var item_ids: Array[String] = []
var choosing_target := false
var pending_discard := false
@onready var tabs: TabBar = %Categories
@onready var items: ItemList = %Items
@onready var description: Label = %Description
@onready var status: Label = %Status
@onready var targets: ScrollContainer = %Targets
@onready var target_cards: VBoxContainer = %TargetCards
var target_ids: Array[String] = []
var selected_target := 0
@onready var target_title: Label = %TargetTitle
@onready var hints: HFlowContainer = %Hints
@onready var body: HBoxContainer = %Body

func _ready() -> void:
	hide()
	set_process_unhandled_input(false)
	tabs.tab_changed.connect(_category_changed)
	items.item_selected.connect(_selected)
	items.item_activated.connect(func(_index: int): _use_selected())
	items.item_clicked.connect(_clicked)
	DeviceManager.presentation_changed.connect(_update_presentation)
	InventoryManager.inventory_changed.connect(_inventory_changed)
	_update_presentation()

func open() -> void:
	if is_open: return
	is_open = true
	show()
	GameManager.push_ui()
	set_process_unhandled_input(true)
	status.text = ""
	refresh_items()
	_update_presentation()
	_focus_items()

func close() -> void:
	if not is_open: return
	is_open = false
	choosing_target = false
	pending_discard = false
	hide()
	set_process_unhandled_input(false)
	GameManager.pop_ui()
	closed.emit()

func refresh_items() -> void:
	var previous_index := maxi(item_ids.find(selected_item_id), 0)
	items.clear()
	item_ids.clear()
	for item_name in InventoryManager.items:
		var id: String = ItemManager.get_item_id(item_name)
		if id.is_empty() or ItemManager.get_item_tipo(id) != current_category: continue
		item_ids.append(id)
		items.add_item("%s  ×%s" % [item_name, InventoryManager.items[item_name]])
	if item_ids.is_empty():
		selected_item_id = ""
		description.text = "No hay objetos en esta categoría."
	else:
		var index := item_ids.find(selected_item_id)
		if index < 0: index = mini(previous_index, item_ids.size() - 1)
		items.select(index)
		items.ensure_current_is_visible()
		_selected(index)

func _selected(index: int) -> void:
	selected_item_id = item_ids[index]
	var item: Dictionary = DataLoader.items.get(selected_item_id, {})
	description.text = "%s\n\n%s" % [ItemManager.get_item_nombre(selected_item_id), item.get("description", "Sin descripción")]

func _category_changed(index: int) -> void:
	current_category = CATEGORIES[index]
	selected_item_id = ""
	status.text = ""
	refresh_items()
	_focus_items()

func _clicked(index: int, _position: Vector2, button: int) -> void:
	_selected(index)
	if button == MOUSE_BUTTON_RIGHT: _request_discard()
	elif button == MOUSE_BUTTON_LEFT: _use_selected()

func _use_selected() -> void:
	if pending_discard:
		_confirm_discard()
		return
	if choosing_target or selected_item_id.is_empty(): return
	if current_category != "consumible":
		status.text = "Este objeto no se puede usar desde el inventario."
		return
	for card in target_cards.get_children():
		target_cards.remove_child(card)
		card.queue_free()
	target_ids.clear()
	for character in PlayableCharacters.get_party_actual():
		var card = character_card_scene.instantiate()
		target_cards.add_child(card)
		card.set_character(character, PlayableCharacters.get_character(character), true)
		var index := target_ids.size()
		target_ids.append(character)
		card.pressed.connect(_use_on_target.bind(index))
		card.focus_entered.connect(func(): selected_target = index)
	if target_ids.is_empty():
		status.text = "No hay personajes disponibles."
		return
	choosing_target = true
	status.text = "Seleccioná un personaje."
	_update_presentation()
	selected_target = 0
	for index in range(target_cards.get_child_count()):
		var card: Control = target_cards.get_child(index)
		var previous: Control = target_cards.get_child(posmod(index - 1, target_ids.size()))
		var next: Control = target_cards.get_child((index + 1) % target_ids.size())
		card.focus_neighbor_top = card.get_path_to(previous)
		card.focus_neighbor_bottom = card.get_path_to(next)
		card.focus_neighbor_left = card.get_path_to(card)
		card.focus_neighbor_right = card.get_path_to(card)
		card.focus_previous = card.get_path_to(previous)
		card.focus_next = card.get_path_to(next)
	target_cards.get_child(0).grab_focus()

func _use_on_target(index: int) -> void:
	if not choosing_target or index < 0 or index >= target_ids.size(): return
	var id := selected_item_id
	var character := target_ids[index]
	if character not in PlayableCharacters.get_party_actual():
		_back()
		status.text = "El personaje ya no está en el grupo activo."
		return
	choosing_target = false
	var context := "battle" if GameManager.is_in_battle() else "world"
	var used: bool = ItemManager.use_item(id, character, context)
	# Refresh the displayed state too, before hiding the recipient panel.
	for card in target_cards.get_children():
		card.set_character(card.character_id, PlayableCharacters.get_character(card.character_id), true)
	status.text = "Objeto utilizado en %s." % character if used else "El objeto no tuvo efecto; no se consumió."
	refresh_items()
	_update_presentation()
	_focus_items()

func _request_discard() -> void:
	if choosing_target or selected_item_id.is_empty(): return
	if current_category == "clave":
		status.text = "Los objetos clave no se pueden descartar."
		return
	pending_discard = true
	status.text = "¿Descartar una unidad de %s?" % ItemManager.get_item_nombre(selected_item_id)
	_update_presentation()

func _confirm_discard() -> void:
	if not pending_discard: return
	pending_discard = false
	InventoryManager.remove_item(ItemManager.get_item_nombre(selected_item_id), 1)
	status.text = "Se descartó una unidad."
	_update_presentation()
	_focus_items()

func _back() -> void:
	if choosing_target or pending_discard:
		choosing_target = false
		pending_discard = false
		status.text = ""
		_update_presentation()
		_focus_items()
	else: close()

func _focus_items() -> void:
	if is_open:
		if item_ids.is_empty(): tabs.grab_focus()
		else: items.grab_focus()

func _inventory_changed() -> void:
	if not is_open: return
	choosing_target = false
	pending_discard = false
	refresh_items()
	_update_presentation()
	_focus_items()

func _action_caption(action: StringName) -> String:
	var family: StringName = &"gamepad" if DeviceManager.input_method == DeviceManager.InputMethod.GAMEPAD else &"keyboard"
	return InputDisplayHelper.action_to_text(action, family)

func _hint(key: String, caption: String, action: Callable) -> void:
	if DeviceManager.uses_touch():
		var button := touch_action_scene.instantiate() as Button
		button.text = caption
		button.pressed.connect(action)
		hints.add_child(button)
		return
	var legend := action_hint_scene.instantiate()
	hints.add_child(legend)
	legend.configure(key, caption)
	legend.activated.connect(action)

func _update_presentation() -> void:
	for child in hints.get_children():
		hints.remove_child(child)
		child.queue_free()
	var pad := DeviceManager.input_method == DeviceManager.InputMethod.GAMEPAD
	var compact := DeviceManager.mobile_layout or DeviceManager.uses_touch()
	items.theme_type_variation = &"InventoryItemsCompact" if compact else &"InventoryItems"
	target_cards.theme_type_variation = &"InventoryTargetsCompact" if compact else &"InventoryTargets"
	description.size_flags_vertical = Control.SIZE_FILL if choosing_target else Control.SIZE_EXPAND_FILL
	targets.visible = choosing_target
	target_title.visible = choosing_target
	items.mouse_filter = Control.MOUSE_FILTER_IGNORE if choosing_target or pending_discard else Control.MOUSE_FILTER_STOP
	items.focus_mode = Control.FOCUS_NONE if choosing_target or pending_discard else Control.FOCUS_ALL
	tabs.mouse_filter = items.mouse_filter
	tabs.focus_mode = items.focus_mode
	if pending_discard:
		_hint(_action_caption("ui_accept"), "Confirmar", _confirm_discard)
	elif choosing_target:
		_hint(_action_caption("ui_accept"), "Usar", func():
			_use_on_target(selected_target))
	else:
		_hint(_action_caption("ui_accept"), "Usar", _use_selected)
		_hint("Y / △" if pad else "R", "Descartar", _request_discard)
		_hint("LB / L1" if pad else "Q", "Anterior", func(): _cycle_category(-1))
		_hint("RB / R1" if pad else "W", "Siguiente", func(): _cycle_category(1))
	_hint(_action_caption("ui_cancel"), "Volver", _back)
	if pending_discard:
		var focus := get_viewport().gui_get_focus_owner()
		if focus and is_ancestor_of(focus): focus.release_focus()

func _cycle_category(direction: int) -> void:
	if choosing_target or pending_discard: return
	tabs.current_tab = posmod(tabs.current_tab + direction, CATEGORIES.size())

func _unhandled_input(event: InputEvent) -> void:
	if not is_open or event.is_echo(): return
	if event.is_action_pressed("ui_cancel"): _back()
	elif pending_discard and event.is_action_pressed("ui_accept"): _confirm_discard()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R: _request_discard()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y: _request_discard()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_Q, KEY_W]: _cycle_category(-1 if event.keycode == KEY_Q else 1)
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]: _cycle_category(-1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
	else: return
	get_viewport().set_input_as_handled()
