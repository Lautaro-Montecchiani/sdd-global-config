## ADDED Requirements

### Requirement: Estructura fija del SRS
`docs/srs.md` SHALL seguir siempre el mismo esqueleto de secciones y numeración, tomado de la Parte 1 (el SRS de ejemplo) del documento de referencia del usuario: `1. Introducción` (1.1 Alcance, 1.2 Objetivos), `2. Información del Dominio del Problema` (2.1 Introducción al dominio, 2.2 Glosario de Términos), `3. Necesidades de Negocio` (3.1 Objetivos de negocio de clientes/usuarios, 3.2 Objetivos de Negocio, 3.3 Actores y Procesos de Negocio, 3.4 Casos de Uso, 3.5 Requisitos Funcionales, 3.6 Requisitos No Funcionales, 3.7 Matriz de Trazabilidad). La skill NO SHALL usar una estructura distinta ni copiar el contenido específico del proyecto de ejemplo del documento de referencia (Chef, Plato, Reserva, etc.).

#### Scenario: Misma estructura en cualquier proyecto
- **WHEN** se invoca `srs-generate` en dos proyectos distintos
- **THEN** `docs/srs.md` de ambos tiene las mismas secciones y la misma numeración
- **AND** solo difiere el contenido de cada subsección, tomado del proyecto destino

#### Scenario: Sección sin contenido disponible
- **WHEN** una sección de la estructura fija no tiene información disponible en specs, código ni entrevista todavía
- **THEN** la sección igual aparece en `docs/srs.md`, marcada como pendiente, en vez de omitirse

### Requirement: Requisitos Funcionales y No Funcionales por agregación, con prioridad
La skill SHALL completar "3.5 Requisitos Funcionales" y "3.6 Requisitos No Funcionales" leyendo `openspec/specs/**/spec.md` (capabilities vigentes) del proyecto destino, agrupando cada capability según la heurística de palabras clave (performance, seguridad, escalabilidad, disponibilidad, usabilidad, mantenibilidad, compliance sobre `## Purpose` y los requirements). Cada requirement en 3.6 SHALL llevar una prioridad (por ejemplo Deseable/Alta/Crítica/Media, como en el documento de referencia) obtenida de la entrevista guiada o de `docs/srs.meta.yaml`.

#### Scenario: Proyecto con specs vigentes
- **WHEN** se invoca `srs-generate` en un proyecto que tiene una o más capabilities en `openspec/specs/`
- **THEN** cada capability aparece en 3.5 o 3.6 según su clasificación, con sus requirements y escenarios
- **AND** cada requirement de 3.6 muestra una prioridad

#### Scenario: Clasificación visible y corregible
- **WHEN** se genera el SRS de un proyecto con capabilities de distinto tipo
- **THEN** el documento deja explícita la clasificación aplicada a cada capability para que se pueda corregir a mano

#### Scenario: Requisito no funcional sin prioridad todavía
- **WHEN** una capability se clasifica en 3.6 y no tiene prioridad asignada en `docs/srs.meta.yaml`
- **THEN** queda marcada como pendiente hasta que la entrevista guiada la complete

### Requirement: Casos de Uso con diagrama UML y, cuando corresponda, diagrama de flujo o secuencia
Cada `#### Scenario:` de una spec del proyecto destino SHALL convertirse en un Caso de Uso dentro de "3.4 Casos de Uso", con un diagrama UML de caso de uso en PlantUML (actor(es) inferido(s) del `WHEN`, sistema y el caso de uso como óvalo). Cuando el `WHEN/THEN` del escenario tenga más de un paso o involucre más de un actor, la skill SHALL agregar además un diagrama Mermaid: flowchart para una secuencia de pasos de un solo actor, sequence diagram cuando hay interacción entre dos o más actores. La skill NO SHALL usar PlantUML para flujo/secuencia ni Mermaid para el diagrama de caso de uso.

#### Scenario: Caso de uso simple
- **WHEN** un escenario de una spec tiene un único actor y un solo paso en el `WHEN`
- **THEN** el Caso de Uso correspondiente en 3.4 incluye su diagrama UML de caso de uso en PlantUML
- **AND** no se agrega diagrama Mermaid

#### Scenario: Caso de uso con varios pasos de un solo actor
- **WHEN** un escenario tiene varios pasos secuenciales de un mismo actor
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en PlantUML, un flowchart en Mermaid con esos pasos

#### Scenario: Caso de uso con interacción entre actores
- **WHEN** un escenario involucra a dos o más actores interactuando
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en PlantUML, un sequence diagram en Mermaid con esa interacción

### Requirement: Matriz de Trazabilidad
La skill SHALL completar "3.7 Matriz de Trazabilidad" cruzando automáticamente los Casos de Uso de 3.4 con los Requisitos Funcionales de 3.5, sin trabajo manual adicional.

#### Scenario: Matriz generada automáticamente
- **WHEN** 3.4 y 3.5 ya están completas
- **THEN** 3.7 muestra una tabla con cada Caso de Uso y los Requisitos Funcionales que le corresponden, sin que nadie la arme a mano

### Requirement: Entrevista guiada para secciones sin fuente formal
Para "2.2 Glosario de Términos", "3.1/3.2 Objetivos de Negocio" y "3.3 Actores y Procesos de Negocio" — que no salen de ninguna spec ni del código — la skill SHALL ofrecer una entrevista guiada corta la primera vez que se genera el SRS del proyecto, y SHALL persistir las respuestas en `docs/srs.meta.yaml`. En regeneraciones siguientes, la skill SHALL leer `docs/srs.meta.yaml` primero y SHALL preguntar solo por los gaps nuevos desde la última corrida (una capability sin prioridad asignada en 3.6, un actor o término que aparece en un escenario nuevo, etc.), sin repetir preguntas ya respondidas.

#### Scenario: Primera generación
- **WHEN** se invoca `srs-generate` por primera vez en un proyecto (no existe `docs/srs.meta.yaml`)
- **THEN** la skill hace la entrevista guiada completa antes de escribir `docs/srs.md`
- **AND** persiste las respuestas en `docs/srs.meta.yaml`

#### Scenario: Regeneración sin gaps nuevos
- **WHEN** se invoca `srs-generate` de nuevo y no hay capabilities, actores ni términos nuevos desde la última corrida
- **THEN** la skill no repite ninguna pregunta de la entrevista y usa `docs/srs.meta.yaml` tal cual está

#### Scenario: Regeneración con un gap nuevo
- **WHEN** se invoca `srs-generate` de nuevo y apareció una capability nueva en 3.6 sin prioridad asignada
- **THEN** la skill pregunta solo por esa prioridad y actualiza `docs/srs.meta.yaml`, sin volver a preguntar el resto

### Requirement: Modo bootstrap para proyectos sin specs de OpenSpec
Si `openspec/specs/` está vacío o no cubre partes evidentes del proyecto, la skill SHALL ofrecer un modo bootstrap que lee código, README y configuración existentes para completar un primer borrador de 3.5/3.6, marcando cada sección resultante como inferida. El modo bootstrap NO SHALL sustituir a la entrevista guiada para las secciones de negocio (2.2, 3.1-3.3): esas siempre se completan por entrevista, nunca por inferencia automática del código.

#### Scenario: Proyecto sin ninguna spec
- **WHEN** se invoca `srs-generate` en un proyecto cuyo `openspec/specs/` no existe o está vacío
- **THEN** la skill ofrece el modo bootstrap antes de generar un SRS con 3.5/3.6 vacías
- **AND**, si el usuario acepta, cada sección de 3.5/3.6 que no venga de una spec queda marcada como "inferido del código, sin spec formal — revisar"

#### Scenario: Proyecto con specs parciales
- **WHEN** se invoca `srs-generate` en un proyecto que tiene algunas capabilities documentadas y zonas de código sin spec asociada
- **THEN** la skill combina en el mismo SRS las secciones basadas en spec (sin marca) con las inferidas por bootstrap (marcadas), sin mezclarlas sin distinción

### Requirement: Regeneración segura con confirmación
Si `docs/srs.md` ya existe, la skill SHALL mostrar un resumen de las secciones que cambiarían antes de sobrescribir el archivo y SHALL pedir confirmación explícita. La skill NO SHALL sobrescribir `docs/srs.md` sin confirmación.

#### Scenario: Regenerar un SRS existente
- **WHEN** se invoca `srs-generate` en un proyecto que ya tiene `docs/srs.md`
- **THEN** la skill muestra qué secciones cambiarían respecto del contenido actual antes de escribir
- **AND** solo sobrescribe el archivo si el usuario confirma

#### Scenario: El usuario cancela la regeneración
- **WHEN** se muestra el resumen de cambios y el usuario no confirma
- **THEN** `docs/srs.md` queda intacto

### Requirement: Enganche opcional en el archive
`skills/openspec-archive-change/SKILL.md` SHALL ofrecer, al final del archive y solo si `docs/srs.md` ya existe en el proyecto, regenerar el SRS invocando `srs-generate`. El archive NO SHALL bloquearse ni forzar la generación de un SRS que el proyecto nunca tuvo.

#### Scenario: Archive en un proyecto que ya usa SRS
- **WHEN** se completa `/opsx:archive` en un proyecto que tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece regenerar el SRS
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

#### Scenario: Archive en un proyecto sin SRS
- **WHEN** se completa `/opsx:archive` en un proyecto que no tiene `docs/srs.md`
- **THEN** el resumen final del archive no menciona ni ofrece generar un SRS

### Requirement: Trazabilidad de origen por requirement
Cada requirement que aparece en 3.5/3.6 del SRS generado SHALL indicar su fuente: la capability y ruta del `spec.md` de origen, la marca de "inferido del código" cuando viene del modo bootstrap, o la marca de "entrevista" cuando el dato (como la prioridad) viene de `docs/srs.meta.yaml`.

#### Scenario: Requirement basado en spec
- **WHEN** un requirement del SRS proviene de `openspec/specs/<capability>/spec.md`
- **THEN** el SRS cita esa capability como fuente del requirement

#### Scenario: Requirement inferido
- **WHEN** un requirement del SRS proviene del modo bootstrap
- **THEN** el SRS lo marca como inferido en vez de citar una spec inexistente

### Requirement: Exclusión de secrets y rutas absolutas en el bootstrap
El modo bootstrap NO SHALL leer ni citar el contenido de archivos excluidos por el `.gitignore` del proyecto destino, ni de `*.env`, `*.key`, `*.pem`, `*.p12` o `secrets/` aunque no estén en `.gitignore`. Antes de incluir un valor literal encontrado en código o configuración, la skill SHALL descartar strings que matcheen patrones típicos de credenciales, y SHALL reemplazar rutas absolutas que contengan el nombre de usuario de la máquina por un placeholder.

#### Scenario: Archivo de secretos ignorado
- **WHEN** el modo bootstrap recorre el código de un proyecto que tiene `.env` o `secrets/` en su `.gitignore`
- **THEN** el contenido de esos archivos no aparece en `docs/srs.md`

#### Scenario: Ruta absoluta con usuario local
- **WHEN** el bootstrap encuentra en el código una ruta absoluta con el nombre de usuario de la máquina
- **THEN** el SRS generado reemplaza esa parte de la ruta por un placeholder en vez de copiarla literal
