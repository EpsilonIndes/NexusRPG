extends Node
@onready var player: Node3D = get_node("../Personajes/Player")
@onready var cont_seguidores: Node3D = get_node("../Personajes/seguidores")
func _ready():
	WorldStateManager.restore_player(player)
	PartyHandler.actualizar_personajes_party()
	
	await get_tree().process_frame
	WorldStateManager.restore_followers(cont_seguidores)
	#UIManager.reset_world_ui()
