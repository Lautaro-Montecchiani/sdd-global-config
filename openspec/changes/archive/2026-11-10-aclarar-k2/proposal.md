## Why

El criterio K2 dice "toca un dato declarado en `## Datos` como `(externo)` o `personal`", pero no define qué es "tocar". En las pruebas de `clasificacion-odd-sdd`, Claude lo razonó de dos maneras para el mismo saludo con el nombre del lead: en S01 dijo que no aplica y en S02 que aplica "por las dudas". Como ante la duda el criterio se cumple y K2 no se puede pasar a ODD, un cambio chico (cambiar el texto fijo de un mensaje que incluye el nombre) puede terminar en el camino largo sin necesidad, y la clasificación deja de ser predecible. Issue: #39.

## What Changes

- **K2 con una lista cerrada de acciones:** se cumple si el pedido cambia cómo se **lee, valida, transforma, guarda, registra, expone o envía** un dato declarado como `(externo)` o `personal`, o si **agrega o quita campos** de ese dato. Usar el dato igual que antes no cumple K2 (por ejemplo, cambiar el texto fijo de un saludo que incluye el nombre).
- El mismo texto en el `CLAUDE.md` global, la skill `odd-change` y sus comandos; una versión corta en `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`.
- La spec `work-classification` suma dos escenarios: dato usado igual que antes (ODD) y dato transformado (SDD por K2).
- Se quita la deuda de K2 de la hoja de ruta de `docs/arquitectura/vision.md`.

## Non-goals

- Cambiar si K2 se puede pasar a ODD: sigue sin poder pasarse.
- Cambiar los demás criterios ni la regla "ante la duda, el criterio se cumple".
- Cambiar los controles de datos personales de la Security Layer.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `work-classification`: el requirement "Criterios SDD" define qué significa tocar un dato para K2.

## Impact

- **Archivos globales modificados:** `.claude/CLAUDE.md` (fila K2 de `## Clasificación ODD / SDD`), `skills/odd-change/SKILL.md`, `.claude/commands/odd.md`, `.claude/commands/odd/start.md` y `.claude/commands/odd/verify.md` (fila K2 de su tabla).
- **Documentación:** `README.md` si nombra K2, `docs/workflow.md`, `docs/modo-de-uso.md` y `docs/arquitectura/vision.md`.
- **Tests:** `tests/aclarar-k2.Tests.ps1` nuevo.
- **Instalación:** `scripts/instalar.ps1` (reglas, skill y comandos; espejo del vault). Las plantillas del Agente no cambian: no listan los criterios.
- **Proyectos:** la clasificación cambia en todos los proyectos desde la instalación; no hay que sincronizar nada por proyecto.
