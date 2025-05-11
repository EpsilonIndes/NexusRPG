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

