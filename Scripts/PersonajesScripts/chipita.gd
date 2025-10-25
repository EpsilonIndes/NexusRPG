extends PersonajeIA

func _custom_ready():
	pj_nombre = "Chipita"
	usa_flip_x = true
	if kosmo:
		print("%s encontró a Astro" % pj_nombre)
