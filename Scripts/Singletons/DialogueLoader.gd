extends Node

var dialogos = {} # Diccionario de diálogos agrupados por NPC y por ID

func _ready():
	cargar_dialogos("res://Data/dialogue/dialogos_NPC_auromora.csv")

func cargar_dialogos(path):

	var file = FileAccess.open(path, FileAccess.READ)

	if file == null:
		print("No se pudo cargar el archivo de diálogos.")
		return

	file.get_csv_line() #Salteamos cabeceras

	while not file.eof_reached():
		var row = file.get_csv_line()
		if row.size() < 4:
			continue

		var id_dialogo = row[0]
		var npc = row[1]
		var nombre = row[2]
		var texto = row[3]
		var requisito = row[4] if row.size() > 4 else ""

		if not dialogos.has(npc):
			dialogos[npc] = {}

		if not dialogos[npc].has(id_dialogo):
			dialogos[npc][id_dialogo] = []

		dialogos[npc][id_dialogo].append({
			"nombre": nombre,
			"texto": texto,
			"requisito": requisito
		})
	print("Diálogos cargads correctamente.")

	file.close()

