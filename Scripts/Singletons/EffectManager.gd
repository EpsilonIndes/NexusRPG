#EffectManager.gd Autoload
extends Node

var effects := {}

func _ready():
	_registrar_todos_los_efectos()

func _registrar_todos_los_efectos():
	
	for method in get_method_list():
		if method.name.begins_with("efecto_"):
			var nombre_efecto = method.name.replace("efecto_", "")
			effects[nombre_efecto] = Callable(self, method.name)

# Llamada externa para aplicar un efecto
func apply_effect(effect_name: String, target):
	if effects.has(effect_name):
		effects[effect_name].call(target)
	else:
		push_warning("EffectManager: efecto no reconocido: %s" % effect_name)

									
# === Ejemplos de efectos === #

func efecto_heal_50hp(target):
	if target.has_method("restore_hp"):
		target.restore_hp(50)
		print("%s ha recuperado 50 HP gracias a una Poción." % target.name)
	else:
		push_warning("Target sin método restore_hp")