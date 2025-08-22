# DriveScore.gd Autoload
# Este sistema maneja la puntuación del modo batalla
# 	La puntuación se basa en los combos ejecutados por el jugador.
# 	La buena ejecución de combos, habilita "miniturnos" exclusivos para personajes.
# 	Estos miniturnos no ocupan un turno normal.
# 	Y alcanzar ciertos puntajes, desbloqueas buffos para el equipo.
# 
extends Node

var score: int = 0
var combo_chain: int = 0
var active_synergies: Array = []
var tier: int = 0

const TIER_THRESHOLDS := [
	{"name": "Static Pulse", "min": 500}, # Clasificación D
	{"name": "Tandem Flow", "min": 1000}, # Clasificación C
	{"name": "Overdrive Sync", "min": 1500}, # Clasificación B
	{"name": "Harmonic Surge", "min": 2250}, # Clasificación A
	{"name": "Soul Gear Resonance", "min": 3000}, # Clasificación S
	{"name": "Nexus Ascent", "min": 5000}, # Clasificación SS
	{"name": "Mythic Sync", "min": 10000} # Clasificación SSS
]
