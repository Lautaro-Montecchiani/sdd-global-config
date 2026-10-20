# Plantillas de configuración e instrucciones por agente

Cierran el circuito de persistencia agéntica: hacen que el Agente constructor, que NO carga `~/.claude/` automáticamente, lea las reglas del workflow SDD desde el espejo del vault de Obsidian (`$env:OBSIDIAN_VAULT\_global\reglas-globales.md`) y lleve las mismas **7 reglas de ejecución**.

**Claude no necesita plantilla:** carga `~/.claude/CLAUDE.md` automáticamente en todas las sesiones, en todos los proyectos.

## Carpetas por agente

- [`antigravity/`](antigravity/README.md) — **Antigravity CLI**: `templates/antigravity/GEMINI.md` (`~/.gemini/GEMINI.md`), `templates/antigravity/settings.json` (permisos y barra de estado en `~/.gemini/antigravity-cli/settings.json`) y guía para generar los scripts de la barra.
- [`copilot/`](copilot/README.md) — **GitHub Copilot**: `templates/copilot/copilot-instructions.md` (`.github/copilot-instructions.md` en cada proyecto).
- [`cursor/`](cursor/README.md) — **Cursor**: `templates/cursor/sdd-workflow.mdc` (`.cursor/rules/sdd-workflow.mdc` en cada proyecto); auto-run documentado en su README.
- [`comun/`](comun/README.md) — **Estándar multi-agente (`AGENTS.md`)**: `templates/comun/AGENTS.md` (en la raíz de cada proyecto; lo leen Codex, Cursor y otros agentes).

## Matriz de soporte por agente

| Agente | Reglas | Permisos | Barra de estado |
|---|---|---|---|
| Antigravity | `antigravity/GEMINI.md` → `~/.gemini/GEMINI.md` | `antigravity/settings.json` → `~/.gemini/antigravity-cli/settings.json` | `antigravity/settings.json` (`statusLine`) + scripts que genera el CLI |
| Copilot | `copilot/copilot-instructions.md` → `.github/copilot-instructions.md` del proyecto | no soportado | no soportado |
| Codex | `comun/AGENTS.md` → raíz del proyecto | no verificado | no verificado |
| Cursor | cursor/sdd-workflow.mdc → .cursor/rules/sdd-workflow.mdc del proyecto (Cursor también lee comun/AGENTS.md) | documentado en cursor/README.md (auto-run del IDE, no versionable) | no verificado |

**Regla de la matriz:** una capacidad se marca cubierta solo si la documentación oficial del agente la confirma.

### Fuentes consultadas

- **Antigravity CLI:** `statusLine` con `type: command`; el CLI pasa un JSON por stdin al script y muestra lo que el script escribe en stdout ([docs](https://www.antigravity.google/docs/cli/statusline)); también se configura con el comando `/statusline` ([docs](https://www.antigravity.google/docs/cli/commands/statusline)).
- **Gemini CLI:** retirado por Google y reemplazado por Antigravity CLI ([anuncio](https://github.com/google-gemini/gemini-cli/discussions/27274)).
- **Cursor:** reglas en `.cursor/rules/*.mdc` o en `AGENTS.md` ([docs](https://docs.cursor.com/context/rules)); permisos del CLI en `~/.cursor/cli-config.json` (`permissions.allow`/`deny` con `Shell(<comando>)`) y por proyecto en `.cursor/cli.json` ([configuración](https://cursor.com/docs/cli/reference/configuration), [permisos](https://cursor.com/docs/cli/reference/permissions)). No se encontró documentación de una barra de estado configurable.
