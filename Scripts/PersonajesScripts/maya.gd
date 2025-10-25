extends PersonajeIA

func _custom_ready():
	pj_nombre = "Maya"
	usa_flip_x = true
	if kosmo:
		print("%s está lista para encontrar fósiles." % pj_nombre)