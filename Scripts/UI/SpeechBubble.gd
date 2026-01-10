# SpeechBubble.gd (En nodo)
extends Control
class_name SpeechBubble

signal initialized

@onready var panel: NinePatchRect = $NinePatchRect
@onready var label: RichTextLabel = $NinePatchRect/MarginContainer/RichTextLabel

var target_anchor: Node3D
var camera: Camera3D
var offset := Vector3.ZERO
var is_typing := false

const MIN_WIDTH := 120
const MAX_WIDTH := 280
const PADDING := Vector2(24,20)

func _ready():
	camera = get_viewport().get_camera_3d()
	
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size * 0.5
	
	await get_tree().process_frame
	print("[SpeechBubble] Inicializado correctamente")
	emit_signal("initialized")

func setup(anchor: Node3D, world_offset: Vector3):
	target_anchor = anchor
	offset = world_offset

func _process(_delta):
	if not target_anchor or not camera:
		return
	
	var screen_pos = camera.unproject_position(target_anchor.global_position)

	var bubble_size := panel.size
	position = screen_pos - bubble_size * 0.5
	_clamp_to_screen()

func set_text(texto: String) -> void:
	is_typing = false
	label.visible_ratio = 0.0
	label.text = texto

	label.autowrap_mode = TextServer.AUTOWRAP_WORD

	# 1️⃣ Medir ancho natural del texto
	var font := label.get_theme_font("normal_font")
	var font_size := label.get_theme_font_size("normal_font_size")
	var text_width := font.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# 2️⃣ Calcular ancho final
	var final_width = clamp(text_width + PADDING.x, MIN_WIDTH, MAX_WIDTH)

	# 3️⃣ Aplicar ancho
	label.custom_minimum_size.x = final_width - PADDING.x
	panel.custom_minimum_size.x = final_width

	await get_tree().process_frame
	await get_tree().process_frame

	# 4️⃣ Ahora sí: altura correcta
	var text_height := label.get_content_height()

	label.custom_minimum_size.y = text_height
	panel.custom_minimum_size.y = text_height + PADDING.y


func type_text(speed: float = 40.0) -> void:
	if is_typing:
		return
	
	is_typing = true
	label.visible_ratio = 0.0

	while label.visible_ratio < 1.0:
		label.visible_ratio += speed * get_process_delta_time() / max(label.text.length(), 1)
		await get_tree().process_frame

		if Input.is_action_just_pressed("accion"):
			label.visible_ratio = 1.0
			break
	
	is_typing = false

func appear():
	panel.scale = Vector2.ZERO

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25)

func _clamp_to_screen():
	var screen := get_viewport().get_visible_rect().size
	var bubble_size := panel.size

	position.x = clamp(position.x, 8, screen.x - bubble_size.x - 8)
	position.y = clamp(position.y, 8, screen.y - bubble_size.y - 8)
