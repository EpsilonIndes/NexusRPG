# CombatData.gd Autoload
extends Node

var jugadores: Array[Dictionary] = []
var enemigos: Array[Dictionary] = []

func set_jugadores(nuevos_jugadores: Array[Dictionary]) -> void:
	jugadores = nuevos_jugadores.duplicate()

func set_enemigos(ids: Array[String]) -> void:
	var lista: Array[Dictionary] = []
	for id in ids:
		var datos = EnemyDatabase.enemies.get(id, {})
		datos["id"] = id
		lista.append(datos)
	enemigos = lista
