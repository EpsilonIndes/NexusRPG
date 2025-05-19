extends Control

@onready var kosmo_rayCast = $"../../Personajes/Player/RayCast3D"

var lineas_dialogo: Array = []
var indice_dialogo: int = 0
var dialogo_activo: bool = false

func _ready():
	UImanager.label_dialogue  = $"../../CanvasLayer/LabelDialogue"

func mostrar_dialogo(nombre: String, lineas: Array):
	
	lineas_dialogo = lineas
	indice_dialogo = 0
	dialogo_activo = true
	get_node("PanelGeneral/NombrePanel/Nombre").text = nombre
	get_node("PanelGeneral").visible = true
	mostrar_linea_actual()
	
func mostrar_linea_actual():
	get_node("PanelGeneral/Dialogo").text = lineas_dialogo[indice_dialogo]

func continuar_dialogo():
	if not dialogo_activo: return
	indice_dialogo += 1

	if indice_dialogo < lineas_dialogo.size():
		mostrar_linea_actual()
	else:
		ocultar_dialogo()

func ocultar_dialogo():	
	get_node("PanelGeneral").visible = false
	dialogo_activo = false
	GameManager.set_estado(GameManager.EstadosDeJuego.LIBRE)

func _input(event):
	if event.is_action_pressed("accion"):
		continuar_dialogo()
	
