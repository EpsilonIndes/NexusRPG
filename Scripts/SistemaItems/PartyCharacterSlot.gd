extends Control

@onready var face := $VBoxContainer/Face
@onready var name_label := $VBoxContainer/Name
@onready var hp_label := $VBoxContainer/HP
@onready var lv_label := $VBoxContainer/Level
@onready var next_label := $VBoxContainer/NextLevel

const FACE_TEXTURES = { "Astro": preload("res://Assets/Faces/Astro.png"),
					   	"Miguelito": preload("res://Assets/Faces/miguelito.png"),
						"Chipita": preload("res://Assets/Faces/chipita.png"),
						"Sigrid": preload("res://Assets/Faces/sigrid.png"),
						"Amanda": preload("res://Assets/Faces/amanda.png"),
						"Maya": preload("res://Assets/Faces/maya.png")}

func set_character(char_id: String, char_data):
	var stats = char_data.stats
	name_label.text = char_id
	lv_label.text = "LV %s" % int(stats.nivel)
	hp_label.text = "HP %s" % int(stats.hp)
	next_label.text = "Exp %s/%d" % [int(stats.get("exp_actual")), int(stats.get("exp_para_siguiente"))]
	face.texture = FACE_TEXTURES.get(char_id)
