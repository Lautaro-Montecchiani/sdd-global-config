# Design

## Context

- **`.claude/statusline.sh`** (la usan Claude Code sin barra propia y Copilot CLI): script bash con Python adentro. Arma la barra de contexto con `units = 12` y `bar = '#' * filled + '-' * (units - filled)` (línea 53), la del límite de uso igual (línea 89), y el reinicio como `reset_str = f" {h}h{m:02d}m" if h else f" {m}m"` (línea 99). La salida ya es UTF-8 (`io.TextIOWrapper(..., encoding='utf-8')`).
- **`templates/antigravity/statusline_new.ps1`** (Antigravity CLI, llamado desde `statusline.bat` con `powershell.exe`): arma `$line = "${proyecto}   ${contextoStr}   ${cuotaSegment}"`, con `$contextoStr = "${green}${contexto}%${reset}"` y `$cuotaSegment` como `"${cuota}%"` o `"${cuota}% ${reinicio}"`. No dibuja barras. Ya fija `[Console]::OutputEncoding` en UTF-8. Si no viene cuota, muestra `0%`.
- **La barra propia del usuario** (`~/.claude/statusline-command.sh`) es la referencia de diseño: `█`/`░`, 12 unidades y `↺` delante del reinicio.
- **`powershell.exe`** (5.1) lee un `.ps1` sin BOM como ANSI, y el ODD `regla-sin-bom` prohíbe el BOM. Un `█` literal saldría ilegible.
- **#74:** `statusline-instalable/S04` compara `Get-Content -Raw` del archivo instalado (LF) con la fuente (CRLF en un checkout de Windows) y falla solo en Windows.

## Goals / Non-Goals

**Goals:** el mismo diseño de barra en las tres CLI y que S04 pase en Windows.

**Non-Goals:** ver proposal (barra propia, colores, ancho, CRLF de los `.bat`).

## Decisions

### D1. `.claude/statusline.sh`

- Línea 53: `bar = '█' * filled + '░' * (units - filled)`.
- Línea 89: `rl_bar = '█' * rl_filled + '░' * (units - rl_filled)`.
- Línea 99: `reset_str = f" ↺ {h}h{m:02d}m" if h else f" ↺ {m}m"`.
- Nada más cambia (colores, `units = 12`, recorte de porcentajes y líneas).

### D2. `templates/antigravity/statusline_new.ps1`

- Después de la definición de colores, agregar las variables `$lleno = [string][char]0x2588`, `$vacio = [string][char]0x2591` y `$flecha = [string][char]0x21BA`, y una función `Barra` que recibe un porcentaje, lo recorta a 0 a 100 y devuelve `($lleno * $n) + ($vacio * (12 - $n))`, con `$n = [int][Math]::Round($porcentaje / 100 * 12, [MidpointRounding]::AwayFromZero)` (redondeo igual al de Python para 50 % → 6).
- `$contextoStr` pasa a `"${green}$(Barra $contexto) ${contexto}%${reset}"`.
- `$cuotaSegment` pasa a `"$(Barra $cuota) ${cuota}%"` y, si hay `$reinicio`, a `"$(Barra $cuota) ${cuota}% ${flecha} ${reinicio}"`.
- El archivo sigue en ASCII puro, sin BOM: ningún `█`, `░` ni `↺` literal.

### D3. S04 de `tests/statusline-instalable.Tests.ps1` (#74)

Las dos comparaciones de S04 (`statusline.bat` y `statusline_new.ps1`) normalizan los saltos de línea de los dos lados antes de comparar (`-replace "\r\n", "\n"` sobre el texto leído con `-Raw`). No se afloja nada más: el contenido sigue teniendo que ser igual.

- **Alternativas descartadas:**
  - *Escribir `█` literal en el `.ps1` con BOM:* lo prohíbe la regla sin BOM.
  - *Que la barra llame a `pwsh` (PowerShell 7) en vez de `powershell.exe`:* `pwsh` no está garantizado en todas las máquinas y cambiaría `statusline.bat`.

## Impacto en proyectos existentes

- Ningún proyecto cambia. Las máquinas ven la barra nueva después de `pwsh scripts/instalar.ps1`. La barra propia del usuario en Claude Code no se toca.

## Impacto en el sistema

**Componentes afectados:** las barras de Antigravity CLI y Copilot CLI de cada máquina (y la de Claude Code donde no hay barra propia), al instalar.

**Atributos de calidad:**
- mantenibilidad (alta): sin efecto. Los archivos siguen siendo una fuente y una copia instalada que controla `instalar.ps1 -Comprobar`.

**Decisiones de arquitectura:** ninguna.

**Deuda técnica:**
- paga: #74 (S04 dependía de los saltos de línea).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/barra-de-estado-con-bloques.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- Los scripts de la barra no ejecutan texto leído del JSON de entrada — Verificación: revisión del diff: sin `Invoke-Expression`, `eval` ni `exec` en las líneas agregadas.
- Sin secretos ni rutas absolutas del usuario en lo agregado — Verificación: revisión del diff: ninguna ruta `C:\Users` ni token fuera de `openspec/`.
- Los archivos nuevos o modificados no tienen BOM — Verificación: S03 y revisión del diff (primeros bytes de cada archivo).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian scripts instalados y un test existente. Cada test lleva `# test-plan: barra-de-estado-con-bloques/<ID>` arriba del `Probar`. Los tests usan JSON inventados; S01 y S04 corren `.claude/statusline.sh` como lo hace `tests/statusline-instalable.Tests.ps1` (`Ejecutar-BashStatusline`), y S02 y S04 corren `templates/antigravity/statusline_new.ps1` con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`, pasándole el JSON por la entrada estándar. Si `powershell.exe` no existe (CI de Linux), S02 y la parte de Antigravity de S04 se saltean con el motivo escrito.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Barra con bloques y reinicio con flecha / Barra de Claude Code y Copilot | auto: con contexto 50 %, límite 25 % y reinicio 4 h 16 min, la salida sin ANSI tiene `██████░░░░░░ 50%`, `███░░░░░░░░░ 25%` y `↺ 4h16m`, y no tiene `#` ni `-` en las barras | `tests/barra-de-estado-con-bloques.Tests.ps1` |
| S02 | Barra con bloques y reinicio con flecha / Barra de Antigravity | auto: con el JSON de Antigravity (contexto 50 %, `remaining_fraction` 0.75, `reset_in_seconds` 15360), la salida sin ANSI tiene `██████░░░░░░ 50%`, `███░░░░░░░░░ 25%` y `↺ 4h16m` | `tests/barra-de-estado-con-bloques.Tests.ps1` |
| S03 | Barra con bloques y reinicio con flecha / Script de Antigravity legible por Windows PowerShell | auto: todos los bytes de `templates/antigravity/statusline_new.ps1` son menores que 128 (sin BOM) y el archivo contiene `[char]0x2588`, `[char]0x2591` y `[char]0x21BA` | `tests/barra-de-estado-con-bloques.Tests.ps1` |
| S04 | Barra con bloques y reinicio con flecha / Dato inválido: sin límite de uso o porcentaje fuera de rango | auto: sin límite de uso, `statusline.sh` no muestra la segunda barra ni `↺`, y `statusline_new.ps1` muestra `░░░░░░░░░░░░ 0%` sin `↺`; con contexto 150, la barra es de 12 `█` | `tests/barra-de-estado-con-bloques.Tests.ps1` |
| M01 | Cadena real `.bat` → `powershell.exe` | manual (lo hace el Agente en el apply, sin marca de usuario y sin correr `instalar.ps1`): copiar `templates/antigravity/statusline.bat` y `statusline_new.ps1` a `<temp>/.gemini/antigravity-cli/scratch/`, correr `cmd /c` con `USERPROFILE=<temp>` y el JSON de S02 por la entrada estándar, y pegar la salida; tiene que mostrar los bloques y `↺` legibles. Después se borra la carpeta temporal | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `.claude/statusline.sh` y `templates/antigravity/statusline_new.ps1` (con `tests/statusline-instalable.Tests.ps1`, C02 incluido) | Datos de la barra: carpeta, porcentajes, rama y modelo | Cambian solo los caracteres de las barras y el `↺` (S01 a S04). La C02 no se modifica |
| C02 | `tests/statusline-instalable.Tests.ps1`, S04 | Instalación de los dos scripts de Antigravity con el mismo contenido que la fuente | La comparación normaliza los saltos de línea (D3); el control del contenido no se afloja |

## Open Questions

- Ninguna.
