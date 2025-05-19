#Clase base para jugadores y enemigos
# Combatant.gd
extends Node3D
class_name Combatant

var class_id: String = ""
@export var es_jugador: bool

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

func _ready():
	if es_jugador:
		cargar_datos_jugador()
	else:
		cargar_datos_enemigo()
		

func cargar_datos_jugador():
	if not PlayableCharacters.characters.has(class_id):
		push_error("El personaje %s no está en PlayableCharacters." % class_id)
		return
	
	var datos = PlayableCharacters.characters[class_id]

	nombre = datos.get("nombre", "???")
	hp_max = datos.get("hp", 100)
	hp = hp_max
	mp_max = datos.get("mp", 20)
	mp = mp_max
	ataque = datos.get("atk", 10)
	defensa = datos.get("def", 5)
	velocidad = datos.get("spd", 10)

func cargar_datos_enemigo():
	if not EnemyDatabase.enemies.has(class_id):
		push_error("El enemigo %s no está en EnemyDatabase." % class_id)
		return

	var datos = EnemyDatabase.get_sats(class_id)

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

