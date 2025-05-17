extends Node

func _ready():
    # Agrega un personaje a través del GameManager
    GameManager.agregar_personaje("Kosmo", "quantic_master")
    GameManager.agregar_personaje("Miguelito", "hunter")
    GameManager.agregar_personaje("Sigrid", "knight")
    GameManager.agregar_personaje("Chipita", "dark_mage")