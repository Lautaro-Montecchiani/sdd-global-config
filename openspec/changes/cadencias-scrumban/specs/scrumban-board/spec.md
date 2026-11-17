# Spec Delta

## MODIFIED Requirements

### Requirement: Configuración del tablero en el vault
El tablero SHALL configurarse en `$env:OBSIDIAN_VAULT/tablero.md`, con un bloque inicial entre líneas `---` que declara `owner` (cuenta dueña del Project), `numero` (número del Project), los límites `wip-diseno`, `wip-construccion` y `wip-revision` (enteros positivos) y la cadencia `cadencia-retro` (días entre retros, entero positivo). Un límite que falta SHALL significar "sin límite" para esa columna, y una `cadencia-retro` que falta SHALL significar "sin aviso de retro". `scripts/tablero.ps1` SHALL aceptar `-Config <ruta>` para leer otro archivo. Si el archivo no existe, si falta `owner` o `numero`, o si un valor no es válido, el script SHALL avisar en una línea que nombra la clave, NO SHALL llamar a `gh` y SHALL terminar con 0.

#### Scenario: Configuración válida
- **WHEN** `tablero.md` declara `owner`, `numero: 3`, `wip-diseno: 1`, `wip-construccion: 2` y `wip-revision: 2`
- **THEN** el script usa el Project 3 de esa cuenta y esos límites

#### Scenario: Configuración con cadencia de retro
- **WHEN** `tablero.md` declara además `cadencia-retro: 7`
- **THEN** `tablero.ps1` funciona igual que sin la clave y el aviso de retro usa 7 días

#### Scenario: Sin tablero configurado
- **WHEN** no existe `tablero.md` en el vault, o `OBSIDIAN_VAULT` no está definida y no se pasa `-Config`
- **THEN** el script imprime una línea que empieza con `Tablero no configurado` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: número o límite mal escrito
- **WHEN** `numero` no es un entero, o `wip-construccion` es `0`, negativo o no numérico
- **THEN** el script imprime `tablero.md inválido: <clave>` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: cadencia mal escrita
- **WHEN** `cadencia-retro` es `0`, negativo o no numérico
- **THEN** el script imprime `tablero.md inválido: cadencia-retro` y termina con 0 sin llamar a `gh`

## ADDED Requirements

### Requirement: Aviso de retro vencida
`scripts/retro.ps1 -Aviso` SHALL comparar los días desde la última retro (la fecha más reciente entre los archivos `AAAA-MM-DD.md` de `$vault/retros/`) con `cadencia-retro`. Si los días alcanzan o superan la cadencia, o si no hay ninguna retro, SHALL imprimir una línea que nombra `/retro` y terminar con 1. Si la retro está al día, si no hay `cadencia-retro`, vault ni tablero, SHALL terminar con 0 sin imprimir nada.

#### Scenario: Retro vencida
- **WHEN** `cadencia-retro` es 7 y la última retro es de hace 8 días
- **THEN** imprime `Retro vencida: pasaron 8 días desde la última (<fecha>): corré /retro` y termina con 1

#### Scenario: Retro al día
- **WHEN** `cadencia-retro` es 7 y la última retro es de hace 3 días
- **THEN** termina con 0 sin imprimir nada

#### Scenario: Sin ninguna retro
- **WHEN** `cadencia-retro` es 7 y `retros/` no existe o no tiene retros
- **THEN** imprime `Todavía no hay retros en el vault: corré /retro` y termina con 1

#### Scenario: Sin cadencia o sin tablero
- **WHEN** `tablero.md` no declara `cadencia-retro`, o no hay `tablero.md` ni vault
- **THEN** termina con 0 sin imprimir nada

#### Scenario: Dato inválido: archivos que no son retros
- **WHEN** `retros/` tiene `notas.md` y `2026-13-40.md` además de las retros
- **THEN** esos archivos no cuentan como retros

#### Scenario: Dato inválido: cadencia mal escrita en el aviso
- **WHEN** `cadencia-retro` es `abc`
- **THEN** imprime `tablero.md inválido: cadencia-retro` y termina con 0

### Requirement: Período de la retro
`scripts/retro.ps1 -Periodo` SHALL imprimir el período de la review (desde la fecha de la última retro, o desde hoy menos la cadencia si no hay retro, o 7 días si no hay cadencia, hasta hoy), la retro anterior, las semanas para `metricas.ps1` y la lista de changes y ODD archivados en ese período, tomada de los nombres `AAAA-MM-DD-<nombre>.md` de `projects/*/archive/` del vault, con el proyecto y si es SDD u ODD. Sin vault SHALL avisar en una línea y terminar con 0.

#### Scenario: Notas del período
- **WHEN** la última retro es del 10/11, hoy es 17/11 y hay notas del 08/11 y del 12/11 en un proyecto y `2026-11-15-odd-texto.md` en otro
- **THEN** lista la del 12/11 como SDD y `texto` como ODD con su proyecto, y no lista la del 08/11

#### Scenario: Primera retro
- **WHEN** no hay retros, `cadencia-retro` es 7 y hoy es 17/11
- **THEN** el período va del 10/11 al 17/11 y la retro anterior dice `ninguna`

#### Scenario: Período sin nada archivado
- **WHEN** no hay notas de archive en el período
- **THEN** imprime `Sin changes ni ODD archivados en el período.`

#### Scenario: Dato inválido: nota de archive sin fecha
- **WHEN** `archive/` tiene `notas-sueltas.md`
- **THEN** esa nota no se lista

### Requirement: Skill de retro con review
La skill `/retro` (`skills/retro/SKILL.md`) SHALL guiar una retro global de 15 minutos en este orden: preparar (directiva primaria de Kerth y acciones de la retro anterior), review (lo terminado según `retro.ps1 -Periodo`, `metricas.ps1` y la opinión de quien usa el sistema), Start / Stop / Continue, analizar, decidir acciones y cerrar. NO SHALL evaluar personas, crear changes, ramas ni commits en el repo, ni escribir código.

#### Scenario: Fases de la skill
- **WHEN** se lee `skills/retro/SKILL.md`
- **THEN** tiene las fases en ese orden, la directiva primaria, `Start / Stop / Continue`, los 15 minutos y las llamadas a `retro.ps1 -Periodo` y `metricas.ps1`

#### Scenario: Skill instalada
- **WHEN** se corre `scripts/instalar.ps1 -Simular` sobre un destino vacío
- **THEN** la salida incluye `.claude/skills/retro/SKILL.md`

#### Scenario: Dato inválido: acción anterior sin issue
- **WHEN** una acción de la retro anterior nombra un issue que `gh` no encuentra o no tiene issue
- **THEN** `skills/retro/SKILL.md` indica marcarla como `no encontrado` o `sin issue` en `## Acciones anteriores` y seguir con la retro

### Requirement: Acciones de la retro como issues
La retro SHALL acordar como máximo 3 acciones SMART (específica, medible, alcanzable, relevante y con fecha). Cada una SHALL crearse como issue con `gh issue create` en el repo que elija el usuario, con etiquetas de prioridad y tipo, `Origen: retro AAAA-MM-DD` y la medida en el cuerpo, sin `status:approved`, y SHALL moverse a `backlog` con `tablero.ps1`. Sin `gh`, red o permiso, SHALL quedar con `issue: pendiente`.

#### Scenario: Acción creada como issue
- **WHEN** se lee el paso de acciones de `skills/retro/SKILL.md`
- **THEN** usa `gh issue create` con prioridad, tipo y `Origen: retro`, mueve la tarjeta a `backlog`, limita a 3 acciones y no agrega `status:approved`

#### Scenario: Sin gh
- **WHEN** se lee el mismo paso
- **THEN** dice que sin `gh`, red o permiso la acción queda con `issue: pendiente`

### Requirement: Nota de la retro en el vault
La skill SHALL escribir `$vault/retros/AAAA-MM-DD.md` sin BOM, con frontmatter (`tipo: retro`, `fecha`, `desde`, `hasta`) y las secciones `## Acciones anteriores`, `## Review`, `## Start / Stop / Continue`, `## Análisis`, `## Acciones` y `## Cierre`, sin rutas absolutas ni nombres de personas. Si ya hay una retro ese día, SHALL agregar una sección al final. Después SHALL commitear `chore: retro AAAA-MM-DD` en el vault y pushear. Sin vault, SHALL frenar.

#### Scenario: Formato de la nota
- **WHEN** se lee el paso de cierre de `skills/retro/SKILL.md`
- **THEN** nombra `retros/AAAA-MM-DD.md`, el frontmatter, las seis secciones, el agregado si ya existe y el commit `chore: retro`

#### Scenario: Sin vault
- **WHEN** se lee el inicio de `skills/retro/SKILL.md`
- **THEN** dice que sin `OBSIDIAN_VAULT` la skill avisa y no hace la retro

### Requirement: Cadencias en las reglas y la guía
`.claude/CLAUDE.md` SHALL tener en `## Al iniciar cada sesión` el paso que corre `retro.ps1 -Aviso` y, si termina con 1, muestra la línea sin correr `/retro` por su cuenta; una subsección `### Cadencias` en `## Scrumban` con la retro global, su review, la cadencia en `tablero.md` y `/retro`; `retros\` en `### Estructura del vault`; y la fila de `/retro` en `### Cuándo actuar`. `docs/workflow.md` SHALL explicar `cadencia-retro` y la retro sin rutas absolutas.

#### Scenario: Reglas y guía
- **WHEN** se leen `.claude/CLAUDE.md` y `docs/workflow.md`
- **THEN** `CLAUDE.md` tiene el paso de `retro.ps1 -Aviso`, `### Cadencias`, `retros\` y `/retro` en `### Cuándo actuar`
- **AND** `docs/workflow.md` nombra `cadencia-retro` y `/retro`, sin rutas absolutas
- **AND** `generar-plantillas.ps1 -Comprobar` no informa diferencias
