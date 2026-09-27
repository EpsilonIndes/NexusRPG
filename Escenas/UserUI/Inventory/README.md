# Edición visual del inventario

Abrí `res://Escenas/UserUI/inventory_ui2.tscn` para editar la estructura completa: panel, márgenes, título, categorías, lista de objetos, descripción, destinatarios y pie de acciones. La estructura ya existe en el editor; el script conecta señales y actualiza los datos.

## Componentes

- `inventory_character_card.tscn`: tarjeta de personaje con retrato, nombre, nivel y resumen. Reutiliza `character_slot.gd`. El texto y retrato iniciales son ejemplos para diseñar; se reemplazan por datos del grupo activo al jugar.
- `inventory_action_hint.tscn`: indicación de tecla/mando clicable con `Keycap/Glyph` y `Caption`.
- `inventory_touch_action.tscn`: acción táctil.

Las tarjetas y acciones se instancian desde estas escenas según el grupo y el estado del inventario. Sus plantillas se pueden cambiar desde **Componentes visuales** en el Inspector del nodo raíz, conservando el contrato del script correspondiente.

## Theme

El nodo raíz tiene asignado `inventory_theme.tres`. Editalo o duplicalo y asigná tu Theme al inventario. Los componentes heredan ese Theme; no tienen un Theme propio ni estilos locales que tapen sus variaciones.

Variaciones principales:

- `InventoryTitle`: fuente y tamaño del título.
- `InventoryCharacterCard`: fondos normal, hover, pressed y focus.
- `InventoryCardContent`: panel interior transparente, para no cubrir el foco de la tarjeta.
- `InventoryActionKey`: fondo y márgenes de las teclas.
- `InventoryMargin`, `InventoryColumn`, `InventoryBody`, `InventoryHints`: márgenes y separaciones.
- `InventoryItems` / `InventoryItemsCompact` y `InventoryTargets` / `InventoryTargetsCompact`: separaciones por dispositivo. DeviceManager selecciona la variación; sus valores se editan en el Theme.

Al previsualizar un componente aislado, usá el Theme del inventario en el editor de Themes para ver sus variaciones. Durante el juego se hereda del inventario.

## Distribución y animaciones futuras

Los tamaños mínimos, anclajes, contenedores y filtros de mouse se editan en las escenas. Los nodos marcados como únicos (`%Items`, `%Targets`, etc.) pueden moverse dentro de la escena principal sin cambiar las referencias del controlador; conservá sus nombres y tipos. En las tarjetas y leyendas, conservá las rutas utilizadas por sus scripts o actualizalas junto con la estructura.

El controlador todavía cambia la visibilidad del selector, el espacio vertical de la descripción y el foco según la interacción. Las escenas ya ofrecen rutas estables para agregar AnimationPlayer, pero esta migración no incorpora un sistema de transiciones ni espera animaciones al cerrar.

Prueba de regresión: `godot --headless --path . --log-file ./inventory-test.log res://Tests/inventory_ui.tscn --quit-after 300`. Incluye herencia del Theme, variaciones por dispositivo y navegación/uso de objetos.
