"""
WorldFlags.gd (Autoload)
Es la verdad del mundo, este script controla los eventos (Misiones y IAs)
y activa flags que se mantendrán coherentes entre escenas.

Determina:
	cofres abiertos
	NPCs que cambiaron
	swaps visuales (NPC ↔ Party)

Vive fuera del mundo
Puede guardarse en savegame

"""
extends Node

var flags := {}

func set_flag(id: String, value: bool = true):
	flags[id] = value

func has_flag(id: String) -> bool:
	return flags.get(id, false)

func clear_flag(id: String):
	flags.erase(id)
