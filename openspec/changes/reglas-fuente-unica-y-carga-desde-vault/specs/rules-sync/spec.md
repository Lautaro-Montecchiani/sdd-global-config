# Spec Delta

## ADDED Requirements

### Requirement: Bloque de reglas generado en el CLAUDE.md
`.claude/CLAUDE.md` SHALL tener las reglas de ejecución del Agente entre las líneas `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`. `scripts/generar-plantillas.ps1` SHALL reemplazar lo que hay entre esas marcas por el texto de `templates/fuente/fragmentos/reglas-ejecucion.md`, sin cambiar el resto del archivo. Si falta una marca, están repetidas o en orden inverso, SHALL terminar con código distinto de 0 sin escribir ningún archivo.

#### Scenario: Bloque generado desde el fragmento
- **WHEN** se cambia una palabra de la regla 3 en `templates/fuente/fragmentos/reglas-ejecucion.md` y se corre `generar-plantillas.ps1`
- **THEN** el texto entre las marcas de `.claude/CLAUDE.md` es igual al fragmento
- **AND** las dos marcas siguen en el archivo, una vez cada una

#### Scenario: El resto del CLAUDE.md no cambia
- **WHEN** se corre `generar-plantillas.ps1` sobre un `.claude/CLAUDE.md` con el bloque atrasado
- **THEN** el texto anterior a la marca de inicio y el posterior a la marca de fin quedan iguales

#### Scenario: Marcas faltantes
- **WHEN** `.claude/CLAUDE.md` no tiene la línea `<!-- fin: reglas-ejecucion -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra `.claude/CLAUDE.md` y la marca
- **AND** ninguna plantilla, ningún comando ni el `CLAUDE.md` cambian

### Requirement: Carga de las reglas de Claude desde el vault
Cuando hay vault, `instalar.ps1` SHALL instalar en `<Destino>/.claude/CLAUDE.md` un archivo de carga con un aviso de archivo generado, una instrucción para avisar al usuario si las reglas no cargaron y una línea `@<ruta absoluta del espejo>` con barras `/`. Sin vault (`-SinVault`, vault no definido o inexistente) o si la ruta del vault tiene espacios, SHALL instalar la copia completa de `.claude/CLAUDE.md` y, en el caso de los espacios, avisar el motivo.

#### Scenario: Archivo de carga con vault
- **WHEN** se corre `instalar.ps1 -Destino <carpeta vacía> -Vault <vault de prueba>`
- **THEN** `<carpeta>/.claude/CLAUDE.md` tiene una sola línea que empieza con `@` y termina con `/_global/reglas-globales.md`, con la ruta absoluta del vault de prueba
- **AND** no contiene el texto de las reglas
- **AND** tiene el aviso de archivo generado y la instrucción de avisar si las reglas no cargaron

#### Scenario: Copia completa sin vault
- **WHEN** se corre `instalar.ps1 -Destino <carpeta vacía> -SinVault`
- **THEN** `<carpeta>/.claude/CLAUDE.md` tiene el mismo contenido que `.claude/CLAUDE.md` del repo

#### Scenario: Ruta del vault con espacios
- **WHEN** se corre `instalar.ps1` con `-Vault` apuntando a una carpeta existente cuyo nombre tiene un espacio
- **THEN** `<Destino>/.claude/CLAUDE.md` tiene la copia completa
- **AND** la salida avisa que no se usó el archivo de carga por los espacios de la ruta
- **AND** el espejo se escribe igual en ese vault

#### Scenario: Copia completa anterior pasa a archivo de carga
- **WHEN** el destino tiene instalada una versión anterior de `.claude/CLAUDE.md` presente en la historia de git y se corre `instalar.ps1` con un vault de prueba
- **THEN** ese archivo figura como `atrasado`, no como `con cambios locales`
- **AND** queda reemplazado por el archivo de carga sin usar `-Forzar`

### Requirement: Protección del espejo ante ediciones a mano
Antes de escribir cualquier archivo, `instalar.ps1` SHALL clasificar el espejo como `igual`, `atrasado`, `con cambios locales` o `repo atrasado`, y mostrarlo en la tabla. Con `con cambios locales` SHALL terminar con código distinto de 0 sin escribir nada, salvo con `-Forzar`, que primero lo respalda. Con `repo atrasado` (el `commit` del encabezado del espejo no existe en el repo local) SHALL terminar con código distinto de 0 también con `-Forzar` y pedir actualizar el repo.

#### Scenario: Espejo ya igual
- **WHEN** se corre `instalar.ps1` dos veces seguidas con el mismo vault de prueba
- **THEN** la segunda corrida muestra el espejo como `igual`
- **AND** no agrega ningún commit al vault

#### Scenario: Espejo editado a mano
- **WHEN** se agrega una línea a `_global/reglas-globales.md` del vault de prueba y se corre `instalar.ps1`
- **THEN** termina con código distinto de 0 y lista el espejo como `con cambios locales`
- **AND** no cambian el espejo ni ningún archivo del destino

#### Scenario: Forzar con respaldo del espejo
- **WHEN** se repite el caso anterior con `-Forzar`
- **THEN** la salida muestra la carpeta de respaldo, que contiene el espejo con la línea agregada
- **AND** el espejo queda con el contenido de `.claude/CLAUDE.md` del repo, sin la línea agregada

#### Scenario: Espejo atrasado
- **WHEN** el espejo tiene el contenido de una versión anterior de `.claude/CLAUDE.md` presente en la historia de git y se corre `instalar.ps1`
- **THEN** el espejo figura como `atrasado` y queda actualizado sin usar `-Forzar`

#### Scenario: Repo atrasado
- **WHEN** el encabezado del espejo tiene un `commit` que no existe en el repo local, su contenido difiere del repo y se corre `instalar.ps1 -Forzar`
- **THEN** termina con código distinto de 0, muestra `repo atrasado` y pide correr `git pull` en el repo
- **AND** no cambian el espejo ni ningún archivo del destino

### Requirement: Comprobación de la instalación
`instalar.ps1 -Comprobar` NO SHALL escribir en el destino, en el manifiesto ni en el vault. SHALL mostrar la tabla de estados y terminar con código 0 solo si todos los archivos del destino y el espejo (cuando hay vault) están `igual`; en cualquier otro caso SHALL terminar con código distinto de 0 y listar los que difieren. Si `-Vault` no se pasa y `OBSIDIAN_VAULT` no está en el proceso, SHALL usar el valor de la variable de usuario del sistema.

#### Scenario: Instalación al día
- **WHEN** se corre `instalar.ps1` con un destino y un vault de prueba, y después `instalar.ps1 -Comprobar` con los mismos parámetros
- **THEN** la comprobación termina con código 0

#### Scenario: Espejo distinto
- **WHEN** después de instalar se agrega una línea al espejo del vault de prueba y se corre `instalar.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `_global/reglas-globales.md`
- **AND** el espejo conserva la línea agregada y el vault no tiene commits nuevos

#### Scenario: Destino atrasado
- **WHEN** se corre `instalar.ps1 -Comprobar` sobre un destino vacío
- **THEN** termina con código distinto de 0
- **AND** el destino sigue vacío

### Requirement: El repo como fuente única de las reglas
`.claude/CLAUDE.md` SHALL declarar que las reglas se editan solo en el repo `sdd-global-config`, que `~/.claude/CLAUDE.md` y el espejo del vault los escribe solo `scripts/instalar.ps1`, y que al iniciar sesión Claude corre `instalar.ps1 -Comprobar` y avisa al usuario si falla, sin corregir las copias a mano. NO SHALL nombrar a `~/.claude/CLAUDE.md` como fuente canónica ni dar un comando para armar el espejo a mano. Las guías SHALL decir lo mismo.

#### Scenario: Texto de las reglas globales
- **WHEN** se lee `.claude/CLAUDE.md`
- **THEN** nombra al repo `sdd-global-config` como fuente de las reglas y a `instalar.ps1 -Comprobar` en el inicio de sesión
- **AND** no contiene "Fuente canónica:** `~/.claude/CLAUDE.md`" ni el comando que arma el espejo con `Out-File`

#### Scenario: Texto de las guías
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** ninguna dice que la fuente canónica de las reglas es `~/.claude/CLAUDE.md`
- **AND** `README.md` dice que `-Comprobar` controla el texto del bloque de reglas del `CLAUDE.md`

## MODIFIED Requirements

### Requirement: Control de desincronización
`generar-plantillas.ps1 -Comprobar` NO SHALL escribir archivos. SHALL terminar con código distinto de 0 y listar los archivos si alguna plantilla commiteada o algún comando de `.claude/commands/` difiere del generado (comparando sin diferencias de fin de línea ni BOM), o si el texto entre las marcas `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->` de `.claude/CLAUDE.md` no es igual al de `templates/fuente/fragmentos/reglas-ejecucion.md`, o si faltan las marcas. El repositorio SHALL correr este control, los tests de los scripts y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` en un workflow de GitHub Actions en cada PR.

#### Scenario: Plantilla editada a mano
- **WHEN** se agrega una línea a `templates/cursor/sdd-workflow.mdc` sin tocar la fuente y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `templates/cursor/sdd-workflow.mdc`
- **AND** el archivo no cambia

#### Scenario: Comando editado a mano
- **WHEN** se agrega una línea a `.claude/commands/opsx/verify.md` sin tocar `skills/openspec-verify-change/SKILL.md` y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `.claude/commands/opsx/verify.md`
- **AND** el archivo no cambia

#### Scenario: Skill editada sin regenerar
- **WHEN** se cambia una línea de `skills/odd-change/SKILL.md` dentro de la sección `Escalado` sin regenerar y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `.claude/commands/odd/start.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd.md`

#### Scenario: Reglas del CLAUDE.md con otro título
- **WHEN** el bloque del `CLAUDE.md` tiene una regla "No inventar nada" y la fuente "No inventar"
- **THEN** `-Comprobar` termina con código distinto de 0 y nombra `.claude/CLAUDE.md`

#### Scenario: Bloque de reglas del CLAUDE.md editado a mano
- **WHEN** se cambia una palabra del cuerpo de la regla 4 dentro del bloque de `.claude/CLAUDE.md`, sin tocar su título ni la fuente, y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `.claude/CLAUDE.md`
- **AND** el archivo no cambia

#### Scenario: Todo sincronizado
- **WHEN** las plantillas y los comandos son los generados y el bloque de reglas del `CLAUDE.md` es igual al fragmento
- **THEN** `-Comprobar` termina con código 0

#### Scenario: Workflow de PR
- **WHEN** se lee `.github/workflows/plantillas.yml`
- **THEN** corre en `pull_request`, hace checkout con `fetch-depth: 0`
- **AND** corre con `pwsh` los tests, `generar-plantillas.ps1 -Comprobar` y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`

### Requirement: Instalación por máquina
`scripts/instalar.ps1` SHALL instalar en el `.claude` de `-Destino` (por defecto `$HOME`) el `CLAUDE.md` (la copia completa de `.claude/CLAUDE.md` o, cuando hay vault, el archivo de carga del requirement "Carga de las reglas de Claude desde el vault"), todos los archivos de `skills/` y los comandos de `.claude/commands/`, y `templates/antigravity/GEMINI.md` en `<Destino>/.gemini/GEMINI.md` solo si existe `<Destino>/.gemini`. SHALL guardar un manifiesto con el commit y el hash de cada archivo instalado y mostrar una tabla con el hash esperado y el instalado. Antes de copiar, SHALL clasificar cada destino existente como `igual`, `atrasado` (coincide con el manifiesto o con una versión de su fuente en la historia de git) o `con cambios locales`; si hay alguno `con cambios locales`, SHALL listarlo y terminar con código distinto de 0 sin copiar ningún archivo, salvo con `-Forzar`, que primero los respalda en la carpeta temporal del sistema. Con `-Simular` NO SHALL escribir nada.

#### Scenario: Destino vacío
- **WHEN** se corre `instalar.ps1 -Destino <carpeta vacía> -SinVault`
- **THEN** existen `<carpeta>/.claude/CLAUDE.md`, las skills y los comandos con el mismo contenido que el repo
- **AND** existe el manifiesto con un hash por archivo
- **AND** la salida tiene la tabla con todos los archivos iguales

#### Scenario: Cambio local
- **WHEN** el `CLAUDE.md` instalado tiene una línea agregada a mano y se corre `instalar.ps1`
- **THEN** termina con código distinto de 0 y lista ese archivo como `con cambios locales`
- **AND** ningún archivo del destino cambia

#### Scenario: Forzar con respaldo
- **WHEN** se repite el caso anterior con `-Forzar`
- **THEN** la salida muestra la carpeta de respaldo, que contiene el `CLAUDE.md` con la línea agregada
- **AND** el `CLAUDE.md` instalado queda igual al esperado

#### Scenario: Simular
- **WHEN** se corre `instalar.ps1 -Simular` sobre un destino con archivos atrasados
- **THEN** la salida muestra la tabla
- **AND** ningún archivo del destino, del manifiesto ni del vault cambia

#### Scenario: GEMINI.md con contenido propio
- **WHEN** el destino tiene `.gemini/GEMINI.md` generado con una línea propia debajo de `## Propio del proyecto`, y la plantilla del repo cambió
- **THEN** después de `instalar.ps1` el `GEMINI.md` instalado tiene la parte generada nueva y conserva la línea propia

### Requirement: Espejo del vault al instalar
Salvo `-SinVault`, `instalar.ps1` SHALL escribir `_global/reglas-globales.md` en el vault de `-Vault` (por defecto `OBSIDIAN_VAULT`) con un encabezado que nombra como fuente a `.claude/CLAUDE.md` del repo `sdd-global-config`, el `commit` corto del repo, la fecha y el aviso de solo lectura, seguido del contenido de `.claude/CLAUDE.md` del repo. SHALL escribirlo antes que los archivos del destino, agregar solo ese archivo al índice, commitear con `chore: sdd-global-config — sync reglas` si hubo cambios y pushear. Si el push falla, SHALL avisar y terminar con código 0. Si el vault no está definido o no existe, SHALL avisar y seguir sin él.

#### Scenario: Espejo sincronizado
- **WHEN** se corre `instalar.ps1` con un vault de prueba que tiene un remote bare
- **THEN** `_global/reglas-globales.md` contiene el `CLAUDE.md` del repo, el aviso de solo lectura que nombra al repo como fuente y una línea `commit:` con el commit corto del repo
- **AND** el último commit del remote bare es `chore: sdd-global-config — sync reglas`
- **AND** ningún otro archivo del vault quedó en ese commit

#### Scenario: Sin vault
- **WHEN** se corre `instalar.ps1` con `-Vault` apuntando a una carpeta que no existe
- **THEN** la salida avisa que no hay vault
- **AND** la instalación en `~/.claude` se completa con la copia completa del `CLAUDE.md` y el código de salida es 0
