# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (corre también `generar-plantillas.ps1 -Comprobar` y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`). Cada test lleva `# test-plan: aviso-proyecto-atrasado/<ID>` arriba del `Probar`. Los tests usan carpetas temporales como proyectos de prueba, nunca proyectos reales ni `$HOME`. Los commits de código no incluyen `openspec/`. El cambio a `.claude/CLAUDE.md` va en un commit que solo toca ese archivo, con una línea de impacto. Tipos de commit: `feat`, `fix`, `chore`, `refactor`, `docs` o `test`. No cambies la cuenta activa de `gh`. Al pegar evidencia, reemplazá rutas absolutas por `{ruta-del-proyecto}`.

## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `scripts/sincronizar-proyecto.ps1`. Verificación: salida en verde pegada (incluye `tests/sincronizar-proyecto.Tests.ps1` y S07 a S09 de `tests/odd-apply.Tests.ps1`).

## 2. Tests (test primero)

- [x] 2.1 Test primero, S01 a S12 en `tests/aviso-proyecto-atrasado.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"`), con proyectos de prueba en carpetas temporales armados como en `tests/sincronizar-proyecto.Tests.ps1`: plantillas actuales copiadas para "al día", la versión de `templates/copilot/copilot-instructions.md` del commit `998c010` para "atrasado", un `AGENTS.md` con texto propio sin `## Propio del proyecto` para "bloqueado" y un `AGENTS.md` vacío para S07. S02 y S06 además comparan los hashes de los archivos del proyecto antes y después. S08 a S11 controlan el texto de la línea según D1 de `design.md`. S12 controla que la salida no contenga la ruta absoluta del proyecto ni la del repo. Verificación: fallan con el código actual (salida en rojo pegada).
- [x] 2.2 Test primero, S13 a S15 en `tests/aviso-proyecto-atrasado.Tests.ps1`: S13 y S14 sobre el texto de "Al iniciar cada sesión" de `.claude/CLAUDE.md` (D2 de `design.md`); S15 sobre `README.md` y `docs/modo-de-uso.md` (`-Aviso`). Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Script

- [x] 3.1 En `scripts/sincronizar-proyecto.ps1`: aplicar D1 de `design.md` (switch `-Aviso`, parámetros incompatibles, destinos solo existentes, mismo cálculo de estado, archivo vacío como bloqueado, salida de una línea sin rutas absolutas y códigos de salida). Actualizar la línea de uso del encabezado del script. Verificación: S01 a S12 en verde, y `tests/sincronizar-proyecto.Tests.ps1` y `tests/odd-apply.Tests.ps1` en verde sin modificarlos.

## 4. Inicio de sesión y documentación

- [x] 4.1 En `.claude/CLAUDE.md`, "## Al iniciar cada sesión", paso 3: sumar el ítem "Comprobar el proyecto" de D2 de `design.md`, después de "Comprobar las reglas". No tocar el bloque generado de reglas. Commit que solo toque este archivo: `docs: aviso de proyecto atrasado al iniciar sesión`, con una línea de impacto y `Spec-ID: aviso-proyecto-atrasado`. Verificación: S13 y S14 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 4.2 En `README.md` ("Sumar un proyecto al workflow"), `docs/modo-de-uso.md` y `docs/workflow.md` (donde ya se documenta `sincronizar-proyecto.ps1`): aplicar D3 de `design.md`, sin rutas absolutas. Verificación: S15 en verde.
- [x] 4.3 En `docs/arquitectura/vision.md`, `## Hoja de ruta`: sumar la línea de D3 de `design.md` ("[media] el CI de los proyectos no detecta reglas del Agente atrasadas ni editadas a mano …"). Verificación: diff de `docs/arquitectura/vision.md` con una línea agregada en el formato `- [prioridad] deuda — origen — propuesta`.

## 5. Cierre

- [x] 5.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S15, C01 y los dos controles del CI en `OK`).
- [x] 5.2 Revisión de seguridad del diff: buscar rutas `C:\Users`, tokens e `Invoke-Expression` en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 5.3 M01 (manual, LO CORRE EL USUARIO: no la simules ni la marques vos): verificar que el cambio aplica en un proyecto de prueba con los pasos de M01 del `## Test Plan` de `design.md`. Dejala `[ ]` y pedile al usuario la evidencia en el resumen.

## 6. Ajustes del verify

- [x] 6.1 Quitar el BOM (bytes `EF BB BF`) del principio de `scripts/sincronizar-proyecto.ps1` y de `tests/aviso-proyecto-atrasado.Tests.ps1`, sin tocar ninguna otra línea (en `master` el script arranca sin BOM). Commit de código con `fix: quitar BOM en sincronizar-proyecto.ps1 y tests del aviso` y `Spec-ID: aviso-proyecto-atrasado`. Verificación: los primeros bytes de los dos archivos son `23 20` (`# `), `git diff master...HEAD -- scripts/sincronizar-proyecto.ps1` ya no muestra cambio en la línea 1 y `pwsh -NoProfile -File tests/ejecutar.ps1` termina con código 0 (salida pegada).
