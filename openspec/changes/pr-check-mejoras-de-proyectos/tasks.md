## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `scripts/sincronizar-proyecto.ps1` y `.github/workflows/pr-check.yml`. Verificación: salida en verde pegada (incluye `tests/sincronizar-proyecto.Tests.ps1`, `tests/aviso-proyecto-atrasado.Tests.ps1`, S07 a S09 de `tests/odd-apply.Tests.ps1` y los dos controles del CI).

## 2. Tests primero

- [x] 2.1 Test primero, S01 a S08 en `tests/pr-check-mejoras-de-proyectos.Tests.ps1` (archivo nuevo, UTF-8 sin BOM, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: pr-check-mejoras-de-proyectos/<ID>` arriba de cada `Probar`). S04 a S06 usan `Con-CarpetaTemporal` con un `.github/workflows/pr-check.yml` inventado que no coincide con ninguna versión de la plantilla (y, en S05, un `AGENTS.md` con texto propio sin marcar). Afirmar lo que dice la columna "Verificación" del Test Plan de `design.md`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Implementación

- [x] 3.1 En `.github/workflows/pr-check.yml`: aplicar D1 de `design.md` (comentario de 3 líneas, `permissions:` a nivel raíz, patrones sensibles, `safeSuffixes`, filtro y mensaje). Commit: `feat: pr-check con permisos mínimos y patrones de los proyectos`, con `Spec-ID: pr-check-mejoras-de-proyectos`. Verificación: S01 a S03 en verde y el control `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` de `tests/ejecutar.ps1` en verde.
- [x] 3.2 En `scripts/sincronizar-proyecto.ps1`: aplicar D2 (mensaje de `pr-check.yml` bloqueado en `-Aviso` y en la sincronización normal), sin cambiar el cálculo de estado, los códigos de salida ni la lista de destinos. Commit: `feat: mensaje de bloqueo de pr-check en sincronizar-proyecto.ps1`, con `Spec-ID: pr-check-mejoras-de-proyectos`. Verificación: S04 a S06 en verde y `tests/sincronizar-proyecto.Tests.ps1` y `tests/aviso-proyecto-atrasado.Tests.ps1` en verde sin modificarlos.
- [x] 3.3 En `.claude/CLAUDE.md`: agregar la viñeta de D3, sin tocar el bloque generado de reglas. Commit que solo toque ese archivo: `docs: regla de mejoras a archivos generados`, con una línea "Impacto: …" y `Spec-ID: pr-check-mejoras-de-proyectos`. Verificación: la parte de `.claude/CLAUDE.md` de S07 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 3.4 En `README.md`: agregar los dos párrafos de D4 en "Sumar un proyecto al workflow", después del párrafo de `-Aviso`. Verificación: S07 y S08 en verde.
- [x] 3.5 En `docs/arquitectura/vision.md`, `## Componentes`: la línea de `.github/workflows/` pasa a "`pr-check.yml` (convenciones de PR con branches `change/` u `odd/`, permisos de solo lectura; se copia a los proyectos y lo propio de cada proyecto va en otro workflow) y `plantillas.yml` (tests y control de plantillas de este repo).". Verificación: diff pegado.

## 4. Cierre

- [x] 4.1 M01 (lo hace el Agente, solo lectura): correr `-Aviso` en pdf_automation_research y en normalizacionRTF-python como dice el Test Plan, y pegar las dos líneas. Verificación: las dos nombran `.github/workflows/pr-check.yml` con el texto de D2, y `git status` de esos dos proyectos no cambia.
- [x] 4.2 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S08, C01 y los dos controles del CI en `OK`).
- [x] 4.3 Revisión de seguridad del diff: buscar rutas `C:\Users`, tokens e `Invoke-Expression` en las líneas agregadas fuera de `openspec/`, y confirmar que ningún archivo nuevo o modificado tiene BOM (`EF BB BF`). Verificación: salida sin coincidencias, pegada.
