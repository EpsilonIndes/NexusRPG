# effectParser.gd (Autoload)
extends Node

func parse_effect_string(raw: String) -> Array:
	var result: Array = []

	if raw == null or raw.strip_edges() == "":
		return result

	var effects = raw.split(";", false)

	for e in effects:
		e = e.strip_edges()
		if e == "":
			continue

		var parts = e.split(":", false)

		match parts.size():
			2:
				# damage:20
				result.append([
					parts[0].strip_edges(),
					_parse_value(parts[1])
				])

			3:
				# heal:hp:100
				result.append([
					parts[0].strip_edges(),
					parts[1].strip_edges(),
					_parse_value(parts[2])
				])

			4:
				# persist:dot:2.0:10
					result.append([
					parts[0].strip_edges(),
					parts[1].strip_edges(),
					_parse_value(parts[2]),
					_parse_value(parts[3])
				])
			5:
				# persist:buff:ataque:0.2:3
				result.append([
					parts[0].strip_edges(),
					parts[1].strip_edges(),
					parts[2].strip_edges(),
					_parse_value(parts[3]),
					_parse_value(parts[4])
				])
			_:
				push_warning("Formato inesperado en efecto: " + e)
	return result

func parse_effect_bool(value) -> bool:
	if value == null:
		return false
	if value is bool:
		return value
	if value is String:
		var v = value.strip_edges().to_lower()
		return v == "true" or v == "1" or v == "yes"
	if value is int:
		return value != 0
	
	return false
	

func _parse_value(value: String):
	value = value.strip_edges()
	
	# Bool explícito
	if value.to_lower() in ["true", "false"]:
		return EffectParser.parse_effect_bool(value)

	if value.is_valid_float():
		return float(value)
	return value