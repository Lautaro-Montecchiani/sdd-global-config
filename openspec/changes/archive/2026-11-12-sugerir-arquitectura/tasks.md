# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1`. Cada test nuevo lleva `# test-plan: sugerir-arquitectura/<ID>` arriba del `Probar`. Los commits de código no incluyen `openspec/`. El cambio a `.claude/CLAUDE.md` va en un commit separado con la descripción del impacto. Los archivos de `.claude/commands/` no se editan a mano: se regeneran con `pwsh scripts/generar-plantillas.ps1`. `openspec/config.yaml` ya tiene `nivel: 0` y `tamaño: 500, 1000` (commit de artefactos del propose): no tocarlo. Commits con tipos `feat`, `fix`, `chore`, `refactor`, `docs` o `test` (no `style`).

## 1. Caracterización

- [x] 1.1 C01 y C02: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada. Verificación: salida en verde pegada en el resumen.

## 2. Tests de contrato (test primero)

- [x] 2.1 Test primero, S01 a S07 en `tests/sugerir-arquitectura.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` como `tests/srs-en-rama-del-change.Tests.ps1`), con lo que pide la columna Verificación del `## Test Plan` de `design.md` y la línea D1 exacta. S05 ya puede pasar en su parte de `openspec/config.yaml`, pero tiene que fallar en las cuatro fuentes. Verificación: S01 a S04, S06 y S07 fallan con el código actual, y S05 falla por las fuentes (salida en rojo pegada).

## 3. Skills y comandos

- [x] 3.1 En `skills/openspec-propose/SKILL.md`: aplicar D1 a D3 de `design.md` (paso 0 y resumen final, con el caso de recomendación aplicada en el mismo change). Verificación: S02 y la parte de propose de S05 y S06 en verde.
- [x] 3.2 En `skills/openspec-verify-change/SKILL.md`: bloque "Sugerencias de arquitectura" al final del reporte, en el método con Test Plan y en el legacy, según D2 y D3. Verificación: S03 en verde.
- [x] 3.3 En `skills/openspec-archive-change/SKILL.md`, fase del vault: línea D1 en el resumen cuando el paso e escribe "sin evaluar" (también en "Output On Success (Fase del vault)"). Verificación: S04 en verde.
- [x] 3.4 Correr `pwsh scripts/generar-plantillas.ps1`. Verificación: `-Comprobar` con código 0 y `git diff --stat` solo con `opsx/propose.md`, `opsx/verify.md` y `opsx/archive.md` entre los comandos.

## 4. Reglas globales (commit separado)

- [x] 4.1 En `.claude/CLAUDE.md`, sección "## Al iniciar cada sesión": sumar el paso de D2 (leer `## Arquitectura` y sugerir con D1 si falta `nivel` o no es receta, sin correr la skill ni escribir). En "### Responsabilidades por actor" de "## Arquitectura del proyecto", la línea de `Claude (/arquitectura)` suma que Claude la sugiere al iniciar sesión, en el propose, en el verify por tamaño y en el archive. No tocar el bloque entre `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`. Commitear solo este archivo con `docs: sugerir /arquitectura en el workflow`, una línea de impacto y `Spec-ID: sugerir-arquitectura`. Verificación: S01 y S06 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.

## 5. ADR y visión

- [x] 5.1 Crear `docs/adr/0003-nivel-0-para-sdd-global-config.md` con el contenido del bloque de código de `## ADR` del design.
- [x] 5.2 En `docs/arquitectura/vision.md`, aplicar D4: link al ADR 0003 en `## Decisiones vigentes`, quitar la línea "[baja] `## Arquitectura` no declara `nivel`" y sumar la línea de `scripts/instalar.ps1` en `## Hoja de ruta`. Verificación: S07 en verde.

## 6. Cierre

- [x] 6.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S07).
- [x] 6.2 Revisión de seguridad del diff: búsqueda de `C:\Users` y de tokens en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 6.3 M01 (manual, lo corre el usuario): verificar que el cambio aplica en un proyecto de prueba con los pasos de M01 del `## Test Plan` de `design.md`, después de `pwsh scripts/instalar.ps1`. Verificación: línea de sugerencia pegada y `git status` del proyecto sin cambios en `openspec/config.yaml`.
