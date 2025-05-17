extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var manager = get_tree().get_root().get_node("InventoryManager")

@onready var main_menu = $MainMenu
@onready var item_list_panel = $Panel_Items
@onready var popup_menu: PopupMenu = $ItemContextMenu

@onready var info_popup: Panel = $ItemInfoPopup
@onready var info_label: Label = $ItemInfoPopup/Label

@onready var btn_objetos = $MainMenu/BoxBotones/Objetos
@onready var btn_salir = $MainMenu/BoxBotones/Salir

var is_open = false
var selected_item_id: String = ""

func _ready():
	visible = false
	item_list_panel.visible = false
	btn_objetos.pressed.connect(_on_objetos_pressed)
	btn_salir.pressed.connect(_on_cerrar_pressed)
	# Setear opciones del menú contextual
	popup_menu.clear()
	popup_menu.add_item("Usar", 0)
	popup_menu.add_item("Información", 1)
	popup_menu.add_item("Descartar", 2)
	popup_menu.id_pressed.connect(_on_context_option_selected)

func toggle_inventory():
	if is_open:
		anim_player.play("close")
		GameManager.estado_actual = GameManager.EstadosDeJuego.LIBRE
		
	else:
		visible = true
		main_menu.visible = true
		item_list_panel.visible = false
		anim_player.play("open")
		GameManager.estado_actual = GameManager.EstadosDeJuego.MENU
	is_open = !is_open

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "close":
		visible = false
		main_menu.visible = true
		item_list_panel.visible = false
	is_open = anim_name == "open"

func _on_objetos_pressed():
	item_list_panel.visible = !item_list_panel.visible
	
	if info_popup.visible == true:
		info_popup.visible = false

	update_item_list()

func _on_cerrar_pressed():
	toggle_inventory()
	main_menu.visible = false
	item_list_panel.visible = false
	info_popup.visible = false

func update_item_list():
	for child in item_list_panel.get_children():
		child.queue_free()

	for item_name in manager.items.keys():
		var btn = Button.new()
		btn.text = item_name + " x" + str(manager.items[item_name])
	
		# Obtenemos su item_id real usando el nombre
		var item_id = ItemManager.get_item_id(item_name)
		btn.set_meta("item_id", item_id)

		btn.pressed.connect(self._on_item_button_pressed.bind(item_id))
		item_list_panel.add_child(btn)

		btn.pressed.connect(func():
			selected_item_id = item_id
			popup_menu.set_position(get_global_mouse_position())
			popup_menu.popup()
			)


func _on_item_pressed(item_id: String, button_node: Button):
	selected_item_id = item_id
	# Posiciona el popup cerca del botón
	var global_pos = button_node.get_global_position()
	popup_menu.set_position(global_pos + Vector2(350, 0)) # Ajustar
	popup_menu.popup()

func _on_context_option_selected(option_id: int):
	match option_id:
		0:
			print("Usar ", selected_item_id)
			var item = DataLoader.items.get(selected_item_id, {})
			var effects = item.get("effect", "").split(";")
			if effects and effects[0] != "":
				EffectManager.apply_effects(effects, "Kosmo") # O el personaje activo
				
			else:
				print("Este objeto no tiene efectos.")

			print(PlayableCharacters.characters["Kosmo"]["stats"])
			update_item_list()
		1:
			print("Información de", selected_item_id)
			var item = DataLoader.items.get(selected_item_id, {})
			var desc = item.get("description", "Sin descripción")
			show_info_popup(desc)
		2:
			print("Descartar ", selected_item_id)
			InventoryManager.remove_item(ItemManager.get_item_nombre(selected_item_id), 1)
			update_item_list()

	selected_item_id = ""

func show_info_popup(text: String):
	info_label.text = text
	info_popup.visible = true

func _on_item_button_pressed(item_id: String):
	print("Seleccionaste el item:", item_id)
