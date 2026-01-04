#EffectManager.gd (Autoload)
extends Node

func apply_effects(effects: Array, target: Combatant, atacante: Combatant) -> void:
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
				var mult = float(efecto[1])
				var atk_base = atacante.ataque
				var dmg = int((atk_base * mult) - target.defensa)
				print(
					"ATK atacante:", atacante.ataque,
					"| MULT:", mult,
					"| DEF target:", target.defensa
				)

				print("aplicando %s de daño a %s" % [float(dmg), target.nombre])
				target.recibir_danio(dmg)
			
			"heal_hp":
				var mult = float(efecto[1])
				var heal = int(atacante.wis * mult)
				print(
					"Espíritu del Caster: ", atacante.wis,
					" | MULT: ", mult
				)

				print("aplicando %s de curación a %s" % [float(heal), target.nombre])
				target.curar_hp(heal)

			"boost":
				print_debug("Lista recibida: %s" % [str(efecto)]) # boost:spd:0.5
				var stat = efecto[1]
				var mult = float(efecto[2])
				var cantidad = int(target.get(stat) * mult)
				target.modificar_stat(stat, cantidad)

			"nerf":
				var stat = efecto[1]
				var mult = float(efecto[2])
				var cantidad = -int(target.get(stat) * mult)
				target.modificar_stat(stat, cantidad)

			#----------------------
			# EFECTOS PERSISTENTES
			# Formato en CSV:
			# 	persist:buff:atk:0.02:3	
			#	persist:dot:5:3
			# efecto = ["persist", "buff", "atk", "0.2", "3"]
			#----------------------------------------------
			"persist":
				_registrar_efecto_persistente(efecto, target)
			
			#-----------------------------------------
			# DEFAULT
			#-----------------------------------------
			_:
				print("Efecto desconocido: %s" % tipo)

func _registrar_efecto_persistente(efecto: Array, target: Combatant) -> void:
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
		"duracion": int(args[-1]),  # Ultimo parámetro = duracion en turnos

		# Se define el comportamiento por tick
		"tick": func(combatant: Combatant):
			match subtipo:

				# Daño por turno: persist:dot:cantidad:duracion
				"dot":
					var dmg = int(args[0])
					combatant.recibir_danio(dmg)
				
				# Buff/nerf temporal
				# persist:buff:atk:0.2:3
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

	print("Registrando efecto persistente en %s: %s" % [target.nombre, efecto_dic["id"]])
	target.agregar_efecto(efecto_dic)
