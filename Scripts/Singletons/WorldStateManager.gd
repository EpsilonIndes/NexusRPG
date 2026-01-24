"""
WorldStateManager.gd (Autoload)
Este script toma un snapshot temporal que vive solo en memoria

❌ NO toca nodos, no guarda referencias
no congela escenas, solo guarda datos
"""
extends Node

var snapshot: Dictionary = {}

func capture_player(player: Node3D) -> void:
	if player == null:
		push_error("[WorldStateManager] No se encontró el nodo Player")
		return

	snapshot = {
		"player_position": player.global_position,
		"player_rotation": player.global_rotation
	}


func capture_followers(seguidores: Node3D):
	var followers_snapshot: Array = []
	
	for child in seguidores.get_children():
		if not child is CharacterBody3D:
			continue

		followers_snapshot.append({
			"name": child.name,
			"position": child.global_position,
			"rotation": child.global_rotation
		})
	
	snapshot["party"] = followers_snapshot


func restore_player(player: Node3D) -> void:
	if snapshot.is_empty():
		return
	
	if snapshot.has("player_position"):
		player.global_position = snapshot["player_position"]

	if snapshot.has("player_rotation"):
		player.global_rotation = snapshot["player_rotation"]
	
	# Limpiar snapshot
	snapshot.clear()

func restore_followers(seguidores: Node3D):
	if not snapshot.has("followers"):
		return
	
	var data = snapshot["followers"]

	for child in seguidores.get_children():
		for saved in data:
			if saved["name"] == child.name:
				child.global_position = saved["position"]
				child.global_rotation = saved["rotation"]
				break
