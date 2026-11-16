# Spec Delta

## Purpose
Define el tablero Scrumban del workflow sobre un GitHub Project de usuario: su configuración en el vault, el script que mueve las tarjetas y cuenta el WIP, qué paso del flujo mueve cada tarjeta, el control de WIP antes de empezar trabajo nuevo y la Definition of Ready y la Definition of Done en las reglas globales.

## ADDED Requirements

### Requirement: Configuración del tablero en el vault
El tablero SHALL configurarse en `$env:OBSIDIAN_VAULT/tablero.md`, con un bloque inicial entre líneas `---` que declara `owner` (cuenta dueña del Project), `numero` (número del Project) y los límites `wip-diseno`, `wip-construccion` y `wip-revision` (enteros positivos). Un límite que falta SHALL significar "sin límite" para esa columna. `scripts/tablero.ps1` SHALL aceptar `-Config <ruta>` para leer otro archivo. Si el archivo no existe, si falta `owner` o `numero`, o si un valor no es válido, el script SHALL avisar en una línea que nombra la clave, NO SHALL llamar a `gh` y SHALL terminar con 0.

#### Scenario: Configuración válida
- **WHEN** `tablero.md` declara `owner`, `numero: 3`, `wip-diseno: 1`, `wip-construccion: 2` y `wip-revision: 2`
- **THEN** el script usa el Project 3 de esa cuenta y esos límites

#### Scenario: Sin tablero configurado
- **WHEN** no existe `tablero.md` en el vault, o `OBSIDIAN_VAULT` no está definida y no se pasa `-Config`
- **THEN** el script imprime una línea que empieza con `Tablero no configurado` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: número o límite mal escrito
- **WHEN** `numero` no es un entero, o `wip-construccion` es `0`, negativo o no numérico
- **THEN** el script imprime `tablero.md inválido: <clave>` y termina con 0 sin llamar a `gh`

### Requirement: Mover la tarjeta de un issue
`scripts/tablero.ps1 -Issue <url> -Columna <columna>` SHALL dejar el issue en el Project configurado con su campo `Status` en la opción de esa columna. Si el issue no está en el Project, SHALL agregarlo antes. `-Columna` SHALL aceptar `backlog`, `listo`, `diseno`, `construccion`, `revision` y `hecho` sin distinguir mayúsculas, que corresponden a las opciones `Backlog`, `Listo`, `Diseño`, `Construcción`, `Revisión` y `Hecho`. Una columna fuera de esa lista SHALL terminar con 1. Si `gh` no está, no hay red, el token no tiene el permiso `project` o `gh` falla, el script SHALL avisar en una línea sin rutas absolutas y terminar con 0. Con `-Simular` SHALL imprimir los comandos de `gh` que correría sin ejecutar los que modifican el Project.

#### Scenario: Issue nuevo en el tablero
- **WHEN** se mueve a `backlog` un issue que no está en el Project
- **THEN** el script lo agrega al Project y pone `Status` en `Backlog`

#### Scenario: Issue que cambia de columna
- **WHEN** se mueve a `revision` un issue que está en `Construcción`
- **THEN** el `Status` del issue pasa a `Revisión` y el resto de los issues no cambia

#### Scenario: Columna desconocida
- **WHEN** se pasa `-Columna testing`
- **THEN** el script termina con 1 y lista las columnas válidas

#### Scenario: Sin permiso o sin gh
- **WHEN** `gh` no está instalado o falla por falta del permiso `project`
- **THEN** el script imprime una línea con el motivo y `gh auth refresh -s project` si es el permiso, y termina con 0

#### Scenario: Dato inválido: Project sin la opción de la columna
- **WHEN** el campo `Status` del Project no existe o no tiene la opción `Diseño`
- **THEN** el script avisa `el tablero no tiene la columna Diseño`, no modifica el issue y termina con 0

### Requirement: Control de WIP de una columna
`scripts/tablero.ps1 -Wip -Columna <columna>` SHALL contar las tarjetas del Project cuyo `Status` es esa columna y compararlas con su límite. Si la cuenta alcanza o supera el límite, SHALL imprimir la cuenta, el límite y el número y título de cada tarjeta de la columna, y SHALL terminar con 2. Si hay lugar o la columna no tiene límite, SHALL terminar con 0. Si no puede leer el tablero, SHALL avisar y terminar con 0.

#### Scenario: Columna llena
- **WHEN** `wip-diseno` es 1 y hay una tarjeta en `Diseño`
- **THEN** el script imprime `Diseño: 1 de 1`, el número y título de esa tarjeta, y termina con 2

#### Scenario: Columna con lugar
- **WHEN** `wip-construccion` es 2 y hay una tarjeta en `Construcción`
- **THEN** el script imprime `Construcción: 1 de 2` y termina con 0

#### Scenario: Columna sin límite
- **WHEN** se controla `backlog`, que no tiene límite
- **THEN** el script termina con 0

#### Scenario: Dato inválido: tarjetas sin Status o sin título
- **WHEN** la lista de tarjetas que devuelve `gh` trae tarjetas sin `Status` o sin título
- **THEN** las tarjetas sin `Status` no se cuentan en ninguna columna y las que no tienen título se muestran con su número solo

### Requirement: Movimientos del flujo
Las skills SHALL mover la tarjeta del issue del change con `scripts/tablero.ps1` desde `$env:SDD_CONFIG_REPO` en estos pasos: `issue-creation` a `backlog` al crear el issue; `openspec-propose` a `diseno` después de controlar el issue y a `construccion` al anunciar el handoff; `odd-change` en `/odd` a `construccion` al anunciar el handoff y en `/odd:close` a `hecho`; `branch-pr` a `revision` después de crear el PR; y `openspec-archive-change` en la fase del vault a `hecho`. Sin issue (`Issue: pendiente` o un ODD sin issue) o sin `SDD_CONFIG_REPO`, la skill SHALL saltear el paso y decirlo en su resumen. Un aviso del script NO SHALL frenar la skill.

#### Scenario: Pasos que mueven la tarjeta
- **WHEN** se leen `skills/issue-creation/SKILL.md`, `skills/openspec-propose/SKILL.md`, `skills/odd-change/SKILL.md`, `skills/branch-pr/SKILL.md` y `skills/openspec-archive-change/SKILL.md`
- **THEN** cada una llama a `tablero.ps1` con la columna de su paso
- **AND** dice que sin issue o sin `SDD_CONFIG_REPO` saltea el paso y que un aviso del script no frena el flujo

#### Scenario: Comandos regenerados
- **WHEN** se leen `.claude/commands/opsx/propose.md`, `.claude/commands/opsx/archive.md`, `.claude/commands/odd.md` y `.claude/commands/odd/close.md`
- **THEN** tienen los mismos pasos del tablero que su skill y `generar-plantillas.ps1 -Comprobar` no informa diferencias

### Requirement: Control de WIP antes de empezar trabajo
`openspec-propose` SHALL controlar el WIP de `diseno` antes de crear el change, y `odd-change` en `/odd` SHALL controlar el de `construccion` antes de redactar el documento. Si el script termina con 2, la skill SHALL mostrar las tarjetas que ocupan la columna y preguntar con **AskUserQuestion** "Seguir igual" o "Frenar". "Frenar" SHALL detener la skill sin crear archivos ni ramas; "Seguir igual" SHALL continuar y anotar la excepción en el resumen final. Sin interfaz interactiva, SHALL avisar y continuar.

#### Scenario: WIP lleno en el propose
- **WHEN** se lee el control de WIP en `skills/openspec-propose/SKILL.md` y en `skills/odd-change/SKILL.md`
- **THEN** los dos llaman a `tablero.ps1 -Wip`, preguntan "Seguir igual" o "Frenar" cuando termina con 2 y dicen que "Frenar" no crea archivos ni ramas

### Requirement: Scrumban en las reglas globales
`.claude/CLAUDE.md` SHALL tener una sección `## Scrumban` con: los roles (usuario = Product Owner y Scrum Master; Claude y el Agente = Developers); las 6 columnas y el paso del flujo que lleva a cada una; la regla de WIP ("dejar de empezar para empezar a terminar") y dónde se configura; la **Definition of Ready** (issue abierto con `status:approved`, prioridad y tipo, criterios de aceptación y lugar en la columna de destino o excepción aceptada); y la **Definition of Done** para SDD (tareas con evidencia, tests en verde ejecutados por el verify, verify sin CRITICAL con la puerta de integración en `sí`, archive en la rama, PR mergeado con `Closes #NN`, cierre en el vault y tarjeta en Hecho) y para ODD (criterios con evidencia, `/odd:verify` sin CRITICAL, merge y `/odd:close`). `### Estructura del vault` SHALL incluir `tablero.md`.

#### Scenario: Sección Scrumban
- **WHEN** se lee `.claude/CLAUDE.md`
- **THEN** tiene `## Scrumban` con roles, las 6 columnas, WIP, `Definition of Ready` y `Definition of Done` (SDD y ODD)
- **AND** la estructura del vault incluye `tablero.md`

### Requirement: Guía de configuración del tablero
`docs/workflow.md` SHALL explicar cómo crear el Project de usuario, cargar las 6 opciones de `Status` con esos nombres exactos, activar el flujo integrado "Item closed" hacia `Hecho`, dar el permiso con `gh auth refresh -s project`, escribir `tablero.md` en el vault y abrir el tablero como app de escritorio desde Edge o Chrome. La guía NO SHALL contener rutas absolutas ni nombres de cuentas reales.

#### Scenario: Guía completa
- **WHEN** se lee la sección del tablero en `docs/workflow.md`
- **THEN** nombra las 6 opciones de `Status`, `gh auth refresh -s project`, las claves de `tablero.md` y la instalación como app
- **AND** no tiene rutas absolutas
