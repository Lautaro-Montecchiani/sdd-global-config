Issue: #75

## Why

El usuario quiere que la barra de estado que instala el workflow se vea como su barra propia de Claude Code: barras de progreso con `█` (lleno) y `░` (vacío) para el contexto y el límite de uso, y el reinicio con `↺` adelante (por ejemplo, `↺ 4h16m`). Hoy `.claude/statusline.sh` (Claude Code sin barra propia y Copilot CLI) dibuja con `#` y `-` y sin `↺`, y la barra de Antigravity (`templates/antigravity/statusline_new.ps1`) no dibuja barras: muestra solo los porcentajes. Además, `statusline-instalable/S04` falla en Windows porque compara texto con distintos saltos de línea (issue #74).

## What Changes

- **`.claude/statusline.sh`:** las dos barras pasan a `█`/`░` y el reinicio a `↺ <h>h<mm>m` (o `↺ <m>m`). El resto (colores, ancho de 12 unidades y líneas) no cambia.
- **`templates/antigravity/statusline_new.ps1`:** suma las dos barras de 12 unidades con `█`/`░` delante de los porcentajes de contexto y de cuota, y el `↺` delante del reinicio. Los caracteres se arman con su código (`[char]0x2588`, `[char]0x2591` y `[char]0x21BA`), porque `powershell.exe` (Windows PowerShell 5.1) lee como ANSI un `.ps1` UTF-8 sin BOM, y el BOM está prohibido por la regla sin BOM.
- **`tests/statusline-instalable.Tests.ps1`, S04:** compara el contenido instalado y la fuente sin depender de los saltos de línea (cierra #74).
- **Tests nuevos:** `tests/barra-de-estado-con-bloques.Tests.ps1`.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `agent-status-line`: requirement nuevo sobre el diseño de la barra (bloques, `↺` y caracteres seguros para Windows PowerShell 5.1).

## Non-goals

- Cambiar la barra propia del usuario (`~/.claude/statusline-command.sh`): `instalar.ps1` la sigue respetando.
- Cambiar colores, ancho, datos que se muestran o la forma de instalar.
- Que `instalar.ps1` escriba los `.bat` con CRLF: queda como observación del #74, y este change solo arregla la comparación del test.

## Impact

- Antigravity CLI y Copilot CLI (y Claude Code en máquinas sin barra propia) ven la barra nueva después de `instalar.ps1`.
- Cierra #75 y #74.
