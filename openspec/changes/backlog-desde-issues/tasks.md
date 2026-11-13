## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `skills/openspec-propose/SKILL.md`, `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md`, `skills/issue-creation/SKILL.md`, `skills/branch-pr/SKILL.md`, `skills/srs-generate/SKILL.md` y `.claude/CLAUDE.md`. Verificación: salida en verde pegada (incluye `tests/generar-comandos.Tests.ps1`, `tests/generar-plantillas.Tests.ps1`, `tests/srs-en-rama-del-change.Tests.ps1` y los dos controles del CI).

## 2. Tests primero

- [x] 2.1 Test primero, S07 a S12 en `tests/backlog-desde-issues.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: backlog-desde-issues/<ID>` arriba de cada `Probar`). Cada test usa `Con-CarpetaTemporal` como proyecto y un archivo JSON con issues inventados en el formato de `gh issue list --json number,title,labels,url` (por ejemplo, `labels` como lista de objetos `{ "name": "prioridad:alta" }`), pasado con `-Entrada`. S11 corre `scripts/generar-backlog.ps1` sin `-Entrada` sobre una carpeta temporal sin repo. Afirmar lo que dice la columna "Verificación" del Test Plan de `design.md`. Verificación: fallan con el código actual porque el script no existe (salida en rojo pegada).
- [x] 2.2 Test primero, S01 a S06 y S13 a S16 en el mismo archivo: cada test lee los archivos del repo y afirma los textos de D2 a D8 de `design.md`, como dice la columna "Verificación". S03, S13 y S16 controlan también el comando generado (`.claude/commands/opsx/propose.md`, `.claude/commands/opsx/archive.md` y `.claude/commands/odd.md`). Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Script del backlog

- [x] 3.1 Crear `scripts/generar-backlog.ps1` según D1 de `design.md`: parámetros `-Proyecto` (obligatorio) y `-Entrada`, lectura con `gh issue list --state open --limit 500 --json number,title,labels,url` desde la carpeta del proyecto, función `Formatear-Backlog` sin entrada ni salida, formato exacto de `docs/backlog.md`, datos inválidos, falla de lectura con código 1 sin tocar el archivo y consola sin rutas absolutas. Escribir el archivo en UTF-8 sin BOM. Commit: `feat: generar-backlog.ps1 desde los issues abiertos`, con `Spec-ID: backlog-desde-issues`. Verificación: S07 a S12 en verde.

## 4. Skills, reglas y regeneración

Cada tarea toca solo la skill o el archivo que nombra, más su comando regenerado con `pwsh scripts/generar-plantillas.ps1`. Va en su propio commit `docs: …` con una línea "Impacto: …" y `Spec-ID: backlog-desde-issues`. No editar a mano ningún archivo de `.claude/commands/`.

- [x] 4.1 `skills/issue-creation/SKILL.md`: aplicar D2 (viñeta del paso 1, paso nuevo "3. Ensure labels" con la tabla del catálogo, renumerar los pasos siguientes y las tres `--label`). Verificación: S01 y S02 en verde.
- [x] 4.2 `skills/openspec-propose/SKILL.md`: aplicar D3 (paso 1b y viñeta de `## Hoja de ruta` de la guía de visión) y regenerar `.claude/commands/opsx/propose.md`. Verificación: S03 a S05 en verde y la parte de `skills/openspec-propose/SKILL.md` de S15.
- [x] 4.3 `skills/branch-pr/SKILL.md`: aplicar D4. Verificación: S06 en verde.
- [x] 4.4 `skills/openspec-archive-change/SKILL.md`: aplicar D5 (paso 6b y línea `**Backlog:**` del resumen) y regenerar `.claude/commands/opsx/archive.md`. Verificación: S13 en verde y `tests/srs-en-rama-del-change.Tests.ps1` en verde sin modificarlo.
- [x] 4.5 `skills/srs-generate/SKILL.md`: aplicar D6. Verificación: S14 en verde.
- [x] 4.6 `.claude/CLAUDE.md`: aplicar D7 en el punto 3 del rol de arquitecto, sin tocar el bloque generado de reglas. El commit toca solo `.claude/CLAUDE.md`. Verificación: S15 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 4.7 `skills/odd-change/SKILL.md`: aplicar D8 y regenerar `.claude/commands/odd.md` y `.claude/commands/odd/start.md`. Verificación: S16 en verde.

## 5. ADR y visión

- [x] 5.1 Crear `docs/adr/0004-issues-de-github-como-fuente-unica-del-backlog.md` con el contenido del bloque de código de `## ADR` del design. Verificación: el título y `## Decisión` del archivo coinciden con el design (diff pegado).
- [x] 5.2 En `docs/arquitectura/vision.md`: en `## Decisiones vigentes`, sumar `- [0004. Issues de GitHub como fuente única del backlog](../adr/0004-issues-de-github-como-fuente-unica-del-backlog.md)`; en `## Componentes`, la línea de `scripts/` pasa a "generación de plantillas, instalación por máquina, sincronización por proyecto y generación del backlog desde los issues (PowerShell 7)."; en `## Hoja de ruta`, la línea `[media] el CI de los proyectos no detecta reglas del Agente atrasadas…` suma al final de su propuesta ", y controle la línea `Issue:` del proposal". Verificación: diff de `docs/arquitectura/vision.md` pegado.

## 6. Migración en GitHub (cuenta Lautaro-Montecchiani; si la activa es otra, frenar y avisar sin cambiarla)

- [x] 6.1 Crear en este repo las etiquetas del catálogo de D2 que falten (`gh label create`). Verificación: `gh label list --json name --jq '.[].name'` con las 9 etiquetas, pegado.
- [x] 6.2 Cerrar #9 y #6 con los comentarios de D9 de `design.md`, y agregarle a #52 las etiquetas `status:approved`, `prioridad:media` y `tipo:feature`. Verificación: `gh issue view 9 --json state`, `gh issue view 6 --json state` y `gh issue view 52 --json labels` pegados.
- [x] 6.3 Por cada una de las 7 líneas de `## Hoja de ruta` de `docs/arquitectura/vision.md`, crear el issue como dice D9 (título `[deuda] …`, cuerpo con `Origen:` y `Propuesta:`, etiquetas `tipo:deuda`, `prioridad:<de la línea>` y `status:needs-review`) y sumarle `— issue: #NN` al final de la línea. Commit de `docs/arquitectura/vision.md`: `docs: hoja de ruta con número de issue`, con `Spec-ID: backlog-desde-issues`. Verificación: los 7 números creados y el diff de la hoja de ruta, pegados.
- [x] 6.4 M01: correr `pwsh scripts/generar-backlog.ps1 -Proyecto .` en este repo y commitear `docs/backlog.md`: `docs: generar backlog`, con `Spec-ID: backlog-desde-issues`. Verificación: salida de consola y primeras 15 líneas de `docs/backlog.md` pegadas; aparecen los 7 issues de deuda y el #52, y no #9 ni #6.

## 7. Cierre

- [x] 7.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S16, C01 y los dos controles del CI en `OK`).
- [x] 7.2 Revisión de seguridad del diff: buscar rutas `C:\Users`, `GH_TOKEN`, `ghp_`, `gho_` e `Invoke-Expression` en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 7.3 Verificar que el cambio aplica en un proyecto de prueba (lo hace Claude en el verify, sin marca de usuario): en este repo, en una rama descartable sacada de `change/backlog-desde-issues`, correr el `/opsx:propose` de la rama (comando de `.claude/commands/`) para un change de prueba que cite el issue #52, y ver que controla el issue con `gh issue view` y que el `proposal.md` arranca con `Issue: #52`. Después se borran la rama y el change de prueba. El Agente no la corre: queda `[ ]` y la cierra Claude con la evidencia del verify.
  Hecho por Claude en el verify del 13/11/2026: en la rama descartable `prueba/issue-en-propose` (borrada), siguiendo el paso 1b del `.claude/commands/opsx/propose.md` de la rama, `gh issue view 52` dio `OPEN` con `status:approved` y el `proposal.md` del change de prueba arrancó con `Issue: #52`; `gh issue view 9` dio `CLOSED`, el caso en que el propose frena y sugiere `/issue-creation`.
