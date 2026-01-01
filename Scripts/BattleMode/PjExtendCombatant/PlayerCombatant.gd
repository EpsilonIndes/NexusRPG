# PlayerCombatant.gd
extends Combatant
class_name PlayerCombatant

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

func inicializar(datos: Dictionary, es_jugador_: bool, battle_manager_: Node) -> void:
	# Llamar al inicializar base
	super.inicializar(datos, es_jugador_, battle_manager_)

	# Aseguramos que tenga el flag
	es_jugador = true

	# Animación idle por defecto
	if sprite:
		sprite.play("idle")


# -------------------------------------------------------
#  ANIMACIONES BASE PARA TODOS LOS JUGADORES
# -------------------------------------------------------

func anim_idle():
	if sprite:
		sprite.play("idle")


func anim_danio():
	if sprite:
		sprite.play("hit")


func anim_muerte():
	if sprite:
		sprite.play("death")


func anim_ataque():
	# Esta animación es genérica; los personajes específicos pueden sobrescribirla
	if sprite:
		# Si existe animación "attack", la usa… si no, usa "idle"
		if "attack" in sprite.sprite_frames.get_animation_names():
			sprite.play("attack")
		else:
			sprite.play("idle")


# -------------------------------------------------------
#  EJECUCIÓN DE TÉCNICAS — CON ANIMACIÓN
# -------------------------------------------------------

func ejecutar_tecnica():
	if tecnica_seleccionada == null:
		emit_signal("turno_finalizado")
		return

	# Animación previa al ataque
	anim_ataque()

	# Le damos un pequeño delay para que se vea
	await get_tree().create_timer(0.4).timeout

	# Llamamos a la lógica base del Combatant
	await super.ejecutar_tecnica()

	# Volver a idle luego de usar técnica
	anim_idle()


# -------------------------------------------------------
#  ANIMACIÓN AL RECIBIR DAÑO
# -------------------------------------------------------
func recibir_danio(cantidad: int):
	hp -= cantidad
	if hp <= 0:
		hp = 0
		anim_muerte()
	else:
		anim_danio()

