# Plantilla de Antigravity CLI

Configuración por máquina para **Antigravity CLI** (`agy`).

> **Reglas de ejecución:** Antigravity lee el contexto global de `~/.gemini/GEMINI.md`. Esa plantilla se genera desde la fuente única en `templates/fuente/` con `scripts/generar-plantillas.ps1` y se instala automáticamente en la máquina con `scripts/instalar.ps1`.

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `GEMINI.md` | `~/.gemini/GEMINI.md` | global por máquina (se instala automáticamente con `scripts/instalar.ps1` si existe `~/.gemini`) |
| `settings.json` | `~/.gemini/antigravity-cli/settings.json` | global por máquina (una sola vez; fusionar a mano si ya existe) |
| `statusline.bat` | `~/.gemini/antigravity-cli/scratch/statusline.bat` | global por máquina (se instala con `scripts/instalar.ps1`) |
| `statusline_new.ps1` | `~/.gemini/antigravity-cli/scratch/statusline_new.ps1` | global por máquina (se instala con `scripts/instalar.ps1`) |

## Instalación

1. **Instalar reglas globales de Antigravity:**  
   `templates/antigravity/GEMINI.md` se copia automáticamente a `~/.gemini/GEMINI.md` al ejecutar:
   ```powershell
   pwsh scripts\instalar.ps1
   ```
   (o con `-Simular` para revisar previamente).

2. **Instalar la baseline de permisos de Antigravity CLI:**  
   Si ya existe un `settings.json` NO se sobrescribe: fusionar a mano con la plantilla:
   ```powershell
   $ag = "$env:USERPROFILE\.gemini\antigravity-cli"
   New-Item -ItemType Directory -Force $ag | Out-Null
   if (-not (Test-Path "$ag\settings.json")) { cp templates\antigravity\settings.json "$ag\settings.json" }
   ```

## Baseline de permisos del Agente (`settings.json`)

La configuración personal del CLI del Agente (`.gemini/`) no se versiona en este repo: contiene rutas de la máquina, workspaces y permisos. Lo que sí se replica en una PC o notebook nueva es esta baseline (spec `agent-cli-permissions`):

- `toolPermission` y `artifactReviewPolicy` en `always-proceed`, y `allowNonWorkspaceAccess` en `true`.
- Allowlist base de comandos: `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec` y `powershell`.
- Entrada `statusLine`: la instala y configura automáticamente `scripts/instalar.ps1` con `"enabled": true` apuntando a `scratch/statusline.bat`.

**Completar después de copiar la plantilla** (los valores reales no se versionan):
- `trustedWorkspaces`: reemplazar el ejemplo (`{RUTA-A-TUS-PROYECTOS}\\{proyecto}`) por una entrada por cada carpeta de proyecto de confianza de esa máquina (barras invertidas dobles en JSON). La ruta de `statusLine` la resuelve automáticamente `scripts/instalar.ps1`.

**No incluye** el modelo (`model`), el esquema de colores (`colorScheme`) ni comandos puntuales: son preferencias o restos de una sesión.

> **Ojo:** esta baseline es permisiva por decisión. Con `always-proceed`, `allowNonWorkspaceAccess` y `powershell`/`cmd.exe` en la allowlist, el Agente ejecuta cualquier comando, en cualquier carpeta, sin pedir confirmación. En un equipo compartido conviene evaluar quitar `powershell`, `cmd.exe` o `allowNonWorkspaceAccess`.

## Barra de estado

Los scripts `statusline.bat` y `statusline_new.ps1` están versionados en esta carpeta (`templates/antigravity/`) y `scripts/instalar.ps1` los instala automáticamente en `~/.gemini/antigravity-cli/scratch/`, configurando además la clave `statusLine` en `~/.gemini/antigravity-cli/settings.json`. Su comportamiento está especificado en el requisito «Barra de estado» de la spec `agent-cli-permissions` (`openspec/specs/agent-cli-permissions/spec.md`).

### Si la barra no aparece

Si la barra de estado deja de mostrarse o no aparece tras instalar, correr `pwsh scripts/instalar.ps1` (que vuelve a poner `enabled: true` si el CLI lo había desactivado) y reiniciar el CLI.
