# Plantillas de instrucciones para agentes

Cierran el circuito de persistencia agéntica: hacen que el Agente, que NO carga `~/.claude/` automáticamente, lea las reglas del workflow SDD desde el espejo del vault de Obsidian (`$env:OBSIDIAN_VAULT\_global\reglas-globales.md`).

| Plantilla | Destino | Alcance | Cuándo instalarla |
|---|---|---|---|
| `copilot-instructions.md` | `{proyecto}\.github\copilot-instructions.md` | por proyecto | al sumar un proyecto al workflow |
| `GEMINI.md` | `~/.gemini/GEMINI.md` | global por máquina | una vez por máquina (setup) |

Los nombres de archivo (`copilot-instructions.md`, `GEMINI.md`) los impone cada herramienta; el contenido es el mismo rol y apunta al mismo espejo del vault.

**Claude no necesita plantilla:** carga `~/.claude/CLAUDE.md` automáticamente en todas las sesiones, en todos los proyectos.

Si el proyecto ya tiene un `.github/copilot-instructions.md` propio, fusionar la sección "Workflow SDD" al principio del archivo existente en lugar de reemplazarlo. Lo mismo aplica para un `GEMINI.md` global con contenido previo.
