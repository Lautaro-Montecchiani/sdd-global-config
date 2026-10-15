# Proposal

## Why

El equipo decidió usar Cursor como constructor (el Agente) del flujo OpenSpec en lugar de Antigravity. Hoy todo el onboarding del Agente está atado a Antigravity: el contexto global por máquina es `~/.gemini/GEMINI.md`, la baseline de permisos es `~/.gemini/antigravity-cli/settings.json`, la barra de estado está especificada para ese CLI, las guías esperan `.agent/skills/openspec-apply-change/` y el handoff de Claude dice `/openspec-apply-change`. Cursor no lee nada de eso: carga reglas desde `.cursor/rules/*.mdc` del proyecto y expone los comandos de OpenSpec como `/opsx-*` en `.cursor/commands/`. Sin este cambio, Cursor implementaría sin conocer las reglas del workflow (rol, ramas, `Spec-ID`, seguridad) y el handoff le pediría un comando que no existe.

## What Changes

- **Plantilla de reglas para Cursor** `templates/cursor-rules.mdc`, que se instala por proyecto en `.cursor/rules/sdd-workflow.mdc` (`alwaysApply: true`). Remite al espejo del vault (`_global/reglas-globales.md`), fija el rol de constructor y limita a Cursor a `/opsx-apply`: propose, verify, archive, explore y sync son de Claude.
- **Handoff de Claude**: "Ejecutá en el Agente: `/opsx-apply {nombre}`" en lugar de `/openspec-apply-change {nombre}`, en el `CLAUDE.md` global, los comandos `/opsx:propose` y `/opsx:apply` y las skills `openspec-propose` y `openspec-apply-change`. **BREAKING** para quien siga usando Antigravity.
- **Inicio de proyectos** con `openspec init --tools cursor`; la verificación pasa a ser que exista `.cursor/commands/opsx-apply.md`.
- **Retiro de Antigravity**: se eliminan `templates/GEMINI.md` y `templates/antigravity-settings.json`, los pasos 4 y 5 del setup por máquina y los requisitos de baseline, allowlist, workspaces y barra de estado del CLI de Antigravity. **BREAKING**.
- **Permisos de Cursor**: el setup por máquina documenta la allowlist de ejecución automática equivalente a la anterior (git de lectura, `git restore`, `openspec`), que se configura a mano en Cursor.
- **Migración de proyectos existentes**: procedimiento documentado (agregar Cursor con `openspec init --tools cursor`, instalar la regla y, opcionalmente, borrar `.agent/`/`.agents/` de Antigravity en un commit aparte desde la rama principal).

### Archivos globales que se modifican y por qué

- `~/.claude/CLAUDE.md` (copia versionada `.claude/CLAUDE.md` y espejo del vault `_global/reglas-globales.md`): regla 8 y tabla de roles con el comando de handoff nuevo, y la línea de onboarding de agentes no-Claude que hoy nombra `GEMINI.md`.
- `~/.claude/commands/opsx/apply.md`, `~/.claude/commands/opsx/propose.md`, `~/.claude/skills/openspec-apply-change/SKILL.md`, `~/.claude/skills/openspec-propose/SKILL.md`: son los que imprimen el handoff.
- `openspec/config.yaml` de este repo: el `context:` dice que el Agente usa `.agent/skills/`.

## Non-goals

- No se modifica `templates/copilot-instructions.md` ni se retira el soporte de proyectos que usen Copilot.
- No se especifica configuración del CLI `cursor-agent` ni barra de estado para Cursor (el IDE no la tiene).
- No se migran todos los proyectos existentes: se documenta el procedimiento y se prueba en uno.
- No se cambia el rol de Claude ni el flujo propose → apply → verify → archive.
- No se deja de ignorar `.gemini/` en `.gitignore` (sigue siendo configuración personal que no se versiona).

## Capabilities

### New Capabilities
<!-- ninguna -->

### Modified Capabilities
- `project-onboarding`: el inicio de proyectos usa `--tools cursor` y verifica `.cursor/commands/`; se agrega la instalación por proyecto de la regla de Cursor y la migración desde Antigravity.
- `agent-cli-permissions`: se retiran los requisitos propios de Antigravity (baseline, allowlist, workspaces, barra de estado, instalación documentada) y se agrega la documentación de permisos de ejecución en Cursor.
- `security-layer-matrix`: el requisito "Rol de Claude en apply" anuncia `/opsx-apply {nombre}`.
- `project-claude-md`: el rol de constructor tampoco se atribuye a Cursor ni a Antigravity.

## Impact

- **Repo**: `templates/` (nueva plantilla, dos eliminadas, `templates/README.md`), `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` (y `docs/modo-de-uso.docx` regenerado), `CONTRIBUTING.md`, `.claude/CLAUDE.md`, `.claude/commands/opsx/{apply,propose}.md`, `skills/openspec-{apply-change,propose}/SKILL.md`, `openspec/config.yaml`.
- **Máquinas**: reinstalar `CLAUDE.md`, comandos y skills en `~/.claude`; `~/.gemini/` deja de ser necesario (no se borra).
- **Proyectos**: necesitan `.cursor/commands/` (vía `openspec init --tools cursor`) y `.cursor/rules/sdd-workflow.mdc`.
- **Change en curso `test-driven-verify`**: toca skills/comandos de verify; este change no toca verify, pero ambos tocan `docs/` y `README.md` → posibles conflictos de merge.
