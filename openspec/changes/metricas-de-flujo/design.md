# Design

## Context

El tablero Scrumban (`tablero-scrumban`, ADR 0006) es un GitHub Project de usuario configurado en `tablero.md` del vault (`owner`, `numero` y límites de WIP), y `scripts/tablero.ps1` mueve las tarjetas. GitHub guarda en la línea de tiempo de cada issue un evento `ProjectV2ItemStatusChangedEvent` por cada cambio de columna, con fecha, columna nueva y el Project donde pasó. Se comprobó el 16/11/2026 que una sola consulta GraphQL sobre los items del Project trae, para cada issue, su repo, número, título, `createdAt`, `closedAt` y esos eventos. El historial de un issue incluye eventos de otros Projects (por ejemplo, los Projects #1 a #3 cerrados ese día), por eso hay que filtrar por el Project configurado.

`scripts/tablero.ps1` tiene 477 líneas (aviso de `tamaño` en 500). Sus funciones `Leer-ConfigTablero`, `Formatear-ErrorGh` e `Invocar-Gh` también las necesita el script de métricas.

## Goals / Non-Goals

**Goals:**
- Lead time, cycle time, throughput, tiempo por columna y trabajo en curso, calculados desde GitHub sin datos cargados a mano.
- Un archivo `metricas.md` en el vault con todo el tablero, actualizado solo en cada cierre.
- Que el cierre no se frene nunca por las métricas.

**Non-Goals:**
- Gráficos, pronósticos y métricas por repo.
- Cadencias (#70).

## Decisions

### D1. Funciones compartidas en `scripts/tablero-comun.ps1`

`Leer-ConfigTablero`, `Formatear-ErrorGh` e `Invocar-Gh` se mueven sin cambios de comportamiento de `scripts/tablero.ps1` a `scripts/tablero-comun.ps1` (archivo nuevo, UTF-8 sin BOM, sin código que se ejecute al cargarse). `scripts/tablero.ps1` y `scripts/metricas.ps1` lo cargan con `. "$PSScriptRoot/tablero-comun.ps1"`. Así no se duplica la lectura de `tablero.md` ni la llamada a `gh` (mantenibilidad alta) y `tablero.ps1` baja del umbral de aviso. Se descartó `scripts/comun.ps1` porque es del instalador y la generación de plantillas, y mezclaría responsabilidades.

### D2. `scripts/metricas.ps1`: parámetros y lectura

Parámetros: `-Semanas <n>` (entero mayor que 0, por defecto 4), `-Ahora <fecha ISO 8601>` (por defecto la fecha y hora UTC de la corrida; para tests), `-Config <ruta>` (como en `tablero.ps1`), `-Salida <ruta>` (por defecto `$env:OBSIDIAN_VAULT/metricas.md`) y `-Entrada <archivo.json>` (no llama a `gh`). `-Semanas` o `-Ahora` inválidos: mensaje y código 1 (error de uso, como la columna desconocida de `tablero.ps1`).

Lectura con `Invocar-Gh` y los argumentos `api graphql -f query=<consulta> -F owner=<owner> -F numero=<numero> -F cursor=<cursor>` (el cursor solo desde la segunda página). La consulta usa `repositoryOwner(login: $owner) { ... on ProjectV2Owner { projectV2(number: $numero) { items(first: 100, after: $cursor) { pageInfo { hasNextPage endCursor } nodes { content { ... on Issue { number title createdAt closedAt repository { nameWithOwner } timelineItems(first: 100, itemTypes: [PROJECT_V2_ITEM_STATUS_CHANGED_EVENT]) { nodes { ... on ProjectV2ItemStatusChangedEvent { createdAt status project { number owner { ... on User { login } ... on Organization { login } } } } } } } } } } } } }`, para que sirva con Projects de usuario y de organización. Repite mientras `hasNextPage` sea verdadero. Los items que no son issues (borradores, PRs) se ignoran.

Formato de `-Entrada`: un JSON con la clave `paginas`, una lista de respuestas tal como las devuelve `gh api graphql` (cada una con `data.repositoryOwner.projectV2.items`).

### D3. Normalización y datos inválidos

Función pura `Normalizar-Tarjetas` (respuestas → lista de tarjetas `{ repo, numero, titulo, creado, cerrado, eventos[] }`):
- Se descartan las tarjetas sin `number` o sin `createdAt`, y las que tienen `closedAt` anterior a `createdAt`.
- Se descartan los eventos sin `status` o sin `createdAt`, y los de otro Project (`project.number` distinto de `numero` o `project.owner.login` distinto de `owner`, sin distinguir mayúsculas).
- Los eventos quedan ordenados por fecha.
- La consola imprime `Descartados por datos incompletos: <n> tarjetas y <m> eventos.` solo si alguno es mayor que 0.

### D4. Cálculo

Funciones puras, con `Ahora` y la lista de tarjetas como entrada:
- Período: desde `Ahora - 7 × Semanas días` hasta `Ahora`. Un issue es "cerrado en el período" si su `closedAt` cae adentro.
- **Lead time:** `closedAt - createdAt`.
- **Cycle time:** `closedAt - <fecha del primer evento a "Diseño" o "Construcción">`. Si no hay ese evento, el issue no entra en el cycle time y se cuenta como "sin cycle time".
- **Throughput:** una fila por semana del período, de la más vieja a la más nueva; la semana *k* va de `inicio + 7(k-1)` a `inicio + 7k` días. Muestra la fecha de inicio (`dd/MM`) y la cantidad de cerrados.
- **Tiempo por columna:** para cada issue cerrado en el período, la duración de cada tramo entre un evento y el siguiente (el último tramo termina en `closedAt`) se suma a la columna de ese evento. Se muestra el promedio por columna sobre los issues que pasaron por ella, en el orden Backlog, Listo, Diseño, Construcción, Revisión y Hecho, salteando las columnas sin datos.
- **Trabajo en curso:** las tarjetas abiertas cuya columna actual (la del último evento) es Diseño, Construcción o Revisión, con `Ahora - <fecha del último evento>`.
- Promedio y mediana sobre los valores disponibles; días con un decimal y coma decimal (`7,0`). Sin valores, se muestra `—`.

### D5. Formato de `metricas.md`

Escrito en UTF-8 sin BOM, finales de línea LF, sin rutas absolutas:

- Línea 1: `<!-- Generado con scripts/metricas.ps1 desde el tablero de GitHub. No editar a mano. -->`
- `# Métricas de flujo`
- `Generado el <dd/MM/yyyy>. Período: <dd/MM/yyyy> a <dd/MM/yyyy> (<n> semanas). Tablero: <owner>/<numero>.`
- `## Resumen`: tabla `Métrica | Promedio | Mediana | Issues` con las filas `Lead time (días)` y `Cycle time (días)`, y debajo `Cerrados en el período: <n>. Sin cycle time (no pasaron por Diseño ni Construcción): <m>.` Sin cerrados: `Sin issues cerrados en el período.`
- `## Throughput`: tabla `Semana desde | Cerrados`.
- `## Tiempo por columna`: tabla `Columna | Promedio (días) | Issues`. Sin datos: `Sin datos en el período.`
- `## Trabajo en curso`: tabla `Issue | Título | Columna | Días en la columna`, ordenada por días de mayor a menor. Sin tarjetas: `Sin trabajo en curso.`
- `## Issues cerrados`: tabla `Issue | Título | Lead time | Cycle time`, ordenada por fecha de cierre. Sin cerrados: `Sin issues cerrados en el período.`

El issue se escribe `<repo>#<numero>` (por ejemplo `Lautaro-Montecchiani/sdd-global-config#66`). En los títulos, `|` se escapa y los saltos de línea pasan a espacio, igual que en `generar-backlog.ps1`.

### D6. Fallas

Sin configuración (`Leer-ConfigTablero`): su mensaje y código 0. Error de `gh` (no instalado, sin red, sin permiso, Project inexistente): `Formatear-ErrorGh` (una línea, sin rutas) y código 0. En los dos casos `metricas.md` no se crea ni se modifica. Al escribir bien: `Métricas generadas: metricas.md (<n> cerrados en <s> semanas).` y código 0.

### D7. Recálculo en el cierre

- `skills/openspec-archive-change/SKILL.md`, fase del vault: paso nuevo **e2. Métricas de flujo**, entre `e` (arquitectura.md) y `f` (sync del vault): `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\metricas.ps1"`. Texto: "Sin `SDD_CONFIG_REPO`, saltear este paso y decirlo en el resumen. Un aviso del script no frena el cierre." La salida del cierre suma la línea `- Métricas: metricas.md actualizado / <aviso>`.
- `skills/odd-change/SKILL.md`, `/odd:close`: el mismo paso como **5b**, entre `5` (context.md) y `6` (commit y push del vault).
- Se regeneran `.claude/commands/opsx/archive.md` y `.claude/commands/odd/close.md` con `scripts/generar-plantillas.ps1`.

### D8. Reglas, guía y ficha

- `.claude/CLAUDE.md`, sección `## Scrumban`: subsección nueva `### Métricas` después de `### WIP`: "`scripts/metricas.ps1` calcula desde el historial del tablero el lead time (creación a cierre), el cycle time (primera entrada a Diseño o Construcción a cierre), el throughput (cerrados por semana), el tiempo por columna y el trabajo en curso, y escribe `metricas.md` en el vault. Se recalcula en el cierre del archive y en `/odd:close`; a mano: `pwsh $env:SDD_CONFIG_REPO\scripts\metricas.ps1 [-Semanas <n>]`." En `### Estructura del vault`, debajo de `tablero.md`: `metricas.md  ← métricas de flujo del tablero (generado por scripts/metricas.ps1)`.
- `docs/workflow.md`, sección `## Tablero Scrumban`: subsección `### Métricas de flujo` con qué mide cada una, el comando a mano, `-Semanas` y que se recalcula sola en el cierre.
- `openspec/config.yaml`, `## Datos`: la línea de tarjetas pasa a `- tarjetas del tablero (issue, columna, fechas de cambio de columna, creación y cierre): GitHub Project de usuario (externo) | interno`.

## Impacto en proyectos existentes

Retrocompatible. `tablero.ps1` mantiene parámetros, mensajes y códigos (lo fija C01). Los proyectos no cambian sus archivos; el recálculo en el cierre llega con `instalar.ps1`. Sin tablero configurado, el paso de métricas imprime una línea y el cierre sigue igual.

## Impacto en el sistema

**Componentes afectados:** `scripts/` (dos scripts nuevos y `tablero.ps1` refactorizado), dos skills y sus comandos generados, `.claude/CLAUDE.md` (y su espejo), el vault (archivo nuevo `metricas.md`) y la integración con GitHub, que suma la API GraphQL a través de `gh api graphql` sobre el mismo Project.

**Atributos de calidad:**
- mantenibilidad (alta): la configuración y la llamada a `gh` quedan en un solo lugar (`tablero-comun.ps1`) y los comandos siguen generados desde las skills. — Verificación: C01 (tests del tablero sin cambios en verde), S12 (comandos regenerados sin diferencias) y revisión del diff: `metricas.ps1` no redefine `Leer-ConfigTablero`, `Formatear-ErrorGh` ni `Invocar-Gh`.

**Decisiones de arquitectura:** ninguna. Es la misma integración del ADR 0006 (GitHub Projects con `gh`), sin tecnología, nivel ni patrón nuevos.

**Deuda técnica:**
- paga: `scripts/tablero.ps1` cerca del aviso de `tamaño` (sin issue).
- agrega: `.claude/CLAUDE.md` suma unas líneas (#55).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `scripts/metricas.ps1` | `scripts/` |
| `scripts/tablero-comun.ps1` | `scripts/` |
| `tests/metricas-de-flujo.Tests.ps1` | `tests/` |

## Security Layer

Tipo `tooling`:
- Sin secretos ni rutas absolutas en scripts, skills, reglas, guía y `metricas.md`. — Verificación: S08 (archivo sin rutas) y revisión del diff: buscar `C:\Users`, `D:\`, `GH_TOKEN`, `ghp_` y `gho_` en las líneas agregadas fuera de `openspec/`.
- El token de `gh` no se lee ni se imprime; los argumentos de `gh` van como lista (`ArgumentList`) por `Invocar-Gh`. — Verificación: revisión del diff: `metricas.ps1` no usa `gh auth token`, `GH_TOKEN`, `Invoke-Expression` ni arma la línea de `gh` concatenando strings.
- Entradas externas validadas antes de usarlas (JSON de GitHub). — Verificación: S03.
- Errores sin salida cruda de `gh` y nunca con código distinto de 0 en el cierre. — Verificación: S10.
- Cambios a skills y al `CLAUDE.md` global en commits separados. — Verificación: revisión del diff: un commit con `.claude/CLAUDE.md` solo.

No hay datos personales: las tarjetas tienen repo, número, título, columnas y fechas de issues (interno).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian `tablero.ps1` y skills que generan comandos. Cada test lleva `# test-plan: metricas-de-flujo/<ID>` arriba del `Probar`. Los tests de `metricas.ps1` usan `-Config` con un `tablero.md` temporal (`owner: dueno-prueba`, `numero: 7`), `-Entrada` con JSON inventado, `-Ahora 2026-03-30T12:00:00Z` y `-Salida` en una carpeta temporal; ninguno llama a GitHub salvo S10, que corre sin `-Entrada` con un `PATH` sin `gh`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Historial del tablero para las métricas / Eventos de otros Projects | auto: un issue con eventos a `Diseño` en el Project 7 de `dueno-prueba` y a `In progress` en el Project 3 y en el Project 7 de otro dueño: el cycle time usa solo el del Project 7 de `dueno-prueba` | `tests/metricas-de-flujo.Tests.ps1` |
| S02 | Historial del tablero para las métricas / Más de una página de tarjetas | auto: `-Entrada` con dos páginas (la primera con `hasNextPage: true`): los issues de las dos aparecen en `## Issues cerrados` | `tests/metricas-de-flujo.Tests.ps1` |
| S03 | Historial del tablero para las métricas / Dato inválido: evento o fecha incompletos | auto: una tarjeta sin `number`, otra con `closedAt` anterior a `createdAt` y un evento sin `status`: consola `Descartados por datos incompletos: 2 tarjetas y 1 eventos.` y ninguno en el archivo | `tests/metricas-de-flujo.Tests.ps1` |
| S04 | Cálculo de las métricas de flujo / Lead time y cycle time | auto: creado el 20/03, a Diseño el 22/03, cerrado el 27/03 (a las 12:00): fila con `7,0` y `5,0` en `## Issues cerrados` | `tests/metricas-de-flujo.Tests.ps1` |
| S05 | Cálculo de las métricas de flujo / Issue cerrado sin pasar por el flujo | auto: un issue cerrado solo con evento a `Backlog`: lead time presente, cycle time `—` y `Sin cycle time (no pasaron por Diseño ni Construcción): 1.` | `tests/metricas-de-flujo.Tests.ps1` |
| S06 | Cálculo de las métricas de flujo / Throughput por semana | auto: `-Semanas 2`, tres cerrados en la primera semana y ninguno en la segunda: dos filas con `3` y `0`, la más vieja primero | `tests/metricas-de-flujo.Tests.ps1` |
| S07 | Cálculo de las métricas de flujo / Trabajo en curso | auto: tarjeta abierta con último evento a `Construcción` el 26/03 12:00: fila con `Construcción` y `4,0` | `tests/metricas-de-flujo.Tests.ps1` |
| S08 | Archivo de métricas en el vault / Archivo generado | auto: sin BOM, primera línea igual al comentario de D5, las cinco secciones en orden y sin la ruta de la carpeta temporal | `tests/metricas-de-flujo.Tests.ps1` |
| S09 | Archivo de métricas en el vault / Período sin issues cerrados | auto: sin cerrados en el período: `Sin issues cerrados en el período.` en `## Resumen` y en `## Issues cerrados`, y las filas de throughput en `0` | `tests/metricas-de-flujo.Tests.ps1` |
| S10 | Archivo de métricas en el vault / Sin tablero o sin gh | auto: `-Config` a un archivo inexistente, y sin `-Entrada` con `PATH` sin `gh`: una línea con el motivo, código 0 y `-Salida` con el contenido previo intacto | `tests/metricas-de-flujo.Tests.ps1` |
| S11 | Métricas recalculadas en el cierre / Paso en el cierre | auto: las dos skills tienen `metricas.ps1` antes del sync del vault (posición de `e2.` antes de `f.` y de `5b.` antes de `6.`) y la frase "Un aviso del script no frena el cierre." | `tests/metricas-de-flujo.Tests.ps1` |
| S12 | Métricas recalculadas en el cierre / Paso en el cierre (comandos) | auto: `.claude/commands/opsx/archive.md` y `.claude/commands/odd/close.md` contienen `metricas.ps1` y `pwsh scripts/generar-plantillas.ps1 -Comprobar` termina con 0 | `tests/metricas-de-flujo.Tests.ps1` |
| S13 | Métricas en las reglas y la guía / Reglas y guía | auto: `.claude/CLAUDE.md` tiene `### Métricas` con las cinco métricas y `metricas.ps1`, y `metricas.md` en la estructura del vault; `docs/workflow.md` tiene `### Métricas de flujo` con las cinco y el comando | `tests/metricas-de-flujo.Tests.ps1` |
| M01 | Métricas reales | manual (lo hace Claude en el verify): `pwsh scripts/metricas.ps1` con el tablero real; `metricas.md` en el vault muestra el #66 en `## Issues cerrados` y el trabajo en curso coincide con el tablero | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/tablero.ps1` | `tests/tablero-scrumban.Tests.ps1` completo en verde (S01 a S21): parámetros, mensajes y códigos de `tablero.ps1` | Ninguno: las funciones se mudan a `tablero-comun.ps1` sin cambiar el comportamiento |
| C02 | `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md` y sus comandos | Suite actual en verde (incluye `tablero-scrumban`, `backlog-desde-issues`, `srs-en-rama-del-change`, `generar-comandos` y `generar-plantillas`) | Se agrega un paso sin renumerar los existentes; lo nuevo lo cubren S11 y S12 |

## Open Questions

- Ninguna bloqueante. Si un issue tiene más de 100 eventos de cambio de columna, solo se leen los primeros 100 (límite de la consulta); no es esperable con este flujo.
