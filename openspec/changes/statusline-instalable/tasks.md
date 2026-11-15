# Tasks

Todos los archivos nuevos o modificados van en UTF-8 **sin BOM** y sin cambiar los finales de línea de los archivos existentes. Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1`. Cada test lleva el comentario `# test-plan: statusline-instalable/<ID>`.

## 1. Confirmaciones y caracterización

- [x] 1.1 Correr `copilot help config` y pegar en el resumen del apply la parte de `statusLine` (y de `experimental`/`footer` si aparece). Si `statusLine` no admite `type: "command"` y `command`, frenar y avisar sin seguir con Copilot (design, Open Questions).
- [x] 1.2 C01 — Correr `pwsh -NoProfile -File tests/instalar.Tests.ps1` antes de modificar `scripts/instalar.ps1` y pegar la salida en verde.
- [x] 1.3 C02 — Crear `tests/statusline-instalable.Tests.ps1` con el test C02 (con la entrada de S14, la salida de `bash .claude/statusline.sh` sin ANSI trae el nombre de la carpeta, `50%`, `25%`, la rama entre paréntesis y el modelo en la segunda línea, sin comparar los caracteres de las barras), y correrlo en verde antes de modificar `.claude/statusline.sh`.

## 2. Tests primero (tienen que fallar contra el código actual)

- [x] 2.1 S01 a S13 — En `tests/statusline-instalable.Tests.ps1`, tests de instalación y comprobación con `Con-CarpetaTemporal` y `instalar.ps1 -Destino <temporal> -SinVault` (crear `<Destino>/.gemini/antigravity-cli` o `<Destino>/.copilot` según el escenario). El comando esperado se arma con la raíz del repo del propio test (`(Resolve-Path "$PSScriptRoot/..").Path` con `/`). Correrlos y pegar la salida en rojo.
- [x] 2.2 S14 a S17 — Tests de formato de `.claude/statusline.sh` (le pasan la entrada por stdin a `bash`, quitan las secuencias ANSI y comparan). S16 controla que cada carácter visible sea ASCII imprimible. Correrlos y pegar la salida en rojo.
- [x] 2.3 S21 a S25 — Tests de la barra de Antigravity con `pwsh -NoProfile -File templates/antigravity/statusline_new.ps1` y las entradas de la spec `agent-cli-permissions`, y control de `git ls-files` y de rutas de la máquina. Correrlos y pegar la salida en rojo.
- [x] 2.4 S18, S19, S20, S26 y S27 — Tests de búsqueda de texto: sin `statusLine` en `.claude/settings*.json` versionados; filas de Copilot y Cursor en la matriz de `templates/README.md`; `instalar.ps1 -Comprobar`, reiniciar y `/experimental on` en `docs/modo-de-uso.md`; instalación de la barra en `README.md` y `docs/modo-de-uso.md`; sin prompt de generación en `templates/antigravity/README.md`. Correrlos y pegar la salida en rojo.

## 3. Implementación

- [x] 3.1 Copiar `~/.gemini/antigravity-cli/scratch/statusline.bat` y `~/.gemini/antigravity-cli/scratch/statusline_new.ps1` de esta máquina a `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1` sin cambiar su contenido (design D5). Confirmar que no contienen rutas de la máquina ni nombres de usuario.
- [x] 3.2 Crear `scripts/barra-estado.ps1` con las funciones de D1 (`Obtener-BarrasEsperadas`, `Clasificar-Barra`, `Escribir-Barra` o equivalentes), la tabla de comandos y el reconocimiento de D2, y la lectura y escritura de JSON de D7. Sin `Invoke-Expression`, sin rutas escritas en el código y sin imprimir el contenido de los `settings.json`.
- [x] 3.3 Modificar `scripts/instalar.ps1`: cargar `scripts/barra-estado.ps1`; agregar a la lista de archivos `templates/antigravity/statusline.bat` y `statusline_new.ps1` con destino `<Destino>/.gemini/antigravity-cli/scratch/`, solo si existe `<Destino>/.gemini/antigravity-cli`; sumarlos a `$rutasRepo`; agregar las filas `settings: barra ...` a la tabla; sumar `falta` y `atrasado` a la lista de error de `-Comprobar`; escribir las barras después de copiar los archivos y mostrar los avisos de `propia` y `json inválido` (design D6). Actualizar la línea `# Uso` del encabezado si cambia.
- [x] 3.4 Modificar `.claude/statusline.sh`: barras con `#` y `-`, reinicio sin `↺` (`<h>h<mm>m` o `<m>m`) y contexto desde `context_window.current_context_used_percentage` cuando viene (design D3 y D4). Sin otros cambios de formato.
- [x] 3.5 Borrar `.claude/settings.json` del repo (design D8) y confirmar con búsqueda que ningún script, test ni workflow lo usa.
- [x] 3.6 Correr `tests/statusline-instalable.Tests.ps1` y pegar S01 a S17 y S21 a S25 en verde.

## 4. Documentación

- [x] 4.1 `README.md`: en el setup por máquina, reemplazar el comentario "La barra de estado NO se copia: se genera con el CLI..." por la instalación con `instalar.ps1` (Claude Code, Antigravity CLI y Copilot CLI si están instalados; respeta una barra propia).
- [x] 4.2 `docs/modo-de-uso.md`: el mismo reemplazo en el setup por máquina, y una sección "Barra de estado" con qué hacer si no aparece: correr `pwsh scripts/instalar.ps1 -Comprobar`, correr `instalar.ps1`, reiniciar el CLI y, en Copilot CLI, `/experimental on` si la versión lo pide.
- [x] 4.3 `templates/README.md`: en la matriz, la columna "Barra de estado" de Antigravity pasa a "scripts `antigravity/statusline.bat` y `statusline_new.ps1` + `statusLine`, instalados por `instalar.ps1`"; la de Copilot a "`statusLine` en `~/.copilot/settings.json`, instalado por `instalar.ps1`"; la de Cursor queda `no verificado` con el motivo y el issue #63. Sumar a "Fuentes consultadas" la referencia de docs.github.com (carpeta de configuración de Copilot CLI) y la de Cursor (`cursor.com/docs/cli/reference/configuration`, sin `statusLine`). Actualizar la línea de `antigravity/` de la lista de carpetas (ya no hay "guía para generar los scripts").
- [x] 4.4 `templates/antigravity/README.md`: reemplazar la sección "Barra de estado (la genera el CLI del Agente)" y su prompt por la instalación con `instalar.ps1` (scripts versionados en esta carpeta), y en "Si la barra no aparece" indicar correr `instalar.ps1` (vuelve a poner `enabled: true`) y reiniciar el CLI. En el punto 2 de la instalación, sacar la mención a reemplazar `{RUTA-DE-TU-USUARIO}` de `statusLine` (lo resuelve `instalar.ps1`).
- [x] 4.5 Correr S18, S19, S20, S26 y S27 y pegar la salida en verde.

## 5. Arquitectura

- [x] 5.1 Crear `docs/adr/0005-instalar-escribe-la-barra-de-estado-de-cada-cli.md` con el contenido del bloque de código de `## ADR` del design.
- [x] 5.2 Actualizar `docs/arquitectura/vision.md`: en `## Contexto e integraciones`, sumar Copilot CLI y la carpeta `~/.copilot/` a los sistemas externos; en `## Componentes`, sumar a `.claude/` el `statusline.sh` (barra de Claude y Copilot), a `templates/` los scripts de la barra de Antigravity, y a `scripts/` la instalación de la barra de estado; en `## Decisiones vigentes`, agregar `- [0005. instalar.ps1 escribe la barra de estado de cada CLI](../adr/0005-instalar-escribe-la-barra-de-estado-de-cada-cli.md)`; en `## Hoja de ruta`, agregar `- [baja] la barra de estado de Cursor CLI no se instala (sin claves oficiales documentadas) — origen: ADR 0005 — propuesta: confirmar las claves en un Cursor CLI instalado y sumarla a barra-estado.ps1 — issue: #63`.

## 6. Verificación final

- [x] 6.1 Correr la suite completa `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar el resumen en verde (incluye C01 y C02).
- [x] 6.2 Buscar `C:\Users`, `C:/Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en `scripts/`, `tests/` y `templates/`, y pegar la salida sin resultados.
- [x] 6.3 M01 (lo corre el usuario) — Verificar que el cambio aplica en un proyecto de prueba: el usuario corre `pwsh scripts/instalar.ps1` en su máquina, abre Claude Code en `D:\proyectos\gamma-installer`, `agy` y `copilot`, y confirma que cada uno muestra su barra sin desbordes. Queda `[ ]` hasta que el usuario lo confirme en el verify.
  - Evidencia aportada por el usuario en el verify del 14/11/2026: corrió `instalar.ps1` desde la rama (`-Comprobar` con las tres barras `igual`) y confirmó la barra de Claude Code y de Antigravity. Copilot CLI no se probó por decisión del usuario (no lo usa); la versión instalada (0.0.414) no lee `statusLine`, así que la barra queda escrita en `~/.copilot/settings.json` y aparece cuando se actualice el CLI.
- [x] 6.4 Arreglos del verify: (a) guardar `scripts/instalar.ps1`, `scripts/barra-estado.ps1` y `tests/statusline-instalable.Tests.ps1` en UTF-8 sin BOM, sin cambiar los finales de línea; (b) que `instalar.ps1` no imprima el valor que devuelve `Escribir-Barra` (hoy salen líneas `True` sueltas: descartarlo en la llamada con `| Out-Null` o asignándolo a `$null`). Pegar en el resumen del apply los primeros 3 bytes de cada archivo, la salida de `pwsh scripts/instalar.ps1 -Destino <temporal> -SinVault` sin líneas `True` y la suite `pwsh -NoProfile -File tests/ejecutar.ps1` en verde.
