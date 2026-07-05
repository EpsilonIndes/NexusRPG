extends Control

signal closed

const ROLES := {
	"opener": "Opener",
	"linker": "Linker",
	"finisher": "Finisher",
	"support": "Support"
}

@export_group("Layout")
@export var panel_size := Vector2(1040, 640)
@export var panel_margin := 14
@export var section_margin := 10
@export var root_separation := 10
@export var columns_separation := 12

@export_group("Personaje")
@export var character_panel_width := 260.0
@export var character_panel_separation := 10
@export var portrait_size := Vector2(220, 400)
@export_enum("Izquierda", "Centro", "Derecha") var character_tabs_alignment := 1
@export var character_tabs_expand := true
@export var character_prev_action := "L1"
@export var character_next_action := "R1"
@export var character_prev_hint := "L1"
@export var character_next_hint := "R1"

@export_group("Tecnicas")
@export var editor_panel_separation := 10
@export var equipped_list_min_height := 132.0
@export var technique_list_separation := 8
@export var description_min_height := 78.0
@export var technique_prev_action := "L2"
@export var technique_next_action := "R2"
@export var technique_prev_hint := "L2"
@export var technique_next_hint := "R2"

@export_group("Indicadores")
@export var show_tab_hints := true
@export var tab_hint_size := Vector2(34, 34)
@export var tab_hint_separation := 6

var current_character_id: String = ""
var character_ids: Array = []

var character_tabs: TabBar
var portrait_rect: TextureRect
var character_info_label: Label
var equipped_title_label: Label
var equipped_list: VBoxContainer
var technique_tabs: TabContainer
var header_label: Label
var description_label: Label
var back_btn: Button

func _ready() -> void:
	hide()
	set_process_unhandled_input(false)
	_build_layout()

func open() -> void:
	show()
	set_process_unhandled_input(true)
	_refresh_character_tabs()
	GameManager.push_ui()
	await get_tree().process_frame

	if character_tabs.get_tab_count() > 0:
		character_tabs.current_tab = 0
		character_tabs.grab_focus()
		select_character(character_ids[0])

func close() -> void:
	hide()
	set_process_unhandled_input(false)
	GameManager.pop_ui()
	emit_signal("closed")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	if _is_action_pressed(event, character_prev_action):
		_cycle_character_tab(-1)
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, character_next_action):
		_cycle_character_tab(1)
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, technique_prev_action):
		_cycle_technique_tab(-1)
		get_viewport().set_input_as_handled()
	elif _is_action_pressed(event, technique_next_action):
		_cycle_technique_tab(1)
		get_viewport().set_input_as_handled()

func _build_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.03, 0.035, 0.045, 0.86)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_bottom = panel_size.y * 0.5
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", panel_margin)
	margin.add_theme_constant_override("margin_top", panel_margin)
	margin.add_theme_constant_override("margin_right", panel_margin)
	margin.add_theme_constant_override("margin_bottom", panel_margin)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", root_separation)
	margin.add_child(root)

	var top_bar := HBoxContainer.new()
	root.add_child(top_bar)

	header_label = Label.new()
	header_label.text = "Personalizar tecnicas"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(header_label)

	back_btn = Button.new()
	back_btn.text = "Regresar"
	back_btn.pressed.connect(close)
	top_bar.add_child(back_btn)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", columns_separation)
	root.add_child(columns)

	var character_panel := VBoxContainer.new()
	character_panel.custom_minimum_size = Vector2(character_panel_width, 0)
	character_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_panel.add_theme_constant_override("separation", character_panel_separation)
	_build_character_panel(character_panel)
	columns.add_child(_wrap_section("", character_panel))

	var editor_panel := VBoxContainer.new()
	editor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_panel.add_theme_constant_override("separation", editor_panel_separation)
	_build_editor_panel(editor_panel)
	columns.add_child(_wrap_section("", editor_panel))

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, description_min_height)
	description_label.size_flags_vertical = Control.SIZE_SHRINK_END
	description_label.text = "Selecciona una tecnica para equiparla o quitarla."
	root.add_child(description_label)

func _build_character_panel(parent: VBoxContainer) -> void:
	var tabs_row := HBoxContainer.new()
	tabs_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_row.add_theme_constant_override("separation", tab_hint_separation)
	parent.add_child(tabs_row)

	if show_tab_hints:
		tabs_row.add_child(_make_tab_hint(character_prev_hint))

	character_tabs = TabBar.new()
	character_tabs.tab_alignment = character_tabs_alignment
	character_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL if character_tabs_expand else Control.SIZE_SHRINK_CENTER
	character_tabs.tab_changed.connect(_on_character_tab_changed)
	tabs_row.add_child(character_tabs)

	if show_tab_hints:
		tabs_row.add_child(_make_tab_hint(character_next_hint))

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = portrait_size
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(portrait_frame)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = portrait_size
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait_rect)

	character_info_label = Label.new()
	character_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(character_info_label)

func _build_editor_panel(parent: VBoxContainer) -> void:
	equipped_title_label = Label.new()
	equipped_title_label.text = "Tecnicas equipadas 0/4"
	parent.add_child(equipped_title_label)

	equipped_list = VBoxContainer.new()
	equipped_list.custom_minimum_size = Vector2(0, equipped_list_min_height)
	equipped_list.add_theme_constant_override("separation", technique_list_separation)
	parent.add_child(equipped_list)

	var separator := HSeparator.new()
	parent.add_child(separator)

	var unlocked_title := Label.new()
	unlocked_title.text = "Tecnicas desbloqueadas"
	parent.add_child(unlocked_title)

	var tabs_row := HBoxContainer.new()
	tabs_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs_row.add_theme_constant_override("separation", tab_hint_separation)
	parent.add_child(tabs_row)

	if show_tab_hints:
		tabs_row.add_child(_make_tab_hint(technique_prev_hint))

	technique_tabs = TabContainer.new()
	technique_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	technique_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for role in ROLES.keys():
		var scroll := ScrollContainer.new()
		scroll.name = ROLES[role]
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var list := VBoxContainer.new()
		list.name = "List"
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", technique_list_separation)
		scroll.add_child(list)
		technique_tabs.add_child(scroll)
	tabs_row.add_child(technique_tabs)

	if show_tab_hints:
		tabs_row.add_child(_make_tab_hint(technique_next_hint))

func _wrap_section(title: String, content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", section_margin)
	margin.add_theme_constant_override("margin_top", section_margin)
	margin.add_theme_constant_override("margin_right", section_margin)
	margin.add_theme_constant_override("margin_bottom", section_margin)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", technique_list_separation)
	margin.add_child(box)

	if title != "":
		var label := Label.new()
		label.text = title
		box.add_child(label)

	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	return panel

func _refresh_character_tabs() -> void:
	character_tabs.clear_tabs()
	character_ids.clear()

	var team: Array = PlayableCharacters.get_party_actual()
	if team.is_empty():
		team = PlayableCharacters.characters.keys()

	for char_id in team:
		character_ids.append(char_id)
		character_tabs.add_tab(_get_character_display_name(char_id))

func _on_character_tab_changed(tab: int) -> void:
	if tab >= 0 and tab < character_ids.size():
		select_character(character_ids[tab])

func _cycle_character_tab(direction: int) -> void:
	var tab_count := character_tabs.get_tab_count()
	if tab_count <= 0:
		return

	var next_tab := wrapi(character_tabs.current_tab + direction, 0, tab_count)
	character_tabs.current_tab = next_tab
	select_character(character_ids[next_tab])

func _cycle_technique_tab(direction: int) -> void:
	var tab_count := technique_tabs.get_tab_count()
	if tab_count <= 0:
		return

	technique_tabs.current_tab = wrapi(technique_tabs.current_tab + direction, 0, tab_count)

func select_character(char_id: String) -> void:
	if char_id == "":
		return

	current_character_id = char_id
	_refresh_character_summary()
	_refresh_equipped_list()
	_refresh_technique_lists()

func _refresh_character_summary() -> void:
	var stats := _get_character_stats(current_character_id)
	var display_name = stats.get("name", current_character_id)
	var job_name = stats.get("job_name", "")
	var level := int(stats.get("nivel", 1))

	character_info_label.text = "%s\n%s | Lv %d" % [display_name, job_name, level]
	portrait_rect.texture = _get_character_portrait(current_character_id, stats)

func _refresh_equipped_list() -> void:
	_clear_container(equipped_list)

	var equipped := GlobalTechniqueDatabase.get_visible_techniques_for(current_character_id)
	equipped_title_label.text = "Tecnicas equipadas %d/%d" % [equipped.size(), GlobalTechniqueDatabase.MAX_EQUIPPED_TECHNIQUES]

	for index in range(GlobalTechniqueDatabase.MAX_EQUIPPED_TECHNIQUES):
		if index < equipped.size():
			var tecnica: Dictionary = equipped[index]
			var tech_id := str(tecnica.get("id", ""))
			var button := Button.new()
			button.text = "%d. %s %s" % [
				index + 1,
				get_role_icon_text(str(tecnica.get("rol_combo", ""))),
				str(tecnica.get("nombre", tech_id))
			]
			button.tooltip_text = "Quitar tecnica"
			button.pressed.connect(func(): _unequip(tech_id))
			button.focus_entered.connect(func(): _show_description(tecnica))
			equipped_list.add_child(button)
		else:
			var empty_label := Label.new()
			empty_label.text = "%d. --" % [index + 1]
			equipped_list.add_child(empty_label)

func _refresh_technique_lists() -> void:
	for tab in technique_tabs.get_children():
		var role := _get_role_from_title(str(tab.name))
		var list := tab.get_node("List") as VBoxContainer
		_clear_container(list)

		var techniques := GlobalTechniqueDatabase.get_unlocked_visible_techniques_by_role(current_character_id, role)
		for tecnica in techniques:
			var tech_id := str(tecnica.get("id", ""))
			var equipped := GlobalTechniqueDatabase.is_technique_equipped(current_character_id, tech_id)
			var button := Button.new()
			button.text = _format_technique_button(tecnica, equipped)
			button.disabled = not equipped and _is_equipped_full()
			button.tooltip_text = "Equipada" if equipped else "Equipar tecnica"
			button.pressed.connect(func(): _toggle_technique(tech_id))
			button.focus_entered.connect(func(): _show_description(tecnica))
			list.add_child(button)

func _toggle_technique(tech_id: String) -> void:
	if GlobalTechniqueDatabase.is_technique_equipped(current_character_id, tech_id):
		_unequip(tech_id)
		return

	var equipped := GlobalTechniqueDatabase.equip_technique(current_character_id, tech_id)
	if not equipped:
		description_label.text = "No se pueden equipar mas de cuatro tecnicas."
	_refresh_equipped_list()
	_refresh_technique_lists()

func _unequip(tech_id: String) -> void:
	GlobalTechniqueDatabase.unequip_technique(current_character_id, tech_id)
	_refresh_equipped_list()
	_refresh_technique_lists()

func _show_description(tecnica: Dictionary) -> void:
	var role := str(tecnica.get("rol_combo", ""))
	description_label.text = "%s | %s | Score +%s\n%s" % [
		str(tecnica.get("nombre", tecnica.get("id", ""))),
		format_role_label(role),
		str(int(tecnica.get("score_value", 0))),
		str(tecnica.get("descripcion", ""))
	]

func _format_technique_button(tecnica: Dictionary, equipped: bool) -> String:
	var marker := "[x] " if equipped else "[ ] "
	var role_icon := get_role_icon_text(str(tecnica.get("rol_combo", "")))
	return marker + role_icon + " " + str(tecnica.get("nombre", tecnica.get("id", "")))

func _is_equipped_full() -> bool:
	return GlobalTechniqueDatabase.get_equipped_technique_ids_for(current_character_id).size() >= GlobalTechniqueDatabase.MAX_EQUIPPED_TECHNIQUES

func _get_role_from_title(title: String) -> String:
	for role in ROLES.keys():
		if ROLES[role] == title:
			return role
	return title.to_lower()

func get_role_color(role: String) -> Color:
	match role.to_lower():
		"opener":
			return Color(0.25, 0.9, 0.35)
		"linker":
			return Color(0.2, 0.55, 1.0)
		"finisher":
			return Color(1.0, 0.55, 0.15)
		"support":
			return Color(0.72, 0.35, 1.0)
		_:
			return Color(0.6, 0.6, 0.6)

func get_role_icon_text(role: String) -> String:
	match role.to_lower():
		"opener":
			return "🟢"
		"linker":
			return "🔵"
		"finisher":
			return "🟠"
		"support":
			return "🟣"
		_:
			return "⚪"

func format_role_label(role: String) -> String:
	return "%s %s" % [
		get_role_icon_text(role),
		ROLES.get(role.to_lower(), "Sin rol")
	]

func _get_character_display_name(char_id: String) -> String:
	var stats := _get_character_stats(char_id)
	return stats.get("name", char_id)

func _get_character_stats(char_id: String) -> Dictionary:
	var character = PlayableCharacters.get_character(char_id)
	if character != null and character.stats != null:
		return character.stats
	return {}

func _get_character_portrait(char_id: String, stats: Dictionary) -> Texture2D:
	var face_path := str(stats.get("face", ""))
	if face_path != "" and ResourceLoader.exists(face_path):
		return load(face_path) as Texture2D

	if CharacterFaces.FACE_TEXTURES.has(char_id):
		return CharacterFaces.FACE_TEXTURES[char_id]

	return null

func _make_tab_hint(text: String) -> PanelContainer:
	var hint := PanelContainer.new()
	hint.custom_minimum_size = tab_hint_size
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = tab_hint_size
	hint.add_child(label)

	return hint

func _is_action_pressed(event: InputEvent, action_name: String) -> bool:
	return action_name != "" and InputMap.has_action(action_name) and event.is_action_pressed(action_name)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
