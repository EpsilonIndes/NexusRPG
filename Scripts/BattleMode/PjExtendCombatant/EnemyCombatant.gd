# EnemyCombatant.gd
extends Combatant
class_name EnemyCombatant

# Shaders
@onready var body: MeshInstance3D = $Model/MeshInstance3D
@onready var outline: MeshInstance3D = $Model/Outline
var highlight_material: ShaderMaterial


func _ready():
	outline.visible = false
	
	highlight_material = outline.material_override.duplicate()
	outline.material_override = highlight_material



# -------------------------------------------------------
#  INICIALIZACIÓN
# -------------------------------------------------------
func inicializar(datos: Dictionary, es_jugador_: bool, battle_manager_: Node) -> void:
	# Llamamos al inicializar base del padre
	super.inicializar(datos, es_jugador_, battle_manager_)

	# Aseguramos que sea marcado como enemigo
	es_jugador = false



# -------------------------------------------------------
#  ACCIÓN DEL ENEMIGO (IA SIMPLE)
# -------------------------------------------------------
func iniciar_accion():
	await super.iniciar_accion()

# Shaders
func set_target_highlight(active: bool) -> void:
	outline.visible = active
	highlight_material.set_shader_parameter("highlight", active)
