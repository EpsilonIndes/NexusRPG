# Para Astro
extends BattleAnimation

func play():
	animation_player.play("punch")

func _on_hit_frame():
	for target in targets:
		target.reproducir_feedback()
