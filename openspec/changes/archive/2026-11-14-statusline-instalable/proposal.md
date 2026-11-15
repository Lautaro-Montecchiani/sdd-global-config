Issue: #62

# Proposal

## Why

La barra de estado (proyecto, contexto usado, cuota, rama y modelo) hoy solo funciona en una parte de los casos:

- **Claude Code:** el `statusLine` está en `.claude/settings.json` de este repo y apunta a `.claude/statusline.sh` relativo a la raíz del repo actual. Abierto en cualquier otro proyecto (por ejemplo, `gamma-installer`), Claude no muestra ninguna barra.
- **Antigravity CLI:** la plantilla se copia a mano con un placeholder y los scripts los genera el CLI en cada máquina a partir de un prompt. En esta máquina la barra está apagada (`"enabled": false`) y no se ve.
- **Copilot CLI:** acepta una barra personalizada (`statusLine` en `~/.copilot/settings.json`, confirmado en docs.github.com), pero el workflow no la instala.

Además, en terminales que dibujan los caracteres de ancho ambiguo (`█`, `↺`) como dobles, la barra de Claude se desborda y se ve rota.

`scripts/instalar.ps1` ya instala las reglas, las skills y los comandos en cada máquina. Tiene que dejar instalada también la barra de cada CLI, sin pisar la configuración propia de la persona.

## What Changes

- `scripts/instalar.ps1` escribe el `statusLine` en el `settings.json` de usuario de cada CLI presente en la máquina: Claude Code (`~/.claude/settings.json`), Antigravity CLI (`~/.gemini/antigravity-cli/settings.json`) y Copilot CLI (`~/.copilot/settings.json`). Solo toca la clave `statusLine`; el resto del archivo queda igual.
- Si el CLI ya tiene una barra distinta a la del repo, la respeta y avisa. Si ya tiene la del repo en una forma vieja (la entrada con `$SDD_CONFIG_REPO` de Claude, o la de Antigravity apagada), la actualiza.
- Claude y Copilot usan el mismo script del repo (`.claude/statusline.sh`), referenciado con la ruta absoluta del repo en esa máquina. El script pasa a dibujar las barras solo con caracteres de ancho simple y toma el porcentaje de contexto que muestra Copilot cuando viene en la entrada.
- **BREAKING (spec):** los scripts de la barra de Antigravity (`statusline.bat` y `statusline_new.ps1`) pasan a versionarse en `templates/antigravity/` y los instala `instalar.ps1` en `~/.gemini/antigravity-cli/scratch/`. Ya no se genera con un prompt al CLI.
- `instalar.ps1 -Comprobar` informa el estado de la barra de cada CLI. Falla si falta o está desactualizada; avisa sin fallar si la persona tiene una barra propia o si el `settings.json` no es JSON válido.
- Se quita el `statusLine` de `.claude/settings.json` del repo (queda la instalación global, sin dos configuraciones iguales).
- La documentación (`README.md`, `docs/modo-de-uso.md`, `templates/README.md` y `templates/antigravity/README.md`) describe la instalación automática. La matriz por agente marca la barra de Copilot como cubierta. La de Cursor sigue como `no verificado`.

## Capabilities

### New Capabilities
- `agent-status-line`: instalación y comprobación de la barra de estado de cada CLI (Claude Code, Antigravity CLI y Copilot CLI) por `instalar.ps1`, convivencia con la configuración propia de la persona y formato de la barra compartida de Claude y Copilot.

### Modified Capabilities
- `agent-cli-permissions`: el requirement «Barra de estado especificada por comportamiento» deja de prohibir versionar los scripts de Antigravity (ahora los instala `instalar.ps1`), y «La instalación por máquina está documentada» reemplaza el prompt de generación por la instalación automática.

## Non-goals

- **Cursor CLI:** su documentación oficial (`cursor.com/docs/cli/reference/configuration`) no documenta las claves de `statusLine` ni la entrada que recibe el script, y Cursor CLI no está instalado en esta máquina para probarlo. Por la regla de la matriz de `templates/README.md` (una capacidad se marca cubierta solo si la documentación oficial la confirma) y la regla 4 del Agente (no inventar claves), queda en un issue aparte, en la hoja de ruta.
- Activar funciones experimentales de Copilot CLI (`/experimental on` o flags). `instalar.ps1` solo escribe `statusLine`; si la versión instalada lo pide, la documentación indica cómo activarlo.
- Cambiar la plantilla de permisos de Antigravity (`templates/antigravity/settings.json`) o su allowlist.
- Instalar la barra en el `settings.json` de un proyecto. La barra es por usuario.

## Impact

- **Archivos globales modificados** (en cada máquina, al correr `instalar.ps1`): `~/.claude/settings.json`, `~/.gemini/antigravity-cli/settings.json` y `~/.copilot/settings.json`, solo la clave `statusLine`. Es configuración de la persona, por eso se respeta la barra propia y se valida el JSON antes de escribir. También se copian `statusline.bat` y `statusline_new.ps1` a `~/.gemini/antigravity-cli/scratch/`, con el mismo control de cambios locales y manifiesto que el resto de los archivos.
- **Código:** `scripts/instalar.ps1`, un archivo nuevo `scripts/barra-estado.ps1` (funciones de la barra, para no agrandar más `instalar.ps1`), `.claude/statusline.sh`, `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1` (nuevos), y se borra `.claude/settings.json`.
- **Tests:** archivo nuevo `tests/statusline-instalable.Tests.ps1`.
- **Specs:** capability nueva `agent-status-line` y cambios en `agent-cli-permissions`.
- **Dependencias en la máquina:** la barra de Claude y de Copilot necesita `bash` (Git Bash en Windows) y `python3`, como hoy. La de Antigravity, `powershell.exe`.
- **Arquitectura:** ADR nuevo 0005 y actualización de `docs/arquitectura/vision.md`.
