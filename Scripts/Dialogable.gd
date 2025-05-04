extends Node3D

@export var nombre_npc: String = "Miguelito"
@export var dialogo_texto: String = "Ayuda Kosmo, no puedo moverme!"

func interact():
	var dialog_ui = $"../../CanvasLayer/LabelDialogue"

	dialog_ui.get_node("PanelGeneral/NombrePanel/Nombre").text = nombre_npc
	dialog_ui.get_node("PanelGeneral/Dialogo").text = dialogo_texto
	dialog_ui.visible = true