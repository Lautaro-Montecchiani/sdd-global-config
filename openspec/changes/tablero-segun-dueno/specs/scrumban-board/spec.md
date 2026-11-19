# Spec Delta

## MODIFIED Requirements

### Requirement: Configuración del tablero en el vault
El tablero SHALL configurarse en `$env:OBSIDIAN_VAULT/tablero.md`, con un bloque inicial entre líneas `---` que declara `owner` (cuenta dueña del Project) y `numero` (número del Project), que forman el tablero por defecto; cero o más claves `dueno-<dueño del repo>: <cuenta>/<número>`, que asignan el Project `<número>` de `<cuenta>` a los repos de ese dueño (el dueño se compara sin distinguir mayúsculas); los límites `wip-diseno`, `wip-construccion` y `wip-revision` (enteros positivos) y la cadencia `cadencia-retro` (días entre retros, entero positivo). Los dueños sin clave `dueno-` SHALL usar el tablero por defecto, y un `tablero.md` sin claves `dueno-` SHALL funcionar como un único tablero. Un límite que falta SHALL significar "sin límite" para esa columna, y una `cadencia-retro` que falta SHALL significar "sin aviso de retro". `scripts/tablero.ps1` SHALL aceptar `-Config <ruta>` para leer otro archivo. Si el archivo no existe, si falta `owner` o `numero`, o si un valor no es válido, el script SHALL avisar en una línea que nombra la clave, NO SHALL llamar a `gh` y SHALL terminar con 0.

#### Scenario: Configuración válida
- **WHEN** `tablero.md` declara `owner`, `numero: 3`, `wip-diseno: 1`, `wip-construccion: 2` y `wip-revision: 2`
- **THEN** el script usa el Project 3 de esa cuenta y esos límites

#### Scenario: Configuración con cadencia de retro
- **WHEN** `tablero.md` declara además `cadencia-retro: 7`
- **THEN** `tablero.ps1` funciona igual que sin la clave y el aviso de retro usa 7 días

#### Scenario: Configuración con un tablero por dueño
- **WHEN** `tablero.md` declara `owner: cuenta-a`, `numero: 4` y `dueno-org-b: cuenta-c/2`
- **THEN** los repos de `org-b` (o `Org-B`) usan el Project 2 de `cuenta-c` y los repos de cualquier otro dueño usan el Project 4 de `cuenta-a`

#### Scenario: Formato anterior
- **WHEN** `tablero.md` declara solo `owner`, `numero`, límites y cadencia, sin claves `dueno-`
- **THEN** todos los repos usan ese Project y los scripts se comportan igual que antes de las claves `dueno-`

#### Scenario: Sin tablero configurado
- **WHEN** no existe `tablero.md` en el vault, o `OBSIDIAN_VAULT` no está definida y no se pasa `-Config`
- **THEN** el script imprime una línea que empieza con `Tablero no configurado` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: número o límite mal escrito
- **WHEN** `numero` no es un entero, o `wip-construccion` es `0`, negativo o no numérico
- **THEN** el script imprime `tablero.md inválido: <clave>` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: cadencia mal escrita
- **WHEN** `cadencia-retro` es `0`, negativo o no numérico
- **THEN** el script imprime `tablero.md inválido: cadencia-retro` y termina con 0 sin llamar a `gh`

#### Scenario: Dato inválido: tablero de un dueño mal escrito
- **WHEN** una clave `dueno-` tiene un valor sin `/`, con un número que no es entero positivo (`cuenta-c/0`, `cuenta-c/x`) o con la cuenta vacía (`/2`), o la clave es solo `dueno-`
- **THEN** el script imprime `tablero.md inválido: <clave>` y termina con 0 sin llamar a `gh`

### Requirement: Mover la tarjeta de un issue
`scripts/tablero.ps1 -Issue <url o número> -Columna <columna>` SHALL dejar el issue en el Project que corresponde al dueño de su repo según `tablero.md` (el de su clave `dueno-` o, si no tiene, el tablero por defecto), con su campo `Status` en la opción de esa columna. Si el issue no está en ese Project, SHALL agregarlo antes. `-Issue` SHALL aceptar la URL del issue o solo su número; con el número, SHALL armar la URL `https://github.com/<owner>/<repo>/issues/<número>` con el remoto `origin` de la carpeta actual (forma HTTPS o SSH de `github.com`), y el dueño del repo SHALL ser el `<owner>` de esa URL. Si `-Issue` no es una URL de issue de GitHub ni un número, o es un número en una carpeta sin remoto `origin` de GitHub, el script SHALL avisar en una línea y terminar con 1 sin consultar ni modificar el Project. `-Columna` SHALL aceptar `backlog`, `listo`, `diseno`, `construccion`, `revision` y `hecho` sin distinguir mayúsculas, que corresponden a las opciones `Backlog`, `Listo`, `Diseño`, `Construcción`, `Revisión` y `Hecho`. Una columna fuera de esa lista SHALL terminar con 1. Si `gh` no está, no hay red, el token no tiene el permiso `project` o `gh` falla, el script SHALL avisar en una línea sin rutas absolutas y terminar con 0. Con `-Simular` SHALL imprimir los comandos de `gh` que correría sin ejecutar los que modifican el Project.

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

#### Scenario: Issue por número
- **WHEN** se pasa `-Issue 10` en una carpeta cuyo remoto `origin` es `https://github.com/org/repo.git` o `git@github.com:org/repo.git`
- **THEN** el script usa la URL `https://github.com/org/repo/issues/10` y mueve la tarjeta igual que con esa URL

#### Scenario: Dato inválido: issue que no es URL ni número
- **WHEN** se pasa `-Issue abc`, o `-Issue 10` en una carpeta sin remoto `origin` de GitHub
- **THEN** el script avisa en una línea que nombra `-Issue`, termina con 1 y no consulta ni modifica el Project

#### Scenario: Issue de un dueño con tablero propio
- **WHEN** `tablero.md` declara `owner: cuenta-a`, `numero: 4` y `dueno-org-b: cuenta-c/2`, y se pasa `-Issue https://github.com/Org-B/repo/issues/7 -Columna diseno -Simular`
- **THEN** los comandos de `gh` que imprime usan el Project 2 de `cuenta-c` y no el 4 de `cuenta-a`

#### Scenario: Issue por número de un dueño con tablero propio
- **WHEN** con esa misma configuración se pasa `-Issue 7` en una carpeta cuyo remoto `origin` es `git@github.com:org-b/repo.git`
- **THEN** el script usa el Project 2 de `cuenta-c`

#### Scenario: Issue de un dueño sin tablero propio
- **WHEN** con esa misma configuración se pasa la URL de un issue de `otra-org`
- **THEN** el script usa el Project 4 de `cuenta-a`

### Requirement: Control de WIP de una columna
`scripts/tablero.ps1 -Wip -Columna <columna>` SHALL contar las tarjetas cuyo `Status` es esa columna en todos los Projects configurados (el tablero por defecto y los de las claves `dueno-`, cada Project una sola vez) y comparar la suma con el límite de la columna. Un mismo issue que está en esa columna en más de un Project SHALL contarse una sola vez. Si la cuenta alcanza o supera el límite, SHALL imprimir la cuenta, el límite y el número y título de cada tarjeta de la columna, y SHALL terminar con 2. Si hay lugar o la columna no tiene límite, SHALL terminar con 0. Si un Project no se puede leer, SHALL avisar en una línea que nombra ese Project y contar los demás; si no puede leer ninguno, SHALL avisar y terminar con 0.

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

#### Scenario: Columna llena sumando dos tableros
- **WHEN** hay dos Projects configurados, `wip-diseno` es 1, hay una tarjeta en `Diseño` en el Project de `dueno-org-b` y ninguna en el tablero por defecto
- **THEN** el script imprime `Diseño: 1 de 1`, la tarjeta con el Project donde está, y termina con 2

#### Scenario: Suma con lugar
- **WHEN** `wip-construccion` es 3 y hay una tarjeta en `Construcción` en cada uno de dos Projects
- **THEN** el script imprime `Construcción: 2 de 3` y termina con 0

#### Scenario: Dato inválido: el mismo issue en dos tableros
- **WHEN** la misma URL de issue está en `Diseño` en los dos Projects configurados
- **THEN** cuenta 1 para `Diseño`

#### Scenario: Dato inválido: un tablero que no se puede leer
- **WHEN** hay dos Projects configurados, `gh` falla al leer uno y el otro tiene una tarjeta en `Construcción` con `wip-construccion` en 2
- **THEN** el script imprime una línea que nombra el Project que falló, imprime `Construcción: 1 de 2` y termina con 0

### Requirement: Scrumban en las reglas globales
`.claude/CLAUDE.md` SHALL tener una sección `## Scrumban` con: los roles (usuario = Product Owner y Scrum Master; Claude y el Agente = Developers); los tableros (uno por defecto y, opcionalmente, uno por dueño del repo, configurados en `tablero.md`, que los scripts eligen solos por el dueño del repo del issue); las 6 columnas y el paso del flujo que lleva a cada una; la regla de WIP ("dejar de empezar para empezar a terminar"), dónde se configura y que se suma entre todos los tableros; la **Definition of Ready** (issue abierto con `status:approved`, prioridad y tipo, criterios de aceptación y lugar en la columna de destino o excepción aceptada); y la **Definition of Done** para SDD (tareas con evidencia, tests en verde ejecutados por el verify, verify sin CRITICAL con la puerta de integración en `sí`, archive en la rama, PR mergeado con `Closes #NN`, cierre en el vault y tarjeta en Hecho) y para ODD (criterios con evidencia, `/odd:verify` sin CRITICAL, merge y `/odd:close`). `### Estructura del vault` SHALL incluir `tablero.md`.

#### Scenario: Sección Scrumban
- **WHEN** se lee `.claude/CLAUDE.md`
- **THEN** tiene `## Scrumban` con roles, las 6 columnas, WIP, `Definition of Ready` y `Definition of Done` (SDD y ODD)
- **AND** la estructura del vault incluye `tablero.md`

#### Scenario: Varios tableros en las reglas
- **WHEN** se lee `### Tablero` y `### WIP` de `.claude/CLAUDE.md`
- **THEN** dicen que `tablero.md` declara un tablero por defecto y uno por dueño del repo con claves `dueno-`, que los scripts eligen el tablero por el dueño del repo y que el WIP se suma entre todos los tableros

### Requirement: Guía de configuración del tablero
`docs/workflow.md` SHALL explicar cómo crear el Project de usuario, cargar las 6 opciones de `Status` con esos nombres exactos, activar el flujo integrado "Item closed" hacia `Hecho`, dar el permiso con `gh auth refresh -s project`, escribir `tablero.md` en el vault (incluidas las claves `dueno-<dueño del repo>: <cuenta>/<número>` para usar otro tablero con los repos de un dueño, y que el WIP y las métricas suman todos los tableros) y abrir el tablero como app de escritorio desde Edge o Chrome. La guía NO SHALL contener rutas absolutas ni nombres de cuentas reales.

#### Scenario: Guía completa
- **WHEN** se lee la sección del tablero en `docs/workflow.md`
- **THEN** nombra las 6 opciones de `Status`, `gh auth refresh -s project`, las claves de `tablero.md` y la instalación como app
- **AND** no tiene rutas absolutas

#### Scenario: Guía con un tablero por dueño
- **WHEN** se lee la sección del tablero en `docs/workflow.md`
- **THEN** explica las claves `dueno-` con un ejemplo de cuentas inventadas y dice que el WIP y las métricas suman todos los tableros

### Requirement: Historial del tablero para las métricas
`scripts/metricas.ps1` SHALL leer la configuración del tablero igual que `scripts/tablero.ps1` (`tablero.md` del vault o `-Config`) y SHALL obtener, para cada tarjeta de cada Project configurado (el tablero por defecto y los de las claves `dueno-`, cada Project una sola vez), el repo, el número, el título, la fecha de creación, la fecha de cierre y los eventos de cambio de columna con su fecha. SHALL considerar solo los eventos de los Projects configurados (mismo dueño y número). Un mismo issue que está en más de un Project SHALL contarse una sola vez, con los eventos de todos esos Projects. Con `-Entrada <archivo.json>` SHALL leer los datos de ese archivo en lugar de `gh`.

#### Scenario: Eventos de otros Projects
- **WHEN** un issue tiene eventos de cambio de columna en un Project configurado y en otro Project no configurado
- **THEN** solo se usan los del Project configurado

#### Scenario: Más de una página de tarjetas
- **WHEN** el Project tiene más tarjetas que las que devuelve una página
- **THEN** se leen todas las páginas antes de calcular

#### Scenario: Dato inválido: evento o fecha incompletos
- **WHEN** una tarjeta no tiene número o fecha de creación, o un evento no tiene columna o fecha, o la fecha de cierre es anterior a la de creación
- **THEN** la tarjeta o el evento se descarta y la consola informa cuántos se descartaron

#### Scenario: Métricas de dos tableros
- **WHEN** hay dos Projects configurados y en el período se cerró un issue en cada uno
- **THEN** `metricas.md` cuenta 2 cerrados y lista los dos issues con su repo

#### Scenario: Dato inválido: el mismo issue en dos tableros
- **WHEN** el mismo issue (mismo repo y número) está en los dos Projects configurados
- **THEN** cuenta una sola vez en los cerrados, el throughput y el trabajo en curso, con los eventos de los dos Projects ordenados por fecha

### Requirement: Archivo de métricas en el vault
`scripts/metricas.ps1` SHALL escribir `metricas.md` en la raíz del vault (o en `-Salida <ruta>`) en UTF-8 sin BOM, con una primera línea de comentario que dice que es generado y no se edita a mano, la fecha de la corrida, el período y los Projects leídos, y las secciones de resumen, throughput, tiempo por columna, trabajo en curso e issues cerrados. NO SHALL contener rutas absolutas ni nombres de cuentas fuera de los nombres de repos y de los Projects leídos. Si no puede leer ningún Project (sin configuración, sin `gh`, sin red o sin permiso), SHALL avisar en una línea, NO SHALL tocar `metricas.md` y SHALL terminar con 0. Si puede leer algunos, SHALL calcular con esos, avisar en la consola qué Project falló y nombrarlo en el archivo como no leído.

#### Scenario: Archivo generado
- **WHEN** se generan las métricas
- **THEN** `metricas.md` existe sin BOM, su primera línea es el comentario de archivo generado y tiene las cinco secciones en orden

#### Scenario: Período sin issues cerrados
- **WHEN** no se cerró ningún issue en el período
- **THEN** las secciones de resumen e issues cerrados dicen `Sin issues cerrados en el período.` y el throughput muestra las semanas con 0

#### Scenario: Sin tablero o sin gh
- **WHEN** no hay `tablero.md` o `gh` no está disponible
- **THEN** el script imprime una línea con el motivo, termina con 0 y `metricas.md` queda como estaba

#### Scenario: Dato inválido: un tablero que no se puede leer
- **WHEN** hay dos Projects configurados y `gh` falla al leer uno
- **THEN** `metricas.md` se escribe con los datos del otro, su encabezado nombra el Project que no se leyó y la consola avisa en una línea
