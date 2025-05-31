# SynergyDatabase.gd
extends Node

var synergies = {
	"Kosmo_Miguelito": {
		"name": "Hermandad del Caos",
		"multiplier": 1.3,
		"miniturno": true,
		"color_fx": Color.RED
	},
	"Kosmo_Chipita": {
		"name": "Mental Link",
		"multiplier": 1.15,
		"extra_effect": "mp_restore"
	},
	"Sigrid_Chipita": {
		"name": "Mental Link",
		"multiplier": 1.12,
		"extra_effect": "mp_restore"
	}
}

func has_synergy(id: String) -> bool:
	return synergies.has(id)

func get_synergy(id: String) -> Dictionary:
	return synergies.get(id, {})