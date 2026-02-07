extends Control

@onready var face := $VBoxContainer/Face
@onready var name_label := $VBoxContainer/Name
@onready var hp_label := $VBoxContainer/HP
@onready var lv_label := $VBoxContainer/Level
@onready var next_label := $VBoxContainer/NextLevel

func set_character(char_id: String, char_data):
	var stats = char_data.stats
	name_label.text = char_id
	lv_label.text = "LV %s" % int(stats.nivel)
	hp_label.text = "HP %s" % int(stats.hp)
	next_label.text = "Exp %s/%d" % [int(stats.get("exp_actual")), int(stats.get("exp_para_siguiente"))]
	face.texture = CharacterFaces.FACE_TEXTURES.get(char_id)
