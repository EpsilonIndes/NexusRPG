extends Control

@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var manager = get_tree().get_root().get_node("InventoryManager")

@onready var main_menu = $MainMenu
@onready var item_list_panel = $Panel_Items

@onready var btn_objetos = $MainMenu/BoxBotones/Objetos
@onready var btn_salir = $MainMenu/BoxBotones/Salir

var is_open = false

func _ready():
	visible = false
	item_list_panel.visible = false
	btn_objetos.pressed.connect(_on_objetos_pressed)
	btn_salir.pressed.connect(_on_cerrar_pressed)

func toggle_inventory():
	if is_open:
		anim_player.play("close")
	else:
		visible = true
		main_menu.visible = true
		item_list_panel.visible = false # Forzamos el reseteo
		anim_player.play("open")
	is_open = !is_open

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "close":
		visible = false
		main_menu.visible = true
		item_list_panel.visible = false
	is_open = anim_name == "open"
	
# Al presionar el botón "Objetos"
func _on_objetos_pressed():
	item_list_panel.visible = !item_list_panel.visible
	update_item_list()

# Botón "Cerrar" o similar
func _on_cerrar_pressed():
	toggle_inventory()
	main_menu.visible = false
	item_list_panel.visible = false

func update_item_list():
	# Limpiar ítems anteriores (si usás VBoxContainer)
	for child in item_list_panel.get_children():
		child.queue_free()

	for item_name in manager.items.keys():
		var label = Label.new()
		label.text = item_name + " x" + str(manager.items[item_name])
		item_list_panel.add_child(label)
