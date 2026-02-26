# DriveScore.gd (En Nodo)
# Este sistema maneja la puntuación del modo batalla
# 	La puntuación se basa en los combos ejecutados por el jugador.
# 	La buena ejecución de combos, alimenta la barra del sistema Overdrive.

class_name DriveSystem
extends Node

signal score_changed(new_score)
signal rank_changed(new_rank)
signal overdrive_meter_changed(value)
signal overdrive_started()
signal overdrive_ended()

# Score Base
var score: int = 0
var rank: String = "Static Pulse"

# Historial táctico
var last_roles: Array[String] = []
var repeated_role_count: int = 0

# Overdrive
var overdrive_meter: float = 0.0
var overdrive_active: bool = false
var damage_buffer: int = 0

# Configuración
var max_overdrive_meter: float = 100.0
var spam_threshold: int = 2

const RANK_THRESHOLDS := {
	"Static Pulse": 500, # Clasificación D
	"Tandem Flow": 1000, # Clasificación C
	"Overdrive Sync": 1500, # Clasificación B
	"Harmonic Surge": 2250, # Clasificación A
	"Soul Gear Resonance": 3000, # Clasificación S
	"Nexus Ascent": 5000, # Clasificación SS
	"Mythic Sync": 10000 # Clasificación SSS
}

"""
Este método evalúa coherencia, detecta spam, actualiza score, 
actualiza rango, carga Overdrive, si Overdrive 
está activo → acumula daño
"""
func register_action(role: String, damage_done: int) -> void:
		pass

func _evaluate_role(role: String) -> int:
	var value := 0
	
	if last_roles.is_empty():
		value = 5
	elif role != last_roles.back():
		value = 10
		repeated_role_count = 0
	else:
		repeated_role_count += 1
		if not overdrive_active and repeated_role_count >= spam_threshold:
			value = -5
		else:
			value = 3
	
	last_roles.append(role)
	if last_roles.size() > 3:
		last_roles.pop_front()

	return value

func _update_score(delta: int) -> void:
	if overdrive_active and delta < 0:
		return  # Congelamos penalizaciones
	
	score += delta
	score = max(score, 0)
	
	emit_signal("score_changed", score)
	
	_update_rank()
	_update_overdrive_meter(delta)

func _update_rank() -> void:
	var previous_rank = rank
	
	for r in RANK_THRESHOLDS.keys():
		if score >= RANK_THRESHOLDS[r]:
			rank = r
	
	#if overdrive_active and _rank_value(rank) < _rank_value(previous_rank):
	#	rank = previous_rank  # No baja durante Overdrive
	
	if rank != previous_rank:
		emit_signal("rank_changed", rank)

func _update_overdrive_meter(delta: int) -> void:
	if delta > 0:
		overdrive_meter += delta * 0.3
	
	overdrive_meter = clamp(overdrive_meter, 0, max_overdrive_meter)
	emit_signal("overdrive_meter_changed", overdrive_meter)

