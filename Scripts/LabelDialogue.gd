extends Control

func _ready():
	UImanager.label_dialogue = $Nivel1/CanvasLayer/LabelDialogue #No se asignaaaa, para arreglar.

var dialogo_activo := false

func mostrar_dialogo(nombre, texto):
	get_node("PanelGeneral/NombrePanel/Nombre").text = nombre
	get_node("PanelGeneral/Dialogo").text = texto
	get_node("PanelGeneral").visible = true
	dialogo_activo = true

func ocultar_dialogo():
	get_node("PanelGeneral").visible = false
	dialogo_activo = false

func _input(event):
	if event.is_action_pressed("cancelar") and dialogo_activo:
		ocultar_dialogo()