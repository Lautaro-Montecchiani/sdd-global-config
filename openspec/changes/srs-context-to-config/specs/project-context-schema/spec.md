## ADDED Requirements

### Requirement: Subsecciones estructuradas dentro de `context:`
El campo `context:` de `openspec/config.yaml` SHALL admitir subsecciones opcionales con encabezados Markdown fijos — `## Glosario`, `## Actores y Procesos de Negocio` (con sub-encabezados `### Actores` y `### Procesos`), `## Objetivos de Negocio` — para conocimiento del proyecto reusable en toda operación de OpenSpec. Cualquier skill que escriba ahí SHALL appendear estas subsecciones al final del texto existente y NO SHALL sobrescribir ni reordenar el contenido previo a ellas.

#### Scenario: Proyecto sin subsecciones previas
- **WHEN** una skill agrega una subsección por primera vez a un `context:` que no tiene ninguna
- **THEN** la subsección se appendea al final del texto existente, separada por una línea en blanco
- **AND** el contenido previo de `context:` queda intacto

#### Scenario: Proyecto con subsecciones ya presentes
- **WHEN** una skill actualiza una subsección que ya existe (por ejemplo, agrega un término al Glosario)
- **THEN** solo se reemplaza el bloque entre su encabezado y el siguiente `##` (o el final del texto)
- **AND** las demás subsecciones y el contenido previo a ellas no cambian

### Requirement: Formato de cada subsección
Cada subsección SHALL usar una lista simple `- <clave>: <descripción>`: Glosario (término/definición), Objetivos de Negocio (id/descripción). "Actores y Procesos de Negocio" SHALL tener dos sub-listas bajo `### Actores` y `### Procesos`, cada una con el mismo formato (nombre/descripción).

#### Scenario: Formato consistente
- **WHEN** se genera o actualiza cualquiera de las tres subsecciones
- **THEN** cada ítem sigue el formato `- <clave>: <descripción>`
- **AND** "Actores y Procesos de Negocio" separa actores de procesos bajo sus propios sub-encabezados

### Requirement: Advertencia de tamaño antes de escribir
Antes de escribir en `context:`, una skill SHALL calcular el tamaño resultante en bytes y SHALL advertir si supera un umbral de alerta (40KB) sin bloquear la escritura, dado que el CLI de OpenSpec descarta el campo `context` completo (no solo el excedente) si supera su límite duro de 50KB.

#### Scenario: Tamaño dentro del umbral
- **WHEN** el `context:` resultante después de escribir queda por debajo de 40KB
- **THEN** la skill escribe sin advertencias

#### Scenario: Tamaño cerca del límite
- **WHEN** el `context:` resultante después de escribir superaría 40KB
- **THEN** la skill advierte antes de escribir, mostrando el tamaño estimado, y deja la decisión de qué recortar al usuario
