# InventoryUI.gd (En Nodo)
extends Control

signal closed

@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var panel_main: Panel = $MainMenu
@onready var panel_items: Panel = $ItemsPanel
@onready var panel_info: Panel = $ItemInfoPopup

@onready var item_list: VBoxContainer = $ItemsPanel/Scroll/Vbox
@onready var info_label: Label = $ItemInfoPopup/Label
@onready var categories := $MainMenu/Categories.get_children()

@onready var main_menu := $"../MainMenuUI"

@onready var category_buttons := {
	"consumible": $MainMenu/Categories/Consumibles,
	"equipo": $MainMenu/Categories/Equipo,
	"clave": $MainMenu/Categories/Clave,
}

@onready var btn_salir: Button = $MainMenu/Categories2/Salir

@onready var item_context: PopupMenu = $ItemContextMenu
@onready var character_context: PopupMenu = $ItemContextMenu/CharacterContextMenu


var current_category := "consumible"
var selected_item_id := ""
var is_open := false

func _ready():
	visible = false
	panel_items.visible = false
	panel_info.visible = false
	item_context.hide()
	character_context.hide()

	anim.animation_finished.connect(_on_animation_finished)
	for cat in category_buttons.keys():
		category_buttons[cat].pressed.connect(_on_category_selected.bind(cat))
	
	btn_salir.pressed.connect(close)

	item_context.clear()
	item_context.add_item("Usar", 0)
	item_context.add_item("Descartar", 1)
	item_context.id_pressed.connect(_on_item_action)

	character_context.id_pressed.connect(_on_character_selected)

func open() -> void:
	is_open = true
	visible = true
	set_process_unhandled_input(true)

	panel_items.visible = true
	panel_info.visible = true
	categories[0].grab_focus()
	GameManager.push_ui()
	anim.play("open")
	refresh_items()

func close():
	is_open = false
	set_process_unhandled_input(false)

	item_context.hide()
	character_context.hide()
	panel_info.visible = false
	anim.play("close")
	GameManager.pop_ui()
	emit_signal("closed")

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func refresh_items() -> void:
	for c in item_list.get_children():
		c.queue_free()
	
	for item_name in InventoryManager.items.keys():
		var item_id = ItemManager.get_item_id(item_name)
		if item_id == "":
			continue

		if ItemManager.get_item_tipo(item_id) != current_category:
			continue
		
		var btn := Button.new()
		btn.text = "%s x%s" % [item_name, InventoryManager.items[item_name]]
		btn.pressed.connect(_on_item_pressed.bind(item_id))
		btn.focus_entered.connect(_on_item_focused.bind(item_id))
		btn.mouse_entered.connect(_on_item_focused.bind(item_id))

		item_list.add_child(btn)

func _on_category_selected(category: String):
	current_category = category

	for cat in category_buttons.keys():
		category_buttons[cat].disabled = (cat == category)

	selected_item_id = ""
	refresh_items()

func _on_item_pressed(item_id: String):
	selected_item_id = item_id
	item_context.set_position(get_global_mouse_position())
	item_context.popup()

func _on_item_focused(item_id: String):
	selected_item_id = item_id

	var item = DataLoader.items.get(item_id, {})
	info_label.text = item.get("description", "Sin descripción")

func _on_item_action(action_id: int):
	match action_id:
		0:
			_open_character_menu()
		1:
			_show_item_info()
		2:
			_discard_item()

func _open_character_menu():
	character_context.clear()
	var party = PlayableCharacters.get_party_actual()
	for i in range(party.size()):
		character_context.add_item(party[i], i)
	character_context.set_position(get_global_mouse_position())
	character_context.popup()

func _on_character_selected(index: int):
	var char_id = character_context.get_item_text(index)

	var context = "battle" if GameManager.is_in_battle() else "world"
	ItemManager.use_item(selected_item_id, char_id, context)

	refresh_items()
	selected_item_id = ""

func _show_item_info():
	var item = DataLoader.items.get(selected_item_id, {})
	info_label.text = item.get("description", "Sin descripción")
	panel_info.visible = true
	
	#info_label.set_position(get_global_mouse_position())

func _discard_item():
	InventoryManager.remove_item(
		ItemManager.get_item_nombre(selected_item_id),
		1
	)
	refresh_items()

func _on_inventory_changed():
	if not is_open:
		return
	
	refresh_items()
	
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "close":
		visible = false
		panel_items.visible = false
		item_context.hide()
		character_context.hide()
		panel_info.visible = false
		