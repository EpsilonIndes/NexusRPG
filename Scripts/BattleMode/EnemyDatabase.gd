# EnemyDatabase.gd
extends Node

var enemies := { # Recordatorio: Crear CSV con stats enemigos
	"Slime": {
		"nombre": "Slime Celeste",
		"hp": 50,
		"mp": 0,
		"atk": 8,
		"def": 2,
		"spd": 4,
		"lck": 5,
		"wis": 10,
	},
	"Triangle": {
		"nombre": "Triángulo Vengativo",
		"hp": 80,
		"mp": 10,
		"atk": 12,
		"def": 4,
		"spd": 10,
		"lck": 5,
		"wis": 10,
	},
	"Esfera_roja": {
		"nombre": "Esfera Roja",
		"hp": 60,
		"mp": 5,
		"ataque": 10,
		"defensa": 3,
		"velocidad": 11
	}
}

func get_stats(enemy_id: String) -> Dictionary:
	if enemies.has(enemy_id):
		return enemies[enemy_id]
	else:
		push_error("Enemy ID no encontrado: %s" % enemy_id)
		return {}