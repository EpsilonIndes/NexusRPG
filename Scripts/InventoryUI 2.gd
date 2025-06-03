extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var manager: InventoryManager = get_tree().get_root().get_node("InventoryManager")

@onready var main_menu: Panel = $MainMenu
@onready var item_list_panel: VBoxContainer = $Panel_Items
@onready var popup_menu: PopupMenu = $ItemContextMenu

@onready var info_popup: Panel = $ItemInfoPopup
@onready var info_label: Label = $ItemInfoPopup/Label

@onready var btn_objetos: Button = $MainMenu/BoxBotones/Objetos
@onready var btn_estado: Button = $MainMenu/BoxBotones/Estado
@onready var btn_salir: Button = $MainMenu/BoxBotones/Salir

# Lógica del Panel ESTADO
@onready var estado_panel: Panel = $EstadoPanel
@onready var label_stats: Label = $EstadoPanel/Label_Stats
@onready var face_texture = $EstadoPanel/FaceRect

@onready var team: Array = []

@onready var btn_anterior: Button = $EstadoPanel/izq
@onready var btn_siguiente: Button = $EstadoPanel/der
@onready var btn_estado_salir: Button = $EstadoPanel/Salir
@onready var character_ContextMenu: PopupMenu = $ItemContextMenu/CharacterContextMenu

var current_index: int = 0

var is_open := false
var selected_item_id: String = ""

func _ready():
	visible = false
	item_list_panel.visible = false
	btn_objetos.pressed.connect(_on_objetos_pressed)
	btn_estado.pressed.connect(_on_estado_pressed)
	btn_salir.pressed.connect(_on_cerrar_pressed)
	
	# Setear opciones del menú contextual
	popup_menu.clear()
	popup_menu.add_item("Usar", 0)
	popup_menu.add_item("Información", 1)
	popup_menu.add_item("Descartar", 2)
	popup_menu.id_pressed.connect(_on_context_option_selected)
	character_ContextMenu.id_pressed.connect(_on_caracter_ContextMenu_pressed)

	btn_anterior.pressed.connect(_on_anterior_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	btn_estado_salir.pressed.connect(_on_estado_salir_pressed)

	crear_listaContextualCharacter()

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
			character_ContextMenu.visible = true
			# Mover el menú contextual cerca del mouse
			character_ContextMenu.set_position(get_global_mouse_position())
			
		1:
			print("Información de", selected_item_id)
			var item = DataLoader.items.get(selected_item_id, {})
			var desc = item.get("description", "Sin descripción")
			show_info_popup(desc)
		2:
			print("Descartar ", selected_item_id)
			InventoryManager.remove_item(ItemManager.get_item_nombre(selected_item_id), 1)
			update_item_list()

func show_info_popup(text: String):
	info_label.text = text
	info_popup.visible = true

func _on_item_button_pressed(item_id: String):
	print("Seleccionaste el item: ", item_id)

func _on_caracter_ContextMenu_pressed(option_id: int):
	var selected_character = character_ContextMenu.get_item_text(option_id)
	print("Seleccionaste el personaje: ", selected_character)

	if selected_character in PlayableCharacters.party_actual:
		var item = DataLoader.items.get(selected_item_id, {})
		var effects = item.get("effect", "").split(";")
		
		if effects and effects[0] != "":
			EffectManager.apply_effects(effects, selected_character)
			InventoryManager.remove_item(ItemManager.get_item_nombre(selected_item_id), 1)
			update_item_list()
		else:
			print("Este objeto no tiene efectos.")
	else:
		print("El personaje seleccionado no está en el equipo.")
	
	character_ContextMenu.visible = false
	selected_item_id = ""

# Apartado de ESTADO
func _on_estado_pressed():
	team = PlayableCharacters.get_characters()
	current_index = 0
	main_menu.visible = false
	item_list_panel.visible = false
	estado_panel.visible = true
	if team.size() > 0:
		show_character_stats(team[current_index])
	else:
		label_stats.text = "No hay personajes en el equipo."
		face_texture.texture = null
	

func _on_estado_salir_pressed():
	estado_panel.visible = false
	main_menu.visible = true

func show_character_stats(char_id: String):
	if not PlayableCharacters.characters.has(char_id):
		label_stats.text = "Personaje no disponible."
		face_texture.texture = null
		return

	var stats = PlayableCharacters.characters[char_id]["stats"]
	label_stats.text = "Nombre: %s\nClase: %s\nHP: %s\nMP: %s\nAtaque: %s\nAtaque Mágico: %s\nDefensa: %s\nVelocidad: %s\nSuerte: %s\nEspíritu: %s" % [
		char_id,
		stats.get("job_name", "???"),
		stats.get("hp", "???"),
		stats.get("mp", "???"),
		stats.get("atk", "???"),
		stats.get("mag", "???"),
		stats.get("def", "???"),
		stats.get("spd", "???"),
		stats.get("lck", "???"),
		stats.get("fth", "???"),		
	]

	var texture_path = PlayableCharacters.characters[char_id]["stats"]["face"]
	if texture_path != "":
		face_texture.texture = load(texture_path)
	else:
		face_texture.texture = null

func _on_siguiente_pressed():
	if team.size() == 0:
		return
	current_index = (current_index + 1) % team.size()
	show_character_stats(team[current_index])

func _on_anterior_pressed():
	if team.size() == 0:
		return
	current_index = (current_index - 1 + team.size()) % team.size()
	show_character_stats(team[current_index])

func crear_listaContextualCharacter():
	character_ContextMenu.clear()
	for i in range(PlayableCharacters.party_actual.size()):
		character_ContextMenu.add_item(PlayableCharacters.party_actual[i], i)