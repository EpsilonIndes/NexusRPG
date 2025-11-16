# effectParser.gd (Autoload)
extends Node

func parse_effect_string(raw: String) -> Array:
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
