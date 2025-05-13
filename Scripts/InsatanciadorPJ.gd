extends Node

func _ready():
    # Agrega un personaje a través del sistema de personajes jugables
    PlayableCharacters.add_character("Kosmo", "quantic_master")

    # Muestra los stats del personaje
    var stats = PlayableCharacters.get_all_stats("Kosmo")
    for stat in stats.keys():
        print("Kosmo - ", stat, ": ", stats[stat])