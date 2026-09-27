# Iconos de estadisticas

`Escenas/UserUI/stat_icon.tscn` busca PNG en esta carpeta, con el nombre `<stat>_.png`.

| Stat / alias interno | Archivo |
| --- | --- |
| hp, hp_max, max_hp, vida | hp_.png |
| atk, ataque | atk_.png |
| def, defensa | def_.png |
| spd, velocidad | spd_.png |
| lck, suerte | lck_.png |
| wis, espiritu | wis_.png |
| prec, precision | prec_.png |
| eva, evasion | eva_.png |
| crit_rate | crit_rate_.png |
| crit_dmg | crit_dmg_.png |

Se aceptan nombres con o sin el guion bajo final. Para otras stats se aplica
la misma convencion. Si falta el archivo se usa `stat_default.png`.
`stat_texture` permite asignar un icono manual con prioridad sobre la busqueda.

Desde codigo: `icon.configure_stat("defensa", icon.Indicator.DEBUFF)`.
Desde el Inspector: configurar `stat_name` e `indicator`.

`flecha_indicador.png` se comparte: BUFF conserva su verde y orientacion;
DEBUFF gira 180 grados alrededor del centro e intercambia rojo y verde con
un shader. NONE oculta la flecha. Cada instancia tiene su propio material.

El componente solo representa datos. La conexion con efectos activos queda
para el HUD o menu que lo instancie.
