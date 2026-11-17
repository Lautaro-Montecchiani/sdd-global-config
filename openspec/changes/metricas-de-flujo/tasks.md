## 1. Caracterización

- [x] 1.1 C01 y C02: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `scripts/tablero.ps1`, `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md` y `.claude/CLAUDE.md`. Verificación: salida en verde pegada (incluye `tests/tablero-scrumban.Tests.ps1` S01 a S21).

## 2. Tests primero

- [x] 2.1 Test primero, S01 a S10 en `tests/metricas-de-flujo.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: metricas-de-flujo/<ID>` arriba de cada `Probar`). Cada test usa `Con-CarpetaTemporal` para un `tablero.md` (`owner: dueno-prueba`, `numero: 7`) pasado con `-Config`, un JSON inventado en el formato de D2 de `design.md` pasado con `-Entrada`, `-Ahora 2026-03-30T12:00:00Z` y `-Salida` en la carpeta temporal. S10 corre también sin `-Entrada` con un `PATH` sin `gh`. Afirmar lo que dice la columna "Verificación" del Test Plan. Verificación: fallan con el código actual porque `scripts/metricas.ps1` no existe (salida en rojo pegada).
- [x] 2.2 Test primero, S11 a S13 en el mismo archivo: leen `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md`, `.claude/commands/opsx/archive.md`, `.claude/commands/odd/close.md`, `.claude/CLAUDE.md` y `docs/workflow.md`, y afirman los textos de D7 y D8. S12 corre además `pwsh scripts/generar-plantillas.ps1 -Comprobar`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Scripts

- [x] 3.1 Crear `scripts/tablero-comun.ps1` con `Leer-ConfigTablero`, `Formatear-ErrorGh` e `Invocar-Gh` movidas sin cambios desde `scripts/tablero.ps1` (D1), y hacer que `scripts/tablero.ps1` lo cargue con `. "$PSScriptRoot/tablero-comun.ps1"` en lugar de definirlas. UTF-8 sin BOM. Commit: `refactor: funciones del tablero en tablero-comun.ps1`, con `Spec-ID: metricas-de-flujo`. Verificación: `tests/tablero-scrumban.Tests.ps1` en verde sin modificarlo (salida pegada) y `wc -l scripts/tablero.ps1` menor que antes.
- [x] 3.2 Crear `scripts/metricas.ps1` según D2 a D6 de `design.md`: parámetros `-Semanas`, `-Ahora`, `-Config`, `-Salida` y `-Entrada`; consulta GraphQL paginada con `Invocar-Gh`; funciones puras `Normalizar-Tarjetas` y de cálculo; formato exacto de `metricas.md`; mensajes y códigos de D6. UTF-8 sin BOM. Commit: `feat: metricas.ps1 calcula las métricas de flujo del tablero`, con `Spec-ID: metricas-de-flujo`. Verificación: S01 a S10 en verde.

## 4. Skills, reglas y guía

- [x] 4.1 `skills/openspec-archive-change/SKILL.md`: paso `e2. **Métricas de flujo:**` de D7 entre `e` y `f` de la fase del vault, y la línea `- Métricas:` en la salida del cierre. Regenerar `.claude/commands/opsx/archive.md` con `pwsh scripts/generar-plantillas.ps1`. Verificación: la parte del archive de S11 y S12 en verde, y `tests/srs-en-rama-del-change.Tests.ps1`, `tests/backlog-desde-issues.Tests.ps1` y `tests/tablero-scrumban.Tests.ps1` en verde sin modificarlos.
- [x] 4.2 `skills/odd-change/SKILL.md`: paso `5b. **Métricas de flujo:**` de D7 entre `5` y `6` de `/odd:close`. Regenerar `.claude/commands/odd/close.md`. Verificación: la parte de ODD de S11 y S12 en verde.
- [x] 4.3 `.claude/CLAUDE.md`: `### Métricas` después de `### WIP` en `## Scrumban` y la línea de `metricas.md` en `### Estructura del vault` (D8), sin tocar el bloque generado de reglas del Agente. El commit toca solo `.claude/CLAUDE.md` (`docs: métricas de flujo en las reglas globales`). Verificación: la parte de `CLAUDE.md` de S13 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 4.4 `docs/workflow.md`: `### Métricas de flujo` dentro de `## Tablero Scrumban` (D8), sin rutas absolutas. Verificación: la parte de `docs/workflow.md` de S13 en verde.

## 5. Visión y ficha

- [x] 5.1 `docs/arquitectura/vision.md`: en `## Componentes`, la línea de `scripts/` suma "y cálculo de las métricas de flujo del tablero (`metricas.ps1`, con funciones compartidas en `tablero-comun.ps1`)". Verificación: diff pegado.
- [x] 5.2 `openspec/config.yaml`: aplicar la línea de `## Datos` de D8, en un commit aparte `docs: ficha con el historial del tablero`, con `Spec-ID: metricas-de-flujo`. Verificación: diff pegado y `openspec validate metricas-de-flujo` sin errores.

## 6. Cierre

- [x] 6.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S13, C01 y C02).
- [x] 6.2 Revisión de seguridad del diff: buscar `C:\Users`, `D:\`, `GH_TOKEN`, `GITHUB_TOKEN`, `gh auth token`, `ghp_`, `gho_` e `Invoke-Expression` en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 6.3 Verificar que el cambio aplica en un proyecto de prueba (M01, lo hace Claude en el verify, sin marca de usuario): con `instalar.ps1` corrido desde la rama, `pwsh scripts/metricas.ps1` contra el tablero real; `metricas.md` en el vault muestra el #66 en `## Issues cerrados` y el trabajo en curso coincide con el tablero. El Agente no la corre: queda `[ ]` y la cierra Claude con la evidencia del verify.
  - Evidencia del verify (17/11/2026, Claude): `pwsh scripts/metricas.ps1` contra el tablero real → `Métricas generadas: metricas.md (1 cerrados en 4 semanas).`, código 0; `metricas.md` sin BOM, con el #66 en `## Issues cerrados` (lead y cycle 0,1) y el #61 (Revisión) y el #69 (Construcción) en `## Trabajo en curso`, igual que el tablero. Suite: 196 OK, 0 fallas.
