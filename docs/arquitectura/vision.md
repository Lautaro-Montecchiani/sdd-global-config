# Visión de arquitectura: sdd-global-config

## Propósito
Configuración global del workflow SDD Híbrido (Claude arquitecto + Agente constructor). Ver la descripción y `## Objetivos de Negocio` (U-01 a U-03 y OBJ-01 a OBJ-06) en `openspec/config.yaml`.

## Contexto e integraciones
- Actores: usuario del workflow, Claude (arquitecto de software), Agente (constructor: Antigravity, Cursor, Copilot u otro) y mantenedor de este repositorio.
- Sistemas externos: OpenSpec CLI (artefactos y validación), GitHub (`gh`, PR y Actions), vault de Obsidian versionado en git (contexto, notas y espejo de reglas), y las carpetas de instalación `~/.claude/` y `~/.gemini/` de cada máquina.

## Componentes
- `.claude/CLAUDE.md`: reglas globales y única fuente donde se editan. Su bloque de reglas de ejecución del Agente se genera desde `templates/fuente/`. Se espeja en el vault, de donde lo leen Claude y el Agente; en `~/.claude/CLAUDE.md` se instala un archivo de carga (o la copia completa si no hay vault).
- `.claude/commands/`: comandos de Claude Code (`opsx/` para SDD, `odd/` y `odd.md` para ODD), generados desde las skills con `scripts/generar-plantillas.ps1` (encabezados en `templates/fuente/comandos/`).
- `skills/`: skills de Claude que se instalan en `~/.claude/skills/`.
- `templates/`: plantillas de reglas y configuración para agentes no-Claude. Las de reglas se generan desde `templates/fuente/` y `templates/fuente/comandos/` tiene los encabezados de los comandos.
- `scripts/`: generación de plantillas, instalación por máquina, sincronización por proyecto y generación del backlog desde los issues abiertos (PowerShell 7).
- `tests/`: tests de los scripts.
- `.github/workflows/`: `pr-check.yml` (convenciones de PR con branches `change/` u `odd/`, se copia a los proyectos) y `plantillas.yml` (tests y control de plantillas de este repo).
- `openspec/`: specs vigentes del workflow y changes.
- `docs/`: guías, SRS, ADRs y esta visión. En los proyectos, `docs/odd/` guarda los documentos ODD.

## Decisiones vigentes
- [0002. Reglas en una sola fuente y carga de Claude desde el vault](../adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md)
- [0003. Nivel 0 para sdd-global-config](../adr/0003-nivel-0-para-sdd-global-config.md)
- [0004. Issues de GitHub como fuente única del backlog](../adr/0004-issues-de-github-como-fuente-unica-del-backlog.md)

## Hoja de ruta
- [media] las reglas llegan a otra máquina con el pull del vault, pero las skills y los comandos solo con instalar.ps1; pueden quedar desparejos — origen: ADR 0002 — propuesta: evaluar distribuir skills y comandos por el mismo camino que las reglas
- [baja] en este repo .claude/CLAUDE.md se carga dos veces en Claude (global y de proyecto) — origen: reglas-fuente-unica-y-carga-desde-vault — propuesta: evaluar mover la copia versionada fuera de .claude/ del repo
- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software y clasificacion-odd-sdd — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas
- [baja] `scripts/instalar.ps1` está en el umbral de aviso de `tamaño` (500 líneas) y mezcla la clasificación del espejo con lecturas de archivos y `git` — origen: ADR 0003 — propuesta: si pasa de 1000 líneas, evaluar `1-nucleo-funcional` y llevar la clasificación a funciones de `scripts/comun.ps1`
- [baja] Antigravity puede mudar las skills a `~/.gemini/antigravity-cli/skills/` — origen: odd-apply — propuesta: cambiar la ruta de `instalar.ps1` cuando pase
- [media] el CI de los proyectos no detecta reglas del Agente atrasadas ni editadas a mano y no controla la presencia de la línea Issue: en el proposal — origen: aviso-proyecto-atrasado — propuesta: huella (versión y hash) en los archivos generados, controlada por `pr-check.yml`, en un change aparte
- [baja] el flujo ODD no controla los criterios de aceptación que corre el usuario — origen: tareas-del-usuario-sin-marcar — propuesta: la misma marca `(lo corre el usuario)` en `docs/odd/<nombre>.md` y su control en `/odd:verify`, en un change aparte
