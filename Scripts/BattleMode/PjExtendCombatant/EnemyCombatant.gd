# EnemyCombatant.gd
extends Combatant
class_name EnemyCombatant

const EnemyAIClass = preload("res://Scripts/BattleMode/enemy_ai/EnemyAI.gd")
const EnemyRoleBase = preload("res://Scripts/BattleMode/enemy_ai/roles/EnemyRole.gd")

# Shaders
@onready var body: MeshInstance3D = $Model/MeshInstance3D
@onready var outline: MeshInstance3D = $Model/Outline
var highlight_material: ShaderMaterial

var enemy_role_id: String = ""
var enemy_role: EnemyRoleBase = null
var enemy_ai: EnemyAIClass = null


func _ready():
	outline.visible = false

	highlight_material = outline.material_override.duplicate()
	outline.material_override = highlight_material


func inicializar(datos: Dictionary, es_jugador_: bool, battle_manager_: Node) -> void:
	super.inicializar(datos, es_jugador_, battle_manager_)

	es_jugador = false
	_configurar_ia_enemiga(datos)


func _configurar_ia_enemiga(datos: Dictionary) -> void:
	var stats := EnemyDatabase.get_stats(id)
	enemy_role_id = str(datos.get("enemy_role_id", stats.get("enemy_role_id", "")))
	enemy_role = _instanciar_enemy_role(enemy_role_id)
	enemy_ai = EnemyAIClass.new(self, enemy_role)


func _instanciar_enemy_role(role_id: String) -> EnemyRoleBase:
	var role_data = EnemyDatabase.get_role_data(role_id)
	var script_path := str(role_data.get("script_path", ""))
	if script_path == "":
		push_warning("Enemy role sin script_path para %s. Usando EnemyRole base." % role_id)
		return EnemyRoleBase.new()

	var script = load(script_path)
	if script == null:
		push_warning("No se pudo cargar enemy role '%s' en %s. Usando EnemyRole base." % [role_id, script_path])
		return EnemyRoleBase.new()

	var role = script.new()
	if role.has_method("setup"):
		role.setup(self)
	return role


func crear_accion_enemiga() -> Dictionary:
	if enemy_ai == null:
		_configurar_ia_enemiga({})

	var decision := enemy_ai.decide_action(_crear_contexto_ia())
	if _accion_es_valida(decision):
		return decision

	push_warning("El enemigo %s (%s) usa fallback de IA: %s" % [id, nombre, decision.get("reason", "sin_motivo")])
	return _crear_accion_fallback(decision.get("reason", "invalid_decision"))


func get_tecnicas_disponibles() -> Array:
	return tecnicas.duplicate(true)


func _accion_es_valida(accion: Dictionary) -> bool:
	var tecnica: Dictionary = accion.get("tecnica", {})
	if tecnica.is_empty():
		return false

	var scope := str(tecnica.get("target_scope", "SINGLE_ENEMY"))
	if scope == "SELF":
		return true

	var objetivos = accion.get("objetivos", [])
	if not objetivos is Array:
		objetivos = [objetivos]

	for objetivo in objetivos:
		if objetivo != null and is_instance_valid(objetivo) and objetivo.has_method("esta_vivo") and objetivo.esta_vivo():
			return true

	return false


func _crear_accion_fallback(reason: String) -> Dictionary:
	for tecnica in get_tecnicas_disponibles():
		if not tecnica is Dictionary or tecnica.is_empty():
			continue

		var target = _elegir_objetivo_fallback(tecnica)
		var objetivos := _normalizar_objetivos(target)
		if str(tecnica.get("target_scope", "SINGLE_ENEMY")) == "SELF" or not objetivos.is_empty():
			return {
				"intent": "ATTACK",
				"technique": tecnica,
				"target": target,
				"reason": "enemy_combatant_fallback_%s" % reason,
				"tecnica": tecnica,
				"objetivos": objetivos
			}

	var tecnica_defensiva := _crear_tecnica_defensiva_fallback()
	return {
		"intent": "DEFEND",
		"technique": tecnica_defensiva,
		"target": self,
		"reason": "enemy_combatant_defensive_fallback_%s" % reason,
		"tecnica": tecnica_defensiva,
		"objetivos": [self]
	}


func _elegir_objetivo_fallback(tecnica: Dictionary):
	var scope := str(tecnica.get("target_scope", "SINGLE_ENEMY"))
	var contexto := _crear_contexto_ia()
	var allies: Array = contexto.get("allies", [])
	var opponents: Array = contexto.get("opponents", [])

	match scope:
		"ALL_ENEMIES":
			return opponents
		"ALL_ALLIES":
			return allies
		"SINGLE_ALLY", "RANDOM_ALLY":
			return _primer_vivo(allies)
		"SELF":
			return self
		_:
			return _primer_vivo(opponents)


func _primer_vivo(candidatos: Array):
	for candidato in candidatos:
		if candidato != null and is_instance_valid(candidato) and candidato.has_method("esta_vivo") and candidato.esta_vivo():
			return candidato
	return null


func _normalizar_objetivos(target) -> Array:
	if target == null:
		return []
	if target is Array:
		return target.filter(func(t): return t != null and is_instance_valid(t) and t.has_method("esta_vivo") and t.esta_vivo())
	if target != null and is_instance_valid(target) and target.has_method("esta_vivo") and target.esta_vivo():
		return [target]
	return []


func _crear_tecnica_defensiva_fallback() -> Dictionary:
	return {
		"personaje": id,
		"tecnique_id": "%s_defend_fallback" % id,
		"nombre_tech": "Defensa",
		"rol_combo": "enemy",
		"descripcion": "Fallback defensivo enemigo.",
		"score_value": 0,
		"arma": "natural",
		"effect": [],
		"efectos": [],
		"target_scope": "SELF",
		"allow_target_switch": false,
		"tipo_dano": "",
		"visual_tipo": "",
		"animation_scene": null,
		"camera_profile": "default"
	}


func _crear_contexto_ia() -> Dictionary:
	var allies: Array = []
	var opponents: Array = []
	var battle_stats := {}
	var last_technique := ""
	var repeated_count := 0
	var drive_score := 0

	if battle_manager != null:
		allies = battle_manager.combatientes.filter(func(c): return c is Combatant and not c.es_jugador and c.esta_vivo())
		opponents = battle_manager.combatientes.filter(func(c): return c is Combatant and c.es_jugador and c.esta_vivo())
		var stats_value = battle_manager.get("battle_stats")
		var last_technique_value = battle_manager.get("ultima_tecnica_usada")
		var repeated_count_value = battle_manager.get("repeticion_continua")
		var drive_score_value = battle_manager.get("drive_score")

		battle_stats = stats_value if stats_value is Dictionary else {}
		last_technique = str(last_technique_value) if last_technique_value != null else ""
		repeated_count = int(repeated_count_value) if repeated_count_value != null else 0
		drive_score = int(drive_score_value) if drive_score_value != null else 0

	return {
		"owner": self,
		"allies": allies,
		"opponents": opponents,
		"available_techniques": get_tecnicas_disponibles(),
		"enemy_role_id": enemy_role_id,
		"drive_score": drive_score,
		"last_player_technique_id": last_technique,
		"last_player_combo_role": _obtener_rol_combo_tecnica(last_technique),
		"repeated_player_technique_count": repeated_count,
		"player_technique_usage": battle_stats.get("techniques_used", {}),
		"pressure_turns": 0,
		"restriction_condition_met": false
	}


func _obtener_rol_combo_tecnica(tech_id: String) -> String:
	if tech_id == "":
		return ""

	var technique := GlobalTechniqueDatabase.get_tecnica_stats(tech_id)
	return str(technique.get("rol_combo", ""))


func iniciar_accion():
	var accion := crear_accion_enemiga()
	if accion.is_empty():
		emit_signal("turno_finalizado")
		return

	seleccionar_tecnica(accion.get("tecnica", {}), accion.get("objetivos", []))
	await ejecutar_tecnica()


func set_target_highlight(active: bool) -> void:
	outline.visible = active
	highlight_material.set_shader_parameter("highlight", active)
