## Context

La regla 9 del `CLAUDE.md` global dice: "Los changes nuevos llevan `## Test Plan` en `design.md`, los tests llevan marcador de ID, no se marca `[x]` una tarea con el test en rojo, y `/opsx:verify` ejecuta los tests". No muestra el formato del marcador, que sí está en las plantillas (`templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc`, `templates/comun/AGENTS.md`) y en las skills de propose y verify.

En `openspec/specs/agent-templates/spec.md`, el requirement "Matriz de soporte por agente" tiene los escenarios en este orden: "Agente con soporte parcial", "Antigravity con sus reglas", "Cursor cubierto por su carpeta", "Sin Gemini CLI". Antes de `retirar-gemini-cli` el orden era "Agente con soporte parcial", "Cursor cubierto por su carpeta". El SRS numera los casos de uso por posición del escenario dentro del requirement (`CU-<ID>.<n>`), así que Cursor pasó de `.2` a `.3`.

## Goals / Non-Goals

**Goals:**
- Que el `CLAUDE.md` global muestre el formato exacto del marcador.
- Que `CU-3.5.10.2.2` vuelva a ser "Cursor cubierto por su carpeta" y no cambie ningún otro ID existente.

**Non-Goals:**
- Cambiar el contenido de los escenarios o de los requirements.
- Persistir los IDs de casos de uso en `docs/srs.meta.yaml` (sigue el diseño de `srs-convenciones-ids`).

## Decisions

**D1. Regla 9:** "los tests llevan marcador de ID" pasa a "los tests llevan el marcador `test-plan: <nombre-change>/<ID>` (en el nombre, un comentario o el docstring)". El resto de la regla no cambia.

**D2. Reordenar con un MODIFIED** del requirement completo: el archive reemplaza el bloque y respeta el orden del delta. Orden final: "Agente con soporte parcial", "Cursor cubierto por su carpeta", "Antigravity con sus reglas", "Sin Gemini CLI".

**D3. Escenario nuevo al final** de "Regla para el Agente", para no correr el ID del escenario existente.

**D4. Orden ante cambio de reglas:** editar `.claude/CLAUDE.md`, instalar en `~/.claude`, sincronizar el espejo del vault y commitear `CLAUDE.md` aparte con el impacto.

**D5. SRS:** se regenera después del archive (lo hace Claude con la oferta del archive) y se comprueba que solo cambian los CU esperados.

## Security Layer

Proyecto `tooling`: los artefactos modificados son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`.
- Commit aparte del `CLAUDE.md` con la descripción del impacto y verificación con hash de la copia instalada.

## Risks / Trade-offs

- Mínimo: es un agregado de texto y un reordenamiento sin cambio de contenido.
- Cualquier SRS ya publicado con `CU-3.5.10.2.3` = Cursor queda desactualizado hasta regenerar.

## Migration Plan

Instalar el `CLAUDE.md` en `~/.claude` y sincronizar el espejo; regenerar el SRS tras el archive. Rollback: revertir el PR.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Matriz de soporte / Agente con soporte parcial | manual: revisión de contenido. Pasos: confirmar que la fila de Codex de `templates/README.md` sigue igual | `templates/README.md` |
| S02 | Matriz de soporte / Cursor cubierto por su carpeta | manual: requiere el archive. Pasos: tras archivar, confirmar que es el segundo escenario del requirement en `openspec/specs/agent-templates/spec.md` y que en el SRS regenerado es `CU-3.5.10.2.2` | `openspec/specs/agent-templates/spec.md`, `docs/srs.md` |
| S03 | Matriz de soporte / Antigravity con sus reglas | manual: requiere el archive. Pasos: tras archivar, confirmar que es el tercer escenario y `CU-3.5.10.2.3` | ídem |
| S04 | Matriz de soporte / Sin Gemini CLI | manual: requiere el archive. Pasos: confirmar que es el cuarto escenario y `CU-3.5.10.2.4`, y que ningún otro `CU-` existente cambió de nombre | ídem |
| S05 | Regla para el Agente / Test en rojo al terminar la tarea | manual: revisión de contenido. Pasos: confirmar que la regla 9 sigue diciendo que no se marca `[x]` con el test en rojo | `.claude/CLAUDE.md` |
| S06 | Regla para el Agente / Formato del marcador en el CLAUDE.md global | manual: revisión de contenido. Pasos: `grep -n "test-plan: <nombre-change>/<ID>" .claude/CLAUDE.md ~/.claude/CLAUDE.md` y el espejo del vault | `.claude/CLAUDE.md` |

## Open Questions

Sin preguntas abiertas.
