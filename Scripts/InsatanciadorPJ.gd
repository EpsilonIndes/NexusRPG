extends Node

func _ready():
    GameManager.agregar_personaje("Kosmo", "quantic_master")
    GameManager.agregar_personaje("Sigrid", "knight")
    GameManager.agregar_personaje("Chipita", "dark_mage")
    GameManager.agregar_personaje("Maya", "lancer")

    for id in GameManager.equipo_actual:
        PlayableCharacters.characters[id]["in_party"] = true
