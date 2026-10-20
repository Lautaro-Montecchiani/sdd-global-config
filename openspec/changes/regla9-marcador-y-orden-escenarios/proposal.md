## Why

Dos desvíos detectados al cerrar `retirar-gemini-cli`:

1. El requirement "Regla para el Agente" (`test-driven-verification`) exige que el `CLAUDE.md` global indique el marcador `test-plan: <nombre-change>/<ID>`, pero la regla 9 solo dice "los tests llevan marcador de ID", sin el formato. Las plantillas de reglas sí lo tienen. Quien lea solo el `CLAUDE.md` no sabe qué formato usar, y el verify busca exactamente ese literal.
2. En `retirar-gemini-cli`, el delta del requirement "Matriz de soporte por agente" (`agent-templates`) insertó el escenario "Antigravity con sus reglas" en el medio. Al regenerar el SRS, el caso de uso "Cursor cubierto por su carpeta" pasó de `CU-3.5.10.2.2` a `CU-3.5.10.2.3`, que es el límite conocido de la convención de IDs (`srs-convenciones-ids`): los escenarios nuevos van al final.

## What Changes

- La regla 9 del `CLAUDE.md` global muestra el formato del marcador: `test-plan: <nombre-change>/<ID>`.
- Los escenarios de "Matriz de soporte por agente" vuelven al orden original, con los agregados por `retirar-gemini-cli` al final: "Agente con soporte parcial", "Cursor cubierto por su carpeta", "Antigravity con sus reglas", "Sin Gemini CLI". El contenido no cambia.
- "Regla para el Agente" suma, al final, un escenario que verifica el literal en el `CLAUDE.md` global.
- Tras el archive se regenera el SRS: `CU-3.5.10.2.2` vuelve a ser "Cursor cubierto por su carpeta".

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `agent-templates`: solo el orden de los escenarios de "Matriz de soporte por agente".
- `test-driven-verification`: escenario nuevo, al final, en "Regla para el Agente".

## Impact

- `.claude/CLAUDE.md` (y su copia en `~/.claude`, el espejo del vault y la copia versionada).
- Specs `agent-templates` y `test-driven-verification` al archivar; `docs/srs.md` al regenerar.
- Afecta a todos los proyectos por el `CLAUDE.md` global: solo agrega el formato del marcador a una regla existente.
