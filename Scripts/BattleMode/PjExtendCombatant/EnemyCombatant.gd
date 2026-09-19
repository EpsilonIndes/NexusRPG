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
	if not script is Script or not script.can_instantiate():
		push_warning("No se pudo cargar enemy role '%s' en %s. Usando EnemyRole base." % [role_id, script_path])
		return EnemyRoleBase.new()

	var role = script.new()
	if not role is EnemyRoleBase:
		if role is Node:
			role.free()
		push_warning("Script de rol incompatible: %s" % script_path)
		return EnemyRoleBase.new()
	return role


func crear_accion_enemiga() -> Dictionary:
	if not esta_vivo():
		return {}
	if enemy_ai == null:
		_configurar_ia_enemiga({})
	return enemy_ai.decide_action(_crear_contexto_ia())


func get_tecnicas_disponibles() -> Array:
	return tecnicas.duplicate(true)

func _crear_contexto_ia() -> Dictionary:
	var allies: Array = []
	var opponents: Array = []
	var battle_stats := {}
	var last_technique := ""
	var repeated_count := 0

	if is_instance_valid(battle_manager):
		allies = battle_manager.combatientes.filter(func(c): return EnemyAIClass.Targets.living(c) and not c.es_jugador)
		opponents = battle_manager.combatientes.filter(func(c): return EnemyAIClass.Targets.living(c) and c.es_jugador)
		var stats_value = battle_manager.get("battle_stats")
		var last_technique_value = battle_manager.get("ultima_tecnica_usada")
		var repeated_count_value = battle_manager.get("repeticion_continua")

		battle_stats = stats_value if stats_value is Dictionary else {}
		last_technique = str(last_technique_value) if last_technique_value != null else ""
		repeated_count = int(repeated_count_value) if repeated_count_value != null else 0

	return {
		"owner": self,
		"allies": allies,
		"opponents": opponents,
		"available_techniques": get_tecnicas_disponibles(),
		"enemy_role_id": enemy_role_id,
		"last_player_technique_id": last_technique,
		"last_player_combo_role": _obtener_rol_combo_tecnica(last_technique),
		"repeated_player_technique_count": repeated_count,
		"player_technique_usage": battle_stats.get("techniques_used", {}),
		# Placeholders for future role-specific state. Keep them inert until the battle flow owns those counters.
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
