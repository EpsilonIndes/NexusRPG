extends CanvasLayer
## Persistent overlay: it survives scene replacement and freezes input/gameplay.
@export var fade_out_seconds := 0.3
@export var fade_in_seconds := 0.4
@export var black_hold_seconds := 0.5
var active := false
var _was_paused := false
var _curtain: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1000
	_curtain = ColorRect.new()
	_curtain.color = Color.BLACK
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_curtain)
	_curtain.hide()

func _input(_event: InputEvent) -> void:
	if active:
		get_viewport().set_input_as_handled()

func cover() -> void:
	active = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	_curtain.modulate.a = 0.0
	_curtain.show()
	await _fade(1.0, fade_out_seconds)
	# Give the renderer a frame to present full black before synchronous loading.
	await get_tree().process_frame

func reveal() -> void:
	# Let followers/navigation settle behind black while player input stays locked.
	var previous_state = GameManager.estado_actual
	GameManager.set_estado(GameManager.EstadosDeJuego.CINEMATICA)
	get_tree().paused = _was_paused
	await get_tree().create_timer(black_hold_seconds, true, false, true).timeout
	await _fade(0.0, fade_in_seconds)
	_curtain.hide()
	GameManager.set_estado(previous_state)
	get_tree().paused = _was_paused
	active = false

func _fade(alpha: float, duration: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_curtain, "modulate:a", alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
