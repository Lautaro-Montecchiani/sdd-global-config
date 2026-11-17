## ADDED Requirements

### Requirement: Barra con bloques y reinicio con flecha
La barra que instala el workflow (`.claude/statusline.sh` y `templates/antigravity/statusline_new.ps1`) SHALL dibujar el contexto y el límite de uso con barras de 12 unidades de `█` (lleno) y `░` (vacío) antes de su porcentaje, y el reinicio con `↺` adelante. El `.ps1` SHALL quedar en ASCII puro y sin BOM.

#### Scenario: Barra de Claude Code y Copilot
- **WHEN** `.claude/statusline.sh` recibe un JSON con contexto al 50 % y límite de uso al 25 % con reinicio en 4 h 16 min
- **THEN** la primera línea tiene una barra de 12 caracteres `█`/`░` con 6 llenos antes de `50%`, otra con 3 llenos antes de `25%` y `↺4h16m`
- **AND** no tiene `#` ni `-` como relleno de barra

#### Scenario: Barra de Antigravity
- **WHEN** `statusline_new.ps1` corre con `powershell.exe` y recibe un JSON con contexto al 50 % y cuota usada al 25 % con reinicio en 4 h 16 min
- **THEN** la línea tiene una barra de 12 caracteres `█`/`░` antes de `50%`, otra antes de `25%` y `↺4h16m`, sin caracteres ilegibles

#### Scenario: Script de Antigravity legible por Windows PowerShell
- **WHEN** se leen los bytes de `templates/antigravity/statusline_new.ps1`
- **THEN** no hay bytes fuera de ASCII ni BOM
- **AND** `█`, `░` y `↺` se arman con `[char]0x2588`, `[char]0x2591` y `[char]0x21BA`

#### Scenario: Dato inválido: sin límite de uso o porcentaje fuera de rango
- **WHEN** el JSON no trae límite de uso (o cuota), o trae un porcentaje mayor que 100 o negativo
- **THEN** la barra sale sin error y sin `↺`: sin límite de uso, `statusline.sh` no dibuja esa barra (como hoy) y `statusline_new.ps1` dibuja la barra vacía con `0%` (como hoy muestra `0%`)
- **AND** un porcentaje mayor que 100 o negativo se dibuja como barra llena o vacía
