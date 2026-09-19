# Guardado y carga

- Menú inicial: Nueva partida y Cargar partida.
- Menú de exploración: Guardar / cargar.
- Nuevo guardado crea un archivo independiente, sin límite fijo de ranuras.
- Sobrescribir requiere confirmación. Cargar avisa de la pérdida del progreso sin guardar.
- La lista muestra nombre, fecha UTC, duración, mapa, equipo y nivel del líder.
- Los archivos dañados o incompatibles aparecen en la lista, pero no se pueden cargar.
- Nueva partida y carga usan SceneTransition: fundido a negro de 0,3 s y regreso de 0,4 s. La capa persiste entre escenas y pausa el juego y los controles hasta terminar. Si la carga falla, descubre la pantalla anterior. Los tiempos se ajustan en Scripts/Singletons/SceneTransition.gd. La carga de recursos continúa siendo síncrona; el fundido no sustituye una futura carga en segundo plano.

## Datos persistidos

Posición y rotación del jugador, personajes y sus estadísticas (vida, experiencia, nivel, etc.), orden del grupo, líder, inventario, flags del mundo y técnicas obtenidas/equipadas. Los seguidores se reconstruyen alrededor del jugador.

Solo se admite guardar durante la exploración del mapa actual, nivel_1.tscn. Los diálogos y combates no son puntos de guardado. El Drive es un estado de combate y no se serializa; las recompensas ya aplicadas sí forman parte del progreso.

## Archivos y evolución

SaveManager es un autoload. Escribe variantes de Godot sin serialización de objetos en user://saves/save_<id aleatorio>.sav. El nombre visible es independiente del nombre físico. La escritura usa un archivo temporal y conserva la versión anterior como .bak. Una copia .bak se puede recuperar manualmente, con el juego cerrado, reemplazando el .sav correspondiente; no hay recuperación automática.

El esquema tiene versión 1. Los archivos preliminares Slot_N.sav con datos de ejemplo no se migran. Para incorporar nuevos mapas hay que ampliar la lista de escenas admitidas y su restauración. Para incorporar nuevos sistemas de progreso hay que extender build_save_data, _validate, reset_progress y load_game.

Las técnicas todavía ausentes de los CSV conservan sus identificadores para no perder progreso durante el desarrollo.

## Verificación

Desde la raíz del proyecto:

    godot --headless --path . --quit-after 600 res://Tests/save_integration.tscn

La prueba usa los autoloads y las escenas reales. Crea archivos con IDs aleatorios y elimina solo sus propios archivos. Comprueba creación, sobrescritura repetida, respaldo, restauración, pantalla de carga inicial, bloqueo durante combate y rechazo de datos incompatibles sin alterar la partida actual.

Queda pendiente la revisión visual y de navegación con mando en una sesión interactiva. Godot también emite advertencias existentes sobre recursos/efectos y un recurso todavía en uso al cerrar la prueba.
