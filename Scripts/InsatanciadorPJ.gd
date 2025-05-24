extends Node

func _ready():
    GameManager.agregar_personaje("Kosmo", "quantic_master")
    GameManager.agregar_personaje("Miguelito", "hunter")
    GameManager.agregar_personaje("Chipita", "dark_mage")
    GameManager.agregar_personaje("Sigrid", "knight")

    for id in GameManager.equipo_actual:
        PlayableCharacters.characters[id]["in_party"] = true
