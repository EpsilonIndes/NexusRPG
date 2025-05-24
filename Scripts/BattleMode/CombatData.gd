# CombatData.gd Autoload
extends Node

var jugadores: Array[String] = []
var enemigos: Array[String] = []


func configurar_combate(jugadores_lista: Array, enemigos_lista: Array):
	jugadores = jugadores_lista
	enemigos = enemigos_lista
