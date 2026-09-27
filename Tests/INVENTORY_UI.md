# Inventario: controles y verificación

- Flechas / cruceta / stick: seleccionar objetos y personajes.
- Aceptar (acción ui_accept): elegir personaje y usar; confirmar descarte.
- Cancelar (acción ui_cancel): regresar a objetos o cerrar el inventario.
- Q / W o L1 / R1: categoría anterior / siguiente.
- R o Y / Triángulo: solicitar descarte de una unidad.
- Mouse: clic en objeto y personaje para usar; clic derecho para descartar. Las indicaciones inferiores también son clicables.
- Táctil: acciones inferiores como botones.

Las teclas de aceptar/cancelar se muestran desde InputMap mediante InputDisplayHelper. DeviceManager actualiza la presentación en vivo. Los objetos clave no se descartan.

Prueba automática:

```powershell
godot --headless --path . --log-file ./inventory-test.log res://Tests/inventory_ui.tscn --quit-after 300
```

Cubre bloqueo de UI, selección inicial, confirmación/cancelación de descarte, última unidad, categorías vacías, protección de objetos clave, modos táctil/teclado/mando, desconexión, grupo vacío, selección de personaje y uso mediante Enter enviado al viewport, consumo y conservación del foco.

Verificación manual pendiente: aspecto visual a distintas resoluciones y navegación con un mando físico.

La selección de destinatario reutiliza character_slot.gd y CharacterFaces en tarjetas con retrato, nivel, HP/DP actuales y máximos, ATQ/DEF/VEL y estado fuera de combate. Solo aparecen miembros activos. Las tarjetas tienen foco circular y desplazamiento automático; sus datos se actualizan tras usar objetos. Las pruebas también verifican retratos, estadísticas, filtrado del grupo y navegación mediante flechas/cruceta.
