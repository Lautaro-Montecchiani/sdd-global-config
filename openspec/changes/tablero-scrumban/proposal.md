Issue: #66

## Why

El workflow ya cumple buena parte de Scrumban: el backlog son los issues (ADR 0004), las historias son los proposals con escenarios WHEN/THEN y el verify con la puerta de integración funciona como "terminado". Pero las etapas del flujo no se ven juntas en ningún lado, no hay límite de trabajo en curso (WIP) y las condiciones de "listo para empezar" (DoR) y "terminado" (DoD) se cumplen sin estar escritas como tales. Con un equipo de una persona (usuario + Claude + Agente) trabajando en varios proyectos a la vez, el riesgo es abrir changes en paralelo y que queden a medio terminar.

## What Changes

- Tablero Scrumban en **GitHub Projects de usuario**, con un campo `Status` de 6 columnas: Backlog, Listo, Diseño, Construcción, Revisión y Hecho. Junta los issues de todos los repos y no duplica datos: las tarjetas son los mismos issues.
- Configuración del tablero en el vault: `$vault/tablero.md` con el dueño y el número del Project y los límites de WIP (Diseño 1, Construcción 2, Revisión 2). Cada vault (personal o del trabajo) apunta a su propio tablero.
- Script nuevo `scripts/tablero.ps1` que mueve la tarjeta de un issue a una columna (la agrega al Project si no está) y cuenta las tarjetas de una columna para el control de WIP. Sin configuración, sin `gh`, sin red o sin permiso `project`, avisa en una línea y termina con 0 sin frenar el flujo.
- Las skills mueven las tarjetas en cada paso: `issue-creation` (Backlog), `openspec-propose` (Diseño al empezar, Construcción en el handoff), `odd-change` en `/odd` (Construcción) y en `/odd:close` (Hecho), `branch-pr` (Revisión) y `openspec-archive-change` en la fase del vault (Hecho). Los comandos de `.claude/commands/` se regeneran desde las skills.
- Control de WIP en `openspec-propose` (columna Diseño) y en `/odd` (columna Construcción): si la columna está llena, Claude muestra las tarjetas que la ocupan y pregunta "Seguir igual" o "Frenar".
- Sección nueva `## Scrumban` en `.claude/CLAUDE.md` con los roles (usuario = Product Owner y Scrum Master; Claude y el Agente = Developers), las columnas y qué paso del flujo mueve cada una, la regla de WIP, la **Definition of Ready** y la **Definition of Done**.
- Guía de configuración en `docs/workflow.md`: crear el Project de usuario, las opciones de `Status`, el permiso `gh auth refresh -s project`, el `tablero.md` del vault y cómo instalar la página como app de escritorio.
- ADR 0006: tablero en GitHub Projects de usuario como vista del backlog, que complementa al ADR 0004 (los issues siguen siendo la fuente única).

## Capabilities

### New Capabilities
- `scrumban-board`: tablero Scrumban sobre GitHub Projects de usuario, su configuración en el vault, el script que mueve tarjetas y cuenta el WIP, los movimientos de cada skill del flujo, el control de WIP y la DoR/DoD en las reglas globales.

### Modified Capabilities
(ninguna: los requirements de `product-backlog` no cambian; el tablero es una vista nueva sobre los mismos issues)

## Non-goals

- Métricas de flujo (lead time, cycle time, throughput): issue aparte.
- Cadencias (`/retro` con Start/Stop/Continue y review periódica): issue aparte.
- Estimación con story points o Planning Poker: no se adopta; Scrumban mide flujo.
- Mover tarjetas desde el Agente: las reglas de ejecución y las plantillas del Agente no cambian. La columna Construcción la marca Claude en el handoff.
- Crear el Project de GitHub por script: se crea a mano una vez, siguiendo la guía.
- Volver a Construcción cuando el verify encuentra CRITICAL: la tarjeta queda en Revisión hasta el merge.

## Impact

- Archivos globales modificados y por qué:
  - `.claude/CLAUDE.md`: sección `## Scrumban` con roles, columnas, WIP, DoR y DoD; el vault suma `tablero.md` en `### Estructura del vault`. Se espeja en el vault con `instalar.ps1`.
  - `skills/issue-creation`, `skills/openspec-propose`, `skills/odd-change`, `skills/branch-pr` y `skills/openspec-archive-change`: paso de mover la tarjeta y control de WIP. Se regeneran sus comandos en `.claude/commands/`.
- Código nuevo: `scripts/tablero.ps1` y `tests/tablero-scrumban.Tests.ps1`.
- Documentación: `docs/workflow.md`, `docs/adr/0006-…`, `docs/arquitectura/vision.md`.
- `openspec/config.yaml`: `## Stack` suma GitHub Projects a las integraciones y `## Datos` suma las tarjetas del tablero.
- Dependencia de entorno: el token de `gh` necesita el permiso `project`. Sin él, el flujo avisa y sigue igual que hoy.
- Proyectos existentes: no cambian sus archivos. Toman el comportamiento al correr `instalar.ps1`; sin `tablero.md` en el vault, todo sigue como hoy.
