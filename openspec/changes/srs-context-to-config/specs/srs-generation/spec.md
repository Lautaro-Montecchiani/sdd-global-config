## MODIFIED Requirements

### Requirement: Entrevista guiada para secciones sin fuente formal
Para "2.2 Glosario de Términos", "3.1/3.2 Objetivos de Negocio" y "3.3 Actores y Procesos de Negocio" — que no salen de ninguna spec ni del código — la skill SHALL ofrecer una entrevista guiada corta la primera vez que se genera el SRS del proyecto. Las respuestas de Glosario, Objetivos de Negocio, Actores y Procesos de Negocio SHALL persistirse en las subsecciones correspondientes del `context:` de `openspec/config.yaml` (capability `project-context-schema`), NO SHALL persistirse en `docs/srs.meta.yaml`. La prioridad de cada Requisito No Funcional (3.6) SHALL seguir persistiéndose en `docs/srs.meta.yaml`, sin cambios. En regeneraciones siguientes, la skill SHALL leer las subsecciones de `context:` primero y SHALL preguntar solo por los gaps nuevos desde la última corrida (un actor, proceso, término u objetivo que aparece en un escenario nuevo, o una capability sin prioridad asignada en 3.6), sin repetir preguntas ya respondidas.

#### Scenario: Primera generación
- **WHEN** se invoca `srs-generate` por primera vez en un proyecto y las subsecciones de Glosario/Objetivos/Actores-Procesos no existen todavía en `context:`
- **THEN** la skill hace la entrevista guiada completa antes de escribir `docs/srs.md`
- **AND** persiste las respuestas en las subsecciones correspondientes de `context:` en `openspec/config.yaml`

#### Scenario: Regeneración sin gaps nuevos
- **WHEN** se invoca `srs-generate` de nuevo y no hay actores, procesos, términos ni objetivos nuevos desde la última corrida
- **THEN** la skill no repite ninguna pregunta de la entrevista y usa las subsecciones de `context:` tal cual están

#### Scenario: Regeneración con un gap nuevo
- **WHEN** se invoca `srs-generate` de nuevo y apareció una capability nueva en 3.6 sin prioridad asignada
- **THEN** la skill pregunta solo por esa prioridad y la guarda en `docs/srs.meta.yaml`
- **AND** no vuelve a preguntar por el resto de las secciones

#### Scenario: Migración de datos existentes en `docs/srs.meta.yaml`
- **WHEN** `docs/srs.meta.yaml` de un proyecto ya tiene glosario, actores, procesos u objetivos de una corrida anterior a este change
- **THEN** la skill los migra a las subsecciones correspondientes de `context:` en la primera corrida siguiente
- **AND** los quita de `docs/srs.meta.yaml`
- **AND** no vuelve a preguntar por ellos en la entrevista
