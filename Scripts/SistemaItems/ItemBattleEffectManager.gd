# ItemBattleEffectManager.gd (Autoload)
extends Node

func apply_effects(effects: Array, target_id: String) -> bool:
	var battle_manager = get_node("../BattleManager")
	
	var target = battle_manager.get_combatant(target_id)

	if target == null:
		push_warning("[ItemBattleEffectManager]: target inválido %s" % target_id)
		return false
	
	for effect in effects:
		_apply_effect(effect, target)

	return true

func _apply_effect(effect: Array, target: Combatant) -> void:
	var type = effect[0]

	match type:
		"heal_by_stat":
			var stat = effect[1]
			var mult = float(effect[2])
			var heal = int(target.get(stat) * mult)
			target.curar_hp(heal)
		
		"heal_fixed":
			var amount = int(effect[1])
			target.curar_hp(amount)

		"heal_persent":
			var pct = float(effect[1])
			var heal = int(target.max_hp * pct)
			target.curar_hp(heal)

		"revive":
			target.revivir()

		_:
			push_warning("[ItemBattleeffectManager] GameManager: %s", GameManager.is_in_battle())
			push_warning("[ItemBattleEffectManager]: efecto no soportado %s" % type)
