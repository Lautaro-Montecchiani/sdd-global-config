## ADDED Requirements

### Requirement: Generación por agregación desde las specs vigentes
La skill `srs-generate` SHALL construir `docs/srs.md` del proyecto destino leyendo `openspec/specs/**/spec.md` (capabilities vigentes) y organizando sus requirements en la estructura ISO/IEC/IEEE 29148 (Introduction/Scope, Stakeholder Requirements, System Requirements con subsecciones Functional y Non-Functional). La skill NO SHALL redactar requirements que no provengan de una spec o, en modo bootstrap, del código/documentación existente.

#### Scenario: Proyecto con specs vigentes
- **WHEN** se invoca `srs-generate` en un proyecto que tiene una o más capabilities en `openspec/specs/`
- **THEN** `docs/srs.md` incluye una sección por cada capability, con sus requirements y escenarios traducidos a la estructura ISO 29148
- **AND** cada requirement del SRS indica de qué capability sale

#### Scenario: Clasificación Funcional / No-Funcional visible
- **WHEN** se genera el SRS de un proyecto con capabilities de distinto tipo
- **THEN** cada capability aparece bajo "Functional Requirements" o "Non-Functional Requirements" según la heurística de palabras clave (performance, seguridad, escalabilidad, disponibilidad, usabilidad, mantenibilidad, compliance)
- **AND** el documento deja explícita esa clasificación para que se pueda corregir a mano

### Requirement: Modo bootstrap para proyectos sin specs de OpenSpec
Si `openspec/specs/` está vacío o no cubre partes evidentes del proyecto, la skill SHALL ofrecer un modo bootstrap que lee código, README y configuración existentes para completar un primer borrador del SRS, marcando cada sección resultante como inferida.

#### Scenario: Proyecto sin ninguna spec
- **WHEN** se invoca `srs-generate` en un proyecto cuyo `openspec/specs/` no existe o está vacío
- **THEN** la skill ofrece el modo bootstrap antes de generar un SRS vacío
- **AND**, si el usuario acepta, cada sección del SRS resultante que no venga de una spec queda marcada como "inferido del código, sin spec formal — revisar"

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
Cada requirement que aparece en el SRS generado SHALL indicar su fuente: la capability y ruta del `spec.md` de origen, o la marca de "inferido del código" cuando viene del modo bootstrap.

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
