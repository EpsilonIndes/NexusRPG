#CSVReader.gd (Autoload)
extends Node

# Devuelve un Array de filas (cada fila es un Array de columnas)
func read_csv(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir archivo CSV: " + path)
		return []

	var rows: Array = []
	
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() == "":
			continue
		rows.append(_parse_csv_line(line))
	
	return rows

# Parseo correcto respetando comillas y comas dentro de comillas
func _parse_csv_line(line: String) -> Array:
	var result: Array = []
	var current = ""
	var in_quotes = false

	for i in line.length():
		var c = line[i]

		if c == '"':
			in_quotes = !in_quotes
		elif c == "," and not in_quotes:
			result.append(current.strip_edges())
			current = ""
		else:
			current += c

	result.append(current.strip_edges())
	return result
