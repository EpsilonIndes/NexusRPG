# MainMenuUI.gd (En nodo)
extends Control



# Supone que el InventoryUI es su hermano:
@onready var inventory_ui := $"../InventoryUI"
@onready var estadisticas_ui := $"../EstadisticasUI"
@onready var opciones_ui := $"../OpcionesUI"

@onready var inv_btn := $Panel/VBoxContainer/Inventario
@onready var stats_btn := $Panel/VBoxContainer/Estadisticas
@onready var salir_btn := $Panel/VBoxContainer/Salir

@onready var anim := $AnimationPlayer
@onready var party_sumary := $"../PartySumaryUI"
@onready var party_sumary_anim := party_sumary.get_node("AnimationPlayer")

var is_open := false

func _ready() -> void:
	visible = false
	party_sumary.visible = false
	set_process_unhandled_input(false)

	anim.animation_finished.connect(_on_animation_finished)

	inv_btn.pressed.connect(_on_inventario_pressed)
	stats_btn.pressed.connect(_on_estadisticas_pressed)
	salir_btn.pressed.connect(close)

	inventory_ui.closed.connect(_on_child_ui_closed)
	estadisticas_ui.closed.connect(_on_child_ui_closed)


func open():
	if is_open:
		return

	is_open = true
	visible = true
	set_process_unhandled_input(true)

	anim.play("open")

	party_sumary.visible = true
	party_sumary.refresh()
	party_sumary_anim.play("open")

	GameManager.push_ui()
	inv_btn.grab_focus()

func close():
	is_open = false
	set_process_unhandled_input(false)

	anim.play("close")
	party_sumary_anim.play("close")
	
	GameManager.pop_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not is_open and GameManager.ui_lock_count == 0:
		open()
		return
	elif event.is_action_pressed("menu") and is_open and GameManager.ui_lock_count == 1:
		close()
		return

	

#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("ui_cancel") and is_open and GameManager.ui_lock_count == 1:
#		close()
#		get_viewport().set_input_as_handled()


func _on_inventario_pressed():
	inventory_ui.open()
	close()


func _on_estadisticas_pressed() -> void:
	estadisticas_ui.open()
	close()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "close":
		visible = false
		party_sumary.visible = false


func _on_child_ui_closed():
	open()
