#EffectManager.gd (Autoload)
extends Node

func apply_effects(effects: Array, target: Combatant, atacante: Combatant, tecnica: Dictionary) -> void:
	if effects.is_empty():
		print("apply_effects llamado con array vacío")
		return
	for efecto in effects:
		if efecto.size() < 2:
			print("Efecto mal formado: %s" % efecto)
			continue

		var tipo = efecto[0] 

		match tipo:
			
			#-------------------------------------------------
			# EFECTOS INSTANTÁNEOS
			#-------------------------------------------------
			"damage":
				var impacto = _resolver_impacto(atacante, target, tecnica)
				
				if not impacto.hit:
					target.registrar_evento_visual({"tipo": "miss"}) 
					return
				
				
				var mult = float(efecto[1])
				var atk_base = atacante.ataque
				var dmg = int((atk_base * mult) - target.defensa)

				var tipo_dano = tecnica.get("tipo_dano", "normal")
				var rol_combo = tecnica.get("rol_combo", "")

			
				if impacto.crit:
					dmg *= atacante.crit_dmg

				target.recibir_danio(dmg, tipo_dano, rol_combo, impacto.crit)
				
				#print("aplicando %s de daño a %s" % [float(dmg), target.nombre])
				
				
				
				
			
			"heal_hp":
				var mult = float(efecto[1])
				var heal = int(atacante.espiritu * mult)
				
				print("Espíritu del Caster: ", atacante.espiritu, " | MULT: ", mult)
				print("aplicando %s de curación a %s" % [float(heal), target.nombre])
				
				target.curar_hp(heal)

			"buff":
				print_debug("Lista recibida: %s" % [str(efecto)]) # buff:velocidad:0.5
				var stat = efecto[1]
				var mult = float(efecto[2])
				var cantidad = int(target.get(stat) * mult)
				target.modificar_stat(stat, cantidad)

			"debuff":
				var stat = efecto[1]
				var mult = float(efecto[2])
				var cantidad = -int(target.get(stat) * mult)
				target.modificar_stat(stat, cantidad)

			#----------------------
			# EFECTOS PERSISTENTES
			# Formato en CSV:
			# 	persist:buff:ataque:0.2:3
			#	persist:dot:5:3 (es daño crudo)
			# efecto = ["persist", "buff", "ataque", "0.2", "3"]
			#----------------------------------------------
			"persist":
				_registrar_efecto_persistente(efecto, target)
			
			#-----------------------------------------
			# DEFAULT
			#-----------------------------------------
			_:
				print("Efecto desconocido: %s" % tipo)



func _registrar_efecto_persistente(efecto: Array, target: Combatant) -> void:
	var subtipo = efecto[1]
	var args := efecto.slice(2, efecto.size())

	match subtipo:

		#---------------------------------
		# DOT
		# persist:dot:5:2
		#---------------------------------
		"dot":
			if args.size() < 2:
				print("DOT mal formado:", efecto)
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

		#---------------------------------
		# BUFF / DEBUFF
		#---------------------------------
		"buff", "debuff":
			if args.size() < 3:
				print("Buff/Debuff persistente mal formado:", efecto)
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
				"duracion": duracion,
 
				"visual_tipo": subtipo,
				"visual_valor": valor,
				
				"on_apply": func(c):
					c.modificar_stat(stat, valor),

				"on_expire": func(c):
					c.modificar_stat(stat, -valor)
			}

			print("Registrando Buff/Debuff:", efecto_dic)
			target.agregar_efecto(efecto_dic)


func _resolver_impacto(atacante: Combatant, target: Combatant, tecnica: Dictionary) -> Dictionary:
	var precision = atacante.precision
	var evasion = target.evasion
	
	var bonus_precision = tecnica.get("bonus_precision", 0.0)

	var chance = clamp((precision - evasion) + bonus_precision, 5, 95)
	var roll = randi() % 100
	
	if roll >= chance:
		return { "hit": false, "crit": false }
	
	# crítico
	var crit_chance = atacante.crit_rate
	var crit_roll = randi() % 100
	var es_crit = crit_roll < crit_chance
	
	return { "hit": true, "crit": es_crit }


"""
func _registrar_efecto_persistente_viejo(efecto: Array, target: Combatant) -> void:
	if efecto.size() < 3:
		print("Efecto persistente mal formado: %s" % efecto)
		return
	
	var subtipo = efecto[1]
	var args = efecto.slice(2, efecto.size())

	# Cada efecto activo es un diccionario:
	var efecto_dic = {
		"id": "persist_" + subtipo,
		"subtipo": subtipo,
		"args": args,
		"duracion": int(args[-1]),  # Ultimo parámetro es la duracion en turnos

		# Se define el comportamiento por tick
		"tick": func(combatant: Combatant):
			match subtipo:

				# Daño por turno: persist:dot:cantidad:duracion
				"dot":
					var dmg = int(args[0])
					combatant.recibir_danio(dmg)
				
				# Buff/nerf temporal
				# persist:buff:ataque:0.2:3
				"buff":
					var stat = args[0]
					var mult = float(args[1])
					var cant = int(combatant.get(stat) * mult)
					combatant.modificar_stat(stat, cant)
				
				"debuff":
					var stat = args[0]
					var mult = float(args[1])
					var cant = -int(combatant.get(stat) * mult)
					combatant.modificar_stat(stat, cant)
				
				_:
					print("Subtipo persistente desconocido: %s" % subtipo)

	}
	target.agregar_efecto(efecto_dic)
	print("Registrando efecto persistente en %s: %s" % [target.nombre, efecto_dic["id"]])
	
"""
