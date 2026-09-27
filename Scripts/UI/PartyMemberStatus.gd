extends PanelContainer

var combatant: Combatant
var manager: Node
var last_state: Array = []
const STAT_ICON_SCENE := preload("res://Escenas/UserUI/stat_icon.tscn")

func bind_combatant(actor: Combatant, battle_manager: Node) -> void:
	combatant = actor
	manager = battle_manager
	_refresh()

# Effects and items can modify stats directly; read the combatant as the source of truth.
func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(combatant):
		visible = false
		return
	visible = true
	var active: bool = is_instance_valid(manager) and manager.combatiente_actual == combatant and combatant.hp > 0
	var effects_state: Array = []
	for effect in combatant.efectos_activos:
		if effect is Dictionary and not str(effect.get("stat", "")).is_empty():
			effects_state.append([str(effect.get("stat")), str(effect.get("subtipo", "")), int(effect.get("duracion", 0))])
	var modified_state: Array = []
	for stat in combatant.MODIFIABLE_STATS:
		if stat in ["hp", "hp_max"] or not combatant.stats_base.has(stat):
			continue
		modified_state.append([stat, combatant.get(stat)])
	var state: Array = [combatant.nombre, combatant.hp, combatant.hp_max, active, effects_state, modified_state]
	if state == last_state:
		return
	last_state = state
	$Margin/Rows/Name.text = combatant.nombre
	$Margin/Rows/Health.max_value = maxi(1, combatant.hp_max)
	$Margin/Rows/Health.value = clampi(combatant.hp, 0, combatant.hp_max)
	$Margin/Rows/HealthText.text = "%d / %d HP" % [combatant.hp, combatant.hp_max]
	_actualizar_iconos_estado()
	modulate = Color.WHITE if combatant.hp > 0 else Color(0.6, 0.6, 0.6)


func _actualizar_iconos_estado() -> void:
	var container: HBoxContainer = $Margin/Rows/StatusIcons
	for child in container.get_children():
		child.queue_free()
	var shown_stats: Dictionary = {}
	for effect in combatant.efectos_activos:
		if not effect is Dictionary:
			continue
		var stat := str(effect.get("stat", ""))
		if stat.is_empty():
			continue
		shown_stats[stat] = true
		var icon := STAT_ICON_SCENE.instantiate()
		container.add_child(icon)
		var direction: int = icon.Indicator.BUFF if str(effect.get("subtipo", "buff")) == "buff" else icon.Indicator.DEBUFF
		icon.configure_stat(stat, direction)
	# Instantaneous stat modifiers do not enter efectos_activos. Detect them
	# against the captured base stats so they still receive visual feedback.
	for stat in combatant.MODIFIABLE_STATS:
		if stat in ["hp", "hp_max"] or shown_stats.has(stat) or not combatant.stats_base.has(stat):
			continue
		var base_value = combatant.stats_base.get(stat)
		var current_value = combatant.get(stat)
		if current_value == base_value:
			continue
		var icon := STAT_ICON_SCENE.instantiate()
		container.add_child(icon)
		var direction: int = icon.Indicator.BUFF if float(current_value) > float(base_value) else icon.Indicator.DEBUFF
		icon.configure_stat(stat, direction)
	container.visible = container.get_child_count() > 0
