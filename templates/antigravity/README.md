# Plantilla de Antigravity CLI

Configuración por máquina para **Antigravity CLI** (`agy`).

> **Reglas de ejecución:** Antigravity lee el contexto global de `~/.gemini/GEMINI.md`. Esa plantilla vive en `templates/antigravity/GEMINI.md`.

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `GEMINI.md` | `~/.gemini/GEMINI.md` | global por máquina (una sola vez; fusionar al principio si ya existe con contenido previo) |
| `settings.json` | `~/.gemini/antigravity-cli/settings.json` | global por máquina (una sola vez; fusionar a mano si ya existe) |

## Instalación

```powershell
# 1. Instalar las reglas globales de Antigravity
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini" | Out-Null
cp templates\antigravity\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"

# 2. Instalar la baseline de permisos y barra de estado de Antigravity CLI
#    Si ya existe un settings.json NO se sobrescribe: fusionar a mano con la plantilla.
$ag = "$env:USERPROFILE\.gemini\antigravity-cli"
New-Item -ItemType Directory -Force $ag | Out-Null
if (-not (Test-Path "$ag\settings.json")) { cp templates\antigravity\settings.json "$ag\settings.json" }
```

## Baseline de permisos del Agente (`settings.json`)

La configuración personal del CLI del Agente (`.gemini/`) no se versiona en este repo: contiene rutas de la máquina, workspaces y permisos. Lo que sí se replica en una PC o notebook nueva es esta baseline (spec `agent-cli-permissions`):

- `toolPermission` y `artifactReviewPolicy` en `always-proceed`, y `allowNonWorkspaceAccess` en `true`.
- Allowlist base de comandos: `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec` y `powershell`.
- Entrada `statusLine` con `"enabled": true` que apunta a `scratch/statusline.bat`: los scripts de la barra de estado no se versionan, los genera el CLI (ver la sección siguiente).

**Completar después de copiar la plantilla** (los valores reales no se versionan):
- `{RUTA-DE-TU-USUARIO}` en `statusLine.command`: la ruta a tu carpeta de usuario con barras normales (por ejemplo `C:/Users/<usuario>`).
- `trustedWorkspaces`: reemplazar el ejemplo (`{RUTA-A-TUS-PROYECTOS}\\{proyecto}`) por una entrada por cada carpeta de proyecto de confianza de esa máquina (barras invertidas dobles en JSON).

**No incluye** el modelo (`model`), el esquema de colores (`colorScheme`) ni comandos puntuales: son preferencias o restos de una sesión.

> **Ojo:** esta baseline es permisiva por decisión. Con `always-proceed`, `allowNonWorkspaceAccess` y `powershell`/`cmd.exe` en la allowlist, el Agente ejecuta cualquier comando, en cualquier carpeta, sin pedir confirmación. En un equipo compartido conviene evaluar quitar `powershell`, `cmd.exe` o `allowNonWorkspaceAccess`.

## Barra de estado (la genera el CLI del Agente)

Los scripts `statusline.bat` y `statusline_new.ps1` los generó el propio CLI, así que no se versionan: su comportamiento está especificado en el requisito «Barra de estado» de la spec `agent-cli-permissions` (`openspec/specs/agent-cli-permissions/spec.md`), con el formato de salida y escenarios de ejemplo. En una máquina nueva, abrí el CLI del Agente dentro del repo `sdd-global-config` y ejecutá este prompt:

> Leé el requisito «Barra de estado» de `openspec/specs/agent-cli-permissions/spec.md`. Creá en `~/.gemini/antigravity-cli/scratch/` los archivos `statusline.bat` (que invoque al script con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`, resolviendo la carpeta con `%USERPROFILE%`) y `statusline_new.ps1` que cumplan ese requisito. Confirmá que `statusLine` en `settings.json` apunte a `statusline.bat` y probá la barra con las entradas de ejemplo de los escenarios de la spec.

### Si la barra no aparece

Si la barra de estado deja de mostrarse o no aparece tras instalar, revisar que `statusLine.enabled` sea `true` en `~/.gemini/antigravity-cli/settings.json` (el CLI puede escribir `"enabled": false` si se desactiva con `/statusline`) y reiniciar el CLI.
