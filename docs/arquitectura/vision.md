# Visión de arquitectura: sdd-global-config

## Propósito
Configuración global del workflow SDD Híbrido (Claude arquitecto + Agente constructor). Ver la descripción y `## Objetivos de Negocio` (U-01 a U-03 y OBJ-01 a OBJ-06) en `openspec/config.yaml`.

## Contexto e integraciones
- Actores: usuario del workflow, Claude (arquitecto de software), Agente (constructor: Antigravity, Cursor, Copilot u otro) y mantenedor de este repositorio.
- Sistemas externos: OpenSpec CLI (artefactos y validación), GitHub (`gh`, PR y Actions), vault de Obsidian versionado en git (contexto, notas y espejo de reglas), y las carpetas de instalación `~/.claude/` y `~/.gemini/` de cada máquina.

## Componentes
- `.claude/CLAUDE.md`: reglas globales de Claude; se instala en `~/.claude/CLAUDE.md` y se espeja en el vault.
- `.claude/commands/`: comandos de Claude Code (`opsx/` para SDD, `odd/` y `odd.md` para ODD), generados desde las skills con `scripts/generar-plantillas.ps1` (encabezados en `templates/fuente/comandos/`).
- `skills/`: skills de Claude que se instalan en `~/.claude/skills/`.
- `templates/`: plantillas de reglas y configuración para agentes no-Claude. Las de reglas se generan desde `templates/fuente/` y `templates/fuente/comandos/` tiene los encabezados de los comandos.
- `scripts/`: generación de plantillas, instalación por máquina y sincronización por proyecto (PowerShell 7).
- `tests/`: tests de los scripts.
- `.github/workflows/`: `pr-check.yml` (convenciones de PR con branches `change/` u `odd/`, se copia a los proyectos) y `plantillas.yml` (tests y control de plantillas de este repo).
- `openspec/`: specs vigentes del workflow y changes.
- `docs/`: guías, SRS, ADRs y esta visión. En los proyectos, `docs/odd/` guarda los documentos ODD.

## Decisiones vigentes
- [0001. Fuente única de las reglas del Agente, generada con PowerShell 7](../adr/0001-fuente-unica-de-reglas-con-powershell.md)

## Hoja de ruta
- [baja] las reglas del Agente siguen escritas dos veces (plantillas en segunda persona y `CLAUDE.md` en tercera); el CI solo compara los títulos — origen: ADR 0001 — propuesta: evaluar una sola redacción si los textos empiezan a divergir
- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software y clasificacion-odd-sdd — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas
- [baja] `## Arquitectura` no declara `nivel` — propuesta: correr `/arquitectura`
