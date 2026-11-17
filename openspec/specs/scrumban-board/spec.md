# scrumban-board Specification

## Purpose
Define el tablero Scrumban del workflow sobre un GitHub Project de usuario: su configuración en el vault, el script que mueve las tarjetas y cuenta el WIP, qué paso del flujo mueve cada tarjeta, el control de WIP antes de empezar trabajo nuevo y la Definition of Ready y la Definition of Done en las reglas globales.

## Requirements

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

### Requirement: Aviso de permiso en cada máquina
`scripts/tablero.ps1 -Comprobar` SHALL controlar que el token de `gh` de la máquina tenga el permiso `project` cuando hay un tablero configurado. Si falta el permiso, SHALL imprimir una línea con el comando `gh auth refresh -h github.com -s project` y terminar con 1. Si el permiso está, o si no hay tablero configurado, SHALL terminar con 0 sin imprimir nada. Si no puede leer los permisos, SHALL avisar en una línea y terminar con 0. Al iniciar cada sesión, Claude SHALL correr este control y, si termina con 1, mostrarle la línea al usuario para que corra el comando con `!`, sin intentar dar el permiso por su cuenta.

#### Scenario: Máquina sin el permiso
- **WHEN** hay `tablero.md` válido y los permisos del token no incluyen `project`
- **THEN** el script imprime una línea con `gh auth refresh -h github.com -s project` y termina con 1

#### Scenario: Máquina con el permiso o sin tablero
- **WHEN** los permisos incluyen `project`, o no hay `tablero.md`
- **THEN** el script termina con 0 sin imprimir nada

#### Scenario: Dato inválido: permisos ilegibles
- **WHEN** `gh` no está instalado o su salida no trae la línea de permisos
- **THEN** el script imprime `No se pudo leer el permiso de gh` y termina con 0

#### Scenario: Control al iniciar sesión
- **WHEN** se lee `## Al iniciar cada sesión` en `.claude/CLAUDE.md`
- **THEN** tiene el paso que corre `tablero.ps1 -Comprobar`, muestra la línea si termina con 1 y dice que el permiso lo da el usuario con `!`

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

### Requirement: Historial del tablero para las métricas
`scripts/metricas.ps1` SHALL leer la configuración del tablero igual que `scripts/tablero.ps1` (`tablero.md` del vault o `-Config`) y SHALL obtener, para cada tarjeta del Project configurado, el repo, el número, el título, la fecha de creación, la fecha de cierre y los eventos de cambio de columna con su fecha. SHALL considerar solo los eventos del Project configurado (mismo dueño y número). Con `-Entrada <archivo.json>` SHALL leer los datos de ese archivo en lugar de `gh`.

#### Scenario: Eventos de otros Projects
- **WHEN** un issue tiene eventos de cambio de columna en el Project configurado y en otro Project
- **THEN** solo se usan los del Project configurado

#### Scenario: Más de una página de tarjetas
- **WHEN** el Project tiene más tarjetas que las que devuelve una página
- **THEN** se leen todas las páginas antes de calcular

#### Scenario: Dato inválido: evento o fecha incompletos
- **WHEN** una tarjeta no tiene número o fecha de creación, o un evento no tiene columna o fecha, o la fecha de cierre es anterior a la de creación
- **THEN** la tarjeta o el evento se descarta y la consola informa cuántos se descartaron

### Requirement: Cálculo de las métricas de flujo
Para el período de `-Semanas <n>` semanas hasta `-Ahora` (por defecto 4 semanas hasta el momento de la corrida), `scripts/metricas.ps1` SHALL calcular sobre los issues cerrados en el período: el lead time (creación a cierre), el cycle time (primera entrada a Diseño o Construcción a cierre), el throughput (cerrados por semana) y el tiempo promedio en cada columna. SHALL listar las tarjetas abiertas en Diseño, Construcción y Revisión con los días que llevan en su columna actual. Los tiempos SHALL expresarse en días con un decimal; los promedios y las medianas SHALL calcularse solo con los valores disponibles.

#### Scenario: Lead time y cycle time
- **WHEN** un issue se creó el día 1, entró a Diseño el día 3 y se cerró el día 8
- **THEN** su lead time es 7,0 días y su cycle time es 5,0 días

#### Scenario: Issue cerrado sin pasar por el flujo
- **WHEN** un issue se cerró sin entrar nunca a Diseño ni a Construcción
- **THEN** cuenta para el lead time y el throughput, no para el cycle time, y el archivo dice cuántos quedaron sin cycle time

#### Scenario: Throughput por semana
- **WHEN** en un período de 2 semanas se cerraron 3 issues en la primera y ninguno en la segunda
- **THEN** el throughput muestra las dos semanas, con 3 y 0

#### Scenario: Trabajo en curso
- **WHEN** una tarjeta abierta está en Construcción desde hace 4 días
- **THEN** aparece en el trabajo en curso con 4,0 días en Construcción

### Requirement: Archivo de métricas en el vault
`scripts/metricas.ps1` SHALL escribir `metricas.md` en la raíz del vault (o en `-Salida <ruta>`) en UTF-8 sin BOM, con una primera línea de comentario que dice que es generado y no se edita a mano, la fecha de la corrida y el período, y las secciones de resumen, throughput, tiempo por columna, trabajo en curso e issues cerrados. NO SHALL contener rutas absolutas ni nombres de cuentas fuera de los nombres de repos. Si no puede leer el tablero (sin configuración, sin `gh`, sin red o sin permiso), SHALL avisar en una línea, NO SHALL tocar `metricas.md` y SHALL terminar con 0.

#### Scenario: Archivo generado
- **WHEN** se generan las métricas
- **THEN** `metricas.md` existe sin BOM, su primera línea es el comentario de archivo generado y tiene las cinco secciones en orden

#### Scenario: Período sin issues cerrados
- **WHEN** no se cerró ningún issue en el período
- **THEN** las secciones de resumen e issues cerrados dicen `Sin issues cerrados en el período.` y el throughput muestra las semanas con 0

#### Scenario: Sin tablero o sin gh
- **WHEN** no hay `tablero.md` o `gh` no está disponible
- **THEN** el script imprime una línea con el motivo, termina con 0 y `metricas.md` queda como estaba

### Requirement: Métricas recalculadas en el cierre
`openspec-archive-change` en la fase del vault y `odd-change` en `/odd:close` SHALL correr `scripts/metricas.ps1` desde `$env:SDD_CONFIG_REPO` antes de sincronizar el vault, para que `metricas.md` entre en el mismo commit del vault. Sin `SDD_CONFIG_REPO`, SHALL saltear el paso y decirlo en el resumen. Un aviso del script NO SHALL frenar el cierre.

#### Scenario: Paso en el cierre
- **WHEN** se leen `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md`, `.claude/commands/opsx/archive.md` y `.claude/commands/odd/close.md`
- **THEN** tienen el paso de `metricas.ps1` antes del sync del vault y dicen que un aviso no frena el cierre

### Requirement: Métricas en las reglas y la guía
`.claude/CLAUDE.md` SHALL nombrar las métricas de flujo (lead time, cycle time, throughput, tiempo por columna y trabajo en curso) en la sección `## Scrumban`, con cuándo se recalculan y cómo regenerarlas a mano, y SHALL incluir `metricas.md` en `### Estructura del vault`. `docs/workflow.md` SHALL explicar en la guía del tablero qué mide cada métrica y el comando para regenerarlas.

#### Scenario: Reglas y guía
- **WHEN** se leen `.claude/CLAUDE.md` y `docs/workflow.md`
- **THEN** los dos nombran las cinco métricas y `metricas.ps1`, y la estructura del vault incluye `metricas.md`

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

#### Scenario: Dato inválido: repo o etiqueta inexistente
- **WHEN** `gh issue create` falla porque el repo elegido no existe o no tiene la etiqueta de prioridad o de tipo
- **THEN** `skills/retro/SKILL.md` indica dejar la acción en la nota con `issue: pendiente` y el motivo en una línea, avisarlo en la salida y seguir con la retro, sin crear la etiqueta ni el repo

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
