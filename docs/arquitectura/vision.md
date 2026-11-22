# Visión de arquitectura: sdd-global-config

## Propósito
Configuración global del workflow SDD Híbrido (Claude arquitecto + Agente constructor). Ver la descripción y `## Objetivos de Negocio` (U-01 a U-03 y OBJ-01 a OBJ-06) en `openspec/config.yaml`.

## Contexto e integraciones
- Actores: usuario del workflow, Claude (arquitecto de software), Agente (constructor: Antigravity, Cursor, Copilot u otro) y mantenedor de este repositorio.
- Sistemas externos: OpenSpec CLI (artefactos y validación), GitHub (`gh`, PR y Actions), GitHub Projects (uno o más tableros Scrumban de usuario, elegidos por el dueño del repo, con `gh project`), vault de Obsidian versionado en git (contexto, notas y espejo de reglas), Copilot CLI y las carpetas de instalación `~/.claude/`, `~/.gemini/` y `~/.copilot/` de cada máquina.

## Componentes
- `.claude/CLAUDE.md`: reglas globales y única fuente donde se editan. Su bloque de reglas de ejecución del Agente se genera desde `templates/fuente/`. Se espeja en el vault, de donde lo leen Claude y el Agente; en `~/.claude/CLAUDE.md` se instala un archivo de carga (o la copia completa si no hay vault).
- `.claude/commands/`: comandos de Claude Code (`opsx/` para SDD, `odd/` y `odd.md` para ODD), generados desde las skills con `scripts/generar-plantillas.ps1` (encabezados en `templates/fuente/comandos/`).
- `.claude/statusline.sh`: barra de estado compartida para Claude Code y Copilot CLI.
- `.claude/settings.json`: configuración de Claude Code de este repo; excluye `.claude/CLAUDE.md` (`claudeMdExcludes`) para que las reglas se carguen una sola vez, desde las instaladas.
- `skills/`: skills de Claude que se instalan en `~/.claude/skills/` (incluye `/retro`, la retro global con review).
- `templates/`: plantillas de reglas y configuración para agentes no-Claude, incluyendo los scripts de la barra de Antigravity (`statusline.bat` y `statusline_new.ps1`). Las de reglas se generan desde `templates/fuente/` y `templates/fuente/comandos/` tiene los encabezados de los comandos.
- `scripts/`: generación de plantillas, instalación por máquina (incluye la barra de estado), sincronización por proyecto, generación del backlog desde los issues abiertos, movimiento de tarjetas y control de WIP de los tableros (elegidos por el dueño del repo, con el WIP sumado), cálculo de las métricas de flujo de todos los tableros (`metricas.ps1`, con funciones compartidas en `tablero-comun.ps1`) y aviso de cadencia y período de la retro (`retro.ps1`) (PowerShell 7).
- `tests/`: tests de los scripts.
- `.github/workflows/`: `pr-check.yml` (convenciones de PR con branches `change/` u `odd/`, permisos de solo lectura; se copia a los proyectos y lo propio de cada proyecto va en otro workflow) y `plantillas.yml` (tests y control de plantillas de este repo).
- `openspec/`: specs vigentes del workflow y changes.
- `docs/`: guías, SRS, ADRs y esta visión. En los proyectos, `docs/odd/` guarda los documentos ODD.

## Decisiones vigentes
- [0002. Reglas en una sola fuente y carga de Claude desde el vault](../adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md)
- [0003. Nivel 0 para sdd-global-config](../adr/0003-nivel-0-para-sdd-global-config.md)
- [0004. Issues de GitHub como fuente única del backlog](../adr/0004-issues-de-github-como-fuente-unica-del-backlog.md)
- [0005. instalar.ps1 escribe la barra de estado de cada CLI](../adr/0005-instalar-escribe-la-barra-de-estado-de-cada-cli.md)
- [0006. Tablero Scrumban en un GitHub Project de usuario](../adr/0006-tablero-scrumban-en-github-project-de-usuario.md)
- [0007. Un tablero por dueño del repo con WIP y métricas globales](../adr/0007-un-tablero-por-dueno-del-repo.md)
- [0008. Huella de skills y comandos en el espejo del vault](../adr/0008-huella-de-skills-y-comandos-en-el-espejo.md)

## Hoja de ruta
- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software, clasificacion-odd-sdd, tablero-scrumban y cadencias-scrumban — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas — issue: #55
- [baja] `scripts/instalar.ps1` está en el umbral de aviso de `tamaño` (500 líneas) y mezcla la clasificación del espejo con lecturas de archivos y `git` — origen: ADR 0003 — propuesta: si pasa de 1000 líneas, evaluar `1-nucleo-funcional` y llevar la clasificación a funciones de `scripts/comun.ps1` — issue: #56
- [baja] Antigravity puede mudar las skills a `~/.gemini/antigravity-cli/skills/` — origen: odd-apply — propuesta: cambiar la ruta de `instalar.ps1` cuando pase — issue: #57
- [media] el CI de los proyectos no detecta reglas del Agente atrasadas ni editadas a mano y no controla la presencia de la línea Issue: en el proposal — origen: aviso-proyecto-atrasado — propuesta: huella (versión y hash) en los archivos generados, controlada por `pr-check.yml`, en un change aparte — issue: #58
- [baja] el flujo ODD no controla los criterios de aceptación que corre el usuario — origen: tareas-del-usuario-sin-marcar — propuesta: la misma marca `(lo corre el usuario)` en `docs/odd/<nombre>.md` y su control en `/odd:verify`, en un change aparte — issue: #59
- [baja] la barra de estado de Cursor CLI no se instala (sin claves oficiales documentadas) — origen: ADR 0005 — propuesta: confirmar las claves en un Cursor CLI instalado y sumarla a barra-estado.ps1 — issue: #63
