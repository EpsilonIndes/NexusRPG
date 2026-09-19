# DeviceManager e interfaces

DeviceManager es un autoload que detecta presentación e interacción sin consumir eventos ni cambiar controles de juego.

- mobile_layout depende de Android/iOS o de set_layout_override(). Usar mando en un celular no cambia este valor. Los consumidores reciben presentation_changed al cambiar el tamaño del viewport para poder adaptar su distribución.
- input_method cambia con teclado/mouse, botones o movimiento significativo de los sticks, o entrada táctil. Ignora eventos de mouse emulados desde touch, InputEventAction sintéticos, pequeños movimientos del mouse y drift de sticks.
- Conectar un mando emite controller_connection_changed pero no lo selecciona en automático. Usarlo cambia el método activo. Desconectarlo recupera la entrada de la plataforma cuando corresponde.
- Señales públicas: input_method_changed, layout_changed, controller_connection_changed y presentation_changed.
- Opciones > Gameplay > Interfaz de entrada permite Automático, Táctil, Teclado y mouse o Mando. Se guarda mediante SettingsManager y respeta Aplicar/Cancelar. Forzar Mando sin uno conectado usa la entrada alternativa de la plataforma.

## Integraciones actuales

El menú principal ajusta márgenes y tamaño de botones. SaveSlotsUI comparte su lógica con SaveSlotsTouchView: en táctil usa tarjetas con botones de acción y eliminación, en teclado/mando usa la lista con foco y ayudas correspondientes. El diseño compacto también se conserva al usar mando en una plataforma móvil.

MobileControls solo aparece durante exploración táctil (salvo sus overrides de depuración), se oculta en menús/transiciones y libera las acciones pulsadas al ocultarse. Se construye aunque inicialmente esté oculto, para poder activarse tras cambiar de dispositivo.

No se ha integrado ni modificado la interfaz de combate. Tampoco se ha rediseñado el resto de las pantallas para móvil: el gestor deja las señales disponibles para hacerlo gradualmente.

## Pruebas y vista previa

Para probar la presentación móvil en PC sin alterar la detección de entrada:
DeviceManager.set_layout_override(DeviceManager.LayoutOverride.MOBILE)

Para probar touch:
DeviceManager.set_input_override(DeviceManager.InputOverride.TOUCH)

Volver con AUTO en ambos casos. El override de diseño no se persiste; la opción de entrada se persiste desde Opciones.

    godot --headless --path . --log-file ./device-test.log --quit-after 600 res://Tests/device_manager.tscn

Las pruebas simulan eventos y conexiones; no sustituyen la comprobación en Android/iOS ni con un mando físico. Queda por comprobar en dispositivos reales el tamaño táctil, el teclado virtual y las áreas seguras del celular.
