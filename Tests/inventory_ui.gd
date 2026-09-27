extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("INVENTORY TEST: " + message)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataLoader.items["test_a"] = {"item_name": "Test A", "item_type": "consumible", "description": "First"}
	DataLoader.items["test_b"] = {"item_name": "Test B", "item_type": "consumible", "description": "Second"}
	DataLoader.items["test_key"] = {"item_name": "Test Key", "item_type": "clave"}
	InventoryManager.items = {"Test A": 1, "Test B": 2, "Test Key": 1}
	var ui = load("res://Escenas/UserUI/inventory_ui2.tscn").instantiate()
	check(ui.get_node("Panel/Margin/Column/Body/Items") is ItemList, "Layout exists before ready, directly from the scene")
	add_child(ui)
	check(ui.tabs.tab_count == 3, "Category tabs loaded from scene")
	check(ui.items.get_theme_constant("v_separation") == 12, "Desktop spacing comes from Theme")
	var locks: int = GameManager.ui_lock_count
	ui.open()
	ui.open()
	check(GameManager.ui_lock_count == locks + 1, "Opening twice does not leak UI locks")
	check(ui.selected_item_id == "test_a", "First item selected on open")
	check(get_viewport().gui_get_focus_owner() == ui.items, "Inventory receives focus")
	ui._request_discard()
	check(InventoryManager.has_item("Test A"), "Discard requires confirmation")
	ui._back()
	check(ui.is_open and not ui.pending_discard, "Cancel returns to inventory")
	ui._request_discard()
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	ui._unhandled_input(accept)
	check(not InventoryManager.has_item("Test A") and ui.selected_item_id == "test_b", "Removing last unit selects adjacent item")
	ui._cycle_category(1)
	check(ui.selected_item_id.is_empty() and not ui.description.text.is_empty(), "Empty category clears stale selection")
	ui._cycle_category(1)
	ui._request_discard()
	check(not ui.pending_discard and InventoryManager.has_item("Test Key"), "Key objects protected")
	DeviceManager.set_input_override(DeviceManager.InputOverride.TOUCH)
	check(ui.hints.get_child(0) is Button, "Touch actions available")
	check(ui.items.get_theme_constant("v_separation") == 20, "Compact Theme variation applied")
	DeviceManager.set_input_override(DeviceManager.InputOverride.KEYBOARD_MOUSE)
	check(ui.hints.get_child(0) is HBoxContainer, "Desktop uses keycap legends")
	ui._cycle_category(1)
	PlayableCharacters.party_actual.clear()
	ui._use_selected()
	check(not ui.choosing_target and InventoryManager.get_item_count("Test B") == 2, "Empty party does not consume item")
	var character := PlayableCharacter.new("Test Hero", "test", {"hp": 10, "max_hp": 100, "dp": 12, "max_dp": 30, "nivel": 5})
	character.in_party = true
	PlayableCharacters.characters["Test Hero"] = character
	PlayableCharacters.party_actual = ["Test Hero"]
	var astro := PlayableCharacter.new("Astro", "test", {"hp": 0, "max_hp": 200})
	astro.in_party = true
	PlayableCharacters.characters["Astro"] = astro
	PlayableCharacters.party_actual.append("Astro")
	PlayableCharacters.characters["Inactive"] = PlayableCharacter.new("Inactive", "test", {})
	DataLoader.items["test_b"]["effect"] = [["heal_fixed", 25]]
	ui._use_selected()
	check(ui.choosing_target and get_viewport().gui_get_focus_owner() == ui.target_cards.get_child(0), "Target card receives focus")
	check(ui.target_cards.get_child_count() == 2, "Only active party members have cards")
	check(ui.target_cards.get_child(0).summary_label.text.contains("HP 10 / 100    DP 12 / 30"), "Current and maximum resources displayed")
	check(ui.target_cards.get_child(1).portrait.texture == CharacterFaces.FACE_TEXTURES["Astro"], "Existing portrait provider reused")
	check(ui.target_cards.get_child(1).summary_label.text.contains("Fuera de combate"), "Defeated character status displayed")
	var custom_theme: Theme = ui.theme.duplicate(true)
	var custom_style := StyleBoxFlat.new()
	custom_style.bg_color = Color.MAGENTA
	custom_theme.set_stylebox("normal", "InventoryCharacterCard", custom_style)
	custom_theme.set_stylebox("panel", "InventoryActionKey", custom_style)
	ui.theme = custom_theme
	check(ui.target_cards.get_child(0).get_theme_stylebox("normal") == custom_style, "Character cards inherit root Theme without style overrides")
	check(ui.hints.get_child(0).get_node("Keycap").get_theme_stylebox("panel") == custom_style, "Action keycaps inherit root Theme without style overrides")
	ui._back()
	check(ui.is_open and get_viewport().gui_get_focus_owner() == ui.items, "Cancel target restores item focus")
	ui._use_selected()
	await get_tree().process_frame
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	get_viewport().push_input(down)
	check(ui.selected_target == 1, "Keyboard moves focus between character cards")
	down.pressed = false
	get_viewport().push_input(down)
	var up := InputEventJoypadButton.new()
	up.button_index = JOY_BUTTON_DPAD_UP
	up.pressed = true
	get_viewport().push_input(up)
	check(ui.selected_target == 0, "Controller moves focus between character cards")
	up.pressed = false
	get_viewport().push_input(up)
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	get_viewport().push_input(key)
	await get_tree().process_frame
	var release := InputEventKey.new()
	release.keycode = KEY_ENTER
	release.pressed = false
	get_viewport().push_input(release)
	check(character.stats.hp == 35 and InventoryManager.get_item_count("Test B") == 1, "Use applies effect and consumes exactly one unit")
	check(ui.target_cards.get_child(0).summary_label.text.contains("HP 35 / 100"), "Card reflects updated HP after use")
	check(ui.selected_item_id == "test_b" and get_viewport().gui_get_focus_owner() == ui.items, "Use preserves selection and focus")
	DeviceManager._controller_changed(77, true)
	DeviceManager.set_input_override(DeviceManager.InputOverride.GAMEPAD)
	check(ui.hints.get_child(1).get_child(0).get_child(0).text == "Y / △", "Controller hints update live")
	DeviceManager._controller_changed(77, false)
	check(ui.hints.get_child(1).get_child(0).get_child(0).text == "R", "Controller disconnection restores keyboard hints")
	ui.close()
	ui.close()
	check(GameManager.ui_lock_count == locks, "Close balances UI lock")
	ui.queue_free()
	await get_tree().process_frame
	print("INVENTORY TESTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	get_tree().quit(failures)
