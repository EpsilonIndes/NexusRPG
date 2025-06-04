# Clase base para jugadores y enemigos
# Combatant.gd
extends Node3D
class_name Combatant

@export var es_jugador: bool

var posicion_inicial: Vector3 = Vector3.ZERO
var nombre: String = "???"
var class_id: String = ""
var pj_id: String = ""
var hp: int
var hp_max: int
var mp: int
var mp_max: int
var ataque: int
var defensa: int
var velocidad: int
var drive: int

var speed: float = 2 # Solo se utiliza para rotar los enemigos conceptuales (Eliminar luego)
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D if es_jugador else null

var esta_muerto: bool = false
var esta_actuando: bool = false
var indice: int = -1 # Indice antes de instanciar

func _ready():
	if es_jugador:
		animated_sprite.play("idle")

# Inicializa datos del combatiente según su tipo
func inicializar():
	if es_jugador:
		cargar_datos_jugador()
		print("Inicializando Personaje %s" % nombre)
	else:
		cargar_datos_enemigo()
		print("Inicializando enemigo %s" % nombre)

func cargar_datos_jugador(): 
	if not PlayableCharacters.characters.has(pj_id):
		push_error("El personaje %s no está en PlayableCharacters." % pj_id)
		return
	
	var datos = PlayableCharacters.characters[pj_id]
	var stats = datos.get("stats", {})

	nombre = datos.get("nombre", "???")
	hp_max = stats.get("hp", 100)
	hp = hp_max
	mp_max = stats.get("mp", 20)
	mp = mp_max
	ataque = stats.get("atk", 10)
	defensa = stats.get("def", 5)
	velocidad = stats.get("spd", 10)

func cargar_datos_enemigo():
	print("Cargando enemigo: %s" % nombre)
	if not EnemyDatabase.enemies.has(class_id):
		push_error("El enemigo %s no está en EnemyDatabase." % class_id)
		return

	var datos = EnemyDatabase.get_stats(class_id)

	nombre = datos.get("nombre", "???")
	hp_max = datos.get("hp", 100)
	hp = hp_max
	mp_max = datos.get("mp", 10)
	mp = mp_max
	ataque = datos.get("ataque", 10)
	defensa = datos.get("defensa", 5)
	velocidad = datos.get("velocidad", 10)
# # #
	
func _physics_process(delta):
	if es_jugador == false: 
		rotation.y = rotation.y + speed * delta 

func recibir_danio(cantidad: int):
	var danio_real = max(1, cantidad - defensa)
	hp -= danio_real
	print("%s recibe %d de daño" % [nombre, danio_real])

	if hp <= 0:
		morir()
	return danio_real

func morir():
	esta_muerto = true
	print("%s ha sido derrotado." % nombre)
	
	if es_jugador:
		animated_sprite.play("death")
	else:
		# Animación de muerte para enemigos #
		queue_free()

func seleccionar_turno(): # activa el menú de acciones del jugador
	if esta_muerto:
		return
	esta_actuando = true
	
	var tecnicas_validas = []

	for t in GlobalTechniqueDatabase.get_techniques_for(nombre):
		if int(t["costo_mana"]) <= mp and int(t["costo_drive"]) <= drive:
			tecnicas_validas.append(t)

	var battle_manager_instance = get_parent().get_parent()
	var posicion_3d = battle_manager_instance.posiciones_jugadores[indice]
	battle_manager_instance.mostrar_tecnicas_sobre(posicion_3d, tecnicas_validas)

func realizar_accion(): # Aquí estará la IA del enemigo
	print("%s está realizando una acción." % nombre)
	if esta_muerto:
		return
	esta_actuando = true
	# Dar un paso hacia adelante
	global_transform.origin += Vector3(0, 0, -1) * 1.2
	regresar_a_posicion()
	terminar_turno()
	
func terminar_turno():
	esta_actuando = false

func regresar_a_posicion():
	global_transform.origin = posicion_inicial
