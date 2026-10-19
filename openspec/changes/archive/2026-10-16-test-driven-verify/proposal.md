## Why

Hoy `/opsx:verify` no ejecuta nada: cuenta los checkboxes de `tasks.md` y, por cada requirement y escenario, busca palabras clave en el código para inferir si "parece implementado". No prueba que el código funcione, es caro (Claude lee mucho código del repo en cada verify) y no es reproducible (dos verifies del mismo change pueden dar resultados distintos). Además, un change que modifica código existente puede romper algo fuera de su diff sin que nada lo detecte. Origen: [issue #9](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/9), aprobado el 2026-09-26.

## What Changes

- **Propose** genera en `design.md` una sección `## Test Plan`: cada escenario de las delta specs recibe un ID (`S01`, `S02`…) y un test automático o una verificación manual justificada. Si el change modifica código existente, el plan suma tests de caracterización (`C01`…) de las partes tocadas.
- **Propose** ordena `tasks.md` con los tests primero: caracterización antes de modificar código viejo, tests de escenarios antes de implementar. Si el proyecto no tiene infraestructura de tests, agrega una tarea inicial para armarla.
- **Propose** lee el comando y el entorno de tests de una subsección nueva `## Tests` del `context:` de `openspec/config.yaml`, y la pregunta una sola vez si no existe.
- **Verify** pasa a ejecutar: corre los tests del plan, busca cada test por su marcador de ID, decide por el diff si corre la suite completa contra la rama principal, revisa que cada test compruebe el THEN de su escenario y lee solo el diff del change para diseño y seguridad. Deja de buscar por palabras clave en todo el repo.
- **Verify** conserva el método actual para los changes sin `## Test Plan` (creados antes de esta regla) y lo avisa en el reporte.
- Las plantillas del Agente (`templates/copilot-instructions.md`, `templates/GEMINI.md`) y el `CLAUDE.md` global suman la regla: no marcar una tarea de tests como hecha si el test no pasa.

Archivos globales que se modifican y por qué:
- `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: generar el Test Plan y las tareas de tests (los comandos tienen su propia copia de la lógica).
- `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: el verify que ejecuta tests.
- `.claude/CLAUDE.md` (copia de `~/.claude/CLAUDE.md`): la regla de tests por escenario, para que la lean Claude y el Agente (vía el espejo del vault).
- `templates/copilot-instructions.md`, `templates/GEMINI.md`: la regla para el Agente.
- `docs/workflow.md`, `docs/modo-de-uso.md`: documentación.

## Capabilities

### New Capabilities
- `test-driven-verification`: plan de tests por escenario en el diseño, orden de las tareas de tests, tests de caracterización del código existente modificado, ejecución de tests en el verify con reglas de seguridad, criterio para correr la suite completa, verificación manual justificada y compatibilidad con changes sin plan.

### Modified Capabilities
- `project-context-schema`: el `context:` de `openspec/config.yaml` admite una cuarta subsección fija, `## Tests` (comando, comando rápido, tiempo máximo, requisitos de entorno, exclusiones).

## Non-goals

- No se agrega CI nueva en los proyectos, ni cobertura mínima, ni cambios al schema de OpenSpec.
- No se escriben tests para el código existente que el change no toca, ni para changes ya archivados.
- No se modifican las skills del Agente de cada proyecto (`.agent/skills/`, `.github/skills/`): las obligaciones viajan en `tasks.md`.
- No se saca la duplicación de lógica entre skills y comandos `/opsx` (va en un change aparte).
- No se agrega la columna "Test" a la matriz de trazabilidad del SRS (posible mejora futura de `srs-generation`).

## Impact

- **Skills y comandos de Claude:** propose y verify (4 archivos). Apply y archive no cambian.
- **Reglas globales:** `CLAUDE.md` global + espejo del vault + plantillas del Agente.
- **Proyectos:** ninguno cambia hasta su próximo propose. Los changes en curso siguen con el verify actual. La primera vez que un proyecto haga propose con esta regla, se le va a pedir la subsección `## Tests` de su `config.yaml`.
- **Costo:** los changes suman tareas de tests; el verify gana ejecución de comandos del proyecto (acotada por las reglas de seguridad del diseño).
