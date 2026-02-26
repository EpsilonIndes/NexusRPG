extends Node3D
class_name BattleAnimation

signal finished
signal impact(targets)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var source: Node3D
var targets: Array
var data

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)

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
	for target in targets:
		target.reproducir_feedback()

func _move_forward():
	if source and targets.size() > 0:
		var target = targets[0]
		var direction = (target.global_position - source.global_position).normalized()
		var attack_position = target.global_position - direction * 1.2
		source.anim_move_to(attack_position, 0.25)

func _move_back():
	if source:
		source.anim_return_to_origin(0.25)

func _on_animation_finished(_anim_name):
	emit_signal("finished")
