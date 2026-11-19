Issue: #81

# Proposal

## Why

`tablero.md` declara un solo tablero (`owner` y `numero`), así que todas las tarjetas van al mismo GitHub Project. Los repos de la empresa (`Toyota-Yacopini/*`) se siguen en otro Project ("Tablero Scrumban - Trabajo", #2 de otra cuenta), pero `openspec-propose`, `branch-pr`, `openspec-archive-change`, `/odd` y `/odd:close` agregan y mueven sus tarjetas en el tablero personal (#4). Hay que elegir el tablero según el dueño del repo sin perder lo que el ADR 0006 cuidaba: un solo WIP de la persona y métricas y retro globales.

## What Changes

- `tablero.md` admite claves `dueno-<dueño del repo>: <cuenta del Project>/<número>` en el frontmatter. `owner` y `numero` pasan a ser el tablero por defecto para los dueños que no figuran. Un `tablero.md` sin claves `dueno-` funciona igual que hoy.
- `scripts/tablero.ps1 -Issue` elige el tablero por el dueño del repo del issue: lo toma de la URL, o del remoto `origin` cuando recibe solo el número. Las skills siguen llamando igual.
- `scripts/tablero.ps1 -Wip` suma las tarjetas de la columna en todos los tableros configurados (una sola capacidad) y cuenta una sola vez un issue que está en dos tableros. Si un tablero no se puede leer, cuenta los demás y avisa cuál falló.
- `scripts/metricas.ps1` calcula sobre todos los tableros y escribe un solo `metricas.md`. La retro sigue siendo global (no cambia).
- `.claude/CLAUDE.md` (sección `## Scrumban` / `### Tablero` y `### WIP`) y `docs/workflow.md` hablan de varios tableros elegidos por dueño del repo.
- ADR 0007: un tablero por dueño del repo con WIP y métricas globales (complementa al ADR 0006).

Archivo global que se modifica: `.claude/CLAUDE.md`, para que las reglas digan que `tablero.md` puede declarar un tablero por dueño del repo y que el WIP se suma entre todos.

## Capabilities

### New Capabilities

(ninguna)

### Modified Capabilities

- `scrumban-board`: la configuración admite un tablero por dueño del repo; mover una tarjeta usa el tablero del dueño del issue; el WIP y las métricas suman todos los tableros; las reglas globales y la guía describen varios tableros.

## Non-goals

- No cambia cómo llaman las skills a `tablero.ps1` ni a `metricas.ps1` (no hay parámetros nuevos).
- No mueve ni borra tarjetas que hoy están en el tablero equivocado: la limpieza del #4 es manual (ver Migration Plan en el design).
- No hay límites de WIP por tablero: los límites siguen siendo globales.
- No cambia `scripts/retro.ps1` ni la skill `/retro`: la cadencia sigue en `tablero.md` y la retro es una sola.
- No resuelve el bug #77: ya lo resolvió el ODD `tablero-issue-por-numero` (PR #78) y el issue se cerró.
- No crea Projects ni da permisos en GitHub.

## Impact

- Código: `scripts/tablero-comun.ps1`, `scripts/tablero.ps1`, `scripts/metricas.ps1`.
- Tests: `tests/tablero-segun-dueno.Tests.ps1` (nuevo). `tests/tablero-scrumban.Tests.ps1` y `tests/metricas-de-flujo.Tests.ps1` no cambian y sirven de caracterización.
- Documentación: `.claude/CLAUDE.md`, `docs/workflow.md`, `docs/adr/0007-...md` (nuevo) y `docs/arquitectura/vision.md`.
- Vault: `tablero.md` de cada vault que trabaje con repos de varios dueños suma sus líneas `dueno-` (lo hace el usuario).
- Datos externos: tarjetas e historial de GitHub Projects, ahora de más de un Project.
- Sin dependencias nuevas.
