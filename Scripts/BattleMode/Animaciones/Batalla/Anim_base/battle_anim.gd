extends Node3D
class_name BattleAnimation

signal finished
signal impact(targets)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var source: Node3D
var targets: Array
var data

func setup(_source, _targets, _data):
	source = _source
	targets = _targets
	data = _data

func play():
	animation_player.play("main")

func set_speed(multiplier: float):
	animation_player.speed_scale = multiplier

func _on_hit_frame():
	emit_signal("impact", targets)

func _on_animation_finished(_anim_name):
	emit_signal("finished")
