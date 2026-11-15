# agent-status-line Specification

## Purpose
Que `scripts/instalar.ps1` deje instalada en cada máquina la barra de estado de cada CLI del workflow (Claude Code, Antigravity CLI y Copilot CLI), sin pisar la barra propia de la persona, y que `-Comprobar` informe si está al día.

## Requirements

### Requirement: Barra de Claude Code instalada por máquina
`scripts/instalar.ps1` SHALL escribir en `<Destino>/.claude/settings.json` la clave `statusLine` con `"type": "command"` y `"command": "bash \"<raíz del repo>/.claude/statusline.sh\""`, donde `<raíz del repo>` es la ruta absoluta del repo `sdd-global-config` en esa máquina, resuelta desde la ubicación del script y escrita con barras `/`. Si `<Destino>/.claude/settings.json` no existe, SHALL crearlo con solo la clave `statusLine`. La barra del repo SHALL reconocerse cuando el comando, comparado sin distinguir mayúsculas ni el tipo de barra, es el esperado o la forma anterior `bash "$SDD_CONFIG_REPO/.claude/statusline.sh"`; la forma anterior SHALL reemplazarse por la esperada.

#### Scenario: Destino sin settings.json
- **WHEN** se corre `instalar.ps1 -Destino <carpeta vacía> -SinVault`
- **THEN** `<carpeta>/.claude/settings.json` existe y su `statusLine.command` es `bash "<raíz del repo>/.claude/statusline.sh"` con barras `/`

#### Scenario: Forma anterior con variable de entorno
- **WHEN** `<Destino>/.claude/settings.json` tiene `statusLine.command` igual a `bash "$SDD_CONFIG_REPO/.claude/statusline.sh"` y se corre `instalar.ps1`
- **THEN** `statusLine.command` queda con la ruta absoluta del repo
- **AND** la tabla muestra la barra de Claude como `atrasado` antes de escribir

### Requirement: Barra de Antigravity CLI instalada por máquina
Solo si existe `<Destino>/.gemini/antigravity-cli`, `instalar.ps1` SHALL copiar `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1` a `<Destino>/.gemini/antigravity-cli/scratch/`, con la misma clasificación (`igual`, `atrasado`, `con cambios locales`), manifiesto, respaldo con `-Forzar` y tabla que el resto de los archivos instalados. Además SHALL escribir en `<Destino>/.gemini/antigravity-cli/settings.json` la clave `statusLine` con `"type": "command"`, `"command": "<Destino con barras />/.gemini/antigravity-cli/scratch/statusline.bat"` y `"enabled": true`. La barra del repo SHALL reconocerse cuando el comando termina en `/.gemini/antigravity-cli/scratch/statusline.bat` (sin distinguir mayúsculas ni el tipo de barra); si es la del repo con otra ruta o con `"enabled": false`, SHALL quedar `atrasado` y reemplazarse por la esperada.

#### Scenario: Barra apagada
- **WHEN** `<Destino>/.gemini/antigravity-cli/settings.json` tiene `statusLine` con el comando a `scratch/statusline.bat` y `"enabled": false`, y se corre `instalar.ps1`
- **THEN** `statusLine.enabled` queda en `true`
- **AND** `toolPermission`, `permissions` y `trustedWorkspaces` quedan con los mismos valores que antes

#### Scenario: Scripts instalados
- **WHEN** existe `<Destino>/.gemini/antigravity-cli` y se corre `instalar.ps1`
- **THEN** `scratch/statusline.bat` y `scratch/statusline_new.ps1` tienen el mismo contenido que sus fuentes de `templates/antigravity/`
- **AND** el manifiesto tiene un hash para cada uno

#### Scenario: Sin Antigravity
- **WHEN** no existe `<Destino>/.gemini/antigravity-cli` y se corre `instalar.ps1`
- **THEN** no se crea ningún archivo en `<Destino>/.gemini/antigravity-cli`
- **AND** la tabla no tiene filas de la barra de Antigravity

### Requirement: Barra de Copilot CLI instalada por máquina
Solo si existe `<Destino>/.copilot`, `instalar.ps1` SHALL escribir en `<Destino>/.copilot/settings.json` la clave `statusLine` con `"type": "command"` y el mismo `command` que la barra de Claude Code, y SHALL crear el archivo con solo esa clave si no existe. SHALL NOT escribir `config.json` ni activar funciones experimentales.

#### Scenario: Copilot instalado
- **WHEN** existe `<Destino>/.copilot` sin `settings.json` y se corre `instalar.ps1`
- **THEN** `<Destino>/.copilot/settings.json` tiene solo `statusLine` con el comando de la barra de Claude Code
- **AND** no existe `<Destino>/.copilot/config.json`

#### Scenario: Sin Copilot
- **WHEN** no existe `<Destino>/.copilot` y se corre `instalar.ps1`
- **THEN** no se crea `<Destino>/.copilot`

### Requirement: Convivencia con la configuración propia
Al escribir un `settings.json`, `instalar.ps1` SHALL cambiar solo la clave `statusLine`: el resto de las claves y sus valores SHALL quedar iguales, y dentro de `statusLine` SHALL conservar las claves que no escribe (por ejemplo `padding`). Si `statusLine` existe y no es la barra del repo, SHALL clasificarla como `propia`, no SHALL cambiarla (tampoco con `-Forzar`) y SHALL mostrar un aviso con el archivo. Si el `settings.json` no es JSON válido, SHALL clasificarlo como `json inválido`, no SHALL escribirlo y SHALL mostrar un aviso con el archivo, sin cortar la instalación del resto. Los `settings.json` SHALL escribirse en UTF-8 sin BOM.

#### Scenario: Barra propia
- **WHEN** `<Destino>/.claude/settings.json` tiene `statusLine.command` igual a `mi-barra.sh` y se corre `instalar.ps1`
- **THEN** `statusLine.command` sigue siendo `mi-barra.sh`
- **AND** la salida muestra un aviso que nombra `.claude/settings.json`
- **AND** el código de salida es 0

#### Scenario: Otras claves intactas
- **WHEN** `<Destino>/.claude/settings.json` tiene `model`, `permissions.allow` y `theme`, sin `statusLine`, y se corre `instalar.ps1`
- **THEN** `model`, `permissions.allow` y `theme` tienen los mismos valores que antes
- **AND** `statusLine` es la barra del repo

#### Scenario: Dato inválido: settings.json que no es JSON
- **WHEN** `<Destino>/.claude/settings.json` contiene `{ "model": ` (JSON cortado) y se corre `instalar.ps1`
- **THEN** el archivo queda byte a byte igual
- **AND** la salida muestra un aviso con `json inválido` y `.claude/settings.json`
- **AND** el resto de los archivos se instala y el código de salida es 0

### Requirement: Comprobación de la barra
La tabla de `instalar.ps1` SHALL tener una fila por cada barra que corresponde instalar (`settings: barra Claude`, `settings: barra Antigravity` y `settings: barra Copilot`) con su estado: `igual`, `falta`, `atrasado`, `propia` o `json inválido`. `instalar.ps1 -Comprobar` SHALL terminar con código distinto de 0 si alguna barra está `falta` o `atrasado`, y SHALL listarla. Los estados `propia` y `json inválido` SHALL mostrarse como aviso sin cambiar el código de salida. Con `-Comprobar` o `-Simular`, `instalar.ps1` NO SHALL escribir ningún `settings.json`.

#### Scenario: Barra al día
- **WHEN** se corre `instalar.ps1` sobre un destino de prueba y después `instalar.ps1 -Comprobar` con los mismos parámetros
- **THEN** la comprobación termina con código 0 y la fila `settings: barra Claude` está `igual`

#### Scenario: Barra que falta
- **WHEN** después de instalar se borra `statusLine` de `<Destino>/.claude/settings.json` y se corre `instalar.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `settings: barra Claude` como `falta`
- **AND** `<Destino>/.claude/settings.json` no cambia

#### Scenario: Barra propia en la comprobación
- **WHEN** después de instalar se cambia `statusLine.command` por `mi-barra.sh` y se corre `instalar.ps1 -Comprobar`
- **THEN** termina con código 0 y muestra un aviso con `propia`

### Requirement: Formato de la barra de Claude y Copilot
`.claude/statusline.sh` SHALL leer por entrada estándar el JSON del CLI y escribir dos líneas: la primera con el nombre de la carpeta, la barra y el porcentaje de contexto, la barra y el porcentaje de la cuota de 5 horas con su reinicio (solo si viene `rate_limits.five_hour`) y la rama entre paréntesis; la segunda con el modelo. Las barras SHALL tener 12 posiciones dibujadas solo con `#` (lleno) y `-` (vacío), y la salida SHALL NOT contener caracteres de ancho ambiguo (por ejemplo `█`, `░` o `↺`). El reinicio SHALL escribirse como `<h>h<mm>m` o `<m>m`. El porcentaje de contexto SHALL tomarse de `context_window.current_context_used_percentage` si existe (Copilot CLI), si no de `context_window.used_percentage` (Claude Code), y si no SHALL calcularse con los tokens de `context_window.current_usage`; sin datos SHALL mostrar `--`. La carpeta SHALL salir de `workspace.current_dir`, si no de `cwd`, si no del directorio actual, y el modelo de `model.display_name` o `model.id`. La barra SHALL NOT fallar ante una entrada vacía o un JSON inválido.

#### Scenario: Entrada de Claude Code
- **WHEN** la entrada es `{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25}}}`
- **THEN** la primera línea, sin secuencias ANSI, empieza con `mi-proyecto` y contiene `######------ 50%` y `###--------- 25%`
- **AND** la segunda línea es `Modelo Ejemplo`

#### Scenario: Entrada de Copilot CLI
- **WHEN** la entrada trae `context_window.used_percentage` 10 y `context_window.current_context_used_percentage` 50, sin `rate_limits`
- **THEN** la barra de contexto muestra `50%`
- **AND** la línea no tiene barra de cuota

#### Scenario: Solo caracteres de ancho simple
- **WHEN** se pasa cualquiera de las entradas anteriores
- **THEN** ningún carácter de la salida, sin secuencias ANSI, tiene ancho ambiguo o doble según Unicode (East Asian Width `A`, `W` o `F`)

#### Scenario: Dato inválido: entrada que no es JSON
- **WHEN** la entrada estándar es `no es json`
- **THEN** la barra muestra el nombre del directorio actual y `--` como contexto
- **AND** termina con código 0 sin escribir errores

### Requirement: Una sola configuración de la barra en el repo
El repo SHALL NOT tener `statusLine` en `.claude/settings.json`: la barra de Claude Code en `sdd-global-config` SHALL salir de la instalación de usuario, igual que en el resto de los proyectos.

#### Scenario: Sin barra de proyecto
- **WHEN** se busca `statusLine` en los `settings*.json` versionados dentro de `.claude/`
- **THEN** no hay resultados

### Requirement: Barra de estado documentada por agente
`README.md`, `docs/modo-de-uso.md`, `templates/README.md` y `templates/antigravity/README.md` SHALL decir que `instalar.ps1` instala la barra de Claude Code, Antigravity CLI y Copilot CLI cuando el CLI está en la máquina, que respeta una barra propia, y qué hacer si no aparece: reiniciar el CLI, correr `instalar.ps1 -Comprobar`, y en Copilot CLI activar las funciones experimentales con `/experimental on` si la versión instalada lo pide. La matriz de `templates/README.md` SHALL marcar la barra de Copilot como cubierta, con la fuente de docs.github.com, y la de Cursor como `no verificado`, con el motivo (sin claves documentadas en la documentación oficial).

#### Scenario: Matriz actualizada
- **WHEN** se lee la fila de Copilot y la de Cursor en la columna "Barra de estado" de `templates/README.md`
- **THEN** la de Copilot nombra `~/.copilot/settings.json` instalado por `instalar.ps1`
- **AND** la de Cursor dice `no verificado`

#### Scenario: Qué hacer si no aparece
- **WHEN** se lee la sección de la barra de estado de `docs/modo-de-uso.md`
- **THEN** menciona `instalar.ps1 -Comprobar`, reiniciar el CLI y `/experimental on` para Copilot CLI
