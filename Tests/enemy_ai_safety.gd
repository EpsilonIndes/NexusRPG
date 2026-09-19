extends Node

const Targets = preload("res://Scripts/BattleMode/ActionTargets.gd")
const AI = preload("res://Scripts/BattleMode/enemy_ai/EnemyAI.gd")
const Role = preload("res://Scripts/BattleMode/enemy_ai/roles/EnemyRole.gd")

class ProposalRole extends Role:
	var proposal := {}
	func evaluate(_context: Dictionary) -> Dictionary:
		return proposal

class QueueManager extends "res://Scripts/BattleMode/BattleManager2.gd":
	var next_state := -1
	func cambiar_estado_diferido(state: BattleState) -> void:
		next_state = state

class RecordingEnemy extends EnemyCombatant:
	var executions := 0
	var executed := {}
	func ejecutar_tecnica():
		executions += 1
		executed = tecnica_seleccionada.duplicate(true)
		tecnica_seleccionada = null
		turno_finalizado.emit()

class EffectEnemy extends EnemyCombatant:
	var feedback_count := 0
	func reproducir_feedback() -> void:
		feedback_count += cola_feedback.size()
		cola_feedback.clear()

var failures := 0
var checks := 0
var owned: Array[Node] = []

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("ENEMY AI: " + message)

func fighter(player: bool, health: int = 100) -> Combatant:
	var result := Combatant.new()
	result.es_jugador = player
	result.hp = health
	result.hp_max = 100
	owned.append(result)
	return result

func technique(id: String, scope: String, tactical: String = "enemy_attack") -> Dictionary:
	return {"tecnique_id": id, "target_scope": scope, "rol_combo": tactical, "efectos": [["damage", "0.5"]]}

func _run() -> void:
	seed(125)
	DataLoader.load_enemy_techniques("res://Data/Enemy_stats/enemy_techniques.csv")
	DataLoader.load_enemy_roles("res://Data/Enemy_stats/enemy_roles.csv")
	DataLoader.load_enemy_stats("res://Data/Enemy_stats/stats_enemigos.csv")
	var enemy := RecordingEnemy.new()
	enemy.hp = 100
	enemy.hp_max = 100
	enemy.id = "test_enemy"
	owned.append(enemy)
	var ally := fighter(false)
	var player := fighter(true, 20)
	var other := fighter(true, 80)
	var dead := fighter(true, 0)
	var freed := fighter(true)
	owned.erase(freed)
	freed.free()
	var roster := [enemy, ally, player, other, dead, player, freed]
	var attack := technique("attack", "SINGLE_ENEMY")
	var area := technique("area", "ALL_ENEMIES")
	check(Targets.resolve(enemy, attack, [ally, player, other], roster) == [player], "Single removes wrong side and excess targets")
	check(Targets.resolve(enemy, area, [ally], roster) == [player, other], "Area rebuilds full living opposing team without duplicates")
	check(Targets.resolve(enemy, technique("allies", "ALL_ALLIES"), [player], roster) == [enemy, ally], "All allies includes owner, excludes opponents")
	check(Targets.resolve(enemy, technique("self", "SELF"), [player], roster) == [enemy], "SELF cannot target someone else")
	check(Targets.resolve(enemy, technique("bad", "INVALID"), [player], roster).is_empty(), "Unknown scope rejected")
	check(Targets.resolve(enemy, attack, [dead, freed], roster) == [player], "Dead/freed target replaced")
	check(Targets.resolve(player, attack, [dead], roster, false).is_empty(), "Player single-target action does not silently retarget")
	var random_tech := technique("random", "RANDOM_ENEMY")
	var seen := []
	for i in range(64):
		var target = Targets.resolve(enemy, random_tech, [], roster)[0]
		if target not in seen:
			seen.append(target)
	check(seen.size() == 2, "Random scopes actually sample both opponents")
	check(Targets.resolve(enemy, random_tech, [other], roster) == [other], "Execution preserves valid previously rolled random target")

	var role := ProposalRole.new()
	role.proposal = {"intent": "CHARGE", "tactical_role": "enemy_charge", "target": enemy, "reason": "build_pressure"}
	var ai := AI.new(enemy, role)
	var context := {"allies": [enemy, ally], "opponents": [player, other], "available_techniques": [attack]}
	var decision := ai.decide_action(context)
	check(decision.intent == "ATTACK" and decision.tactical_role == "enemy_attack", "Fallback reports executed intent and tactical role")
	check(decision.requested_intent == "CHARGE" and decision.requested_reason == "build_pressure", "Original proposal retained separately")
	check(decision.reason == "attack_fallback" and decision.objetivos == [player], "Fallback adjusts reason and target")
	check(decision.technique == decision.tecnica and decision.target == decision.objetivos[0], "Compatibility aliases agree")
	var wrong_scope := technique("bad_charge", "SINGLE_ENEMY", "enemy_charge")
	context.available_techniques = [wrong_scope, attack]
	check(ai.decide_action(context).tecnica.tecnique_id == "attack", "Incompatible charge scope cannot bypass intent matching")
	var charge := technique("charge", "SELF", "enemy_charge")
	charge.efectos = [["buff", "ataque", "0.25"]]
	context.available_techniques = [charge, attack]
	check(ai.decide_action(context).tecnica == charge, "Compatible tactical technique precedes generic attack")
	context.available_techniques = [area]
	check(ai.decide_action(context).objetivos == [player, other], "Generic offensive fallback supports full area")
	context.available_techniques = [technique("support", "SINGLE_ALLY", "enemy_protect")]
	check(ai.decide_action(context).intent == "PROTECT", "Any usable allied technique is a truthful fallback")
	context.available_techniques = [null, {}, {"tecnique_id": "broken"}, technique("invalid", "BAD"), {"tecnique_id": "bad_fx", "target_scope": "SELF", "efectos": ["damage"]}]
	decision = ai.decide_action(context)
	check(decision.intent == "WAIT" and decision.tecnica.efectos.is_empty(), "Malformed techniques produce explicit harmless wait")
	context.available_techniques = []
	check(ai.decide_action(context).intent == "WAIT", "No techniques does not block combat")
	context.available_techniques = [attack, charge]
	context.opponents = []
	check(ai.decide_action(context).tecnica == charge, "No opponents still permits a self action")
	context.available_techniques = [attack]
	check(ai.decide_action(context).intent == "WAIT", "No legal targets falls back to wait")
	enemy.hp = 0
	check(ai.decide_action(context).is_empty(), "Dead owner produces no action")
	enemy.hp = 100
	check(AI.new().decide_action(context).is_empty(), "Missing owner produces no action")
	context.opponents = [player, other]
	role.proposal = {"intent": "ATTACK", "tactical_role": "enemy_attack", "target": player}
	context.available_techniques = [random_tech]
	seen.clear()
	for i in range(64):
		var target = ai.decide_action(context).target
		if target not in seen:
			seen.append(target)
	check(seen.size() == 2, "Role preference cannot turn RANDOM into focused targeting")

	# Exercise the production queue with a recording executor, without camera/UI scenes.
	var manager := QueueManager.new()
	owned.append(manager)
	manager.combatientes = [enemy, ally, player, other, dead, freed]
	enemy.battle_manager = manager
	manager.estado_actual = manager.BattleState.EJECUCION_ACCION
	context.available_techniques = [attack]
	decision = ai.decide_action(context)
	player.hp = 0
	manager.cola_acciones = [{"actor": enemy, "tecnica": attack, "objetivos": [player], "decision": decision}]
	await manager._procesar_cola_acciones()
	check(enemy.executions == 1 and enemy.executed.objetivos == [other], "Queue replaces a target killed after decision")
	check(enemy.executed.decision.objetivos == [other] and enemy.executed.decision.target == other, "Decision metadata follows revalidated targets")
	check(not manager.procesando_cola_acciones and manager.next_state == manager.BattleState.CHEQUEAR_FINAL, "Queue returns control after enemy execution")
	manager.estado_actual = manager.BattleState.EJECUCION_ACCION
	manager.cola_acciones = [{"actor": dead, "tecnica": attack, "objetivos": [enemy]}, {"actor": freed, "tecnica": attack, "objetivos": [enemy]}, {"actor": enemy, "tecnica": {}, "objetivos": [other]}]
	await manager._procesar_cola_acciones()
	check(enemy.executions == 1 and not manager.procesando_cola_acciones, "Dead/freed actors and malformed technique cannot block queue")
	manager.estado_actual = manager.BattleState.EJECUCION_ACCION
	# No legal allied target for this actor with this deliberately reduced roster.
	manager.combatientes = [other]
	manager.cola_acciones = [{"actor": enemy, "tecnica": technique("ally", "SINGLE_ALLY"), "objetivos": [dead]}]
	var ui := Node.new()
	owned.append(ui)
	manager.ui_overlay = ui
	await manager._procesar_cola_acciones()
	check(enemy.executions == 1 and not manager.procesando_cola_acciones, "Missing targets at execution are skipped without hanging")
	manager.combatientes = [enemy, other]
	manager.estado_actual = manager.BattleState.EJECUCION_ACCION
	decision = ai.fallback_decision("test_wait")
	manager.cola_acciones = [{"actor": enemy, "tecnica": decision.tecnica, "objetivos": decision.objetivos, "decision": decision}]
	await manager._procesar_cola_acciones()
	check(enemy.executions == 2 and enemy.executed.decision.intent == "WAIT", "Wait fallback traverses normal action pipeline")
	manager.combatientes = [enemy, other, freed]
	manager._rebuild_turn_queue()
	check(manager.cola_turnos.size() == 2, "Turn queue rebuild removes freed roster entries")

	# Exercise real Combatant -> EffectManager execution, replacing only presentation.
	var effect_enemy := EffectEnemy.new()
	owned.append(effect_enemy)
	effect_enemy.hp = 100
	effect_enemy.hp_max = 100
	effect_enemy.ataque = 20
	effect_enemy._capturar_stats_base()
	effect_enemy.battle_manager = manager
	manager.combatientes = [effect_enemy, other]
	manager.estado_actual = manager.BattleState.EJECUCION_ACCION
	manager.cola_acciones = [{"actor": effect_enemy, "tecnica": charge, "objetivos": [effect_enemy]}]
	await manager._procesar_cola_acciones()
	check(effect_enemy.ataque == 25 and effect_enemy.feedback_count == 1, "Real executor applies shared effects and flushes feedback")
	check(not manager.procesando_cola_acciones and manager.next_state == manager.BattleState.CHEQUEAR_FINAL, "Real executor returns control to manager")

	for enemy_id in ["Slime", "Triangle", "Esfera_roja", "Mimic"]:
		var loaded_techniques := GlobalTechniqueDatabase.get_techniques_for(enemy_id)
		check(loaded_techniques.size() == 4, "All four techniques loaded for " + enemy_id)
		for loaded in loaded_techniques:
			check(Targets.valid_technique(loaded), "Loaded technique remains valid: " + str(loaded.get("tecnique_id")))
		enemy.id = enemy_id
		enemy.tecnicas = loaded_techniques
		enemy._configurar_ia_enemiga({})
		manager.combatientes = [enemy, other]
		var actual := enemy.crear_accion_enemiga()
		var expected := "esfera_roja_02" if enemy_id == "Esfera_roja" else ("slime_01" if enemy_id == "Slime" else ("triangle_01" if enemy_id == "Triangle" else "mimic_01"))
		check(actual.tecnica.tecnique_id == expected, "Configured role preserves initial behavior: " + enemy_id)
		manager.repeticion_continua = 2
		manager.battle_stats["techniques_used"] = {"player_test": 3}
		actual = enemy.crear_accion_enemiga()
		expected = "esfera_roja_02" if enemy_id == "Esfera_roja" else ("slime_02" if enemy_id == "Slime" else ("triangle_02" if enemy_id == "Triangle" else "mimic_03"))
		check(actual.tecnica.tecnique_id == expected, "Configured role preserves reaction: " + enemy_id)
		manager.repeticion_continua = 0
		manager.battle_stats["techniques_used"] = {}
	for node in owned:
		node.free()
	print("ENEMY AI SAFETY: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
