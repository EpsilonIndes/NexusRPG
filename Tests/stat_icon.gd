extends Node

func _ready() -> void:
	var scene := preload("res://Escenas/UserUI/stat_icon.tscn")
	var buff := scene.instantiate()
	var debuff := scene.instantiate()
	add_child(buff)
	add_child(debuff)
	buff.configure_stat("hp_", buff.Indicator.BUFF)
	debuff.configure_stat("defensa", debuff.Indicator.DEBUFF)
	assert(buff.get_node("Stat").texture == buff.FALLBACK_ICON)
	assert(debuff.get_node("Stat").texture == debuff.FALLBACK_ICON)
	var up: TextureRect = buff.get_node("Indicator")
	var down: TextureRect = debuff.get_node("Indicator")
	assert(up.texture == down.texture and up.visible and down.visible)
	assert(is_zero_approx(up.rotation) and is_equal_approx(down.rotation, PI))
	assert(up.material != down.material)
	assert(not up.material.get_shader_parameter("is_debuff"))
	assert(down.material.get_shader_parameter("is_debuff"))
	debuff.size = Vector2(64, 64)
	await get_tree().process_frame
	assert(down.pivot_offset == down.size * 0.5)
	debuff.indicator = debuff.Indicator.BUFF
	assert(is_zero_approx(down.rotation))
	assert(not down.material.get_shader_parameter("is_debuff"))
	debuff.indicator = debuff.Indicator.NONE
	assert(not down.visible)
	buff.configure(up.texture)
	assert(buff.get_node("Stat").texture == up.texture)
	buff.configure_stat("unknown_stat")
	assert(buff.get_node("Stat").texture == buff.FALLBACK_ICON)
	buff.indicator_texture = null
	buff.indicator = buff.Indicator.BUFF
	assert(not up.visible)
	buff.queue_free()
	debuff.queue_free()
	await get_tree().process_frame
	print("STAT_ICON_TEST PASSED")
	get_tree().quit()
