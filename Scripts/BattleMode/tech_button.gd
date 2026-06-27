extends TextureButton

signal tecnica_seleccionada(tecnica_id: String)

@export_group("Opener")
@export var opener_normal: Texture2D
@export var opener_hover: Texture2D
@export var opener_pressed: Texture2D

@export_group("Linker")
@export var linker_normal: Texture2D
@export var linker_hover: Texture2D
@export var linker_pressed: Texture2D

@export_group("Finisher")
@export var finisher_normal: Texture2D
@export var finisher_hover: Texture2D
@export var finisher_pressed: Texture2D

@export_group("Support")
@export var support_normal: Texture2D
@export var support_hover: Texture2D
@export var support_pressed: Texture2D

var tecnica_id: String
var tecnica_stats: Dictionary = {}
var battle_manager: Node = null

func _ready():
	pressed.connect(_on_pressed)
	
	var overlays = get_tree().get_nodes_in_group("technique_overlay")
	if overlays.size() > 0:
		overlays[0].register_button(self)

func configurar(nuevo_id: String, stats: Dictionary) -> void:
	tecnica_id = nuevo_id
	tecnica_stats = stats

	if has_node("Label"):
		$Label.text = stats.get("nombre_tech", tecnica_id)

	aplicar_rol_combo(stats.get("rol_combo", ""))

func aplicar_rol_combo(rol_combo: String) -> void:
	var texturas := _get_texturas_por_rol(rol_combo)

	if texturas.get("normal") != null:
		texture_normal = texturas["normal"]
	if texturas.get("hover") != null:
		texture_hover = texturas["hover"]
		texture_focused = texturas["hover"]
	if texturas.get("pressed") != null:
		texture_pressed = texturas["pressed"]

func _get_texturas_por_rol(rol_combo: String) -> Dictionary:
	match rol_combo:
		"opener":
			return {
				"normal": opener_normal,
				"hover": opener_hover,
				"pressed": opener_pressed,
			}
		"linker":
			return {
				"normal": linker_normal,
				"hover": linker_hover,
				"pressed": linker_pressed,
			}
		"finisher":
			return {
				"normal": finisher_normal,
				"hover": finisher_hover,
				"pressed": finisher_pressed,
			}
		"support":
			return {
				"normal": support_normal,
				"hover": support_hover,
				"pressed": support_pressed,
			}
		_:
			return {}

func _on_pressed():
	
	emit_signal("tecnica_seleccionada", tecnica_id)

func _exit_tree() -> void:
	var overlays = get_tree().get_nodes_in_group("technique_overlay")
	if overlays.size() > 0:
		overlays[0].unregister_button(self)
