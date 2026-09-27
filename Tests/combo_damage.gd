extends Node

var failures := 0
var checks := 0

class QuietCombatant extends Combatant:
	func mostrar_feedback_estado(_effect: Dictionary) -> void:
		pass

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	DataLoader.load_tecnicas("res://Data/Tecnicas/tecnicas.csv")
	DataLoader.load_enemy_techniques("res://Data/Enemy_stats/enemy_techniques.csv")
	var drive := DriveSystem.new()
	var manager = load("res://Scripts/BattleMode/BattleManager2.gd").new()
	manager.drive_system = drive
	var actor := QuietCombatant.new()
	actor.es_jugador = true
	actor.ataque = 25
	actor.precision = 100
	var enemy := QuietCombatant.new()
	enemy.hp = 1000
	enemy.hp_max = 1000
	enemy.defensa = 10
	enemy._capturar_stats_base()
	for role in ["opener", "linker"]:
		drive.register_action({"role": role, "valid_action": true})
	check(drive.combo_chain == 2, "Opener > Linker grows chain to two")
	check(drive.finisher_prep == 2, "Opener > Linker prepares two charges")
	var finisher := GlobalTechniqueDatabase.get_tecnica_stats("astro_04")
	check(is_equal_approx(drive.get_finisher_damage_multiplier_for(finisher), 1.25), "Prepared finisher receives 1.25x damage")
	var context := {"technique": finisher, "drive_system": drive}
	# Find a deterministic hit; actual accuracy remains capped at 95%.
	var hit_seed := 0
	while true:
		seed(hit_seed)
		if EffectManager._resolver_impacto(actor, enemy, finisher).hit:
			break
		hit_seed += 1
	seed(hit_seed)
	EffectManager.aplicar_efectos(finisher.efectos, actor, enemy, context)
	check(enemy.hp == 979, "Prepared Astro finisher deals floor(25 * 1.25 - 10) = 21")
	check(drive.finisher_prep == 2, "Finisher combo:reset waits until score registration")
	check(bool(context.get("deferred_combo_reset", false)), "Finisher schedules deferred reset")
	var result: Dictionary = drive.register_action({"role": "finisher", "valid_action": true, "damage_done": 21})
	check(result.combo_finished and drive.max_combo_chain == 3, "Full combo finishes at three")
	manager._aplicar_cierre_drive_result(result)
	check(drive.combo_chain == 0, "Combo closes after finisher")
	enemy.defensa = 1000
	seed(hit_seed)
	EffectManager.aplicar_efectos([["damage", "0.5"]], actor, enemy, {"technique": {}})
	check(enemy.hp == 978, "Even overwhelming defense leaves minimum one damage on hit")
	# Replay the reported Astro > Maya > Astro sequence through real CSV effects
	# and BattleManager snapshots, with deterministic successful hits.
	drive.reset_battle()
	enemy.defensa = 10
	var damages: Array[int] = []
	for tech_id in ["astro_01", "maya_02", "astro_04"]:
		var technique := GlobalTechniqueDatabase.get_tecnica_stats(tech_id)
		actor.ataque = 20 if tech_id == "maya_02" else 25
		var before: Dictionary = manager._capturar_estado_objetivos([enemy])
		var hp_before := enemy.hp
		var action_context := {"technique": technique, "drive_system": drive}
		seed(hit_seed)
		var effects: Dictionary = EffectManager.split_effects_by_scope(technique.efectos)
		EffectManager.aplicar_efectos(effects.target, actor, enemy, action_context)
		damages.append(hp_before - enemy.hp)
		var event: Dictionary = manager._construir_drive_event(technique, actor, [enemy], before, manager._capturar_estado_objetivos([enemy]))
		var action_result := drive.register_action(event)
		manager._aplicar_cierre_drive_result(action_result)
	check(damages == [40, 1, 21], "Astro > Maya > Astro actual techniques deal 40 / 1 / 21 against defense 10")
	check(drive.max_combo_chain == 3, "Reported party sequence reaches combo three")

	for tech_id in ["slime_03", "esfera_roja_02", "mimic_04"]:
		enemy.defensa = 10
		enemy._capturar_stats_base()
		var technique := GlobalTechniqueDatabase.get_tecnica_stats(tech_id)
		EffectManager.aplicar_efectos(technique.efectos, enemy, enemy, {"technique": technique})
		var first_defense := enemy.defensa
		check(first_defense > 10, tech_id + " increases defense")
		EffectManager.aplicar_efectos(technique.efectos, enemy, enemy, {"technique": technique})
		check(enemy.defensa == first_defense, tech_id + " refreshes without stacking")
		enemy.procesar_efectos_activos()
		check(enemy.defensa == 10, tech_id + " expires at next owner turn")
	manager.free()
	drive.free()
	actor.free()
	enemy.free()
	print("COMBO DAMAGE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
