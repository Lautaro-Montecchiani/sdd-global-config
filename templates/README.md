# Plantillas de instrucciones para agentes

Cierran el circuito de persistencia agéntica: hacen que el Agente, que NO carga `~/.claude/` automáticamente, lea las reglas del workflow SDD desde el espejo del vault de Obsidian (`$env:OBSIDIAN_VAULT\_global\reglas-globales.md`).

| Plantilla | Destino | Alcance | Cuándo instalarla |
|---|---|---|---|
| `copilot-instructions.md` | `{proyecto}\.github\copilot-instructions.md` | por proyecto | al sumar un proyecto al workflow |
| `GEMINI.md` | `~/.gemini/GEMINI.md` | global por máquina | una vez por máquina (setup) |
| `antigravity-settings.json` | `~/.gemini/antigravity-cli/settings.json` | global por máquina | una vez por máquina; si ya existe un `settings.json`, fusionar a mano |
| `antigravity-statusline.bat` | `~/.gemini/antigravity-cli/scratch/statusline.bat` | global por máquina | una vez por máquina (setup) |
| `antigravity-statusline.ps1` | `~/.gemini/antigravity-cli/scratch/statusline_new.ps1` | global por máquina | una vez por máquina (setup) |

Los nombres de archivo (`copilot-instructions.md`, `GEMINI.md`) los impone cada herramienta; el contenido es el mismo rol y apunta al mismo espejo del vault.

**Claude no necesita plantilla:** carga `~/.claude/CLAUDE.md` automáticamente en todas las sesiones, en todos los proyectos.

Si el proyecto ya tiene un `.github/copilot-instructions.md` propio, fusionar la sección "Workflow SDD" al principio del archivo existente en lugar de reemplazarlo. Lo mismo aplica para un `GEMINI.md` global con contenido previo.

## Baseline de permisos del Agente (`antigravity-settings.json`)

La configuración personal del CLI del Agente (`.gemini/`) ya no se versiona en este repo: contiene rutas de la máquina, workspaces y permisos. Lo que sí se replica en una PC o notebook nueva es esta baseline (spec `agent-cli-permissions`):

- `toolPermission` y `artifactReviewPolicy` en `always-proceed`, y `allowNonWorkspaceAccess` en `true`.
- Allowlist base de comandos: `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec` y `powershell`.
- Barra de estado (`statusLine`) con los dos scripts de `antigravity-statusline.*`.

**Completar después de copiar la plantilla** (los valores reales no se versionan):
- `{RUTA-DE-TU-USUARIO}` en `statusLine.command`: la ruta a tu carpeta de usuario con barras normales (por ejemplo `C:/Users/<usuario>`).
- `trustedWorkspaces`: reemplazar el ejemplo por una entrada por cada carpeta de proyecto de confianza de esa máquina (barras invertidas dobles en JSON).

**No incluye** el modelo (`model`), el esquema de colores (`colorScheme`) ni comandos puntuales: son preferencias o restos de una sesión.

> **Ojo:** esta baseline es permisiva por decisión. Con `always-proceed`, `allowNonWorkspaceAccess` y `powershell`/`cmd.exe` en la allowlist, el Agente ejecuta cualquier comando, en cualquier carpeta, sin pedir confirmación. En un equipo compartido conviene evaluar quitar `powershell`, `cmd.exe` o `allowNonWorkspaceAccess`.
