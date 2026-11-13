## ADDED Requirements

### Requirement: Regla 1 con tareas del usuario
La regla 1 de ejecución del Agente ("Evidencia antes de `[x]`"), en `templates/fuente/fragmentos/reglas-ejecucion.md` y en todo lo que se genera desde ella (las cuatro plantillas de reglas y el bloque de reglas de `.claude/CLAUDE.md`), SHALL nombrar la marca `(lo corre el usuario)` de `tasks.md`. SHALL decir que el Agente deja esas tareas en `[ ]` aunque el usuario le pida correrlas, y que lo que haya corrido lo pega en el resumen del apply como "evidencia para que confirme el usuario".

#### Scenario: Regla en la fuente y en lo generado
- **WHEN** se busca `(lo corre el usuario)` en `templates/fuente/fragmentos/reglas-ejecucion.md`, en las cuatro plantillas de reglas y en `.claude/CLAUDE.md`
- **THEN** aparece en la regla 1 de los seis archivos

#### Scenario: Pedido del usuario
- **WHEN** se lee la regla 1 en `templates/fuente/fragmentos/reglas-ejecucion.md`
- **THEN** dice que la tarea queda `[ ]` aunque el usuario le pida al Agente correrla
- **AND** dice que lo corrido va en el resumen como "evidencia para que confirme el usuario"

#### Scenario: Plantillas regeneradas
- **WHEN** se corre `pwsh scripts/generar-plantillas.ps1 -Comprobar` después del cambio
- **THEN** termina con código 0
