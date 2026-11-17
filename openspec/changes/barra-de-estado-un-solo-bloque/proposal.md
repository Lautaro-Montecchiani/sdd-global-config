Issue: #79

## Why

Las barras que instala el workflow se desbordan en la terminal del usuario: `░` se dibuja más ancho que `█`, así que la parte vacía de la barra ocupa más que la llena (captura del 17/11/2026: al 41 %, 5 `█` y 7 `░`, con la parte vacía mucho más larga). Es el mismo problema que llevó a la D4 de `statusline-instalable` el 14/11. `barra-de-estado-con-bloques` (PR #76) volvió a los bloques con la condición de revertir con otro change si se repetía. El usuario eligió el 17/11 la opción A: dibujar la parte vacía con el mismo `█`, en gris.

## What Changes

- **`.claude/statusline.sh`** (Claude Code sin barra propia y Copilot CLI): la parte vacía de las dos barras pasa de `░` a `█` en gris (`ESC[90m`), y vuelve al color del segmento antes del porcentaje. Los llenos siguen con su color (verde el contexto; naranja o rojo el límite de uso).
- **`templates/antigravity/statusline_new.ps1`** (Antigravity CLI): lo mismo. Se saca `$vacio` (`[char]0x2591`) y `Barra` recibe el color del segmento. El archivo sigue en ASCII puro y sin BOM.
- **`↺` se mantiene:** va al final de la línea y no corre las barras.
- **Tests:** S01 a S04 nuevos en `tests/barra-de-estado-un-solo-bloque.Tests.ps1`, que miran la salida con ANSI (sin ANSI la barra es siempre de 12 `█`). Se adaptan S01 a S04 de `tests/barra-de-estado-con-bloques.Tests.ps1` y S14, S16, S21 y S23 de `tests/statusline-instalable.Tests.ps1`, que esperaban `░`.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `agent-status-line`: «Barra con bloques y reinicio con flecha» (la parte vacía es `█` en gris) y «Formato de la barra de Claude y Copilot» (sin `░`).
- `agent-cli-permissions`: «Barra de estado especificada por comportamiento» (barras de `█` con la parte vacía en gris).

## Non-goals

- Cambiar la barra propia del usuario (`~/.claude/statusline-command.sh`): tiene el mismo problema, pero está fuera del repo y `instalar.ps1` la respeta. Se ajusta aparte.
- Cambiar `↺`, los datos que se muestran, el ancho de 12 o la forma de instalar.
- Darle color a la cuota de Antigravity (hoy va sin color).

## Impact

- Las barras de Antigravity CLI y Copilot CLI (y la de Claude Code donde no hay barra propia) se ven después de `pwsh scripts/instalar.ps1` desde `master`.
- Archivo global modificado: `.claude/statusline.sh`, que `instalar.ps1` referencia desde el repo para Claude Code y Copilot CLI; cambia el dibujo de la barra.
- Sin color ANSI (por ejemplo, en un log), las barras se ven llenas: los porcentajes siguen al lado.
- Cierra #79.
