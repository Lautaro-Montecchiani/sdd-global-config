# Design

## Context

Ver proposal.md (Why). Estado actual:

- `scripts/tablero-comun.ps1` → `Leer-ConfigTablero` lee el frontmatter de `tablero.md` (pares `clave: valor`, claves pasadas a minúsculas), valida `owner`, `numero`, `wip-*` y `cadencia-retro`, y devuelve un solo `owner`/`numero`. Lo usan `tablero.ps1`, `metricas.ps1` y `retro.ps1` (este último solo para `cadencia-retro`).
- `scripts/tablero.ps1 -Issue` ya acepta la URL o el número (ODD `tablero-issue-por-numero`, PR #78): con el número arma la URL con el remoto `origin`. Después usa `cfg.owner`/`cfg.numero` para `project view`, `field-list`, `item-add` e `item-edit`.
- `scripts/tablero.ps1 -Wip` lee `project item-list` de un solo Project y cuenta por `status`. Con `-Entrada` toma `tarjetas` del JSON.
- `scripts/metricas.ps1` (469 líneas) pide por GraphQL las tarjetas de un Project, filtra los eventos por ese `owner`/`numero`, calcula y escribe `metricas.md` con el encabezado `Tablero: <owner>/<numero>.`. Con `-Entrada` toma `paginas` del JSON.
- Las skills llaman `tablero.ps1 -Issue "<url>"` (la URL sale de `gh issue view`) y `metricas.ps1` sin parámetros. No cambian.
- La cuenta activa de `gh` tiene permiso sobre los dos Projects reales y `-Comprobar` pasa: `-Comprobar` no cambia.

## Goals / Non-Goals

**Goals:**
- Que la resolución del tablero (qué Projects hay y cuál le toca a un issue) viva en un solo lugar (`tablero-comun.ps1`) y la usen `tablero.ps1` y `metricas.ps1`.
- Que con un `tablero.md` sin claves `dueno-` la salida de los dos scripts sea idéntica a la de hoy (los tests existentes no cambian).

**Non-Goals:**
- Límites de WIP por tablero o por dueño.
- Elegir el tablero por repo (solo por dueño).
- Migrar tarjetas existentes entre Projects (es manual, ver Migration Plan).

## Decisions

### D1. Claves `dueno-<dueño>` en el frontmatter (elegida por el usuario)
`tablero.md` suma líneas `dueno-<dueño del repo>: <cuenta>/<número>`. `owner` y `numero` siguen siendo obligatorios y forman el tablero por defecto. Validación: la clave tiene que tener algo después de `dueno-`, y el valor tiene que cumplir `^[A-Za-z0-9][A-Za-z0-9-]*/[1-9][0-9]*$`; si no, `tablero.md inválido: <clave>` (la clave como la deja el lector, en minúsculas). El dueño se compara en minúsculas (GitHub no distingue mayúsculas en los nombres de cuenta).
- Alternativa: tabla markdown en el cuerpo. Más legible en Obsidian, pero necesita un segundo lector y se rompe con ediciones a mano. Descartada por el usuario.
- Alternativa: un `tablero.md` por dueño (varios archivos). Parte la configuración de WIP y cadencia en varios lugares. Descartada.
- Alternativa: elegir por repo en vez de por dueño. Más líneas para mantener sin un caso real que lo pida. Descartada.

### D2. Resolución en `tablero-comun.ps1`
`Leer-ConfigTablero` agrega a la configuración que devuelve:
- `tableros`: lista de Projects distintos (`owner`, `numero`), primero el de por defecto y después los de las claves `dueno-` en el orden del archivo. Un Project repetido aparece una vez (comparación sin mayúsculas).
- `duenos`: tabla dueño (minúsculas) → Project.

Función nueva y pura `Resolver-TableroDeIssue` (recibe la configuración y la URL del issue, devuelve `owner` y `numero`): toma el dueño de `https://github.com/<dueño>/...`, busca en `duenos` y, si no está, devuelve el de por defecto. Las claves y valores que ya devuelve la configuración (`owner`, `numero`, `wip-*`, `cadencia-retro`) no cambian, así `retro.ps1` sigue igual.

### D3. `-Issue` usa el tablero del dueño
Después de normalizar `-Issue` a URL (código actual), `tablero.ps1` llama a `Resolver-TableroDeIssue` y usa ese `owner`/`numero` en `project view`, `field-list`, `item-add` (también en la línea de `-Simular`) e `item-edit`. Con `-Entrada`, `proyecto`, `campos` y `tarjetas` siguen siendo los del tablero elegido (formato sin cambios).

### D4. `-Wip` suma todos los tableros (elegida por el usuario: contar los legibles y avisar)
Para cada Project de `tableros`: lee las tarjetas (`gh project item-list` o `-Entrada`). Si falla, imprime `Tablero <owner>/<numero> no disponible: <motivo>`, con el motivo pasado por la misma limpieza de `Formatear-ErrorGh` (sin rutas absolutas), y sigue con el siguiente. Si fallan todos, termina con 0 sin línea de cuenta (como hoy). Las tarjetas de la columna se juntan y se cuentan una vez por URL de issue (`content.url`; si falta, repo y número). Salida:
- Un solo Project configurado: igual que hoy (`  #<n> <título>`).
- Más de uno: cada tarjeta lleva el Project donde está: `  #<n> <título> (<owner>/<numero>)`.

Formato de `-Entrada` para `-Wip` con varios tableros: clave `tableros`, objeto cuyas claves son `<owner>/<numero>` y cuyos valores tienen `tarjetas` (mismo formato de hoy) o `error` (texto del error de `gh`). Si un Project configurado no está en `tableros`, cuenta como no disponible. Sin clave `tableros`, `tarjetas` es la del tablero por defecto (formato actual). Con `-Entrada` el script nunca llama a `gh`.

### D5. Métricas sobre todos los tableros
`metricas.ps1` recorre `tableros`: pide las páginas de cada Project con la misma consulta GraphQL y las normaliza filtrando los eventos por el `owner`/`numero` de ese Project. Después junta las tarjetas por `repo#numero`: si una aparece en dos Projects, queda una sola con los eventos de los dos, ordenados por fecha. El aviso de descartados se imprime una vez, con la suma de todos los tableros. Con un error de `gh` en un Project: avisa en una línea (`Tablero <owner>/<numero> no disponible: <motivo>`) y sigue con los otros. Si no se pudo leer ninguno, se comporta como hoy (no toca `metricas.md`).

Encabezado: un solo Project configurado y leído → `Tablero: <owner>/<numero>.` (igual que hoy); más de uno → `Tableros: <a>/<n>, <b>/<m>.` y, si alguno falló, `Sin leer: <c>/<k>.`.

`-Entrada`: igual que en D4, `tableros` con `paginas` o `error` por Project; sin `tableros`, `paginas` es la del tablero por defecto.

Para que `metricas.ps1` no pase el aviso de tamaño (500 líneas), la unión de tarjetas de varios Projects va como función en `tablero-comun.ps1`.

### D6. Reglas y guía
- `.claude/CLAUDE.md`, `### Tablero`: "Uno o más GitHub Projects de usuario configurados en `tablero.md` del vault: `owner` y `numero` son el tablero por defecto y cada línea `dueno-<dueño del repo>: <cuenta>/<número>` manda los repos de ese dueño a otro Project. `scripts/tablero.ps1` elige el tablero por el dueño del repo del issue, mueve las tarjetas y cuenta el WIP. Sin tablero configurado, el flujo sigue igual." `### WIP`: agregar "El WIP se suma entre todos los tableros: la capacidad es una sola." `### Métricas`: "...desde el historial de todos los tableros...".
- `docs/workflow.md`, paso 3: ejemplo con `dueno-org-ejemplo: otra-cuenta/2` (cuentas inventadas), explicación de la clave y que el WIP y las métricas suman todos los tableros. Reemplaza la viñeta "Si usás múltiples vaults... cada vault apunta a su propio Project" por una que diga que cada vault tiene su `tablero.md` y que dentro de un vault los repos de distintos dueños pueden ir a distintos Projects.

## Risks / Trade-offs

- [Un issue de la empresa ya está en el #4 y además en el #2] → el WIP y las métricas lo cuentan una vez (D4 y D5). La limpieza del #4 es manual (Migration Plan).
- [Más llamadas a `gh`: el WIP y las métricas leen cada Project] → con dos Projects, el control de WIP pasa de 1 a 2 llamadas; las métricas corren solo en el cierre. Aceptado.
- [Un Project inaccesible (sin red o sin permiso) da un WIP menor al real] → la línea de aviso nombra el Project, así el usuario sabe que la cuenta es parcial; el flujo no se frena (decisión del usuario).
- [Una clave `dueno-` mal escrita deja todo el tablero sin funcionar] → avisa `tablero.md inválido: <clave>` y no llama a `gh`, igual que las otras claves; el flujo sigue.
- [`retro.ps1 -Aviso` también lee `tablero.md`] → una clave `dueno-` inválida hace que imprima `tablero.md inválido: <clave>` en vez del aviso de retro; es coherente con el resto de las claves.

## Migration Plan

1. Merge y, en cada máquina, `git pull` del repo y `pwsh scripts/instalar.ps1` (por el cambio de `.claude/CLAUDE.md`). Los scripts se usan desde `$env:SDD_CONFIG_REPO`, así que toman el cambio con el pull.
2. En el vault del trabajo, sumar a `tablero.md` la línea `dueno-` del dueño de los repos de la empresa hacia el Project del trabajo (M01). El vault personal no cambia si no trabaja con esos repos.
3. Limpieza manual del tablero personal: listar las tarjetas de repos de la empresa que quedaron en el #4, sacarlas de ahí y, si falta alguna en el #2, moverla con `tablero.ps1 -Issue <url> -Columna <columna>`.
4. Rollback: borrar las líneas `dueno-` de `tablero.md` vuelve al comportamiento de un solo tablero sin revertir código.

## Impacto en proyectos existentes

- Skills y comandos: no cambian. Siguen pasando la URL del issue, y ahora la tarjeta cae en el tablero del dueño del repo.
- Un `tablero.md` sin claves `dueno-` (por ejemplo, el del vault personal) funciona igual que hoy.
- Los proyectos no tienen archivos que cambien: el efecto se ve en qué Project reciben las tarjetas de sus issues.
- `retro.ps1` no cambia, pero comparte el lector de `tablero.md` (ver Risks).

## Impacto en el sistema

**Componentes afectados:** las skills que llaman a `tablero.ps1` (`issue-creation`, `openspec-propose`, `odd-change`, `branch-pr`, `openspec-archive-change`, `retro`) y `metricas.ps1` (archive y `/odd:close`) sin cambios en sus llamadas; `scripts/retro.ps1`, que comparte `Leer-ConfigTablero`; `tablero.md` y `metricas.md` de cada vault; los GitHub Projects #2 (trabajo) y #4 (personal).

**Atributos de calidad:** mantenibilidad (alta): mejora. La lista de tableros y la elección por dueño están en un solo lugar (`tablero-comun.ps1`) y la usan los dos scripts; las salidas con un solo tablero no cambian. — Verificación: revisión del diff: `tablero.ps1` y `metricas.ps1` no leen claves `dueno-` ni arman la lista de tableros por su cuenta, y C01 a C03 siguen en verde sin cambios.

**Decisiones de arquitectura:** ADR nuevo: 0007.

**Deuda técnica:** agrega: unas líneas más en `.claude/CLAUDE.md` (ya registrada en #55). Descubre: `scripts/metricas.ps1` está cerca del aviso de tamaño (469 de 500 líneas). D5 lleva lo nuevo a `tablero-comun.ps1`, y si igual lo pasa, el verify lo informa como SUGGESTION. Hoy no es deuda nueva en la hoja de ruta.

## ADR

```markdown
# 0007. Un tablero por dueño del repo con WIP y métricas globales

Estado: aceptada
Fecha: 2026-11-19
Change: tablero-segun-dueno

## Contexto

El ADR 0006 dejó un GitHub Project de usuario por vault, configurado en `tablero.md`, con el WIP de la persona y no de cada repo. En la práctica, los repos de la empresa se siguen en un Project de la cuenta del trabajo, y los personales en otro, pero desde el mismo vault: las tarjetas de los repos de la empresa caían en el tablero personal. Un solo `owner`/`numero` no alcanza, y partir el WIP por tablero contradice el motivo del ADR 0006.

## Alternativas

- **Un `tablero.md` por dueño (varios archivos):** reparte los límites de WIP y la cadencia entre archivos y obliga a sumar a mano. Descartada.
- **Tabla en el cuerpo de `tablero.md`:** más legible en Obsidian, pero necesita un segundo lector y se rompe con ediciones a mano. Descartada.
- **Elegir el tablero por repo:** más configuración sin un caso que lo necesite; el dueño ya separa trabajo y personal. Descartada.
- **WIP por tablero:** dos capacidades para una sola persona; vuelve al problema que el ADR 0006 evitaba. Descartada.
- **Pasarle el tablero a `tablero.ps1` desde cada skill:** cambia todas las skills y sus comandos, y cada skill tendría que saber de tableros. Descartada.

## Decisión

`tablero.md` mantiene `owner` y `numero` como tablero por defecto y suma líneas `dueno-<dueño del repo>: <cuenta>/<número>`. Los scripts eligen el tablero por el dueño del repo del issue (de la URL o del remoto `origin`), sin parámetros nuevos para las skills. Los límites de WIP siguen siendo uno por columna y se comparan con la suma de todos los tableros. Las métricas y la retro siguen siendo globales: `metricas.ps1` junta todos los tableros en un solo `metricas.md`. Un issue que está en dos tableros cuenta una vez. Complementa al ADR 0006, que sigue vigente.

## Consecuencias

- Positivas: cada tarjeta cae en el tablero de su dueño sin tocar las skills; una sola capacidad de WIP y un solo `metricas.md`; un `tablero.md` viejo sigue funcionando.
- Negativas: el control de WIP y las métricas hacen una lectura de `gh` por tablero; si un tablero no se puede leer, el WIP es parcial (se avisa); la cuenta activa de `gh` necesita acceso a todos los Projects configurados.
```

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/tablero-segun-dueno.Tests.ps1` | `tests/` |
| `docs/adr/0007-un-tablero-por-dueno-del-repo.md` | `docs/` (implícita) |

Archivos modificados: `scripts/tablero-comun.ps1`, `scripts/tablero.ps1`, `scripts/metricas.ps1` (`scripts/`); `.claude/CLAUDE.md` (`.claude/`, implícita); `docs/workflow.md` y `docs/arquitectura/vision.md` (`docs/`).

## Security Layer

`project_type: tooling`. No toca datos personales: `## Datos` declara las tarjetas e issues como `interno`.

- Sin secretos: `tablero.md` y los ejemplos solo tienen nombres de cuenta y números de Project; ningún token ni credencial en el código, los tests ni la documentación. — Verificación: revisión del diff: sin tokens, `ghp_`, `github_pat_` ni passwords en las líneas agregadas.
- Sin rutas absolutas en los avisos: el aviso de un tablero que no se puede leer pasa por la limpieza de `Formatear-ErrorGh`. — Verificación: S10 y S15 (el error de prueba trae una ruta `C:\...` y la salida no la tiene).
- Documentación sin cuentas reales: `docs/workflow.md` usa cuentas inventadas. — Verificación: S12.
- Inputs externos validados: el valor de cada clave `dueno-` se valida antes de usarlo, y el dueño se toma de una URL ya validada por el patrón de issue de GitHub. — Verificación: S03 y S04 a S06.
- Errores que no frenan el flujo: un tablero que falla avisa y el script termina con 0 (WIP y métricas). — Verificación: S10 y S15.
- Instrucciones para IA (`.claude/CLAUDE.md`) sin secretos ni rutas absolutas. — Verificación: revisión del diff: el texto nuevo de `## Scrumban` no tiene rutas ni cuentas reales.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se corre la suite completa porque `tablero-comun.ps1` lo usan `tablero.ps1`, `metricas.ps1` y `retro.ps1`. Cada test nuevo lleva el marcador `test-plan: tablero-segun-dueno/<ID>` en un comentario. Los tests usan `-Config` con un `tablero.md` temporal, `-Entrada` con JSON inventado y `-Simular`. No llaman a `gh` real y usan cuentas inventadas (`cuenta-a`, `org-b`, `cuenta-c`).

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Configuración del tablero en el vault / Configuración con un tablero por dueño | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S02 | Configuración del tablero en el vault / Formato anterior | auto (además de C01 a C03 sin cambios) | `tests/tablero-segun-dueno.Tests.ps1` |
| S03 | Configuración del tablero en el vault / Dato inválido: tablero de un dueño mal escrito | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S04 | Mover la tarjeta de un issue / Issue de un dueño con tablero propio | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S05 | Mover la tarjeta de un issue / Issue por número de un dueño con tablero propio | auto (repo git temporal con remoto `origin` SSH) | `tests/tablero-segun-dueno.Tests.ps1` |
| S06 | Mover la tarjeta de un issue / Issue de un dueño sin tablero propio | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S07 | Control de WIP de una columna / Columna llena sumando dos tableros | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S08 | Control de WIP de una columna / Suma con lugar | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S09 | Control de WIP de una columna / Dato inválido: el mismo issue en dos tableros | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S10 | Control de WIP de una columna / Dato inválido: un tablero que no se puede leer | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S11 | Scrumban en las reglas globales / Varios tableros en las reglas | auto (lee `.claude/CLAUDE.md`) | `tests/tablero-segun-dueno.Tests.ps1` |
| S12 | Guía de configuración del tablero / Guía con un tablero por dueño | auto (lee `docs/workflow.md`: `dueno-`, WIP y métricas suman, sin las cuentas reales del usuario) | `tests/tablero-segun-dueno.Tests.ps1` |
| S13 | Historial del tablero para las métricas / Métricas de dos tableros | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S14 | Historial del tablero para las métricas / Dato inválido: el mismo issue en dos tableros | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| S15 | Archivo de métricas en el vault / Dato inválido: un tablero que no se puede leer | auto | `tests/tablero-segun-dueno.Tests.ps1` |
| `tablero-scrumban/S01` | Configuración del tablero en el vault / Configuración válida | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `cadencias-scrumban/S01` | Configuración del tablero en el vault / Configuración con cadencia de retro | auto (existente, C03) | `tests/cadencias-scrumban.Tests.ps1` |
| `tablero-scrumban/S02` | Configuración del tablero en el vault / Sin tablero configurado | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `tablero-scrumban/S03` | Configuración del tablero en el vault / Dato inválido: número o límite mal escrito | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `cadencias-scrumban/S02` | Configuración del tablero en el vault / Dato inválido: cadencia mal escrita | auto (existente, C03) | `tests/cadencias-scrumban.Tests.ps1` |
| `tablero-scrumban/S04` a `S08` | Mover la tarjeta de un issue / Issue nuevo, cambia de columna, columna desconocida, sin permiso o sin gh, Project sin la opción | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `odd-tablero-issue-por-numero/S22` y `S23` | Mover la tarjeta de un issue / Issue por número; Dato inválido: issue que no es URL ni número | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `tablero-scrumban/S09` a `S12` | Control de WIP de una columna / Columna llena, con lugar, sin límite, tarjetas sin Status o sin título | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `tablero-scrumban/S16` | Scrumban en las reglas globales / Sección Scrumban | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `tablero-scrumban/S17` | Guía de configuración del tablero / Guía completa | auto (existente, C01) | `tests/tablero-scrumban.Tests.ps1` |
| `metricas-de-flujo/S01` a `S03` | Historial del tablero para las métricas / Eventos de otros Projects, más de una página, evento o fecha incompletos | auto (existente, C02) | `tests/metricas-de-flujo.Tests.ps1` |
| `metricas-de-flujo/S08` a `S10` | Archivo de métricas en el vault / Archivo generado, período sin issues cerrados, sin tablero o sin gh | auto (existente, C02) | `tests/metricas-de-flujo.Tests.ps1` |
| M01 | Configuración real en el vault del trabajo (WIP sumado y métricas de los dos tableros) | manual: (lo corre el usuario) ver tarea 7.2 | — |
| M02 | Verificar que el cambio aplica en un proyecto de prueba | manual: (lo corre el usuario) ver tarea 7.3 | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `tests/tablero-scrumban.Tests.ps1` (con `scripts/tablero.ps1` y `scripts/tablero-comun.ps1`) | Un solo tablero: lectura y validación de `tablero.md`, mover tarjetas, formato de la salida del WIP (`  #<n> <título>`), `-Comprobar`, issue por número | Ninguno: con un solo tablero la salida no cambia. El tablero por dueño lo cubren S01 a S10 |
| C02 | `tests/metricas-de-flujo.Tests.ps1` (con `scripts/metricas.ps1`) | Métricas de un solo tablero, filtro de eventos por Project, encabezado `Tablero: <owner>/<numero>.`, formato de `-Entrada` con `paginas` | Ninguno: con un solo tablero el archivo no cambia. Varios tableros: S13 a S15 |
| C03 | `tests/cadencias-scrumban.Tests.ps1` (con `scripts/retro.ps1`) | `cadencia-retro` leída con `Leer-ConfigTablero` y su validación | Ninguno |

## Open Questions

(ninguna)
