extends PersonajeIA

func _custom_ready():
	pj_nombre = "Amanda"
	usa_flip_x = false
	if kosmo:
		print("%s encontró a Astro." % pj_nombre)
