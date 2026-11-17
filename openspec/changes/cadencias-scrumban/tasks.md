# Tasks

## 1. Caracterización

- [x] 1.1 C01 y C02: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `scripts/tablero-comun.ps1` y `.claude/CLAUDE.md`. Verificación: salida en verde pegada (incluye `tests/tablero-scrumban.Tests.ps1` y `tests/metricas-de-flujo.Tests.ps1`) y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.

## 2. Tests primero

- [x] 2.1 Test primero, S02 a S12 en `tests/cadencias-scrumban.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: cadencias-scrumban/<ID>` arriba de cada `Probar`). Cada test usa `Con-CarpetaTemporal` como vault (pasado con `-Vault`), un `tablero.md` inventado (`owner: dueno-prueba`, `numero: 7`) y `-Ahora 2026-11-17`; S02 corre `scripts/tablero.ps1 -Wip -Columna diseno -Config <tablero> -Entrada <JSON de tarjetas inventado>`. Afirmar lo que dice la columna "Verificación" del Test Plan de `design.md`. Verificación: fallan con el código actual porque `cadencia-retro` no se valida y `scripts/retro.ps1` no existe (salida en rojo pegada).
- [x] 2.2 Test primero, S13 a S18 en el mismo archivo: leen `skills/retro/SKILL.md`, `.claude/CLAUDE.md` y `docs/workflow.md` y afirman los textos de D3, D4, D5 y D7; S14 corre `pwsh -NoProfile -File scripts/instalar.ps1 -Destino <carpeta temporal> -SinVault -Simular` y busca `.claude/skills/retro/SKILL.md`; S18 corre además `pwsh scripts/generar-plantillas.ps1 -Comprobar`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Scripts

- [x] 3.1 Agregar S01 a `tests/cadencias-scrumban.Tests.ps1` (`tablero.ps1 -Wip` con `cadencia-retro: 7`, mismo armado que S02). No es test primero: hoy `tablero.ps1` ignora la clave, así que S01 pasa antes y después y fija que la clave válida no cambia nada. Después, `scripts/tablero-comun.ps1`: en `Leer-ConfigTablero`, validación de `cadencia-retro` y la clave en `$cfg` según D1 de `design.md`, sin otros cambios. UTF-8 sin BOM. Commit: `feat: cadencia-retro en tablero.md`, con `Spec-ID: cadencias-scrumban`. Verificación: S01 y S02 en verde, y `tests/tablero-scrumban.Tests.ps1` y `tests/metricas-de-flujo.Tests.ps1` en verde sin modificarlos.
- [x] 3.2 Crear `scripts/retro.ps1` según D2 de `design.md`: parámetros `-Aviso`, `-Periodo`, `-Vault`, `-Config` y `-Ahora`; funciones puras `Obtener-FechasRetro` y `Obtener-NotasArchive`; mensajes, formato de salida y códigos exactos de D2; carga de `tablero-comun.ps1`; sin rutas absolutas en la salida. UTF-8 sin BOM. Commit: `feat: retro.ps1 con aviso de cadencia y período de la retro`, con `Spec-ID: cadencias-scrumban`. Verificación: S03 a S12 en verde.

## 4. Skill, reglas y guía

- [x] 4.1 Crear `skills/retro/SKILL.md` según D3, D4 y D5 de `design.md` (frontmatter, restricciones, pasos 0 a 6, issue de cada acción, formato de la nota y salida). No agregarla a `scripts/generar-plantillas.ps1` (D6). Commit: `feat: skill /retro con review y Start / Stop / Continue`, con `Spec-ID: cadencias-scrumban`. Verificación: S13 a S17 en verde.
- [x] 4.2 `.claude/CLAUDE.md`: paso de la retro en `## Al iniciar cada sesión`, `### Cadencias` después de `### Métricas` en `## Scrumban`, `retros\` en `### Estructura del vault` y la fila de `/retro` en `### Cuándo actuar`, según D7, sin tocar el bloque generado de reglas del Agente. El commit toca solo `.claude/CLAUDE.md`: `docs: cadencias Scrumban y aviso de retro en las reglas globales`, con `Spec-ID: cadencias-scrumban` y una línea de impacto (todas las sesiones corren el aviso; sin `cadencia-retro` es silencioso). Verificación: la parte de `CLAUDE.md` de S18 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [x] 4.3 `docs/workflow.md`: `cadencia-retro: 7` en el ejemplo de `### 3. Configurar tablero.md en el vault` y `### Retro semanal` después de `### Métricas de flujo`, según D7, sin rutas absolutas ni nombres de cuentas. Verificación: la parte de `docs/workflow.md` de S18 en verde.

## 5. Visión

- [x] 5.1 `docs/arquitectura/vision.md`: en `## Componentes`, la línea de `scripts/` suma "aviso de cadencia y período de la retro (`retro.ps1`)" y la de `skills/` suma "(incluye `/retro`, la retro global con review)"; en `## Hoja de ruta`, el `origen` de la deuda #55 suma `cadencias-scrumban`. Verificación: diff pegado.

## 6. Correcciones del verify

- [ ] 6.1 Test primero, S19 en `tests/cadencias-scrumban.Tests.ps1` (con `# test-plan: cadencias-scrumban/S19`), según la fila S19 del Test Plan de `design.md`. Verificación: falla con el código actual (salida en rojo pegada).
- [ ] 6.2 `skills/retro/SKILL.md`, Fase 5: (a) la definición SMART con las cinco letras de D4 de `design.md` (Específica, Medible, Alcanzable, Relevante y con Tiempo) más quién la hace; (b) el párrafo "Dato inválido" de D4: si `gh issue create` falla por otro motivo (repo que no existe, etiqueta que el repo no tiene), la acción queda `issue: pendiente (<motivo>)`, se avisa y se sigue, sin crear etiquetas ni repos. Commit: `fix: datos inválidos y SMART completo en /retro`, con `Spec-ID: cadencias-scrumban`. Verificación: la parte de la skill de S19 en verde y S13 a S17 en verde sin modificarlos.
- [ ] 6.3 `docs/workflow.md`, `### Retro semanal`, punto 1: cambiar "si pasaron más de `cadencia-retro` días" por "si pasaron `cadencia-retro` días o más". Verificación: la parte de `docs/workflow.md` de S19 en verde.

## 7. Integración

- [ ] 7.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada con S01 a S19, y los primeros 3 bytes de cada archivo tocado (ninguno `EF BB BF`). (Se desmarcó en el verify porque se sumó S19.)
- [ ] 7.2 M01 (lo corre el usuario): agregar `cadencia-retro: 7` a `tablero.md` de cada vault, correr `pwsh scripts/instalar.ps1` y abrir una sesión nueva de Claude Code en otro proyecto (por ejemplo, shorts-factory); tiene que aparecer `Todavía no hay retros en el vault: corré /retro`. Queda `[ ]` hasta que el usuario lo confirme en el verify.
- [ ] 7.3 M02 (lo corre el usuario): correr `/retro` en una sesión real de Claude Code; tiene que quedar `retros/AAAA-MM-DD.md` en el vault con las seis secciones, los issues de las acciones en Backlog del tablero y, en una sesión nueva, ningún aviso de retro. Queda `[ ]` hasta que el usuario lo confirme en el verify.
- [ ] 7.4 (lo corre el usuario) Verificar que el cambio aplica en un proyecto de prueba: con M01 y M02 hechos desde un proyecto que no es `sdd-global-config`, confirmar que el aviso y `/retro` funcionan ahí. Queda `[ ]` hasta que el usuario lo confirme en el verify.

## Workflow follow-up

- Verify con `/opsx:verify cadencias-scrumban`, archive en la rama, PR con `Closes #70`, merge y cierre en el vault.
- En la otra PC: `git pull`, `pwsh scripts/instalar.ps1` y `cadencia-retro: 7` en su `tablero.md`.
