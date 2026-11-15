# Spec Delta

## MODIFIED Requirements

### Requirement: Barra de estado especificada por comportamiento
Los scripts de la barra de estado del CLI del Agente SHALL versionarse en `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1`, y `scripts/instalar.ps1` SHALL instalarlos en `~/.gemini/antigravity-cli/scratch/` según el requirement «Barra de Antigravity CLI instalada por máquina» de la spec `agent-status-line`. `statusline.bat` SHALL invocar a `statusline_new.ps1` con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`, resolviendo la carpeta con `%USERPROFILE%`, sin rutas de la máquina. La plantilla SHALL configurar `statusLine` con `"enabled": true` y un comando que apunte a `statusline.bat` dentro de `~/.gemini/antigravity-cli/scratch/`. La barra SHALL leer por entrada estándar el JSON que envía el CLI y escribir una única línea con el formato `<proyecto>   <contexto>%   <cuota>% <reinicio>  (<rama>)  <modelo>`, con tres espacios entre proyecto, contexto y cuota, y dos espacios antes de la rama y del modelo. Los campos SHALL obtenerse así:

- `<proyecto>`: el último segmento de `workspace.project_dir`; si no existe, el de `cwd`; si no hay entrada válida, el nombre del directorio actual; `desconocido` si nada de lo anterior aplica.
- `<contexto>`: `context_window.used_percentage` redondeado, o `0` si falta, en verde con secuencias ANSI.
- `<cuota>` y `<reinicio>`, de la cuota de 5 horas: se usa `3p-5h` cuando existe y su `remaining_fraction` es menor que 1; si no, `gemini-5h`; si no, `3p-5h`. `<cuota>` es el redondeo de `(1 - remaining_fraction) * 100`, o `0` si no hay cuota. `<reinicio>` es `<h>h<mm>m` calculado desde `reset_in_seconds` cuando es mayor que 0, y se omite en otro caso.
- `<rama>`: la salida de `git rev-parse --abbrev-ref HEAD` ejecutado en `cwd` (o en el directorio actual si `cwd` no existe); el bloque `(<rama>)` se omite si no hay repositorio.
- `<modelo>`: `model.display_name`, o `model.id` si falta; se omite si no hay ninguno.

La barra SHALL NOT fallar ante una entrada vacía o un JSON inválido.

#### Scenario: Línea con datos completos
- **WHEN** la entrada es `{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":42.4},"quota":{"gemini-5h":{"remaining_fraction":0.75,"reset_in_seconds":5400}},"model":{"display_name":"Modelo Ejemplo"}}`
- **THEN** la línea, sin secuencias ANSI, empieza con `mi-proyecto   42%   25% 1h30m`
- **AND** termina con `Modelo Ejemplo`

#### Scenario: Selección de la cuota
- **WHEN** la entrada trae `3p-5h` con `remaining_fraction` 1 y `gemini-5h` con `remaining_fraction` 0.75
- **THEN** la cuota mostrada es `25%`, tomada de `gemini-5h`

#### Scenario: Entrada inválida
- **WHEN** la entrada estándar no es un JSON válido
- **THEN** la barra usa el nombre del directorio actual como proyecto, `0%` de contexto y `0%` de cuota
- **AND** no produce ningún error

#### Scenario: Barra prendida en la plantilla
- **WHEN** se lee `statusLine` de `templates/antigravity/settings.json`
- **THEN** tiene `"enabled": true`

#### Scenario: Scripts versionados sin rutas de la máquina
- **WHEN** se ejecuta `git ls-files templates/antigravity/statusline.bat templates/antigravity/statusline_new.ps1`
- **THEN** devuelve los dos archivos
- **AND** ninguno contiene `C:\Users`, `C:/Users` ni un nombre de usuario

### Requirement: La instalación por máquina está documentada
El `README.md`, `templates/antigravity/README.md` y la guía de uso (`docs/modo-de-uso.md`) SHALL describir la instalación por máquina de la plantilla de permisos, indicando el destino y los valores que hay que completar, y SHALL decir que la barra de estado (scripts y `statusLine`) la instala `scripts/instalar.ps1`, sin pedirle al CLI que la genere. SHALL indicar qué hacer si la barra no aparece: correr `instalar.ps1`, que vuelve a poner `statusLine.enabled` en `true` cuando es la barra del repo, y reiniciar el CLI.

#### Scenario: Pasos de instalación visibles
- **WHEN** se lee la sección de setup por máquina del `README.md` y de `docs/modo-de-uso.md`
- **THEN** describen dónde copiar `templates/antigravity/settings.json`
- **AND** indican reemplazar el placeholder de `trustedWorkspaces`
- **AND** dicen que la barra de estado la instala `instalar.ps1`

#### Scenario: Prompt para generar la barra de estado
- **WHEN** se lee `templates/antigravity/README.md`
- **THEN** no incluye un prompt para que el CLI genere `statusline.bat` ni `statusline_new.ps1`
- **AND** indica que, si la barra no aparece, hay que correr `instalar.ps1` y reiniciar el CLI
