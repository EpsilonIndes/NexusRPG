# CombatData.gd Autoload
extends Node

var jugadores: Array[String] = []
var enemigos: Array[String] = []
var sinergias_activas: Dictionary = {}

func calcular_sinergias():
	sinergias_activas.clear()
	for i in range(jugadores.size()):
		for j in range(i + 1, jugadores.size()):
			var par = [jugadores[i], jugadores[j]]
			var clave = par[0] + "_" + par[1]
			if SynergyDatabase.has_synergy(clave):

				sinergias_activas[clave] = SynergyDatabase[clave]
func configurar_combate(jugadores_lista: Array, enemigos_lista: Array):
	jugadores = jugadores_lista
	enemigos = enemigos_lista
	calcular_sinergias()
