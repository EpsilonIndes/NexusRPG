# Para Astro
extends BattleAnimation

func play():
	if animation_player == null:
		call_deferred("_emit_finished")
		return
	animation_player.play("punch")

func _on_hit_frame():
	emit_signal("impact", targets)
