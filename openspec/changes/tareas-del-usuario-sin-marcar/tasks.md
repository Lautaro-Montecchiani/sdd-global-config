## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `templates/fuente/fragmentos/reglas-ejecucion.md`, `skills/openspec-propose/SKILL.md` y `skills/openspec-verify-change/SKILL.md`. Verificación: salida en verde pegada (incluye `tests/generar-plantillas.Tests.ps1`, `tests/generar-comandos.Tests.ps1` y los dos controles del CI).

## 2. Tests primero

- [x] 2.1 Test primero, S01 a S08 en `tests/tareas-del-usuario-sin-marcar.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: tareas-del-usuario-sin-marcar/<ID>` arriba de cada `Probar`). Cada test lee los archivos del repo y afirma las oraciones de D1, D2 y D3 de `design.md` como dice la columna "Verificación" del Test Plan. S02 a S06 controlan tanto `skills/openspec-verify-change/SKILL.md` como `.claude/commands/opsx/verify.md`, y S02 controla que la viñeta "Tareas del usuario" aparezca dos veces en cada uno (paso 6 y "Task Completion"). S07 controla los seis archivos: la fuente, `templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc`, `templates/comun/AGENTS.md` y `.claude/CLAUDE.md`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Fuentes y regeneración

- [x] 3.1 En `templates/fuente/fragmentos/reglas-ejecucion.md`: agregar la oración de D1 de `design.md` al final de la regla 1, sin tocar el resto. Correr `pwsh scripts/generar-plantillas.ps1` y no editar a mano ningún archivo generado. Commit con solo la fuente, las cuatro plantillas y `.claude/CLAUDE.md`: `docs: regla 1 con la marca de tareas del usuario`, con una línea "Impacto: …" y `Spec-ID: tareas-del-usuario-sin-marcar`. Verificación: S07 y S08 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 3.2 En `skills/openspec-propose/SKILL.md`: agregar la oración de D2 al final de la viñeta "For `tasks.md`". Regenerar con `pwsh scripts/generar-plantillas.ps1`. Commit con solo la skill y `.claude/commands/opsx/propose.md`: `docs: marca de tareas del usuario en el propose`, con una línea "Impacto: …" y `Spec-ID: tareas-del-usuario-sin-marcar`. Verificación: S01 en verde.
- [x] 3.3 En `skills/openspec-verify-change/SKILL.md`: agregar la viñeta de D3 en el paso 6 y en "Task Completion", y sumar "user tasks `(lo corre el usuario)` not confirmed by the user ("tarea del usuario sin confirmar")" en las dos listas de CRITICAL de "Issues by Priority". Regenerar con `pwsh scripts/generar-plantillas.ps1`. Commit con solo la skill y `.claude/commands/opsx/verify.md`: `docs: control de tareas del usuario en el verify`, con una línea "Impacto: …" y `Spec-ID: tareas-del-usuario-sin-marcar`. Verificación: S02 a S06 en verde.

## 4. Documentación

- [x] 4.1 En `docs/arquitectura/vision.md`, `## Hoja de ruta`: sumar "- [baja] el flujo ODD no controla los criterios de aceptación que corre el usuario — origen: tareas-del-usuario-sin-marcar — propuesta: la misma marca `(lo corre el usuario)` en `docs/odd/<nombre>.md` y su control en `/odd:verify`, en un change aparte". Verificación: diff de `docs/arquitectura/vision.md` con una línea agregada en el formato `- [prioridad] deuda — origen — propuesta`.

## 5. Cierre

- [x] 5.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S08, C01 y los dos controles del CI en `OK`).
- [x] 5.2 Revisión de seguridad del diff: buscar rutas `C:\Users`, tokens e `Invoke-Expression` en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 5.3 M01 (lo corre el usuario): verificar que el cambio aplica en un proyecto de prueba con los pasos de M01 del `## Test Plan` de `design.md`. Queda `[ ]` hasta que el usuario la confirme en el verify. Si corrés algo, pegalo en el resumen como "evidencia para que confirme el usuario".
  Confirmada por el usuario en el verify del 13/11/2026: en el change descartable `prueba-m01`, el Agente dejó la tarea del usuario en `[ ]` aunque se le pidió correrla y puso lo corrido como "evidencia para que confirme el usuario"; el verify preguntó por la tarea marcada a mano y la respuesta "Sí, la corrí yo" quedó anotada sin CRITICAL. El camino "No" queda cubierto por S03 y S05.
