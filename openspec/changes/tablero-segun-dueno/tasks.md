# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Para correr un solo archivo: `pwsh -NoProfile -File tests/<archivo>.Tests.ps1`. Cada test nuevo lleva `# test-plan: tablero-segun-dueno/<ID>`. Datos de prueba inventados (`cuenta-a`, `org-b`, `cuenta-c`, `otra-org`), sin `gh` real.

## 1. Caracterización

- [ ] 1.1 C01, C02 y C03: correr en verde `tests/tablero-scrumban.Tests.ps1`, `tests/metricas-de-flujo.Tests.ps1` y `tests/cadencias-scrumban.Tests.ps1` antes de modificar `scripts/tablero-comun.ps1`, `scripts/tablero.ps1` y `scripts/metricas.ps1`, y pegar la salida. Estos archivos de test no se modifican en todo el change.

## 2. Configuración con un tablero por dueño

- [ ] 2.1 Test primero: S01, S02 y S03 en `tests/tablero-segun-dueno.Tests.ps1` (archivo nuevo, mismo estilo que `tests/tablero-scrumban.Tests.ps1`: `apoyo.ps1`, `Probar`, `Afirmar`, proceso `pwsh` aparte). S01 y S02 se observan con `tablero.ps1 -Issue <url> -Columna backlog -Simular -Config <tmp>` (línea `gh project item-add <numero> --owner <owner>`); S03 prueba `dueno-org-b: cuenta-c`, `dueno-org-b: cuenta-c/0`, `dueno-org-b: cuenta-c/x`, `dueno-org-b: /2` y la clave `dueno-: cuenta-c/2`, y espera `tablero.md inválido: <clave>` con exit 0. Correr contra el código actual: S01 y S03 tienen que fallar (S02 puede pasar, porque fija el formato anterior).
- [ ] 2.2 En `scripts/tablero-comun.ps1`, `Leer-ConfigTablero`: validar las claves `dueno-` (D1) y agregar `tableros` y `duenos` a la configuración (D2) sin cambiar las claves que ya devuelve. Agregar la función pura `Resolver-TableroDeIssue` (D2). Verificar: S03 en verde y C01 a C03 en verde.

## 3. Mover la tarjeta al tablero del dueño

- [ ] 3.1 Test primero: S04, S05 y S06 en `tests/tablero-segun-dueno.Tests.ps1` con `-Simular` (S05 en una carpeta temporal con `git init` y `git remote add origin git@github.com:org-b/repo.git`, pasando `-Issue 7`). Correr contra el código actual: S04 y S05 tienen que fallar.
- [ ] 3.2 En `scripts/tablero.ps1`, modo `-Issue`: usar el `owner`/`numero` de `Resolver-TableroDeIssue` en `project view`, `field-list`, `item-add` (incluida la línea de `-Simular`) e `item-edit` (D3). Verificar: S01, S02 y S04 a S06 en verde, y C01 en verde.

## 4. WIP sumado entre tableros

- [ ] 4.1 Test primero: S07, S08, S09 y S10 en `tests/tablero-segun-dueno.Tests.ps1` con `-Wip -Entrada <json>` en el formato `tableros` de D4. En S10 el `error` del tablero que falla incluye una ruta inventada `C:\Users\prueba\gh.exe`, y el test controla que la salida nombre `cuenta-c/2` y no tenga `:\`. Correr contra el código actual: tienen que fallar.
- [ ] 4.2 En `scripts/tablero.ps1`, modo `-Wip`: leer cada Project de `tableros`, avisar y seguir si uno falla, contar una vez por URL de issue y mostrar el Project en cada tarjeta cuando hay más de uno (D4). El formato `tarjetas` sin `tableros` sigue valiendo para el tablero por defecto. Verificar: S07 a S10 en verde, y C01 en verde.

## 5. Métricas de todos los tableros

- [ ] 5.1 Test primero: S13, S14 y S15 en `tests/tablero-segun-dueno.Tests.ps1` con `metricas.ps1 -Config <tmp> -Entrada <json> -Salida <tmp> -Ahora <fecha>` y el formato `tableros` de D5. S15 controla el encabezado `Sin leer: cuenta-c/2.`, que el archivo se escriba y que la consola no tenga `:\`. Correr contra el código actual: tienen que fallar.
- [ ] 5.2 En `scripts/tablero-comun.ps1`, agregar la función que junta las tarjetas de varios Projects por `repo#numero` con los eventos ordenados (D5). En `scripts/metricas.ps1`, recorrer `tableros`, avisar y seguir si uno falla, sumar los descartados en una sola línea y escribir el encabezado de D5. Verificar: S13 a S15 en verde, C02 en verde, y anotar en el resumen las líneas de `scripts/metricas.ps1` (`(Get-Content scripts/metricas.ps1).Count`).

## 6. Reglas, guía y arquitectura

- [ ] 6.1 Test primero: S11 y S12 en `tests/tablero-segun-dueno.Tests.ps1`. S11 lee `### Tablero` y `### WIP` de `.claude/CLAUDE.md` y busca `dueno-`, el tablero por defecto y que el WIP se suma entre todos los tableros. S12 lee la sección del tablero de `docs/workflow.md` y busca `dueno-`, que el WIP y las métricas suman todos los tableros y que no estén `Toyota-Yacopini`, `lmontecchiani` ni `Lautaro-Montecchiani`. Correr: tienen que fallar.
- [ ] 6.2 Editar `.claude/CLAUDE.md`, sección `## Scrumban`: `### Tablero`, `### WIP` y `### Métricas` con el texto de D6. Editar `docs/workflow.md`, paso 3 de la guía del tablero (ejemplo con cuentas inventadas y la viñeta de varios vaults, D6). Verificar: S11, S12, `tablero-scrumban/S16` y `S17` en verde, y `pwsh -NoProfile -File scripts/generar-plantillas.ps1 -Comprobar` sin diferencias.
- [ ] 6.3 Crear `docs/adr/0007-un-tablero-por-dueno-del-repo.md` con el contenido del bloque de código de `## ADR` del design (sin las comillas del bloque). Verificar: el archivo empieza con `# 0007. Un tablero por dueño del repo con WIP y métricas globales`.
- [ ] 6.4 Actualizar `docs/arquitectura/vision.md`: en `## Contexto e integraciones`, cambiar "GitHub Projects (tablero Scrumban de usuario, con `gh project`)" por "GitHub Projects (uno o más tableros Scrumban de usuario, elegidos por el dueño del repo, con `gh project`)"; en `## Componentes`, línea de `scripts/`, cambiar "movimiento de tarjetas y control de WIP del tablero" por "movimiento de tarjetas y control de WIP de los tableros (elegidos por el dueño del repo, con el WIP sumado)" y "métricas de flujo del tablero" por "métricas de flujo de todos los tableros"; en `## Decisiones vigentes`, agregar al final `- [0007. Un tablero por dueño del repo con WIP y métricas globales](../adr/0007-un-tablero-por-dueno-del-repo.md)`. Verificar con `Select-String` que están las tres líneas nuevas.

## 7. Integración

- [ ] 7.1 Correr la suite completa `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar el resumen: sin fallas ni regresiones. Pegar los primeros 3 bytes de cada archivo tocado (no pueden ser `EF BB BF`).
- [ ] 7.2 M01 (lo corre el usuario): en el vault del trabajo, agregar a `tablero.md` la línea `dueno-` de los repos de la empresa hacia el Project del trabajo, correr `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\tablero.ps1" -Wip -Columna diseno` (tiene que sumar los dos tableros) y `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\metricas.ps1" -Salida <scratch>\metricas.md` (el encabezado nombra los dos Projects). Queda `[ ]` hasta que el usuario lo confirme en el verify.
- [ ] 7.3 M02 (lo corre el usuario): verificar que el cambio aplica en un proyecto de prueba. Desde la carpeta de un repo de la empresa, `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\tablero.ps1" -Issue <número de un issue abierto> -Columna backlog -Simular` muestra el Project del trabajo, y desde `sdd-global-config` el mismo comando con un issue de este repo muestra el Project personal. Queda `[ ]` hasta que el usuario lo confirme en el verify.

## Workflow follow-up

- Después del merge: `git pull` y `pwsh scripts/instalar.ps1` en cada máquina, y limpieza manual del tablero personal (paso 3 del Migration Plan).
