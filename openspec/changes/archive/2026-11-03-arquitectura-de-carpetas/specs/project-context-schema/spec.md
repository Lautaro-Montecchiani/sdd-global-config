## MODIFIED Requirements

### Requirement: Subsecciones estructuradas dentro de `context:`
El campo `context:` de `openspec/config.yaml` SHALL admitir subsecciones opcionales con encabezados Markdown fijos — `## Glosario`, `## Actores y Procesos de Negocio` (con sub-encabezados `### Actores` y `### Procesos`), `## Objetivos de Negocio`, `## Tests`, `## Arquitectura` (formato definido en la capability `project-architecture`) — para conocimiento del proyecto reusable en toda operación de OpenSpec. Cualquier skill que escriba ahí SHALL appendear estas subsecciones al final del texto existente y NO SHALL sobrescribir ni reordenar el contenido previo a ellas. Si `openspec/config.yaml` no existe, o existe sin un `context:` activo (ausente o solo comentado) o sin `project_type`, la skill que necesite escribir una subsección SHALL completar lo que falta antes de escribirla — `schema: spec-driven` si falta el archivo, `project_type` preguntado una vez al usuario, `context:` con una línea que describa el proyecto — sin tocar el resto del archivo (claves, `rules` y comentarios existentes).

#### Scenario: Proyecto sin subsecciones previas
- **WHEN** una skill agrega una subsección por primera vez a un `context:` que no tiene ninguna
- **THEN** la subsección se appendea al final del texto existente, separada por una línea en blanco
- **AND** el contenido previo de `context:` queda intacto

#### Scenario: Proyecto con subsecciones ya presentes
- **WHEN** una skill actualiza una subsección que ya existe (por ejemplo, agrega un término al Glosario)
- **THEN** solo se reemplaza el bloque entre su encabezado y el siguiente `##` (o el final del texto)
- **AND** las demás subsecciones y el contenido previo a ellas no cambian

#### Scenario: Proyecto sin config.yaml
- **WHEN** una skill necesita escribir una subsección y el proyecto no tiene `openspec/config.yaml` (por ejemplo, tras `openspec init` en OpenSpec 1.4.1)
- **THEN** crea el archivo con `schema: spec-driven`, el `project_type` que indique el usuario y un `context:` con la descripción del proyecto
- **AND** recién después appendea la subsección al final del `context:`

#### Scenario: config.yaml sin context activo ni project_type
- **WHEN** una skill necesita escribir una subsección y `openspec/config.yaml` no tiene `context:` activo (por ejemplo, el que genera `openspec init` en OpenSpec 1.14.x, con el `context:` solo comentado) o no tiene `project_type`
- **THEN** agrega las claves que faltan, preguntando `project_type` en la misma pregunta que la subsección `## Tests`
- **AND** el resto del archivo, incluidos los comentarios, queda intacto

#### Scenario: Usuario que no sabe el tipo de proyecto
- **WHEN** se pregunta `project_type` y el usuario responde que no sabe
- **THEN** la skill lo deduce del repo, lo escribe con el comentario `# inferido — revisar` en la misma línea
- **AND** lo menciona en el resumen final para que se revise

#### Scenario: Usuario que no sabe cómo se corren los tests
- **WHEN** se pregunta `## Tests` y el usuario responde que no sabe
- **THEN** si el repo muestra cómo se corren (por ejemplo, pytest con archivos `test_*.py`, o `scripts.test` en `package.json`), la skill escribe ese `comando` junto con `- timeout: 5` por defecto, y menciona los dos en el resumen final como inferidos
- **AND** si el repo no lo muestra, no escribe `## Tests` (tampoco `comando: ninguno`), deja el comando como pendiente en el Test Plan y lo vuelve a preguntar en el próximo propose

#### Scenario: Arquitectura en la misma pregunta
- **WHEN** a un proyecto le faltan `project_type`, `## Tests` y `## Arquitectura`
- **THEN** el propose los pide en una sola pregunta
- **AND** appendea `## Arquitectura` al final del `context:` sin tocar el resto
