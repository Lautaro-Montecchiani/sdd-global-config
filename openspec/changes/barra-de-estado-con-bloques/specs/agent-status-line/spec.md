## ADDED Requirements

### Requirement: Barra con bloques y reinicio con flecha
La barra que instala el workflow (`.claude/statusline.sh` y `templates/antigravity/statusline_new.ps1`) SHALL dibujar el contexto y el límite de uso con barras de 12 unidades de `█` (lleno) y `░` (vacío) antes de su porcentaje, y el reinicio con `↺` adelante. El `.ps1` SHALL quedar en ASCII puro y sin BOM.

#### Scenario: Barra de Claude Code y Copilot
- **WHEN** `.claude/statusline.sh` recibe un JSON con contexto al 50 % y límite de uso al 25 % con reinicio en 4 h 16 min
- **THEN** la primera línea tiene una barra de 12 caracteres `█`/`░` con 6 llenos antes de `50%`, otra con 3 llenos antes de `25%` y `↺ 4h16m`
- **AND** no tiene `#` ni `-` como relleno de barra

#### Scenario: Barra de Antigravity
- **WHEN** `statusline_new.ps1` corre con `powershell.exe` y recibe un JSON con contexto al 50 % y cuota usada al 25 % con reinicio en 4 h 16 min
- **THEN** la línea tiene una barra de 12 caracteres `█`/`░` antes de `50%`, otra antes de `25%` y `↺ 4h16m`, sin caracteres ilegibles

#### Scenario: Script de Antigravity legible por Windows PowerShell
- **WHEN** se leen los bytes de `templates/antigravity/statusline_new.ps1`
- **THEN** no hay bytes fuera de ASCII ni BOM
- **AND** `█`, `░` y `↺` se arman con `[char]0x2588`, `[char]0x2591` y `[char]0x21BA`

#### Scenario: Dato inválido: sin límite de uso o porcentaje fuera de rango
- **WHEN** el JSON no trae límite de uso (o cuota), o trae un porcentaje mayor que 100 o negativo
- **THEN** la barra sale sin error y sin `↺`: sin límite de uso, `statusline.sh` no dibuja esa barra (como hoy) y `statusline_new.ps1` dibuja la barra vacía con `0%` (como hoy muestra `0%`)
- **AND** un porcentaje mayor que 100 o negativo se dibuja como barra llena o vacía

## MODIFIED Requirements

### Requirement: Formato de la barra de Claude y Copilot
`.claude/statusline.sh` SHALL leer por entrada estándar el JSON del CLI y escribir dos líneas: la primera con el nombre de la carpeta, la barra y el porcentaje de contexto, la barra y el porcentaje de la cuota de 5 horas con su reinicio (solo si viene `rate_limits.five_hour`) y la rama entre paréntesis; la segunda con el modelo. Las barras SHALL tener 12 posiciones dibujadas con `█` (lleno) y `░` (vacío). El reinicio SHALL escribirse como `↺ <h>h<mm>m` o `↺ <m>m`. Fuera de `█`, `░` y `↺`, la salida SHALL usar solo caracteres ASCII imprimibles. El porcentaje de contexto SHALL tomarse de `context_window.current_context_used_percentage` si existe (Copilot CLI), si no de `context_window.used_percentage` (Claude Code), y si no SHALL calcularse con los tokens de `context_window.current_usage`; sin datos SHALL mostrar `--`. La carpeta SHALL salir de `workspace.current_dir`, si no de `cwd`, si no del directorio actual, y el modelo de `model.display_name` o `model.id`. La barra SHALL NOT fallar ante una entrada vacía o un JSON inválido.

#### Scenario: Entrada de Claude Code
- **WHEN** la entrada es `{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25}}}`
- **THEN** la primera línea, sin secuencias ANSI, empieza con `mi-proyecto` y contiene `██████░░░░░░ 50%` y `███░░░░░░░░░ 25%`
- **AND** la segunda línea es `Modelo Ejemplo`

#### Scenario: Entrada de Copilot CLI
- **WHEN** la entrada trae `context_window.used_percentage` 10 y `context_window.current_context_used_percentage` 50, sin `rate_limits`
- **THEN** la barra de contexto muestra `50%`
- **AND** la línea no tiene barra de cuota

#### Scenario: Solo caracteres de ancho simple
- **WHEN** se pasa cualquiera de las entradas anteriores
- **THEN** todo carácter de la salida, sin secuencias ANSI, es ASCII imprimible o un salto de línea, salvo `█`, `░` y `↺` de las barras y el reinicio

#### Scenario: Dato inválido: entrada que no es JSON
- **WHEN** la entrada estándar es `no es json`
- **THEN** la barra muestra el nombre del directorio actual y `--` como contexto
- **AND** termina con código 0 sin escribir errores
