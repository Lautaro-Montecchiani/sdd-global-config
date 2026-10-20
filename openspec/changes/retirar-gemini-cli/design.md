## Context

Google retiró Gemini CLI y lo reemplazó por Antigravity CLI. En el repo, `templates/gemini/` tiene `GEMINI.md` (las reglas globales del Agente, que hoy solo usa Antigravity desde `~/.gemini/GEMINI.md`) y un `README.md` que documenta Gemini CLI y sus carpetas de confianza. `templates/README.md` tiene una fila de Gemini CLI y una fuente de su documentación. El `CLAUDE.md` global (líneas de "Reglas de ejecución del Agente", "Distribución a agentes no-Claude" y "Onboarding de agentes no-Claude"), `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `templates/antigravity/README.md` nombran `templates\gemini\GEMINI.md` o "Gemini CLI". OpenSpec trata a Antigravity como herramienta propia (`openspec init --tools antigravity`), sin relación con Gemini CLI.

## Goals / Non-Goals

**Goals:**
- Que el repo no presente a Gemini CLI como agente soportado.
- Que `GEMINI.md` viva en la carpeta del agente que lo usa (`templates/antigravity/`).
- Que todas las rutas y guías apunten a la ubicación nueva.

**Non-Goals:**
- Cambiar el destino `~/.gemini/GEMINI.md` ni pasar a `~/.gemini/AGENTS.md` (la documentación de Antigravity lo recomienda, pero no está probado en estas máquinas; queda para otro change).
- Tocar `.gemini/` de los proyectos ni `~/.gemini/antigravity-cli/`, que son de Antigravity.
- Editar changes archivados o el SRS a mano.
- Cambiar el contenido de las reglas.

## Decisions

**D1. `git mv templates/gemini/GEMINI.md templates/antigravity/GEMINI.md`** para conservar el historial. El contenido no cambia, salvo la mención "Gemini/Antigravity" (D4).

**D2. Se elimina `templates/gemini/README.md`.** Las instrucciones de instalación de `GEMINI.md` (destino `~/.gemini/GEMINI.md`, una vez por máquina, fusionar si ya existe con contenido propio) se integran en `templates/antigravity/README.md`, que deja de decir "compartidas con Gemini CLI". La sección de carpetas de confianza de Gemini CLI no se migra: era de Gemini CLI.

**D3. Matriz:** se borra la fila de Gemini CLI; la fila de Antigravity pasa a `antigravity/GEMINI.md` → `~/.gemini/GEMINI.md`; la lista de carpetas pierde `gemini/`; la fuente de Gemini CLI se reemplaza por una nota: "Gemini CLI: retirado por Google y reemplazado por Antigravity CLI" con el enlace al anuncio oficial (https://github.com/google-gemini/gemini-cli/discussions/27274).

**D4. Textos:** "Gemini/Antigravity" pasa a "Antigravity" en el `CLAUDE.md` global y en las plantillas de reglas; `templates\gemini\GEMINI.md` pasa a `templates\antigravity\GEMINI.md` en `CLAUDE.md`, `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`. Se conservan las menciones a `~/.gemini/` y `.gemini/`, que son rutas de Antigravity.

**D5. Máquinas ya instaladas:** no hay que hacer nada; `~/.gemini/GEMINI.md` no cambia de lugar.

**D6. Orden ante cambio de reglas:** editar `.claude/CLAUDE.md`, instalarlo en `~/.claude`, re-sincronizar el espejo del vault y commitear `CLAUDE.md` aparte con la descripción del impacto.

## Security Layer

Proyecto `tooling`: los artefactos modificados son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en plantillas, guías ni `CLAUDE.md`; verificación con un script en archivo.
- El cambio al `CLAUDE.md` global va en un commit aparte con la descripción del impacto, y la copia instalada se verifica con hash.
- No se tocan configuraciones personales de Antigravity (`~/.gemini/antigravity-cli/`, `.gemini/` de los proyectos).

## Risks / Trade-offs

- Guías o notas fuera de este repo que citen `templates\gemini\GEMINI.md` quedan con la ruta rota; las guías de este repo se corrigen.
- Si Antigravity dejara de leer `~/.gemini/GEMINI.md` en una versión futura, habría que pasar a `AGENTS.md`; hoy la documentación lo mantiene por compatibilidad.

## Migration Plan

1. Mover la plantilla y actualizar READMEs, matriz, guías y `CLAUDE.md`.
2. Instalar el `CLAUDE.md` en `~/.claude` y sincronizar el espejo del vault.
3. Rollback: revertir el PR; `~/.gemini/GEMINI.md` no depende de este repo.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Una carpeta por agente / Estructura por agente | manual: sin tests automáticos. Pasos: listar `templates/` recursivamente; confirmar `antigravity/GEMINI.md`, que no existe `gemini/` y que cada carpeta tiene `README.md` | `templates/**` |
| S02 | Una carpeta por agente / README de instalación por agente | manual: revisión de contenido. Pasos: leer `templates/antigravity/README.md` y confirmar destino de `GEMINI.md` y de `settings.json`, sin "Gemini CLI" | `templates/antigravity/README.md` |
| S03b | Matriz de soporte / Agente con soporte parcial | manual: revisión de contenido. Pasos: pegar la fila de Codex y confirmar reglas en `comun/AGENTS.md` y "no verificado" en permisos y barra | `templates/README.md` |
| S03 | Matriz de soporte / Antigravity con sus reglas | manual: revisión de contenido. Pasos: pegar la fila de Antigravity de `templates/README.md` | `templates/README.md` |
| S04 | Matriz de soporte / Cursor cubierto por su carpeta | manual: revisión de contenido. Pasos: pegar la fila de Cursor y confirmar que no cambió | `templates/README.md` |
| S05 | Matriz de soporte / Sin Gemini CLI | manual: revisión de contenido. Pasos: buscar "Gemini CLI" en `templates/README.md` y confirmar que solo aparece en la nota del retiro con el enlace | `templates/README.md` |
| S06 | Mismas reglas de ejecución / Reglas presentes en cada plantilla | manual: sin tests automáticos. Pasos: buscar las tres frases en las cuatro plantillas (con `antigravity/GEMINI.md`) y pegar el conteo | plantillas |
| S07 | Mismas reglas de ejecución / Copia del resumen en el vault | manual: revisión de contenido. Pasos: buscar `apply\AAAA-MM-DD` en la regla 7 de las cuatro plantillas y del `CLAUDE.md` global | plantillas, `.claude/CLAUDE.md` |
| S08 | Setup por máquina / Pasos separados por agente | manual: revisión de contenido. Pasos: confirmar en `README.md` y `docs/modo-de-uso.md` los bloques de Antigravity y Cursor | guías |
| S09 | Setup por máquina / Plantillas de Antigravity presentes | manual: sin tests automáticos. Pasos: confirmar que existen `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json` | `templates/antigravity/` |
| S10 | Setup por máquina / Ruta nueva en el setup | manual: revisión de contenido. Pasos: buscar `templates\gemini` y `templates/gemini` en `README.md`, `docs/*.md`, `templates/` y `.claude/CLAUDE.md`, excluyendo `docs/srs.md`; debe dar cero | guías |
| S11 | Regla para el Agente / Test en rojo al terminar la tarea | manual: revisión de contenido. Pasos: buscar `test-plan:` en `templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md` y `.claude/CLAUDE.md` | plantillas, `.claude/CLAUDE.md` |

## Open Questions

Sin preguntas abiertas.
