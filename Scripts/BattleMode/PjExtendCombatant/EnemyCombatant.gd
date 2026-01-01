# EnemyCombatant.gd
extends Combatant
class_name EnemyCombatant


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
	if not esta_vivo():
		emit_signal("turno_finalizado")
		return

	# Si no tiene técnicas → evitar crasheos
	if tecnicas.is_empty():
		print("⚠️ El enemigo %s no tiene técnicas definidas" % nombre)
		emit_signal("turno_finalizado")
		return

	# Elegir técnica random
	var tecnica = tecnicas[randi() % tecnicas.size()]

	# Objetivos posibles (solo jugadores vivos)
	var posibles = battle_manager.combatientes.filter(
		func(c): return c.es_jugador and c.esta_vivo()
	)

	if posibles.is_empty():
		emit_signal("turno_finalizado")
		return

	var objetivo = posibles[randi() % posibles.size()]

	# Crear diccionario estándar para acciones
	var action = {
		"usuario": self,
		"objetivo": objetivo,
		"tecnica": tecnica
	}

	battle_manager.ejecutar_accion(action)
