# Design

## Context

Ver `proposal.md` — Why. Estado actual relevante:

- El Agente es Antigravity: contexto global en `~/.gemini/GEMINI.md` (plantilla `templates/GEMINI.md`), permisos en `~/.gemini/antigravity-cli/settings.json` (plantilla `templates/antigravity-settings.json`, spec `agent-cli-permissions`), skills del Agente en `.agent/skills/` o `.agents/` del proyecto.
- OpenSpec 1.14 ya soporta `--tools cursor`: genera `.cursor/commands/opsx-{apply,archive,explore,propose,sync,verify}.md` (comandos `/opsx-*` con la lógica estándar de OpenSpec, sin la capa híbrida ni el vault). Varios proyectos (p. ej. Yacotrucks) y este repo ya tienen `.cursor/commands/` sin versionar.
- Cursor carga reglas de proyecto desde `.cursor/rules/*.mdc` (frontmatter `description`, `globs`, `alwaysApply`). Las "User Rules" globales se cargan desde la configuración del IDE, no desde un archivo, así que no hay equivalente versionable a `~/.gemini/GEMINI.md`.
- El handoff `/openspec-apply-change {nombre}` está en `.claude/CLAUDE.md`, `.claude/commands/opsx/{apply,propose}.md`, `skills/openspec-{apply-change,propose}/SKILL.md`, `README.md`, `CONTRIBUTING.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y la spec `security-layer-matrix`.

## Goals / Non-Goals

**Goals:**
- Que Cursor reciba las reglas del workflow en cada sesión de un proyecto sin pasos manuales por sesión.
- Que el handoff de Claude nombre un comando que exista en Cursor.
- Retirar Antigravity del setup sin dejar referencias colgadas.

**Non-Goals:**
- Reescribir los comandos `/opsx-*` que genera OpenSpec para Cursor (se usan tal cual; la restricción de rol va en la regla).
- Soportar `cursor-agent` (CLI) ni definir su `cli-config.json`.

## Decisions

### D1. Reglas por proyecto en `.cursor/rules/sdd-workflow.mdc` con `alwaysApply: true`
Única forma versionable de que Cursor cargue instrucciones siempre. Contenido: el de `templates/copilot-instructions.md` (rol constructor, git, memoria del proyecto, lectura del espejo del vault) más una sección "Comandos permitidos" que restringe a `/opsx-apply`. La plantilla vive en `templates/cursor-rules.mdc` y se copia, igual que `copilot-instructions.md`.
*Alternativas*: `AGENTS.md` en la raíz — lo leen varias herramientas (incluido Claude en algunos casos) y podría confundir roles; User Rules del IDE — no versionables ni replicables por script.

### D2. Handoff `/opsx-apply {nombre}`
Es el comando que OpenSpec genera para Cursor. Se reemplaza el texto en todos los archivos listados en Context y en el `CLAUDE.md` global (regla 8, tabla de roles, flujo OpenSpec, "Reglas en Modo OpenSpec"). El nombre de la skill del lado de Claude (`openspec-apply-change`, que solo anuncia el handoff) no cambia.
*Alternativa*: crear `.cursor/commands/openspec-apply-change.md` para conservar el nombre — duplica el comando generado y `openspec update` no lo mantiene.

### D3. Los comandos de arquitecto en Cursor se desactivan por regla, no borrándolos
`openspec update` regenera todos los `/opsx-*` de la herramienta configurada; borrarlos no es duradero. La regla D1 instruye no ejecutarlos y derivar al usuario a Claude.

### D4. Retiro de plantillas de Antigravity
Se eliminan `templates/GEMINI.md` y `templates/antigravity-settings.json` y sus pasos de setup; `.gemini/` sigue en `.gitignore`. Los archivos ya instalados en `~/.gemini/` de cada máquina no se tocan.

### D5. Permisos de Cursor documentados, no versionados
La configuración de auto-run de Cursor vive en el IDE. Se documenta la allowlist (`git status`, `git diff`, `git branch`, `git restore`, `openspec`) sin `powershell`/`cmd.exe`, cerrando la permisividad que la baseline de Antigravity tenía a propósito.

### D6. Migración de proyectos
Agregar Cursor con `openspec init --tools cursor` (conserva la configuración existente y suma la herramienta), copiar la regla y, opcionalmente, eliminar `.agent/`/`.agents/` en un commit aparte desde la rama principal — mismo criterio que la limpieza de copias locales de Claude.

## Impacto en proyectos existentes

- Proyectos con Antigravity siguen funcionando para Claude (sus comandos son globales), pero el handoff nuevo pide `/opsx-apply`, que solo existe si el proyecto tiene `.cursor/commands/`. Hasta migrar, el usuario puede seguir usando Antigravity manualmente.
- Changes en curso (p. ej. `lavadero-tablero-unificado` en Yacotrucks, `test-driven-verify` aquí): no requieren cambios en sus artefactos; solo cambia el comando con que se lanza el apply.
- Ningún proyecto queda con copias locales de Claude: `--tools cursor` no crea `.claude/`.
- Quien tenga `~/.gemini/GEMINI.md` lo conserva; deja de ser parte del workflow.

## Security Layer

`project_type: tooling` — los artefactos modificados son instrucciones para IA:
- La plantilla `cursor-rules.mdc`, el `CLAUDE.md` y las guías no contienen secrets ni rutas con el usuario local (solo `$env:OBSIDIAN_VAULT`, `$env:SDD_CONFIG_REPO` y el fallback convencional `C:\TPA`). El chequeo de "no contiene `C:\Users`" se hace con un script en archivo (las barras invertidas se pierden en comandos en línea).
- La regla de Cursor mantiene las prohibiciones de commitear `.env`, `*.key`, `*.pem` y credenciales y de revisar `git diff --staged`.
- La allowlist documentada excluye shells genéricos (D5), reduciendo lo que el Agente ejecuta sin confirmación.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto, y se re-sincronizan el espejo del vault y la copia instalada en `~/.claude/`.

## Risks / Trade-offs

- [Cursor podría leer también `CLAUDE.md` del proyecto, que habla en primera persona de Claude como arquitecto] → la regla D1 aclara explícitamente que Cursor es el Agente y que las reglas de Claude no le aplican; se valida en el proyecto de prueba.
- [Los `/opsx-*` de Cursor no usan el vault ni la lógica híbrida] → Cursor solo ejecuta `/opsx-apply`, que no la necesita; el contexto del vault lo trae la regla.
- [Conflictos de merge con `test-driven-verify`] → este change no toca archivos de verify; los conflictos en `README.md`/`docs/` se resuelven al mergear el segundo.
- [Una regla que el usuario puede desactivar en el IDE] → se acepta; es el mismo nivel de garantía que `copilot-instructions.md`.

## Migration Plan

1. Mergear el change en `master`.
2. En cada máquina: reinstalar `CLAUDE.md`, comandos y skills en `~/.claude` (paso 2 y 3 del setup) y configurar el auto-run de Cursor.
3. En cada proyecto activo: aplicar la migración D6 cuando se vaya a trabajar en él.
4. Rollback: revertir el merge y reinstalar en `~/.claude`; los archivos de `~/.gemini/` siguen en las máquinas.
