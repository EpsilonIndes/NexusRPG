# Combatant.gd
extends Node3D
class_name Combatant

signal turno_finalizado

var battle_manager: Node = null
@export var es_jugador: bool = false

@onready var damage_anchor: Node3D = $DamageAnchor

var cola_feedback: Array = []

# Efectos activos: { id:String, duracion:int, args:[], tick:Callable?, on_apply:Callable?, on_expire:Callable? }
var efectos_activos := [] # cada elemento será {id, duracion, data}

# Datos base
var id: String = ""
var nombre: String = ""
var hp := 0
var hp_max := 0
var mp := 0
var mp_max := 0
var ataque := 0
var defensa := 0
var velocidad := 0
var suerte := 0
var espiritu := 0
var drive := 0
var tecnicas: Array = []
var display_name: String = ""
var precision: int = 0
var evasion := 0.0

var crit_rate := 0
var crit_dmg := 0

# Pa la práctica de Tweens:
var levitation_tween: Tween
@onready var base_y := global_position.y

# Estado de acción
var tecnica_seleccionada = null # {"datos":dict, "objetivos":[combatant, ...]}
var esta_muerto := false

@onready var animated_sprite := $AnimatedSprite3D if es_jugador else null
var position_inicial: Vector3 = Vector3.ZERO
var indice: int = -1

var original_position: Vector3



func _ready() -> void:
	if not es_jugador:
		start_levitation()

	
	

func _physics_process(delta: float) -> void:
	if not es_jugador and not esta_muerto:
		rotation.y = rotation.y + 2 * delta

#--------------------------------------------------------------------------------------
# Inicialización
#--------------------------------------------------------------------------------------


func inicializar(datos: Dictionary, es_jugador_: bool, battle_manager_: Node) -> void:
	es_jugador = es_jugador_
	battle_manager = battle_manager_

	# --- Identidad ---
	id = datos.get("id", "")
	nombre = datos.get("nombre", id)

	# --- Stats base ---
	# csv_encabezados: hp,max_hp,dp,max_dp,atk,def,spd,lck,wis,face
	if es_jugador:
		var stats = PlayableCharacters.get_stats(id)
		ataque = stats.atk
		defensa = stats.def
		velocidad = stats.spd
		suerte = stats.lck
		espiritu = stats.wis
		hp_max = stats.max_hp
		hp = hp_max
		mp_max = stats.max_dp
		mp = mp_max
		precision = stats.prec
		
		evasion = velocidad % suerte * 2

		crit_dmg = stats.crit_dmg
		crit_rate = stats.crit_rate

	else:
		var stats = EnemyDatabase.get_stats(id)
		ataque = stats.atk
		defensa = stats.def
		velocidad = stats.spd
		suerte = stats.lck
		espiritu = stats.wis
		hp_max = stats.get("hp", 50)
		hp = hp_max
		mp_max = stats.get("mp", 0)
		mp = mp_max

	# --- Técnicas ---
	tecnicas = GlobalTechniqueDatabase.get_techniques_for(id)
	original_position = global_position
	

#------------------
# Helpers básicos
#------------------
func esta_vivo() -> bool:
	return hp > 0


func recibir_danio(cantidad: int, tipo: String, rol_combo: String = "", critico: bool = false) -> void:
	if cantidad <= 0:
		print("Salud reducida a 0! ", nombre)
		return

	hp = max(0, hp - cantidad)
	print("%s recibe %d de daño | HP: %d/%d" % [nombre, cantidad, hp, hp_max])
	
	cola_feedback.append({
		"valor": cantidad,
		"tipo": tipo,
		"critico": critico,
		"rol_combo": rol_combo
	})

	# Animacion de daño
	if animated_sprite and "hit" in animated_sprite.sprite_frames.get_animation_names():
		animated_sprite.play("hit")

	if hp <= 0 and not esta_muerto:
		esta_muerto = true
		_on_muerte()


""" Para restaurar si algo sale mal alv:
func recibir_danio(cantidad: int) -> void:
	if cantidad <= 0:
		print("Salud reducida a 0! ", nombre)
		return

	hp = max(0, hp - cantidad)
	print("%s recibe %d de daño | HP: %d/%d" % [nombre, cantidad, hp, hp_max])
	
	mostrar_numero_danio(cantidad)

	# Animacion de daño
	if animated_sprite and "hit" in animated_sprite.sprite_frames.get_animation_names():
		animated_sprite.play("hit")

	if hp <= 0 and not esta_muerto:
		esta_muerto = true
		_on_muerte()
"""

func _on_muerte() -> void:
	# para resultados:
	battle_manager.registrar_enemigos_derrotado(self)

	#levitation_tween.pause()
	print("%s ha caído en batalla." % nombre)
	# reproducir anim de muerte si corresponde
	if animated_sprite and "death" in animated_sprite.sprite_frames.get_animation_names():
		animated_sprite.play("death")
		
		# NOTA: no emitimos turno_finalizado aquí; lo maneja el flujo cuando corresponda.

func curar_hp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	hp = min(hp + cantidad, hp_max)
	print("%s recupera %d HP | HP: %d/%d" % [nombre, cantidad, hp, hp_max])
	
	cola_feedback.append({
		"valor": cantidad,
		"tipo": "heal",
		"critico": 0,
		"rol_combo": "support"
	})

func modificar_stat(stat: String, cantidad: int) -> void:
	var allowed := ["hp", "hp_max", "dp", "mp_max", "ataque", "defensa", "velocidad", "drive"]
	if not stat in allowed:
		print("Stat no encontrada o no segura para modificar: %s" % stat)
		return
	# usar set/get para propiedades
	var current = self.get(stat)
	if current == null:
		current = 0

	self.set(stat, current + cantidad)
	print("%s modifica %s por %+d | Nuevo valor: %d" %
		[nombre, stat, cantidad, self.get(stat)])
	
	cola_feedback.append({
		"valor": cantidad,
		"tipo": "debuff",
		"critico": false,
		"rol_combo": ""
	})
#--------------------------
# Efectos persistentes
#--------------------------

func agregar_efecto(nuevo: Dictionary) -> void:
	for e in efectos_activos:
		if e.id == nuevo.id:
			if nuevo.tier > e.tier:
				if e.has("on_expire") and e.on_expire is Callable:
					e.on_expire.call(self)

				efectos_activos.erase(e)

				if nuevo.has("on_apply") and nuevo.on_apply is Callable:
					nuevo.on_apply.call(self)
				

				efectos_activos.append(nuevo)
			else:
				e.duracion = max(e.duracion, nuevo.duracion)
			return
	
	if nuevo.has("on_apply") and nuevo.on_apply is Callable:
		nuevo.on_apply.call(self)

	efectos_activos.append(nuevo)
	
	if nuevo.has("visual_tipo"):
		mostrar_feedback_estado(nuevo)
	
	print("registrado efecto %s en %s (dur: %s)" % [nuevo.get("id","?"), nombre, nuevo.get("duracion", "?")])


func procesar_efectos_activos() -> void:
	var expirados := []

	for e in efectos_activos:
		if typeof(e) != TYPE_DICTIONARY:
			push_warning("[Combatant] Efecto corrupto detectado: %s" % e)
			return
	
		# Tick
		if e.has("tick") and e.tick is Callable:
			e.tick.call(self)
		
		# Duración
		if e.has("duracion"):
			e.duracion -= 1
			if e.duracion <= 0:
				expirados.append(e)
	
	# Expirar
	for ex in expirados:
		if ex.has("on_expire") and ex.on_expire is Callable:
			ex.on_expire.call(self)
		efectos_activos.erase(ex)


#--------------------
# Selección / ejecución de técnicas (API usada por BattleManager)
#--------------------
# 'objetivo' puede ser un Combatant o un Array de Combatants (según scope)
func seleccionar_tecnica(tecnica: Dictionary, objetivo) -> void:
	# Guardamos la técnica y la lista de objetivos uniformemente como array
	var objetivos_arr := []
	if objetivo == null:
		objetivos_arr = []
	elif objetivo is Array:
		objetivos_arr = objetivo.duplicate()
	else:
		objetivos_arr = [objetivo]
	tecnica_seleccionada = {"datos": tecnica, "objetivos": objetivos_arr}
	# El BattleManager espera que cambiemos a EJECUCION_ACCION cuando el jugador confirme.
	# No emitimos turno_finalizado aquí.


func ejecutar_tecnica():
	# PROCESAR EFECTOS ANTES DE ACTUAR
	procesar_efectos_activos()

	if not esta_vivo():
		emit_signal("turno_finalizado")
		return
	
	if tecnica_seleccionada == null:
		emit_signal("turno_finalizado")
		return

	var tecnica = tecnica_seleccionada["datos"]
	var objetivos: Array = tecnica_seleccionada.get("objetivos", [])
	
	print("Tecnica completa:", tecnica)
	print("Keys disponibles:", tecnica.keys())

	# Aplicar costes (chequeos simples)
	mp = max(0, mp - tecnica.get("costo_dp", 0))
	drive = max(0, drive - tecnica.get("costo_drive", 0))

	# Log y animacion de ataque
	var nombres_objetivos = objetivos.map(func(o): return o.nombre)
	print("%s usa %s a %s" % [nombre, tecnica.get("tecnique_id", "unknown"), nombres_objetivos])
	if animated_sprite and "attack" in animated_sprite.sprite_frames.get_animation_names():
		animated_sprite.play("attack")

	# Aplicar efectos a cada objetivo (si no hay objetivos pero la técnica aplica SELF, se permite target self)
	if objetivos.size() == 0:
		# fallback: si la técnica targetea SELF
		if tecnica.get("target_scope", "SELF") == "SELF":
			objetivos = [self]
	
	# Ejecutar efectos (Effectmanager espera target: Combatant)
	var efectos = tecnica.get("efectos", [])
	for t in objetivos:
		if t == null:
			continue
		EffectManager.apply_effects(efectos, t, self, tecnica)
		# Si el objetivo murió, ver log y update
		if not t.esta_vivo():
			print("%s ha muerto tras recibir efectos." % t.nombre)
	
	var anim_scene: PackedScene = tecnica.get("animation_scene", null)
	
	if anim_scene:
		print("Anim_scene existe")
		battle_manager.reproducir_animacion(anim_scene, self, objetivos)
		await battle_manager.battle_animator.animation_finished
	else:
		print("anim_scene no existe")

	# Limpiar selección y avisar al BattleManager
	tecnica_seleccionada = null
	print("avisando al battleManager que finalizó turno") # No aparece este log.
	emit_signal("turno_finalizado")

#------------------------------
# IA simple para enemigos
#------------------------------
func iniciar_accion():
	# Llamada por battleManager en turno enemigo
	if not esta_vivo():
		emit_signal("turno_finalizado")
		return

	# PROCESAR EFECTOS ANTES DE ACTUAR
	procesar_efectos_activos()

	#Si el veneno te mató acá, no actuás
	if not esta_vivo():
		emit_signal("turno_finalizado")
		return

	# Enemigo elige técnica random
	if tecnicas.is_empty():
		push_warning("⚠️ El enemigo %s no tiene técnicas definidas" % nombre)
		emit_signal("turno_finalizado")
		return
	
	var tecnica = tecnicas.pick_random()
	
	# candidatos según scope (usar el método público del BattleManager)
	var scope = tecnica.get("target_scope", "SINGLE_ENEMY")
	var candidatos = battle_manager._candidatos_por_scope(scope)
	#fallback si no hay candidatos
	var target = null
	if candidatos.size() > 0:
		# Si SINGLE -> random entre candidatos; si ALL -> pasar lista
		if scope.begins_with("SINGLE") or scope.begins_with("RANDOM"):
			target = candidatos.pick_random()
		else:
			target = candidatos.duplicate()
	
	# seleccionar y ejecutar
	seleccionar_tecnica(tecnica, target)


#
#	Práctica de Tweens
#

func start_levitation():
	levitation_tween = create_tween()
	levitation_tween.set_loops() # Para Loop Infinito

	levitation_tween.tween_property(
		self,
		"global_position:y",
		base_y + 0.3,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	levitation_tween.tween_property(
		self,
		"global_position:y",
		base_y,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ----------------
# Feedback visual
# ----------------

func mostrar_numero_danio(valor: int, tipo: String = "normal", critico: bool = false, rol_combo: String = "") -> void:
	var damage_scene = preload("res://Escenas/Battle/DamageText/damage_number.tscn")
	var damage_instance = damage_scene.instantiate()

	damage_anchor.add_child(damage_instance)
	damage_instance.position = Vector3.ZERO
	damage_instance.setup(valor, tipo, rol_combo, critico)


func mostrar_feedback_estado(efecto: Dictionary):
	var tipo = efecto.get("visual_tipo", "")
	var valor = efecto.get("visual_valor", 0)

	match tipo:
		"buff":
			mostrar_numero_danio(valor, "buff", false, "")
		"debuff":
			mostrar_numero_danio(abs(valor), "debuff", false, "")
		
func registrar_evento_visual(tipo: Dictionary) -> void:
	var miss = str(tipo.get("tipo"))
	cola_feedback.append({
		"valor": 0,
		"tipo": miss,
		"critico": 0,
		"rol_combo": ""
	})

func reproducir_feedback() -> void:
	var delay := 0.0
	
	for evento in cola_feedback:
		_mostrar_feedback_con_delay(evento, delay)
		delay += 0.12 # pequeño escalonado
		
	cola_feedback.clear()

func _mostrar_feedback_con_delay(data: Dictionary, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	mostrar_numero_danio(
		data.valor,
		data.tipo,
		data.critico,
		data.rol_combo
	)


# ---------------
#   MOVIMIENTO
# ---------------

func anim_move_to(target_position: Vector3, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func anim_return_to_origin(duration: float) -> void:
	anim_move_to(original_position, duration)