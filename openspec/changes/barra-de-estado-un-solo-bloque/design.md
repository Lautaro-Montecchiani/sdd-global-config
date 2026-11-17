# Design

## Context

- **`.claude/statusline.sh`** (Claude Code sin barra propia y Copilot CLI): arma la barra de contexto en la línea 53 (`bar = '█' * filled + '░' * (units - filled)`) y la del límite de uso en la 89 (`rl_bar`). Las imprime dentro del color del segmento: `f"{C_GREEN}{bar} {percent}{C_RESET}"` (línea 106) y `f"  {rl_color}{rl_bar} {rl_percent}{reset_str}{C_RESET}"` (línea 100), con `rl_color` naranja (`C_ORANGE`) o rojo (`C_RED`, desde 90 %). Los colores están definidos en las líneas 75 a 81.
- **`templates/antigravity/statusline_new.ps1`** (Antigravity CLI): define `$lleno = [string][char]0x2588`, `$vacio = [string][char]0x2591` y `$flecha` (líneas 8 a 10), y `Barra` devuelve `($lleno * $n) + ($vacio * (12 - $n))` (línea 17). El contexto va en verde (`"${green}$(Barra $contexto) ${contexto}%${reset}"`, línea 73) y la cuota sin color (`"$(Barra $cuota) ${cuota}%"`, líneas 113 y 115).
- **El problema** (captura del usuario del 17/11/2026): `░` (U+2591) se dibuja más ancho que `█` (U+2588) en su terminal, así que la parte vacía ocupa más que la llena. Los dos caracteres son de ancho ambiguo en Unicode, y la terminal resuelve `░` con una fuente de reemplazo más ancha. Usando un solo carácter para las 12 posiciones, la barra mide siempre lo mismo.
- **Decisión del usuario (17/11/2026, opción A):** lleno `█` en el color del segmento y vacío `█` en gris. Se descartó volver a ASCII (`#`/`-`).
- **Tests que esperan `░`:** S01, S02, S03 y S04 de `tests/barra-de-estado-con-bloques.Tests.ps1` (líneas 107, 108, 125, 126, 140, 152 y 169) y S14, S16, S21 y S23 de `tests/statusline-instalable.Tests.ps1` (líneas 373, 374, 396, 451 y 471).

## Goals / Non-Goals

**Goals:** que la barra mida 12 posiciones iguales en cualquier terminal, con la proporción visible por el color.

**Non-Goals:** ver proposal (barra propia del usuario, `↺`, color de la cuota de Antigravity).

## Decisions

### D1. `.claude/statusline.sh`

- Mover el bloque de colores (líneas 75 a 81, de `C_RESET` a `C_RED`) sin cambiarlo hasta justo antes de `units = 12` (línea 50), y agregar al final de ese bloque `C_GRAY = '\033[90m'`. Hace falta porque `bar` se arma en la línea 53, antes de que hoy se definan los colores. Nada más se mueve.
- Barra de contexto: `bar = '█' * filled + C_GRAY + '█' * (units - filled) + C_GREEN`. La línea 106 queda como está (`f"{C_GREEN}{bar} {percent}{C_RESET}"`), así que el porcentaje sale en verde.
- Barra del límite de uso: `rl_bar = '█' * rl_filled + C_GRAY + '█' * (units - rl_filled) + rl_color`, armada después de calcular `rl_color` (hoy `rl_color` se calcula después de `rl_bar`: se invierte ese orden). La línea 100 no cambia.
- La secuencia gris se escribe siempre, aunque no haya posiciones vacías (100 %): así la salida es predecible.
- No queda ningún `░` en el archivo. `↺`, los porcentajes, el recorte y el resto de la línea no cambian.

### D2. `templates/antigravity/statusline_new.ps1`

- Agregar `$gris = "$esc[90m"` después de `$reset` (línea 6) y borrar `$vacio` (línea 9).
- `Barra` recibe un segundo parámetro, `[string]$color`, y devuelve `($lleno * $n) + $gris + ($lleno * (12 - $n)) + $color`. El cálculo de `$n` (recorte a 0 a 100 y redondeo `AwayFromZero`) no cambia.
- `$contextoStr` pasa a `"${green}$(Barra $contexto $green) ${contexto}%${reset}"`.
- `$cuotaSegment` pasa a `"$(Barra $cuota $reset) ${cuota}%"` y, con reinicio, a `"$(Barra $cuota $reset) ${cuota}% ${flecha} ${reinicio}"`: después del gris vuelve al color por defecto, porque la cuota no tiene color.
- El archivo sigue en ASCII puro y sin BOM: ningún `█`, `░` ni `↺` literal, y ya no aparece `0x2591`.

### D3. Tests existentes que esperan `░`

Siguen al requirement modificado, sin aflojar nada más. Sin ANSI, la barra queda en 12 `█`; la proporción se controla en S01 a S04 nuevos, con la salida con ANSI.

- `tests/barra-de-estado-con-bloques.Tests.ps1`:
  - S01 y S02: esperan `████████████ 50%` y `████████████ 25%` en la salida sin ANSI, en vez de `██████░░░░░░ 50%` y `███░░░░░░░░░ 25%`. `↺ 4h16m` y el control de `#`/`-` no cambian.
  - S03: el archivo tiene que contener `[char]0x2588` y `[char]0x21BA` y **no** contener `0x2591`. El control de bytes menores que 128 no cambia.
  - S04: `statusline.sh` sin límite muestra una sola barra de `█{12}` (en vez de `[█░]{12}`); `statusline_new.ps1` sin cuota muestra `████████████ 0%` (en vez de `░░░░░░░░░░░░ 0%`). El resto no cambia.
- `tests/statusline-instalable.Tests.ps1`:
  - S14: espera `████████████ 50%` y `████████████ 25%`.
  - S16: saca `[char]0x2591` de los caracteres permitidos (quedan ASCII imprimible, 10, 13, `0x2588` y `0x21BA`).
  - S21: espera que la línea empiece con `mi-proyecto   ████████████ 42%   ████████████ 25% ↺ 1h30m`.
  - S23: la regex pasa de `0%\s+░{12} 0%` a `0%\s+█{12} 0%`.

- **Alternativas descartadas:**
  - *Volver a `#`/`-`:* el usuario prefiere los bloques.
  - *Otro carácter para el vacío (`▒`, `·`, espacio):* también puede tener ancho distinto o no verse; con el mismo `█` el ancho es seguro.
  - *Cambiar `↺`:* va al final y no corre las barras; en la terminal del usuario se ve bien.

## Impacto en proyectos existentes

- Ningún proyecto cambia. Las máquinas ven la barra nueva después de `pwsh scripts/instalar.ps1` desde `master`. La barra propia del usuario en Claude Code no se toca.

## Impacto en el sistema

**Componentes afectados:** las barras de Antigravity CLI y Copilot CLI de cada máquina (y la de Claude Code donde no hay barra propia), al instalar.

**Atributos de calidad:**
- mantenibilidad (alta): sin efecto. Los archivos siguen siendo una fuente y una copia instalada que controla `instalar.ps1 -Comprobar`.

**Decisiones de arquitectura:** ninguna.

**Deuda técnica:** ninguna. Descubre fuera del repo que la barra propia del usuario (`~/.claude/statusline-command.sh`) tiene el mismo desborde; se ajusta aparte.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/barra-de-estado-un-solo-bloque.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- Los scripts de la barra no ejecutan texto leído del JSON de entrada — Verificación: revisión del diff: sin `Invoke-Expression`, `eval` ni `exec` en las líneas agregadas.
- Sin secretos ni rutas absolutas del usuario en lo agregado — Verificación: revisión del diff: ninguna ruta `C:\Users` ni token fuera de `openspec/`.
- Los archivos nuevos o modificados no tienen BOM — Verificación: S03 y revisión del diff (primeros bytes de cada archivo).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian scripts instalados y tests existentes. Cada test nuevo lleva `# test-plan: barra-de-estado-un-solo-bloque/<ID>` arriba del `Probar`. Los tests usan JSON inventados y miran la salida **con** ANSI (sin ANSI la barra siempre es de 12 `█`): S01 y S04 corren `.claude/statusline.sh` como `tests/barra-de-estado-con-bloques.Tests.ps1` (`Ejecutar-BashStatusline`), y S02 y S04 corren `templates/antigravity/statusline_new.ps1` con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`, pasándole el JSON por la entrada estándar. Si `powershell.exe` no existe (CI de Linux), S02 y la parte de Antigravity de S04 se saltean con el motivo escrito.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Barra con bloques y reinicio con flecha / Barra de Claude Code y Copilot | auto: con contexto 50 %, límite 25 % y reinicio 4 h 16 min, la salida con ANSI contiene `█{6}` + `ESC[90m` + `█{6}` + `ESC[32m` + ` 50%` y `█{3}` + `ESC[90m` + `█{9}` + `ESC[33m` + ` 25%`, contiene `↺ 4h16m` y no contiene `░` | `tests/barra-de-estado-un-solo-bloque.Tests.ps1` |
| S02 | Barra con bloques y reinicio con flecha / Barra de Antigravity | auto: con el JSON de Antigravity (contexto 50 %, `remaining_fraction` 0.75, `reset_in_seconds` 15360), la salida con ANSI contiene `█{6}` + `ESC[90m` + `█{6}` + `ESC[32m` + ` 50%` y `█{3}` + `ESC[90m` + `█{9}` + `ESC[0m` + ` 25%`, contiene `↺ 4h16m` y no contiene `░` | `tests/barra-de-estado-un-solo-bloque.Tests.ps1` |
| S03 | Barra con bloques y reinicio con flecha / Script de Antigravity legible por Windows PowerShell | auto: todos los bytes de `statusline_new.ps1` son menores que 128, contiene `[char]0x2588` y `[char]0x21BA`, y no contiene `0x2591` | `tests/barra-de-estado-un-solo-bloque.Tests.ps1` |
| S04 | Barra con bloques y reinicio con flecha / Dato inválido: sin límite de uso o porcentaje fuera de rango | auto: sin límite, `statusline.sh` no muestra la segunda barra ni `↺`; sin cuota, `statusline_new.ps1` muestra `ESC[90m` + `█{12}` antes de ` 0%`, sin `↺`; con contexto 150 las dos barras de contexto tienen `█{12}` seguido de `ESC[90m` (sin posiciones vacías); con contexto -5, `ESC[90m` + `█{12}` | `tests/barra-de-estado-un-solo-bloque.Tests.ps1` |
| M01 | Cadena real `.bat` → `powershell.exe` | manual (lo hace el Agente en el apply, sin `instalar.ps1`): copiar `templates/antigravity/statusline.bat` y `statusline_new.ps1` a `<temp>/.gemini/antigravity-cli/scratch/`, correr `cmd /c` con `USERPROFILE=<temp>` y el JSON de S02 por la entrada estándar, y pegar la salida con las secuencias ANSI visibles (por ejemplo, reemplazando `ESC` por `<ESC>`). Después se borra la carpeta temporal | — |
| M02 | Ancho de la barra en la terminal del usuario | manual (lo corre el usuario): en la terminal donde se desbordaba, desde la rama del change y sin `instalar.ps1`, pasar el JSON de S02 a `powershell.exe -NoProfile -ExecutionPolicy Bypass -File templates/antigravity/statusline_new.ps1` y confirmar que las dos barras miden lo mismo y que la parte vacía se ve en gris | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `.claude/statusline.sh` y `templates/antigravity/statusline_new.ps1` (con `tests/statusline-instalable.Tests.ps1`, C02 incluido) | Datos de la barra: carpeta, porcentajes, rama, modelo y `↺` | Cambia solo la parte vacía de las barras (S01 a S04). La C02 no se modifica |
| C02 | `tests/barra-de-estado-con-bloques.Tests.ps1`, S01 a S04 | Barras de 12 posiciones, `↺` y casos sin límite o fuera de rango | Pasan a esperar `█` sin `░` según D3 |
| C03 | `tests/statusline-instalable.Tests.ps1`, S14, S16, S21 y S23 | Formato de las barras de Claude, Copilot y Antigravity | Pasan a esperar `█` sin `░` según D3 |

## Open Questions

- Ninguna.
