extends Node

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func seed_for_hit(actor: Combatant, target: Combatant) -> int:
	for candidate in range(10000):
		seed(candidate)
		if EffectManager._resolver_impacto(actor, target, {}).hit:
			return candidate
	return -1

func _ready() -> void:
	DataLoader.load_tecnicas("res://Data/Tecnicas/tecnicas.csv")
	DataLoader.load_enemy_techniques("res://Data/Enemy_stats/enemy_techniques.csv")
	DataLoader.load_enemy_stats("res://Data/Enemy_stats/stats_enemigos.csv")
	var astro := Combatant.new()
	astro.es_jugador = true
	astro.hp = 1000
	astro.hp_max = 1000
	astro.ataque = 25
	astro.precision = 100
	astro._capturar_stats_base()
	var enemy := Combatant.new()
	enemy.hp = 1000
	enemy.hp_max = 1000
	enemy.ataque = 50
	enemy.precision = 80
	var drive := DriveSystem.new()
	for enemy_id in ["Slime", "Triangle", "Esfera_roja"]:
		var stats := EnemyDatabase.get_stats(enemy_id)
		enemy.defensa = int(stats.def)
		enemy.evasion = int(stats.spd) % maxi(1, int(stats.lck)) * 2
		drive.reset_battle()
		for tech_id in ["astro_01", "astro_02", "astro_04"]:
			var technique := GlobalTechniqueDatabase.get_tecnica_stats(tech_id)
			var before := enemy.hp
			var hit_seed := seed_for_hit(astro, enemy)
			seed(hit_seed)
			var effects: Dictionary = EffectManager.split_effects_by_scope(technique.efectos)
			EffectManager.aplicar_efectos(effects.target, astro, enemy, {"technique": technique, "drive_system": drive})
			check(enemy.hp < before, "%s hits %s for positive damage" % [tech_id, enemy_id])
			drive.register_action({"role": technique.rol_combo})
		check(drive.max_combo_chain == 3, enemy_id + " allows full combo")

	# Apply Triangle's real attack, including its accuracy debuff.
	var triangle_attack := GlobalTechniqueDatabase.get_tecnica_stats("triangle_02")
	var triangle_seed := seed_for_hit(enemy, astro)
	seed(triangle_seed)
	EffectManager.aplicar_efectos(triangle_attack.efectos, enemy, astro, {"technique": triangle_attack})
	check(astro.precision == 80, "Angulo Muerto lowers Astro accuracy from 100 to 80")
	# Find a roll that hit before the debuff and misses afterwards.
	enemy.evasion = 0
	var miss_seed := -1
	for candidate in range(10000):
		seed(candidate)
		var roll := randi() % 100
		if roll >= 80 and roll < 95:
			miss_seed = candidate
			break
	check(miss_seed >= 0, "Found deterministic debuff-induced miss")
	for tech_id in ["astro_01", "astro_02", "astro_04"]:
		var technique := GlobalTechniqueDatabase.get_tecnica_stats(tech_id)
		enemy.cola_feedback.clear()
		var before := enemy.hp
		seed(miss_seed)
		EffectManager.aplicar_efectos(technique.efectos, astro, enemy, {"technique": technique})
		check(enemy.hp == before, tech_id + " misses without changing HP")
		check(enemy.cola_feedback.size() == 1 and enemy.cola_feedback[0].tipo == "miss", tech_id + " queues miss event")
		var event: Dictionary = enemy.cola_feedback[0]
		var visual = preload("res://Escenas/Battle/DamageText/damage_number.tscn").instantiate()
		add_child(visual)
		visual.setup(event.valor, event.tipo, event.rol_combo, bool(event.critico))
		check(visual.get_node("Label3D").text == "MISS", tech_id + " displays MISS instead of zero")
		visual.free()
	var amanda := Combatant.new()
	amanda.es_jugador = true
	amanda.espiritu = 18
	astro.hp = 500
	var heal := GlobalTechniqueDatabase.get_tecnica_stats("amanda_04")
	EffectManager.aplicar_efectos(heal.efectos, amanda, astro, {"technique": heal})
	check(astro.hp == 545, "Amanda heals independently of attack accuracy")
	var damage_visual = preload("res://Escenas/Battle/DamageText/damage_number.tscn").instantiate()
	add_child(damage_visual)
	damage_visual.setup(29, "fisico", "finisher", false)
	check(damage_visual.get_node("Label3D").text == "29", "Successful damage remains numeric")
	damage_visual.setup(45, "heal", "support", false)
	check(damage_visual.get_node("Label3D").text == "+45", "Healing keeps its positive value")
	damage_visual.free()
	amanda.free()
	astro.free()
	enemy.free()
	drive.free()
	print("COMBAT MISS FEEDBACK: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
