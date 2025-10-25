extends PersonajeIA

func _custom_ready():
	pj_nombre = "Sigrid"
	usa_flip_x = true
	if kosmo:
		print("%s localizó a Astro. No es que le importe ni nada..." % pj_nombre)
	else:
		print("Sigrid no encontró a Astro. Típico.")
