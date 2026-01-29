# MainMenuUI.gd (En nodo)
extends Control

# Supone que el InventoryUI es su hermano:
@onready var inventory_ui := $"../InventoryUI"
@onready var inv_btn := $Panel/VBoxContainer/Inventario
@onready var salir_btn := $Panel/VBoxContainer/Salir
@onready var anim := $AnimationPlayer
@onready var party_sumary := $"../PartySumaryUI"

var inventario_abierto: bool = false

@onready var estadisticas_ui := $"../EstadisticasUI"

@onready var opciones_ui := $"../OpcionesUI"

var is_open := false

func _ready() -> void:
	visible = false
	party_sumary.visible = false
	anim.animation_finished.connect(_on_animation_finished)

	inv_btn.pressed.connect(_on_inventario_pressed)
	salir_btn.pressed.connect(_on_salir_pressed)

func toggle() -> void:
	is_open = !is_open
	if is_open:
		visible = true
		anim.play("open")
		GameManager.push_ui()
		party_sumary.refresh()
		party_sumary.visible = true
		inv_btn.grab_focus()
	else:
		anim.play("close")
		party_sumary.visible = false
		GameManager.pop_ui()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if inventario_abierto == true:
			return
						
		print("Presionado MENU")
		toggle()

func _on_inventario_pressed():
	inventario_abierto = true
	if inventory_ui.visible or estadisticas_ui.visible or opciones_ui.visible:
		return
	
	inventory_ui.toggle()
	
	toggle()

func _on_salir_pressed():
	toggle()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "close":
		visible = false
