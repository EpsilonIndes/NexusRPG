extends Node

var items: Dictionary = {}

func add_item(item_name: String, cantidad: int = 1):
    if items.has(item_name):
        items[item_name] += cantidad
    else:
        items[item_name] = cantidad
    print("[SISTEMA] Agregado: ", item_name, " x", cantidad)

func remove_item(item_name: String, cantidad: int = 1):
    if items.has(item_name):
        items[item_name] -= cantidad
        if items[item_name] <= 0:
            items.erase(item_name)
        print("[SISTEMA] Quitado: ", cantidad, "x ", item_name)
    else:
        print(item_name, " no está en el inventario.")

func has_item(item_name: String) -> bool:
    return items.has(item_name)

func get_item_count(item_name: String) -> int:
    return items.get(item_name, 0)

func print_inventory():                # No se utiliza, pero servirá para comprobar #
        print("=== Inventario ===")    # si funciona el inventario internamente.    #
        for item_name in items.keys():
            print(item_name, " x", items[item_name])