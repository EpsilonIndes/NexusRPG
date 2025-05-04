extends Control

@onready var kosmo_rayCast = $"../../Personajes/Player/RayCast3D"

func _ready():
	UImanager.label_dialogue  = $"../../CanvasLayer/LabelDialogue"

func mostrar_dialogo(nombre, texto):
	
	get_node("PanelGeneral/NombrePanel/Nombre").text = nombre
	get_node("PanelGeneral/Dialogo").text = texto
	get_node("PanelGeneral").visible = true
	
func ocultar_dialogo():
	get_node("PanelGeneral").visible = false

func _input(event):
	if event.is_action_pressed("accion"):
		ocultar_dialogo()
		GameManager.set_estado(GameManager.EstadosDeJuego.LIBRE)