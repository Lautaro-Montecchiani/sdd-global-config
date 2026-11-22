## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `README.md`. Verificación: salida en verde pegada (incluye `reglas-fuente-unica/S17`, S07 y S08 de `pr-check-mejoras-de-proyectos` y S10 de `huella-de-instalacion-en-espejo`).

## 2. Tests primero

- [x] 2.1 Test primero, S01 a S04 en `tests/carga-unica-de-reglas.Tests.ps1` (archivo nuevo, UTF-8 sin BOM), como dice el Test Plan de `design.md`: `. "$PSScriptRoot/apoyo.ps1"`, `# test-plan: carga-unica-de-reglas/<ID>` arriba de cada `Probar` y la regla de comparación de `**/` para S02. Los tests solo leen archivos del repo. Comando: `pwsh -NoProfile -File tests/carga-unica-de-reglas.Tests.ps1`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Implementación

- [x] 3.1 Crear `.claude/settings.json` con el contenido exacto de D1 de `design.md` (UTF-8 sin BOM, LF). Commit que solo toque ese archivo y el test nuevo: `chore: excluir la copia de las reglas del repo en Claude Code`, con una línea "Impacto: …" y `Spec-ID: carga-unica-de-reglas`. Verificación: S01 a S03 en verde.
- [x] 3.2 En `README.md`: agregar el párrafo de D2 en el lugar que indica. Commit: `docs: carga única de las reglas en este repo`, con `Spec-ID: carga-unica-de-reglas`. Verificación: S04 en verde y los tests de C01 en verde sin modificarlos.

## 4. Documentos de arquitectura

- [x] 4.1 En `docs/arquitectura/vision.md`: en `## Componentes`, después de la línea de `.claude/statusline.sh`, agregar `- \`.claude/settings.json\`: configuración de Claude Code de este repo; excluye \`.claude/CLAUDE.md\` (\`claudeMdExcludes\`) para que las reglas se carguen una sola vez, desde las instaladas.`; en `## Hoja de ruta`, quitar la línea `- [baja] en este repo .claude/CLAUDE.md se carga dos veces en Claude (global y de proyecto) — origen: reglas-fuente-unica-y-carga-desde-vault — propuesta: evaluar mover la copia versionada fuera de .claude/ del repo — issue: #54`. Verificación: diff pegado.

## 5. Cierre

- [x] 5.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S04, C01 y los controles del CI en `OK`).
- [x] 5.2 Revisión de seguridad del diff: buscar `C:\Users`, el nombre de la carpeta del usuario, tokens e `Invoke-Expression`/`iex` en las líneas agregadas fuera de `openspec/`, y confirmar que ningún archivo nuevo o modificado empieza con `EF BB BF`. Verificación: salida sin coincidencias y los primeros 3 bytes de cada archivo tocado, pegados.
- [x] 5.3 M01 (lo corre el usuario): verificar que el cambio aplica en una sesión real de Claude Code en este repo, como dice M01 del Test Plan: en la rama del change, abrir Claude Code y correr `/memory`; la lista tiene `~/.claude/CLAUDE.md` y no `.claude/CLAUDE.md` del proyecto. Queda `[ ]` hasta que el usuario lo confirme en el verify. Evidencia aportada por el usuario en el verify del 22/11/2026: `/memory` en una sesión interactiva lista "User instructions" (`~/.claude/CLAUDE.md`), el espejo `D:\vault-sdd\_global\…` importado y "Project instructions — Checked in at ./CLAUDE.md" (ubicación de la raíz, que no existe); `.claude/CLAUDE.md`, que sí existe, no aparece.
