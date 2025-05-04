extends Node

# Diccionario de ítems: nombre -> cantidad
var items: Dictionary = {}

func add_item(item_name: String, cantidad: int = 1):
    if items.has(item_name):
        items[item_name] += cantidad
    else:
        items[item_name] = cantidad
    print("Agregado: ", cantidad, "x ", item_name)

func remove_item(item_name: String, cantidad: int = 1):
    if items.has(item_name):
        items[item_name] -= cantidad
        if items[item_name] <= 0:
            items.erase(item_name)
        print("Quitado: ", cantidad, "x ", item_name)
    else:
        print(item_name, " no está en el inventario.")

func has_item(item_name: String) -> bool:
    return items.has(item_name)

func get_item_count(item_name: String) -> int:
    return items.get(item_name, 0)

func print_inventory():
        print("=== Inventario ===")
        for item_name in items.keys():
            print(item_name, " x", items[item_name])