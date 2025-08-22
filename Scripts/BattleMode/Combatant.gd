# Clase base para jugadores y enemigos
# Combatant.gd
extends Node3D

class_name Combatant

@export var es_jugador: bool
@onready var battle_manager = get_parent().get_parent()
signal turno_finalizado

# Datos base
var id: String = ""
var nombre: String = ""
var hp: int = 0
var hp_max: int	= 0
var mp: int	= 0
var mp_max: int	= 0
var mag: int = 0
var ataque: int = 0
var defensa: int = 0
var velocidad: int = 0
var drive: int = 0

var tecnicas: Array = []

var es_aliado: bool = true
var indice := 0

var position_inicial : Vector3

var tecnica_seleccionada = null


var speed: float = 2 # Solo se utiliza para rotar los enemigos conceptuales (Eliminar luego)

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D if es_jugador else null

var esta_muerto: bool = false
var esta_actuando: bool = false

func _ready():
	if es_jugador:
		animated_sprite.play("idle")

func _physics_process(delta):
	if not es_jugador:
		rotation.y += speed * delta

# Inicializa datos del combatiente según su tipo
func inicializar(datos: Dictionary, es_jugador_: bool) -> void:
	id = datos.get("id", "???")
	nombre = id
	hp = datos.get("hp", 100)
	hp_max = hp
	mp = datos.get("mp", 10)
	mp_max = mp
	tecnicas = datos.get("tecnicas", [])
	es_jugador = es_jugador_
	es_aliado = es_jugador
	
	tecnicas = GlobalTechniqueDatabase.get_techniques_for(nombre)
	
func esta_vivo() -> bool:
	return hp > 0

func seleccionar_tecnica(tecnica: Dictionary, objetivo: Combatant) -> void:
	tecnica_seleccionada = {
		"datos": tecnica,
		"objetivo": objetivo
	}
	battle_manager.cambiar_estado(battle_manager.BattleState.EJECUCION_ACCION)

func ejecutar_tecnica():
	if tecnica_seleccionada == null:
		push_warning("No se ha seleccionado ninguna técnica.")
		emit_signal("turno_finalizado")
		return
	
	var tecnica = tecnica_seleccionada["datos"]
	var objetivo: Combatant = tecnica_seleccionada["objetivo"]

	# Costos
	mp -= tecnica.get("costo_mp", 0)
	drive -= tecnica.get("costo_drive", 0)

	# Aplicar efectos
	var efectos = tecnica.get("efectos", [])
	for efecto_id in efectos:
		EffectManager.apply_effects(efecto_id, objetivo.id)
	
	# Mostrar animación o Feedback
	print("%s usa %s sobre %s" % [nombre, tecnica["tecnique_id"], objetivo.nombre])

	await get_tree().create_timer(0.6).timeout
	emit_signal("turno_finalizado")

func iniciar_accion():
	# Para enemigos: Eligen automáticamente
	if not esta_vivo():
		emit_signal("turno_finalizado")
		return
	
	# Seleccionar tecnica aleatoria
	var tecnica = tecnicas[randi() % tecnicas.size()]

	# Elige objetivo valido (Jugadores vivos)
	var posibles = battle_manager.combatientes.filter(func(c): return c.is_jugador() and c.esta_vivo())
	if posibles.is_empty():

		emit_signal("turno_finalizado")
		return
	
	var objetivo = posibles[randi() % posibles.size()]
	tecnica_seleccionada = {"datos": tecnica, "objetivo": objetivo}

	ejecutar_tecnica()

func is_jugador() -> bool:
	return es_jugador