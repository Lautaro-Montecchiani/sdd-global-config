## MODIFIED Requirements

### Requirement: Portada, tabla de contenidos y formato de tabla
`docs/srs.md` SHALL abrir con un encabezado de identificación (título del documento, nombre del proyecto, fecha de generación y estado: "borrador" si quedan secciones pendientes o inferidas, o diagramas de caso de uso sin renderizar a SVG; "completo" si no) seguido de una tabla de contenidos derivada de sus propios headings. Las secciones "3.1/3.2 Objetivos de Negocio", "3.3 Actores y Procesos de Negocio" y "3.6 Requisitos No Funcionales" SHALL presentarse en formato de tabla, como en el documento de referencia, y no como texto corrido.

#### Scenario: Encabezado y estado del documento
- **WHEN** se genera `docs/srs.md` y quedan secciones marcadas como pendientes o inferidas
- **THEN** el encabezado indica estado "borrador"
- **AND** cuando no queda ninguna, indica "completo"

#### Scenario: Secciones en formato de tabla
- **WHEN** se generan 3.1/3.2, 3.3 y 3.6
- **THEN** cada objetivo de negocio, cada actor, cada proceso de negocio y cada requisito no funcional aparece como una fila o tabla individual, no como párrafo

#### Scenario: Diagramas sin renderizar
- **WHEN** se genera `docs/srs.md` y al menos un diagrama de caso de uso quedó solo como `.puml`, sin su `.svg`
- **THEN** el encabezado indica estado "borrador" aunque no haya secciones pendientes ni inferidas

### Requirement: Casos de Uso con diagrama UML y, cuando corresponda, diagrama de flujo o secuencia
Cada `#### Scenario:` de una spec del proyecto destino SHALL convertirse en un Caso de Uso dentro de "3.4 Casos de Uso", con un diagrama UML de caso de uso en PlantUML (actor(es) inferido(s) del `WHEN`, sistema y el caso de uso como óvalo). El diagrama SHALL escribirse en `docs/diagramas/<ID del caso de uso>.puml` con el motor de layout interno de PlantUML (sin Graphviz), y el Caso de Uso SHALL mostrar la imagen `.svg` generada y un link a esa fuente; la skill NO SHALL escribir bloques PlantUML inline en `docs/srs.md`. Cuando el `WHEN/THEN` del escenario tenga más de un paso o involucre más de un actor, la skill SHALL agregar además un diagrama Mermaid inline: flowchart para una secuencia de pasos de un solo actor, sequence diagram cuando hay interacción entre dos o más actores. La skill NO SHALL usar PlantUML para flujo/secuencia ni Mermaid para el diagrama de caso de uso.

#### Scenario: Caso de uso simple
- **WHEN** un escenario de una spec tiene un único actor y un solo paso en el `WHEN`
- **THEN** el Caso de Uso correspondiente en 3.4 incluye su diagrama UML de caso de uso como imagen SVG generada desde `docs/diagramas/<ID del caso de uso>.puml`, con un link a esa fuente
- **AND** no se agrega diagrama Mermaid

#### Scenario: Caso de uso con varios pasos de un solo actor
- **WHEN** un escenario tiene varios pasos secuenciales de un mismo actor
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en SVG con su link a la fuente `.puml`, un flowchart en Mermaid con esos pasos

#### Scenario: Caso de uso con interacción entre actores
- **WHEN** un escenario involucra a dos o más actores interactuando
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en SVG con su link a la fuente `.puml`, un sequence diagram en Mermaid con esa interacción

#### Scenario: Sin bloques PlantUML inline
- **WHEN** se genera o regenera `docs/srs.md`
- **THEN** el documento no contiene ningún bloque de código `plantuml`
- **AND** cada `.puml` de `docs/diagramas/` declara el motor de layout interno

### Requirement: Guard de escala y alcance acotado
La skill SHALL aceptar un alcance opcional (lista de capabilities a incluir; por defecto, todas). Antes de generar, la skill SHALL contar los escenarios y requirements en alcance y mostrar el conteo con una estimación del tamaño; si supera un umbral configurable (por defecto ~40 casos de uso), la skill SHALL pedir confirmación u ofrecer acotar el alcance antes de continuar. Por encima del umbral, la skill SHALL generar un solo diagrama de casos de uso por capability (modo agrupado, en `docs/diagramas/CAP-<ID de la capability>.puml` con su `.svg`) en vez de uno por escenario, y NO SHALL generar los diagramas Mermaid de flujo/secuencia por escenario salvo que el alcance acotado quede por debajo del umbral.

#### Scenario: Proyecto por debajo del umbral
- **WHEN** se invoca `srs-generate` sin acotar el alcance en un proyecto con pocos escenarios
- **THEN** la skill genera un diagrama de caso de uso por escenario (D7) sin pedir acotar

#### Scenario: Proyecto por encima del umbral
- **WHEN** se invoca `srs-generate` en un proyecto cuyo total de escenarios en alcance supera el umbral
- **THEN** la skill muestra el conteo y una estimación de tamaño y pide confirmación u ofrece acotar
- **AND** si se continúa, genera un solo diagrama de casos de uso por capability en vez de uno por escenario

#### Scenario: Alcance acotado a capabilities
- **WHEN** se invoca `srs-generate` con un alcance que limita las capabilities a incluir
- **THEN** el SRS generado solo cubre esas capabilities
- **AND** si el subconjunto queda por debajo del umbral, vuelven los diagramas por escenario

## ADDED Requirements

### Requirement: Renderizado de diagramas PlantUML a SVG
La skill SHALL generar el `.svg` de cada `.puml` de caso de uso con Java y una versión fija de `plantuml.jar`, guardada en una caché del usuario fuera del repo. Si el jar falta, SHALL bajarlo solo de la URL fija y verificar su SHA-256 antes de ejecutarlo. Si no hay Java, si el jar no se puede obtener o verificar, o si un `.puml` no se puede renderizar, SHALL conservar los `.puml`, enlazar solo a la fuente, avisarlo en el resumen y dejar el SRS en "borrador". SHALL borrar los `.puml` y `.svg` con su patrón de nombre que ya no correspondan a ningún diagrama vigente, y listar en la regeneración segura los archivos que crea y borra.

#### Scenario: Java y jar disponibles
- **WHEN** se genera el SRS en una máquina con Java y el jar fijo en la caché
- **THEN** cada `.puml` de `docs/diagramas/` tiene su `.svg` al lado
- **AND** el Caso de Uso muestra esa imagen y un link al `.puml`

#### Scenario: Jar ausente
- **WHEN** hay Java pero el jar fijo no está en la caché
- **THEN** la skill lo baja de la URL fija, verifica su SHA-256 y recién entonces lo ejecuta

#### Scenario: Hash que no coincide
- **WHEN** el SHA-256 del jar cacheado no coincide con el fijado en la skill
- **THEN** la skill no lo ejecuta, lo borra y lo baja una vez más de la URL fija
- **AND** si el SHA-256 del jar descargado tampoco coincide, lo borra y aplica el fallback

#### Scenario: Sin Java
- **WHEN** se genera el SRS en una máquina sin Java
- **THEN** quedan los `.puml`, los Casos de Uso enlazan solo a la fuente, el resumen avisa que faltan los SVG y el SRS queda en "borrador"

#### Scenario: Diagramas huérfanos
- **WHEN** se regenera el SRS y un caso de uso o capability ya no existe, o cambia el modo (por escenario o agrupado)
- **THEN** la skill borra los `.puml` y `.svg` de `docs/diagramas/` que ya no corresponden a ningún diagrama vigente
- **AND** no toca archivos de esa carpeta que no sigan su patrón de nombre

#### Scenario: Un diagrama con error
- **WHEN** PlantUML falla al renderizar un `.puml` puntual
- **THEN** ese Caso de Uso enlaza solo a la fuente, el resumen nombra el archivo con el error y el SRS queda en "borrador"
