extends Control

@onready var kosmo = $"../../Personajes/Player"

func _ready():
	UImanager.label_dialogue  = $"../../CanvasLayer/LabelDialogue"

func mostrar_dialogo(nombre, texto):
	
	get_node("PanelGeneral/NombrePanel/Nombre").text = nombre
	get_node("PanelGeneral/Dialogo").text = texto
	get_node("PanelGeneral").visible = true
	kosmo.speed = 0
func ocultar_dialogo():
	get_node("PanelGeneral").visible = false

func _input(event):
	if event.is_action_pressed("accion") and kosmo.speed == 0:
		kosmo.speed = 5
		ocultar_dialogo()