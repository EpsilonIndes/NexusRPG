extends Control

signal closed

@onready var party_list = $RootContainer/LeftPanel/LeftMargin/PartyList
@onready var name_label = $RootContainer/CenterPanel/CenterMargin/CenterContent/Header/Headerinfo/NameLabel
@onready var role_label = $RootContainer/CenterPanel/CenterMargin/CenterContent/Header/Headerinfo/RoleLabel
@onready var level_label = $RootContainer/CenterPanel/CenterMargin/CenterContent/Header/Headerinfo/LevelLabel
#@onready var portrait = $RootContainer/CenterPanel/CenterMargin/CenterContent/Header/Portait

@onready var core_stats = $RootContainer/CenterPanel/CenterMargin/CenterContent/CoreStats
@onready var derived_stats = $RootContainer/CenterPanel/CenterMargin/CenterContent/DeriverStats
@onready var breakdown_list = $RootContainer/RightPanel/RightMargin/RightContent/BreakdownList

@onready var back_btn = $BackButton
@onready var main_menu = $"../MainMenuUI"

var current_character_id: String = ""

enum FocusArea {
	PARTY,
	STATS,
	DETAILS
}
var current_focus: FocusArea = FocusArea.PARTY
var current_slot: Button = null

var current_stats: Dictionary = {}
var current_pj_name: String = ""

const CORE_STAT_KEYS = {
	"hp": "HP",
	"atk": "Ataque",
	"def": "Defensa",
	"spd": "Velocidad",
	"lck": "Suerte",
	"wis": "Inteligencia"
}

const DERIVED_STAT_KEYS = {
	"crit_rate": "Prob. Critico",
	"crit_dmg": "Daño Crítico",
	"evasion": "Evasión",
	"precision": "Precisión",
}


func _ready():
	hide()
	set_process_unhandled_input(false)
	back_btn.pressed.connect(close)

func open():
	show()
	set_process_unhandled_input(true)

	_build_party_list()
	GameManager.push_ui()
	await get_tree().process_frame

	if party_list.get_child_count() > 0:
		var first_slot = party_list.get_child(0)
		first_slot.grab_focus()
		select_character(first_slot.character_id)

func close():
	hide()
	set_process_unhandled_input(false)

	GameManager.pop_ui()
	emit_signal("closed")
# ─────────────────────────────
# Party
# ─────────────────────────────

func _build_party_list():
	_clear_container(party_list)

	var team: Array = PlayableCharacters.get_party_actual()
	for char_id in team:
		var char_data = PlayableCharacters.get_character(char_id)
		if not char_data:
			continue
		
		var slot: Button = preload("res://Escenas/UserUI/EstadisticasUI/character_slot.tscn").instantiate()
		party_list.add_child(slot)
		slot.set_character(char_id, char_data)
		slot.focus_entered.connect(func():
			select_character(char_id)
		)

	var party = PlayableCharacters.get_party_actual()
	print("PARTY ACTUAL:", party, " | count:", party.size())


# ─────────────────────────────
# Selección
# ─────────────────────────────

func select_character(pj_name: String):
	current_character_id = pj_name

	if current_slot:
		current_slot.set_selected(false)

	var char_data = PlayableCharacters.get_character(pj_name)
	if not char_data:
		return

	current_stats = char_data.stats if char_data.stats else {}
	if current_stats.is_empty():
		return

	for slot in party_list.get_children():
		if slot.character_id == pj_name:
			current_slot = slot
			current_slot.set_selected(true)
			break


	_render_header(current_stats)
	_render_core_stats(current_stats)
	_render_derived_stats(current_stats)
	_clear_breakdown()

# ─────────────────────────────
# Render
# ─────────────────────────────

func _render_header(stats: Dictionary):
	name_label.text = stats.get("name", current_character_id)
	role_label.text = stats.get("job_name", "")
	level_label.text = "Lv " + str(int(stats.get("nivel", 1)))

	# portrait.texture = ...

func _render_core_stats(stats: Dictionary):
	_clear_container(core_stats)

	for key in CORE_STAT_KEYS.keys():
		if not stats.has(key):
			continue
		
		var row = preload(
			"res://Escenas/UserUI/EstadisticasUI/stat_row.tscn"
		).instantiate()
		
		core_stats.add_child(row)
		row.set_stat(CORE_STAT_KEYS[key], stats[key])
		

func _render_derived_stats(stats: Dictionary):
	_clear_container(derived_stats)

	for key in DERIVED_STAT_KEYS.keys():
		if not stats.has(key):
			continue
		
		var row = preload(
			"res://Escenas/UserUI/EstadisticasUI/stat_row.tscn"
		).instantiate()
		
		derived_stats.add_child(row)
		row.set_stat(DERIVED_STAT_KEYS[key], stats[key])

func _clear_breakdown():
	_clear_container(breakdown_list)


"""
INPUT

"""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_move_focus_right()
	elif event.is_action_pressed("ui_left"):
		_move_focus_left()
	
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

func _move_focus_right():
	match current_focus:
		FocusArea.PARTY:
			_focus_stats()
		FocusArea.STATS:
			_focus_details()

func _move_focus_left():
	match current_focus:
		FocusArea.DETAILS:
			_focus_stats()
		FocusArea.STATS:
			_focus_party()

func _focus_party():
	current_focus = FocusArea.PARTY

	if current_slot:
		current_slot.grab_focus()

func _focus_stats():
	current_focus = FocusArea.STATS

	if core_stats.get_child_count() > 0:
		core_stats.get_child(0).grab_focus()

func _focus_details():
	current_focus = FocusArea.DETAILS

	if breakdown_list.get_child_count() > 0:
		breakdown_list.get_child(0).grab_focus()


"""
func _show_stat_breakdown(stat_key: String):
	_clear_container(breakdown_list)

	if current_stats.is_empty():
		return

	var breakdown = current_stats.get("breakdown", {}).get(stat_key, {})
	if breakdown.is_empty():
		return

	for source in breakdown.keys():
		var value = breakdown[source]

		var row = preload(
			"res://Escenas/UserUI/EstadisticasUI/stat_row.tscn"
		).instantiate()

		row.set_stat(source.capitalize(), value)
		breakdown_list.add_child(row)
"""

func _clear_container(container: Node):
	for child in container.get_children():
		child.queue_free()

func _on_salir_pressed():
	close()
