# Contrato y seguridad de acciones enemigas

## Responsabilidades

- `EnemyCombatant` construye el contexto e instancia la IA y el rol.
- `EnemyRole.evaluate()` propone `intent`, `tactical_role`, `target` preferido y `reason`. No selecciona técnicas ni aplica efectos.
- `EnemyAI` elige una técnica utilizable y produce la decisión final.
- `ActionTargets` valida la estructura básica de técnicas y resuelve objetivos respecto al actor y al roster actual. No contiene reglas tácticas ni resuelve efectos.
- `BattleManager2` revalida actor, técnica y objetivos antes de ejecutar. `Combatant` y `EffectManager` mantienen la ejecución compartida.

## Decisión

`intent`, `tactical_role`, `reason`, `technique` y `target` describen la acción final. `requested_intent`, `requested_tactical_role` y `requested_reason` conservan la propuesta original. `fallback_reason` queda vacío cuando se pudo cumplir la propuesta.

`tecnica` es el alias de `technique`; `objetivos` es siempre un array. `target` es un array para ALL y un combatiente para los demás alcances. La cola conserva la decisión y actualiza sus objetivos tras revalidarlos; la ejecución puede transmitirla a la animación sin modificar la UI.

Jerarquía: categoría y alcance compatibles con intención → ataque genérico → otra técnica ofensiva → cualquier técnica utilizable → WAIT. Solo se consideran técnicas con ID, alcance reconocido, array de efectos estructurado, animación nula/PackedScene y objetivos disponibles. La validación de estructura no implementa costes/cooldowns ni sustituye los handlers de EffectManager.

WAIT consume el turno sin efectos. Reemplaza la antigua defensa vacía y no otorga una mejora defensiva ficticia. Un actor muerto o inexistente devuelve una decisión vacía.

## Objetivos y ejecución

- SELF: únicamente el actor vivo.
- SINGLE: un objetivo vivo del bando indicado, perteneciente al roster.
- ALL: todos los miembros vivos del bando indicado, sin duplicados.
- RANDOM: selección aleatoria; la preferencia del rol no la anula. Se conserva el resultado al ejecutar si sigue siendo válido.
- Si un objetivo enemigo seleccionado murió, se busca otro válido. Si no hay ninguno, se omite la acción sin efectos ni cambios de resonancia y continúa el turno.
- Las acciones individuales del jugador no se redirigen automáticamente al perder su objetivo.
- Un actor eliminado se valida antes de convertirlo a una referencia tipada; no puede dejar la cola bloqueada.

## Pruebas

Desde la raíz del proyecto:

```powershell
godot --headless --path . res://Tests/enemy_ai_safety.tscn --quit-after 300
```

La salida debe incluir `ENEMY AI SAFETY` con cero fallos. El límite de frames es un watchdog: una salida sin ese resumen no demuestra éxito.

La escena cubre alcances, bandos, duplicados, aleatoriedad, objetivos muertos/eliminados, técnicas mal formadas, jerarquía de fallbacks, coherencia de metadatos, continuación de la cola, ejecución real mediante EffectManager y las técnicas/roles configurados en los CSV. La prueba no carga ni modifica partidas guardadas.

Los comportamientos progresivos del Castigador, la adaptación a patrones, las condiciones del Restrictor y el contador del Presionador siguen siendo trabajo separado. Este cambio no implementa esos diseños ni feedback visual nuevo.
