Issue: #70

# Proposal

## Why

El workflow ya tiene tablero, WIP y métricas de flujo (`tablero-scrumban` y `metricas-de-flujo`), pero le falta el momento de inspección y adaptación: nadie mira cada tanto lo terminado ni cómo estamos trabajando los tres (usuario, Claude y Agente). Los errores repetidos del Agente, los pasos que traban y los changes que quedan grandes se ven una vez y se pierden. Sin una cadencia con aviso, la retro no pasa.

## What Changes

- Skill nueva **`/retro`** (`skills/retro/SKILL.md`): una sola retro **global** para todo el vault, de 15 minutos, que empieza con la **review** (lo terminado en el período, tomado de las notas `archive\` de todos los proyectos y de `metricas.md`, más la opinión de quien usa el sistema) y sigue con las 5 fases de Derby y Larsen y la dinámica **Start / Stop / Continue**. Cada acción SMART acordada sale como un issue con prioridad y tipo, que entra al Backlog del tablero.
- Nota de cada retro en **`$vault/retros/AAAA-MM-DD.md`**, con la review, Start / Stop / Continue, las acciones con su issue y el cierre. La retro siguiente revisa el estado de las acciones de la anterior.
- Script nuevo **`scripts/retro.ps1`**: `-Aviso` (al iniciar sesión, una línea si venció la cadencia) y `-Periodo` (desde cuándo cuenta la review y qué se archivó en ese período).
- Clave nueva **`cadencia-retro`** (días, entero positivo) en `tablero.md` del vault, validada en `Leer-ConfigTablero` de `scripts/tablero-comun.ps1`. Sin la clave no hay aviso. La cadencia acordada es semanal (`cadencia-retro: 7`).
- **Archivo global modificado: `.claude/CLAUDE.md`**: paso nuevo en `## Al iniciar cada sesión` (aviso de retro vencida), `### Cadencias` en `## Scrumban`, `retros\` en `### Estructura del vault` y la fila de `/retro` en `### Cuándo actuar`. Se modifica porque el aviso al iniciar sesión y la cadencia son reglas que Claude tiene que seguir en todos los proyectos.
- `docs/workflow.md`: la clave `cadencia-retro` y cómo se hace la retro, en la guía del tablero.

## Non-goals

- Una retro por proyecto, o una review separada de la retro (decisión del usuario del 17/11: una sola, global, con la review adentro).
- Programar la retro en un calendario o con una tarea programada: el aviso es al iniciar sesión.
- Evaluar personas: la retro mira el proceso (directiva primaria de Kerth).
- Que la retro apruebe los issues que crea: quedan sin `status:approved` y en Backlog; los aprueba el usuario como Product Owner.
- Un comando generado en `.claude/commands/`: `/retro` es una skill, como `/ficha` y `/arquitectura`.
- Cambiar `metricas.ps1`: la retro lo usa tal como está.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `scrumban-board`: la configuración del tablero suma `cadencia-retro`; se agregan el aviso de cadencia, el período de la retro, la skill `/retro` con la review y Start / Stop / Continue, las acciones como issues, la nota en el vault y las cadencias en las reglas y la guía.

## Impact

- Nuevos: `skills/retro/SKILL.md`, `scripts/retro.ps1`, `tests/cadencias-scrumban.Tests.ps1`.
- Modificados: `scripts/tablero-comun.ps1` (validación de `cadencia-retro`), `.claude/CLAUDE.md`, `docs/workflow.md`, `docs/arquitectura/vision.md`.
- Vault: carpeta nueva `retros/` y clave nueva en `tablero.md` (la agrega el usuario en cada vault).
- GitHub: la retro crea issues en los repos que elija el usuario y los suma al tablero.
- Otras máquinas: la skill llega con `git pull` y `pwsh scripts/instalar.ps1` (instala todo `skills/`).
- Sin dependencias nuevas.
