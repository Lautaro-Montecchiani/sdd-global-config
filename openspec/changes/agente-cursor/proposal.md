# Proposal

## Why

En el equipo se usan agentes distintos como constructor (el Agente) del flujo OpenSpec: hay quienes siguen con Antigravity y quienes pasan a Cursor. Hoy el onboarding del Agente está pensado solo para Antigravity (contexto global en `~/.gemini/GEMINI.md`, permisos y barra de estado en `~/.gemini/antigravity-cli/settings.json`, skills en `.agent/skills/`) y el handoff de Claude dice `/openspec-apply-change`. Cursor no lee nada de eso: carga reglas desde `.cursor/rules/*.mdc` del proyecto y expone los comandos de OpenSpec como `/opsx-*` en `.cursor/commands/`. Sin este cambio, Cursor implementaría sin conocer las reglas del workflow (rol, ramas, `Spec-ID`, seguridad) y el handoff le pediría un comando que no existe.

## What Changes

Cursor se **suma** como agente soportado, siguiendo la estructura por agente de `templates/` (change `plantillas-por-agente`, ya archivado). No se retira Antigravity.

- **Plantilla de reglas para Cursor** `templates/cursor/sdd-workflow.mdc`, que se instala por proyecto en `.cursor/rules/sdd-workflow.mdc` (`alwaysApply: true`). Remite al espejo del vault (`_global/reglas-globales.md`), fija el rol de constructor y limita a Cursor a `/opsx-apply`: propose, verify, archive, explore y sync son de Claude.
- **`templates/cursor/README.md`**: instalación de la regla por proyecto, permisos de ejecución automática de Cursor (allowlist documentada, sin `powershell`/`cmd.exe`) y cómo agregar Cursor a un proyecto que ya usa Antigravity.
- **Matriz de soporte** de `templates/README.md`: la fila de Cursor pasa de "lo agrega `agente-cursor`" a apuntar a `templates/cursor/`.
- **Handoff de Claude con los dos agentes**: "Ejecutá en el Agente: `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor)", en el `CLAUDE.md` global, los comandos `/opsx:propose` y `/opsx:apply` y las skills `openspec-propose` y `openspec-apply-change`. Nadie queda con un comando que no existe en su agente.
- **Inicio de proyectos** con `openspec init --tools <agente>`, donde `<agente>` es `antigravity` o `cursor`; la verificación depende del agente (`.agent/skills/openspec-apply-change/` o `.cursor/commands/opsx-apply.md`).
- **Setup por máquina por agente**: `README.md` y `docs/modo-de-uso.md` separan los pasos de Antigravity (`GEMINI.md`, `settings.json`) de los de Cursor (auto-run), e indican seguir solo los del agente que se use.
- **Agregar Cursor a proyectos existentes**: procedimiento documentado (`openspec init --tools cursor` más la regla; el borrado de `.agent/`/`.agents/` solo si el proyecto deja Antigravity, en un commit aparte).

### Archivos globales que se modifican y por qué

- `~/.claude/CLAUDE.md` (copia versionada `.claude/CLAUDE.md` y espejo del vault `_global/reglas-globales.md`): regla 8, tabla de roles y flujo con el handoff por agente, y la línea de onboarding de agentes no-Claude (suma la regla de Cursor).
- `~/.claude/commands/opsx/apply.md`, `~/.claude/commands/opsx/propose.md`, `~/.claude/skills/openspec-apply-change/SKILL.md`, `~/.claude/skills/openspec-propose/SKILL.md`: son los que imprimen el handoff.
- `openspec/config.yaml` de este repo: el `context:` dice que el Agente usa `.agent/skills/`; pasa a describir los dos agentes.

## Non-goals

- No se retira Antigravity: se conservan `templates/gemini/`, `templates/antigravity/` y todos los requirements de `agent-cli-permissions`. Cada persona usa el agente que prefiera.
- No se modifica `templates/copilot/` ni `templates/comun/`.
- No se especifica configuración del CLI `cursor-agent` (`~/.cursor/cli-config.json`) ni barra de estado para Cursor (el IDE no la tiene configurable por script).
- No se migran todos los proyectos existentes: se documenta el procedimiento y se prueba en uno.
- No se cambia el rol de Claude ni el flujo propose → apply → verify → archive.
- No se cambia la versión de OpenSpec: `openspec init --tools cursor` ya funciona con la 1.4.1 instalada.

## Capabilities

### New Capabilities
<!-- ninguna -->

### Modified Capabilities
- `project-onboarding`: el inicio de proyectos usa `--tools <agente>` con verificación por agente; se agrega la instalación por proyecto de la regla de Cursor, el setup por máquina por agente y cómo agregar Cursor a un proyecto existente.
- `agent-cli-permissions`: se agrega la documentación de permisos de ejecución en Cursor; los requisitos de Antigravity no cambian.
- `security-layer-matrix`: el requisito "Rol de Claude en apply" anuncia el comando de cada agente.
- `project-claude-md`: el rol de constructor tampoco se atribuye a Antigravity ni a Cursor.
- `agent-templates`: la matriz de soporte incluye `templates/cursor/` y su fila deja de estar pendiente.

## Impact

- **Repo**: `templates/` (carpeta nueva `cursor/`, `templates/README.md`), `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` (y `docs/modo-de-uso.docx` regenerado), `CONTRIBUTING.md`, `.claude/CLAUDE.md`, `.claude/commands/opsx/{apply,propose}.md`, `skills/openspec-{apply-change,propose}/SKILL.md`, `openspec/config.yaml`.
- **Máquinas**: reinstalar `CLAUDE.md`, comandos y skills en `~/.claude`. Quien use Antigravity no cambia nada más; quien use Cursor configura el auto-run.
- **Proyectos**: los que usen Cursor necesitan `.cursor/commands/` (vía `openspec init --tools cursor`) y `.cursor/rules/sdd-workflow.mdc`. Los de Antigravity siguen igual.
- **Conflictos**: `test-driven-verify`, `completar-purpose-specs`, `plantillas-por-agente` y `archive-ofrece-srs-nuevo` ya están archivados en `master`; este change se actualizó sobre ese estado.
