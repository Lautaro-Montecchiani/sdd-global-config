# rules-sync Specification

## Purpose
Fuente única de las plantillas de reglas del Agente, con generación y control de desincronización en el CI, instalación por máquina y sincronización por proyecto mediante scripts que frenan ante cambios locales.
## Requirements
### Requirement: Plantillas generadas desde una fuente única
Las partes compartidas de las plantillas de reglas del Agente SHALL vivir en `templates/fuente/fragmentos/`, y cada plantilla SHALL tener un esqueleto en `templates/fuente/esqueletos/` con líneas `<!-- incluir: <fragmento> -->`. `scripts/generar-plantillas.ps1` SHALL generar `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md` reemplazando cada marca por su fragmento, en UTF-8 sin BOM y con fin de línea LF. Si un esqueleto nombra un fragmento que no existe, el script SHALL terminar con código distinto de 0 sin escribir ninguna plantilla.

#### Scenario: Generar las cuatro plantillas
- **WHEN** se corre `generar-plantillas.ps1` con un fragmento `reglas-ejecucion` incluido en los cuatro esqueletos
- **THEN** las cuatro plantillas contienen el texto del fragmento en el lugar de la marca
- **AND** ninguna contiene la línea `<!-- incluir: reglas-ejecucion -->`

#### Scenario: Fragmento inexistente
- **WHEN** un esqueleto tiene `<!-- incluir: no-existe -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra el esqueleto y el fragmento
- **AND** ninguna plantilla cambia

### Requirement: Control de desincronización
`generar-plantillas.ps1 -Comprobar` NO SHALL escribir archivos. SHALL terminar con código distinto de 0 y listar los archivos si alguna plantilla commiteada o algún comando de `.claude/commands/` difiere del generado (comparando sin diferencias de fin de línea ni BOM), o si los títulos de las reglas numeradas de `### Reglas de ejecución del Agente` de `.claude/CLAUDE.md` no son iguales, en el mismo orden, a los de `templates/fuente/fragmentos/reglas-ejecucion.md`. El repositorio SHALL correr este control, los tests de los scripts y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` en un workflow de GitHub Actions en cada PR.

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
- **WHEN** el `CLAUDE.md` tiene una regla "No inventar nada" y la fuente "No inventar"
- **THEN** `-Comprobar` termina con código distinto de 0 y muestra las dos listas de títulos

#### Scenario: Todo sincronizado
- **WHEN** las plantillas y los comandos son los generados y los títulos coinciden
- **THEN** `-Comprobar` termina con código 0

#### Scenario: Workflow de PR
- **WHEN** se lee `.github/workflows/plantillas.yml`
- **THEN** corre en `pull_request`, hace checkout con `fetch-depth: 0`
- **AND** corre con `pwsh` los tests, `generar-plantillas.ps1 -Comprobar` y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`

### Requirement: Instalación por máquina
`scripts/instalar.ps1` SHALL copiar `.claude/CLAUDE.md`, todos los archivos de `skills/` y los comandos de `.claude/commands/` al `.claude` de `-Destino` (por defecto `$HOME`), y `templates/antigravity/GEMINI.md` a `<Destino>/.gemini/GEMINI.md` solo si existe `<Destino>/.gemini`. SHALL guardar un manifiesto con el commit y el hash de cada archivo instalado y mostrar una tabla con el hash del repo y el instalado. Antes de copiar, SHALL clasificar cada destino existente como `igual`, `atrasado` (coincide con el manifiesto o con una versión de su fuente en la historia de git) o `con cambios locales`; si hay alguno `con cambios locales`, SHALL listarlo y terminar con código distinto de 0 sin copiar ningún archivo, salvo con `-Forzar`, que primero los respalda en la carpeta temporal del sistema. Con `-Simular` NO SHALL escribir nada.

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
- **AND** el `CLAUDE.md` instalado queda igual al del repo

#### Scenario: Simular
- **WHEN** se corre `instalar.ps1 -Simular` sobre un destino con archivos atrasados
- **THEN** la salida muestra la tabla
- **AND** ningún archivo del destino, del manifiesto ni del vault cambia

#### Scenario: GEMINI.md con contenido propio
- **WHEN** el destino tiene `.gemini/GEMINI.md` generado con una línea propia debajo de `## Propio del proyecto`, y la plantilla del repo cambió
- **THEN** después de `instalar.ps1` el `GEMINI.md` instalado tiene la parte generada nueva y conserva la línea propia

### Requirement: Espejo del vault al instalar
Salvo `-SinVault`, `instalar.ps1` SHALL escribir `_global/reglas-globales.md` en el vault de `-Vault` (por defecto `OBSIDIAN_VAULT`) con el encabezado del comando "Sincronizar reglas globales al vault" del `CLAUDE.md` y el contenido del `CLAUDE.md` instalado, agregar solo ese archivo al índice, commitear con `chore: sdd-global-config — sync reglas` si hubo cambios y pushear. Si el push falla, SHALL avisar y terminar con código 0. Si el vault no está definido o no existe, SHALL avisar y seguir sin él.

#### Scenario: Espejo sincronizado
- **WHEN** se corre `instalar.ps1` con un vault de prueba que tiene un remote bare
- **THEN** `_global/reglas-globales.md` contiene el `CLAUDE.md` del repo y el aviso de solo lectura
- **AND** el último commit del remote bare es `chore: sdd-global-config — sync reglas`
- **AND** ningún otro archivo del vault quedó en ese commit

#### Scenario: Sin vault
- **WHEN** se corre `instalar.ps1` con `-Vault` apuntando a una carpeta que no existe
- **THEN** la salida avisa que no hay vault
- **AND** la instalación en `~/.claude` se completa y el código de salida es 0

### Requirement: Sincronización por proyecto
`scripts/sincronizar-proyecto.ps1 -Proyecto <ruta>` SHALL actualizar `AGENTS.md`, `.github/copilot-instructions.md` y `.cursor/rules/sdd-workflow.mdc` (según `-Agentes`, o según los que el proyecto ya usa) y `.github/workflows/pr-check.yml` (con `-PrCheck` o si ya existe). Si el archivo tiene `## Propio del proyecto`, SHALL reemplazar lo anterior al título por lo generado y conservar lo de abajo. Si no lo tiene y es igual a una versión de su plantilla en la historia de git del repo, SHALL reemplazarlo. En cualquier otro caso SHALL marcarlo `bloqueado: contenido propio`, no escribirlo y terminar con código distinto de 0, salvo con `-Forzar`, que lo respalda y lo reemplaza. Con `-Comprobar` NO SHALL escribir y SHALL terminar con código distinto de 0 si algún archivo quedaría distinto o bloqueado. NO SHALL commitear, pushear ni crear ramas en el proyecto.

#### Scenario: Proyecto nuevo
- **WHEN** se corre `sincronizar-proyecto.ps1 -Proyecto <repo vacío> -Agentes comun,cursor`
- **THEN** existen `AGENTS.md` y `.cursor/rules/sdd-workflow.mdc` iguales a sus plantillas
- **AND** no existe `.github/copilot-instructions.md`

#### Scenario: Conserva lo propio
- **WHEN** el `AGENTS.md` del proyecto tiene la línea "Usar pnpm" debajo de `## Propio del proyecto` y la plantilla cambió
- **THEN** después de sincronizar, el `AGENTS.md` tiene la parte generada nueva y sigue teniendo "Usar pnpm" debajo del título

#### Scenario: Copia vieja reconocida
- **WHEN** el `.github/copilot-instructions.md` del proyecto es igual a una versión anterior de la plantilla en la historia de git
- **THEN** queda `actualizado` con la plantilla actual

#### Scenario: Contenido propio sin marcar
- **WHEN** el `AGENTS.md` del proyecto no tiene `## Propio del proyecto` y no coincide con ninguna versión de la plantilla
- **THEN** la salida lo marca `bloqueado: contenido propio` y el código de salida es distinto de 0
- **AND** el archivo no cambia

#### Scenario: Comprobar
- **WHEN** se corre con `-Comprobar` sobre un proyecto con una plantilla atrasada
- **THEN** termina con código distinto de 0 y ningún archivo cambia
- **AND** después de sincronizar, `-Comprobar` termina con código 0

#### Scenario: Sin commits en el proyecto
- **WHEN** se sincroniza un repo de prueba con un commit inicial
- **THEN** el repo sigue con un solo commit y en la misma rama
- **AND** `git status` muestra los archivos sincronizados como cambios sin commitear

### Requirement: Scripts sin rutas personales ni ejecución de texto leído
Los scripts y sus tests SHALL resolver las rutas desde `$HOME`, los parámetros, `OBSIDIAN_VAULT` y la ubicación del propio script, sin rutas absolutas escritas en el código ni nombres de usuario. NO SHALL ejecutar texto leído de archivos (`Invoke-Expression`). Los tests NO SHALL escribir en el `$HOME` real ni en el vault real.

#### Scenario: Revisión de los scripts
- **WHEN** se buscan `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en `scripts/`, `tests/`, `templates/` y `.claude/CLAUDE.md`
- **THEN** no hay resultados

### Requirement: Comandos de Claude generados desde las skills
Las skills de `skills/` SHALL ser la única fuente del texto de los comandos de `.claude/commands/`. Cada comando SHALL tener en `templates/fuente/comandos/` un encabezado con su frontmatter y una o más líneas `<!-- incluir-skill: <skill> -->` (el cuerpo completo de `skills/<skill>/SKILL.md`, sin su frontmatter) o `<!-- incluir-skill: <skill>#<título> -->` (solo la sección `## <título>` de esa skill, hasta el siguiente título `## ` que no esté dentro de un bloque de código). `scripts/generar-plantillas.ps1` SHALL generar `.claude/commands/opsx/apply.md`, `opsx/archive.md`, `opsx/explore.md`, `opsx/propose.md`, `opsx/verify.md`, `odd/start.md`, `odd/verify.md`, `odd/close.md` y `odd.md` reemplazando cada marca por el texto que nombra, con un aviso de archivo generado después del frontmatter, en UTF-8 sin BOM y con fin de línea LF. `odd.md` SHALL ser idéntico a `odd/start.md`. Si una marca nombra una skill o una sección que no existe, el script SHALL terminar con código distinto de 0, nombrar el encabezado y la marca, y no escribir ningún archivo (ni plantillas ni comandos).

#### Scenario: Comando con la skill completa
- **WHEN** se corre `generar-plantillas.ps1` con el encabezado `opsx/apply.md` que incluye `openspec-apply-change`
- **THEN** `.claude/commands/opsx/apply.md` tiene el frontmatter del encabezado, el aviso de archivo generado y el cuerpo de `skills/openspec-apply-change/SKILL.md` sin su frontmatter
- **AND** no contiene la línea `<!-- incluir-skill: openspec-apply-change -->`

#### Scenario: Comando con secciones de una skill
- **WHEN** se corre `generar-plantillas.ps1` con el encabezado `odd/verify.md` que incluye las secciones `Verify (`/odd:verify`)` y `Escalado` de `odd-change`
- **THEN** `.claude/commands/odd/verify.md` contiene esas dos secciones completas
- **AND** no contiene la sección `Inicio (`/odd`)`

#### Scenario: Título dentro de un bloque de código
- **WHEN** la sección incluida tiene un bloque de código con líneas `## Objetivo` o `## Evidencia`
- **THEN** esas líneas quedan dentro de la sección generada y la sección termina en el siguiente título `## ` fuera del bloque

#### Scenario: Mismo texto para /odd y /odd:start
- **WHEN** se corre `generar-plantillas.ps1`
- **THEN** `.claude/commands/odd.md` y `.claude/commands/odd/start.md` son idénticos

#### Scenario: Dato inválido: skill inexistente
- **WHEN** un encabezado tiene `<!-- incluir-skill: no-existe -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra el encabezado y la marca
- **AND** ninguna plantilla ni ningún comando cambia

#### Scenario: Dato inválido: sección inexistente
- **WHEN** un encabezado tiene `<!-- incluir-skill: odd-change#No existe -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra el encabezado y la marca
- **AND** ninguna plantilla ni ningún comando cambia

