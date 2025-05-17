extends Node

enum EstadosDeJuego {
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE

func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

# Nuevo: lista del equipo activo (usamos los class_id)
var equipo_actual: Array = ["Kosmo", "Sigrid", "Miguelito", "Chipita"] # Kosmo, Sigrid, Miguelito, Chipita

func agregar_personaje(class_id: String, class_nombre: String):
	if not PlayableCharacters.characters.has(class_id):
		PlayableCharacters.add_character(class_id, class_nombre)
	agregar_al_equipo(class_id)

# Si querés, podés hacer un método para agregar o remover miembros
func agregar_al_equipo(class_id: String):
	if not equipo_actual.has(class_id):
		equipo_actual.append(class_id)

func remover_del_equipo(class_id: String):
	equipo_actual.erase(class_id)

