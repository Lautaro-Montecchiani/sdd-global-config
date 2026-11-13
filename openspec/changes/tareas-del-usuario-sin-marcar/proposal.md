## Why

La regla 1 de ejecución del Agente ya dice que una tarea manual que corre el usuario, o que necesita una sesión real, "no se simula ni se marca". Igual pasó: en `aviso-proyecto-atrasado` el Agente marcó `[x]` la tarea 5.3 (M01). Corrió el script a mano, en vez de la sesión real de Claude Code que pedía la tarea, y escribió "ejecutado por solicitud explícita del usuario". El verify lo detectó solo porque Claude leyó la nota a mano: no hay una marca fija que identifique esas tareas en `tasks.md`, y el verify no tiene un control que las trate distinto de una tarea manual cualquiera.

## What Changes

- **Marca fija en `tasks.md`:** `openspec-propose` escribe `(lo corre el usuario)` justo después del ID en toda tarea manual que necesita al usuario: una sesión real de Claude Code o del Agente, otro proyecto, otra máquina o credenciales propias. Va en la skill y en el comando `/opsx:propose`, que se genera desde ella.
- **Regla 1 de ejecución del Agente** (`templates/fuente/fragmentos/reglas-ejecucion.md`, que se regenera en las cuatro plantillas y en el bloque de reglas de `.claude/CLAUDE.md`): nombra la marca y aclara que, aunque el usuario le pida al Agente correrla, la tarea queda `[ ]`. Lo que el Agente haya corrido va en el resumen como "evidencia para que confirme el usuario".
- **`openspec-verify-change` y `/opsx:verify`:** por cada tarea con la marca:
  - en `[x]`, le preguntan al usuario si la corrió él y si la evidencia es suya. Si dice que no, o si el verify corre sin interfaz, es CRITICAL "tarea del usuario sin confirmar";
  - en `[ ]`, sigue siendo CRITICAL de completitud. Si el usuario pega la evidencia en el verify, Claude marca la tarea en `tasks.md` y anota de dónde vino la evidencia.
- **Tests nuevos:** `tests/tareas-del-usuario-sin-marcar.Tests.ps1` controla el texto de la regla, de la skill y de los comandos generados.

Archivos globales que se modifican y por qué:
- `templates/fuente/fragmentos/reglas-ejecucion.md`: es la fuente única de las 8 reglas del Agente.
- `skills/openspec-verify-change/SKILL.md` y `skills/openspec-propose/SKILL.md`: son las fuentes del comportamiento de Claude en el verify y en el propose.
- Generados (no se editan a mano): las cuatro plantillas de `templates/`, el bloque de reglas de `.claude/CLAUDE.md`, `.claude/commands/opsx/verify.md` y `.claude/commands/opsx/propose.md`.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `test-driven-verification`: dos requirements nuevos sobre las tareas que corre el usuario: la marca en `tasks.md` que escribe el propose y el control del verify.
- `agent-templates`: requirement nuevo para que la regla 1 de las plantillas y del `CLAUDE.md` global nombre la marca y prohíba marcarla aunque el usuario lo pida.

## Non-goals

- El flujo ODD (`docs/odd/<nombre>.md` y `/odd:verify`): los criterios de aceptación del ODD tienen su propia evidencia. Si hace falta, va en un change aparte.
- Detectar por inferencia tareas del usuario que no llevan la marca: solo cuenta la marca literal. Los changes en curso que no la tienen siguen como hasta ahora.
- Cambiar los `tasks.md` de changes ya archivados.
- Impedir técnicamente que el Agente marque la tarea: el control es la regla más el verify.

## Impact

- Proyectos: reciben la regla nueva al sincronizar (`sincronizar-proyecto.ps1`) y Claude recibe el verify y el propose nuevos con `instalar.ps1`. Los `tasks.md` de changes en curso no cambian.
- El verify suma una pregunta por cada tarea marcada con `(lo corre el usuario)` en `[x]`. Sin interfaz interactiva, esas tareas quedan CRITICAL, igual que la pregunta de explicabilidad.
- Las plantillas de los proyectos van a mostrarse "atrasadas" con `-Aviso` hasta que se sincronicen.
