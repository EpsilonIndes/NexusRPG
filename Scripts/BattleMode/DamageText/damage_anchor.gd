extends Node3D

@onready var label: Label3D = $Label3D
var velocidad := 1.5
var tiempo_vida := 1.0

func setup(valor: int, tipo: String, rol_combo: String, critico: bool = false) -> void:
	label.text = str(valor)

	match tipo:
		"fisico":
			label.modulate = Color(1, 1, 1)
		"magico":
			label.modulate = Color(0.4, 0.8, 1)
		"dot":
			label.modulate = Color(0.5, 0.5, 0)
	
	match rol_combo:
		"finisher":
			scale *= 1.6
		"opener":
			scale *= 1.05
		"linker":
			scale *= 1.10
		"support":
			scale *= 1
	
	match tipo:
		"buff":
			label.modulate = Color(0.3, 1, 0.3)
			label.text = "+" + str(valor)
		"debuff":
			label.modulate = Color(1, 0.3, 0.3)
			label.text = "-" + str(valor)
		
		"heal":
			label.modulate = Color(0, 1, 0.2)
			label.text = "+" + str(valor)

	
	if critico:
		scale *= 2

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 1.5, 1.0)
	tween.tween_callback(queue_free)

