#Clase base para jugadores y enemigos
# Combatant.gd
extends Node3D
class_name Combatant

var class_id: String = ""
@export var es_jugador: bool

var posicion_inicial: Vector3 = Vector3.ZERO

var nombre: String = "???"
var hp: int
var hp_max: int
var mp: int
var mp_max: int
var ataque: int
var defensa: int
var velocidad: int

var esta_vivo: bool = true
var esta_actuando: bool = false

signal turno_listo(combatant: Combatant)
signal muerte(combatant: Combatant)

var speed: float = 2

func _physics_process(delta):
	if es_jugador == false:
		rotation.y = rotation.y + speed * delta




func inicializar():
	if es_jugador:
		print("Inicializando jugador %s" % class_id)
		cargar_datos_jugador()
	else:
		print("Inicializando enemigo %s" % class_id)
		cargar_datos_enemigo()

func cargar_datos_jugador():
	if not PlayableCharacters.party_actual.has(class_id):
		push_error("El personaje %s no está en PlayableCharacters." % class_id)
		return
	
	var datos = PlayableCharacters.get_stats(class_id)

	if datos == null:
		push_error("No se encontró el personaje con class_id %s en party_actual." % class_id)
		return

	nombre = datos.get("nombre", "???")
	hp_max = datos.get("hp", 100)
	hp = hp_max
	mp_max = datos.get("mp", 20)
	mp = mp_max
	ataque = datos.get("atk", 10)
	defensa = datos.get("def", 5)
	velocidad = datos.get("spd", 10)

func cargar_datos_enemigo():
	print("Cargando enemigo: %s" % class_id)
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



func recibir_danio(cantidad: int):
	var danio_real = max(1, cantidad - defensa)
	hp -= danio_real
	print("%s recibe %d de daño" % [nombre, danio_real])

	if hp <= 0:
		morir()
	return danio_real

func curar(cantidad: int):
	hp = min(hp + cantidad, hp_max)

func morir():
	esta_vivo = false
	print("%s ha sido derrotado." % nombre)
	emit_signal("muerte", self)
	queue_free()

func iniciar_turno():
	if not esta_vivo:
		return
	esta_actuando = true
	emit_signal("turno_listo", self)

func terminar_turno():
	esta_actuando = false

func regresar_a_posicion():
	global_transform.origin = posicion_inicial
