# effectParser.gd (Autoload)
extends Node

func parse_effect_string_viejo(raw: String) -> Array:
    var result: Array = []

    if raw == null or raw == "":
        return result
    
    var effects = raw.split(";", false)

    for e in effects:
        e = e.strip_edges()
        if e == "":
            continue
    
        var parts = e.split(":", false)

        if parts.size() == 2:
            var effect_name = parts[0].strip_edges()
            var value = parts[1].strip_edges()

            var final_value = value
            if value.is_valid_float():
                final_value = float(value)

            result.append([effect_name, final_value])
        
        elif parts.size() == 3:
            var effect_name = parts[0].strip_edges()
            var subtype = parts[1].strip_edges()
            var value = parts[2].strip_edges()
            
            var final_value = value
            if value.is_valid_float():
                final_value = float(value)

            result.append([effect_name, subtype, final_value])
        
        else: push_warning("Formato inesperado en efecto: " + e)

    return result

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
            _:
                push_warning("Formato inesperado en efecto: " + e)
    
    return result


func _parse_value(value: String):
    value = value.strip_edges()
    if value.is_valid_float():
        return float(value)
    return value
    
