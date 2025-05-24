# EnemyDatabase.gd
extends Node

var enemies := { # Recordatorio: Crear CSV con stats enemigos
	"slime": {
		"nombre": "Slime Azul",
		"hp": 50,
		"mp": 0,
		"ataque": 6,
		"defensa": 2,
		"velocidad": 8
	},
	"Triangle": {
		"nombre": "Triángulo Vengativo",
		"hp": 80,
		"mp": 10,
		"ataque": 12,
		"defensa": 4,
		"velocidad": 10
	},
	"esfera_roja": {
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