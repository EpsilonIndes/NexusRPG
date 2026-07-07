# EffectManager.gd (Autoload)
extends Node

const TARGET_SCOPED_EFFECTS := [
	"damage",
	"heal",
	"heal_hp",
	"buff",
	"debuff",
	"persist",
	"status",
	"cleanse",
	"shield"
]

const ACTION_SCOPED_EFFECTS := [
	"drive",
	"resonance",
	"combo",
	"initiative",
	"turn_order",
	"targeting"
]


func get_effect_scope(effect) -> String:
	if not (effect is Array) or effect.size() < 1:
		push_warning("No se pudo clasificar efecto mal formado: %s" % str(effect))
		return "unknown"

	var tipo := String(effect[0]).strip_edges()
	if tipo in TARGET_SCOPED_EFFECTS:
		return "target"
	if tipo in ACTION_SCOPED_EFFECTS:
		return "action"

	push_warning("Efecto con ambito desconocido: %s" % tipo)
	return "unknown"


func split_effects_by_scope(effects: Array) -> Dictionary:
	var scoped := {
		"target": [],
		"action": [],
		"unknown": []
	}

	for effect in effects:
		match get_effect_scope(effect):
			"target":
				scoped["target"].append(effect)
			"action":
				scoped["action"].append(effect)
			_:
				scoped["unknown"].append(effect)

	return scoped


func has_offensive_target_effects(effects: Array) -> bool:
	for effect in effects:
		if not (effect is Array) or effect.size() < 1:
			continue

		var tipo := String(effect[0]).strip_edges()
		if tipo in ["damage", "debuff", "persist", "status"]:
			return true
	return false


func has_damage_effects(effects: Array) -> bool:
	for effect in effects:
		if not (effect is Array) or effect.size() < 1:
			continue
		if String(effect[0]).strip_edges() == "damage":
			return true
	return false


func apply_effects(effects: Array, target: Combatant, atacante: Combatant, tecnica: Dictionary = {}, context: Dictionary = {}) -> void:
	var merged_context := context.duplicate(true)
	if not merged_context.has("technique"):
		merged_context["technique"] = tecnica
	aplicar_efectos(effects, atacante, target, merged_context)


func aplicar_efectos(efectos: Array, actor: Combatant, target: Combatant, context: Dictionary = {}) -> void:
	if efectos.is_empty():
		print("aplicar_efectos llamado con array vacio")
		return

	var technique: Dictionary = context.get("technique", {})
	var has_primary_feedback := _has_primary_feedback_effect(efectos)
	var showed_stat_feedback := false

	for efecto in efectos:
		if not (efecto is Array) or efecto.size() < 1:
			push_warning("Efecto mal formado: %s" % str(efecto))
			continue

		var tipo := String(efecto[0]).strip_edges()
		if tipo == "":
			push_warning("Efecto sin tipo: %s" % str(efecto))
			continue

		match tipo:
			"damage":
				if not _aplicar_damage(efecto, actor, target, technique, context):
					return
			"heal", "heal_hp":
				_aplicar_heal_hp(efecto, actor, target, context)
			"buff":
				var show_buff_feedback := not has_primary_feedback and not showed_stat_feedback
				_aplicar_buff(efecto, target, show_buff_feedback)
				showed_stat_feedback = showed_stat_feedback or show_buff_feedback
			"debuff":
				var show_debuff_feedback := not has_primary_feedback and not showed_stat_feedback
				_aplicar_debuff(efecto, target, show_debuff_feedback)
				showed_stat_feedback = showed_stat_feedback or show_debuff_feedback
			"persist":
				_aplicar_persistente(efecto, target)
			"status":
				_aplicar_status(efecto, target, actor, context)
			"cleanse":
				_aplicar_cleanse(efecto, target, actor, context)
			"shield":
				_aplicar_shield(efecto, target, actor, context)
			"drive":
				_aplicar_drive_effect(efecto, target, actor, context)
			"resonance":
				_aplicar_resonance_effect(efecto, target, actor, context)
			"initiative", "turn_order":
				_aplicar_initiative_effect(efecto, target, actor, context)
			"targeting":
				_aplicar_targeting_effect(efecto, target, actor, context)
			"combo":
				_aplicar_combo_effect(efecto, target, actor, context)
			_:
				push_warning("Efecto desconocido: %s" % tipo)


func _aplicar_damage(efecto: Array, actor: Combatant, target: Combatant, technique: Dictionary, context: Dictionary) -> bool:
	if efecto.size() < 2:
		push_warning("Damage mal formado: %s" % str(efecto))
		return true
	if actor == null or target == null:
		push_warning("Damage requiere actor y target validos: %s" % str(efecto))
		return true

	var impacto := _resolver_impacto(actor, target, technique)
	if not impacto.hit:
		target.registrar_evento_visual({"tipo": "miss"})
		return false

	_registrar_target_hit(context, target)

	var mult := float(efecto[1])
	var atk_base := actor.ataque
	var dmg := int((atk_base * mult) - target.defensa)
	var tipo_dano := String(technique.get("tipo_dano", "normal"))
	var rol_combo := String(technique.get("rol_combo", ""))
	var finisher_multiplier := _get_finisher_damage_multiplier(actor, technique, context)

	if impacto.crit:
		dmg *= actor.crit_dmg
	if finisher_multiplier != 1.0:
		dmg = int(dmg * finisher_multiplier)

	var hp_before := target.hp
	target.recibir_danio(dmg, tipo_dano, rol_combo, impacto.crit)
	if target.hp < hp_before:
		_registrar_resolution_target(context, "damaged", target)
	return true


func _aplicar_heal_hp(efecto: Array, actor: Combatant, target: Combatant, context: Dictionary) -> void:
	if efecto.size() < 2:
		push_warning("Heal HP mal formado: %s" % str(efecto))
		return
	if actor == null or target == null:
		push_warning("Heal HP requiere actor y target validos: %s" % str(efecto))
		return

	var mult := float(efecto[1])
	var heal := int(actor.espiritu * mult)
	print("Espiritu del Caster: ", actor.espiritu, " | MULT: ", mult)
	print("aplicando %s de curacion a %s" % [float(heal), target.nombre])
	var hp_before := target.hp
	target.curar_hp(heal)
	if target.hp > hp_before:
		_registrar_resolution_target(context, "healed", target)


func _aplicar_buff(efecto: Array, target: Combatant, show_feedback: bool) -> void:
	if efecto.size() < 3:
		push_warning("Buff mal formado: %s" % str(efecto))
		return
	if target == null:
		push_warning("Buff requiere target valido: %s" % str(efecto))
		return

	var stat := String(efecto[1])
	var mult := float(efecto[2])
	var cantidad := int(target.get(stat) * mult)
	target.modificar_stat(stat, cantidad, show_feedback, "buff")


func _aplicar_debuff(efecto: Array, target: Combatant, show_feedback: bool) -> void:
	if efecto.size() < 3:
		push_warning("Debuff mal formado: %s" % str(efecto))
		return
	if target == null:
		push_warning("Debuff requiere target valido: %s" % str(efecto))
		return

	var stat := String(efecto[1])
	var mult := float(efecto[2])
	var cantidad := -int(target.get(stat) * mult)
	target.modificar_stat(stat, cantidad, show_feedback, "debuff")


func _aplicar_persistente(efecto: Array, target: Combatant) -> void:
	if efecto.size() < 2:
		push_warning("Persistente mal formado: %s" % str(efecto))
		return
	if target == null:
		push_warning("Persistente requiere target valido: %s" % str(efecto))
		return

	var subtipo := String(efecto[1])
	var args := efecto.slice(2, efecto.size())

	match subtipo:
		"dot":
			if args.size() < 2:
				push_warning("DOT persistente requiere cantidad y duracion: %s" % str(efecto))
				return

			var dmg := int(args[0])
			var duracion := int(args[1])
			var tier := int(args[2]) if args.size() > 2 else 1

			var efecto_dic := {
				"id": "dot",
				"subtipo": "dot",
				"tier": tier,
				"duracion": duracion,
				"tick": func(c):
					c.recibir_danio(dmg, "dot", "", false)
			}

			print("Registrando DOT:", efecto_dic)
			target.agregar_efecto(efecto_dic)

		"buff", "debuff":
			if args.size() < 3:
				push_warning("Buff/Debuff persistente requiere stat, cantidad y duracion: %s" % str(efecto))
				return

			var stat := String(args[0])
			var mult := float(args[1])
			var duracion := int(args[2])
			var tier := int(args[3]) if args.size() > 3 else 1
			var valor := int(target.get(stat) * mult)
			if subtipo == "debuff":
				valor = -valor

			var efecto_dic := {
				"id": stat,
				"subtipo": subtipo,
				"tier": tier,
				"stat": stat,
				"valor": valor,
				"applied_delta": 0,
				"duracion": duracion,
				"visual_tipo": subtipo,
				"visual_valor": valor
			}
			efecto_dic["on_apply"] = func(c):
				var aplicado = c.modificar_stat(stat, valor)
				efecto_dic["applied_delta"] = aplicado
				efecto_dic["visual_valor"] = aplicado
			efecto_dic["on_expire"] = func(c):
				c.modificar_stat(stat, -int(efecto_dic.get("applied_delta", valor)))

			print("Registrando Buff/Debuff:", efecto_dic)
			target.agregar_efecto(efecto_dic)

		_:
			push_warning("Subtipo persistente desconocido: %s" % subtipo)


func _aplicar_status(efecto: Array, target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if target == null:
		push_warning("Status requiere target valido: %s" % str(efecto))
		return
	if target.has_method("aplicar_status"):
		target.aplicar_status(efecto, actor, context)
	elif target.has_method("agregar_estado"):
		target.agregar_estado(efecto)
	else:
		push_warning("Status sin handler compatible en Combatant: %s" % str(efecto))


func _aplicar_cleanse(efecto: Array, target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if target == null:
		push_warning("Cleanse requiere target valido: %s" % str(efecto))
		return
	if target.has_method("aplicar_cleanse"):
		target.aplicar_cleanse(efecto, actor, context)
	elif target.has_method("limpiar_estados"):
		target.limpiar_estados()
	else:
		push_warning("Cleanse sin handler compatible en Combatant: %s" % str(efecto))


func _aplicar_shield(efecto: Array, target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if target == null:
		push_warning("Shield requiere target valido: %s" % str(efecto))
		return
	if target.has_method("aplicar_shield"):
		target.aplicar_shield(efecto, actor, context)
	elif target.has_method("agregar_escudo"):
		target.agregar_escudo(efecto)
	else:
		push_warning("Shield sin handler compatible en Combatant: %s" % str(efecto))


func _aplicar_drive_effect(efecto: Array, _target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if efecto.size() < 2:
		push_warning("Drive effect mal formado: %s" % str(efecto))
		return

	var drive_system = _get_drive_system(context, actor)
	if drive_system == null:
		push_warning("Drive effect sin drive_system en context: %s" % str(efecto))
		return

	var accion := String(efecto[1])
	match accion:
		"add":
			if efecto.size() < 3:
				push_warning("drive:add requiere amount: %s" % str(efecto))
				return
			if drive_system.has_method("add_drive"):
				drive_system.add_drive(_effect_int(efecto, 2, 0))
			else:
				push_warning("DriveSystem no implementa add_drive para efecto: %s" % str(efecto))
		"bonus_next":
			if efecto.size() < 3:
				push_warning("drive:bonus_next requiere multiplier: %s" % str(efecto))
				return
			if drive_system.has_method("set_next_drive_bonus"):
				drive_system.set_next_drive_bonus(float(efecto[2]))
			else:
				push_warning("DriveSystem no implementa set_next_drive_bonus para efecto: %s" % str(efecto))
		_:
			push_warning("Accion drive desconocida: %s" % accion)


func _aplicar_resonance_effect(efecto: Array, _target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if efecto.size() < 2:
		push_warning("Resonance effect mal formado: %s" % str(efecto))
		return

	var drive_system = _get_drive_system(context, actor)
	if drive_system == null:
		push_warning("Resonance effect sin drive_system en context: %s" % str(efecto))
		return

	var accion := String(efecto[1])
	match accion:
		"add":
			if efecto.size() < 3:
				push_warning("resonance:add requiere amount: %s" % str(efecto))
				return
			if drive_system.has_method("add_resonance"):
				drive_system.add_resonance(_effect_int(efecto, 2, 0))
			else:
				push_warning("DriveSystem no implementa add_resonance para efecto: %s" % str(efecto))
		"reset":
			if drive_system.has_method("reset_resonance"):
				drive_system.reset_resonance("effect")
			else:
				push_warning("DriveSystem no implementa reset_resonance para efecto: %s" % str(efecto))
		"protect_break":
			if efecto.size() < 3:
				push_warning("resonance:protect_break requiere turns_or_count: %s" % str(efecto))
				return
			if drive_system.has_method("protect_resonance_break"):
				drive_system.protect_resonance_break(_effect_int(efecto, 2, 1))
			else:
				push_warning("DriveSystem no implementa protect_resonance_break para efecto: %s" % str(efecto))
		_:
			push_warning("Accion resonance desconocida: %s" % accion)


func _aplicar_initiative_effect(efecto: Array, target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if efecto.size() < 2:
		push_warning("Initiative effect mal formado: %s" % str(efecto))
		return

	var battle_manager = _get_battle_manager(context, actor)
	if battle_manager == null:
		push_warning("Initiative effect sin battle_manager en context: %s" % str(efecto))
		return

	var accion := String(efecto[1])
	match accion:
		"next_ally_after_user":
			var resolution: Dictionary = context.get("resolution", {})
			var requires_hit := bool(resolution.get("requires_hit_for_initiative", false))
			if requires_hit and not bool(resolution.get("any_hit", false)):
				print("Iniciativa no activada: la tecnica no impacto objetivos validos.")
				return

			if battle_manager.has_method("promote_next_ally_after"):
				if not battle_manager.promote_next_ally_after(actor):
					push_warning("No se pudo promover siguiente aliado para: %s" % str(efecto))
			else:
				push_warning("BattleManager no implementa promote_next_ally_after para efecto: %s" % str(efecto))
		"delay_target":
			if battle_manager.has_method("delay_turn_target"):
				battle_manager.delay_turn_target(target)
			else:
				push_warning("BattleManager no implementa delay_turn_target para efecto: %s" % str(efecto))
		"promote_target":
			if battle_manager.has_method("promote_turn_target"):
				battle_manager.promote_turn_target(target)
			else:
				push_warning("BattleManager no implementa promote_turn_target para efecto: %s" % str(efecto))
		"push_enemy_back":
			if battle_manager.has_method("push_enemy_back"):
				battle_manager.push_enemy_back(target)
			else:
				push_warning("BattleManager no implementa push_enemy_back para efecto: %s" % str(efecto))
		_:
			push_warning("Accion initiative desconocida: %s" % accion)


func _aplicar_targeting_effect(efecto: Array, target: Combatant, actor: Combatant, context: Dictionary) -> void:
	var battle_manager = _get_battle_manager(context, actor)
	if battle_manager != null and battle_manager.has_method("apply_targeting_effect"):
		battle_manager.apply_targeting_effect(efecto, target, actor, context)
	else:
		push_warning("Targeting effect preparado como hook, sin handler activo: %s" % str(efecto))


func _aplicar_combo_effect(efecto: Array, _target: Combatant, actor: Combatant, context: Dictionary) -> void:
	if efecto.size() < 2:
		push_warning("Combo effect mal formado: %s" % str(efecto))
		return

	var drive_system = _get_drive_system(context, actor)
	var battle_manager = _get_battle_manager(context, actor)
	var accion := String(efecto[1])

	match accion:
		"extend":
			if efecto.size() < 3:
				push_warning("combo:extend requiere amount: %s" % str(efecto))
				return
			if drive_system != null and drive_system.has_method("extend_combo"):
				drive_system.extend_combo(_effect_int(efecto, 2, 1))
			elif battle_manager != null and battle_manager.has_method("extend_combo"):
				battle_manager.extend_combo(_effect_int(efecto, 2, 1))
			else:
				push_warning("No hay handler para combo:extend: %s" % str(efecto))
		"protect_break":
			if efecto.size() < 3:
				push_warning("combo:protect_break requiere count: %s" % str(efecto))
				return
			if drive_system != null and drive_system.has_method("protect_combo_break"):
				drive_system.protect_combo_break(_effect_int(efecto, 2, 1))
			elif battle_manager != null and battle_manager.has_method("protect_combo_break"):
				battle_manager.protect_combo_break(_effect_int(efecto, 2, 1))
			else:
				push_warning("No hay handler para combo:protect_break: %s" % str(efecto))
		"reset":
			if drive_system != null and drive_system.has_method("reset_combo"):
				drive_system.reset_combo("combo_effect")
			elif battle_manager != null and battle_manager.has_method("reset_combo"):
				battle_manager.reset_combo()
			else:
				push_warning("No hay handler para combo:reset: %s" % str(efecto))
		_:
			push_warning("Accion combo desconocida: %s" % accion)


func _has_primary_feedback_effect(effects: Array) -> bool:
	for efecto in effects:
		if not (efecto is Array):
			continue
		if efecto.size() < 1:
			continue
		if String(efecto[0]) in ["damage", "heal", "heal_hp"]:
			return true
	return false


func _resolver_impacto(actor: Combatant, target: Combatant, technique: Dictionary) -> Dictionary:
	var precision = actor.precision
	var evasion = target.evasion
	var bonus_precision = technique.get("bonus_precision", 0.0)
	var chance = clamp((precision - evasion) + bonus_precision, 5, 95)
	var roll = randi() % 100

	if roll >= chance:
		return {"hit": false, "crit": false}

	var crit_chance = actor.crit_rate
	var crit_roll = randi() % 100
	var es_crit = crit_roll < crit_chance
	return {"hit": true, "crit": es_crit}


func _registrar_target_hit(context: Dictionary, target: Combatant) -> void:
	_registrar_resolution_target(context, "hit", target)


func _registrar_resolution_target(context: Dictionary, prefix: String, target: Combatant) -> void:
	if target == null:
		return
	if not context.has("resolution") or not (context["resolution"] is Dictionary):
		context["resolution"] = {}

	var resolution: Dictionary = context["resolution"]
	var ids_key := "_%s_target_ids" % prefix
	var count_key := "%s_count" % prefix
	var target_ids: Array = resolution.get(ids_key, [])
	var target_id := str(target.get_instance_id())

	if not target_ids.has(target_id):
		target_ids.append(target_id)

	resolution[ids_key] = target_ids
	resolution[count_key] = target_ids.size()
	if prefix == "hit":
		resolution["any_hit"] = target_ids.size() > 0


func _effect_int(effect: Array, index: int, default_value: int = 0) -> int:
	if effect.size() <= index:
		return default_value

	var value = effect[index]
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		var text = value.strip_edges()
		if text.is_valid_float():
			return int(float(text))

	push_warning("Valor numerico invalido en efecto: %s" % str(effect))
	return default_value


func _get_battle_manager(context: Dictionary, actor: Combatant):
	var battle_manager = context.get("battle_manager", null)
	if battle_manager != null:
		return battle_manager
	if actor != null:
		return actor.battle_manager
	return null


func _get_drive_system(context: Dictionary, actor: Combatant):
	var drive_system = context.get("drive_system", null)
	if drive_system != null:
		return drive_system

	var battle_manager = _get_battle_manager(context, actor)
	if battle_manager != null:
		return battle_manager.get("drive_system")
	return null


func _get_finisher_damage_multiplier(actor: Combatant, technique: Dictionary, context: Dictionary) -> float:
	if str(technique.get("rol_combo", "")).to_lower() != "finisher":
		return 1.0

	var drive_system = _get_drive_system(context, actor)
	if drive_system != null and drive_system.has_method("get_finisher_damage_multiplier_for"):
		return float(drive_system.get_finisher_damage_multiplier_for(technique))
	return 1.0
