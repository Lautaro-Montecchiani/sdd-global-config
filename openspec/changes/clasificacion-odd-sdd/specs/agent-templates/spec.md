## ADDED Requirements

### Requirement: Handoff ODD en las plantillas de reglas
Las cuatro plantillas de reglas del Agente (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`) SHALL tener una sección `## Handoff ODD`, con texto idéntico, que diga que el Agente: lee `docs/odd/<nombre>.md`; trabaja solo en el branch `odd/<nombre>` y en los archivos permitidos; aplica las mismas reglas de ejecución que en SDD; pega la evidencia en `## Evidencia` del documento en vez de escribir la nota `apply\` del vault; frena y avisa "escalar a SDD" si al implementar se cumple un criterio SDD; y commitea con `Spec-ID: odd-<nombre>`. La regla 7 de cada plantilla y la del `CLAUDE.md` global SHALL terminar con la excepción ODD: en un handoff ODD, la evidencia va en `## Evidencia` del documento y no se escribe la nota `apply\` del vault.

#### Scenario: Sección presente en las cuatro
- **WHEN** se busca `## Handoff ODD` en las cuatro plantillas de reglas
- **THEN** aparece una vez en cada una
- **AND** el texto de la sección es idéntico en las cuatro

#### Scenario: Excepción ODD en la regla 7
- **WHEN** se lee la regla 7 de las cuatro plantillas de reglas y la del `CLAUDE.md` global
- **THEN** cada una termina diciendo que en un handoff ODD la evidencia va en `## Evidencia` del documento ODD y no se escribe la nota `apply\` del vault
- **AND** la oración es idéntica en las cuatro plantillas

#### Scenario: El Agente encuentra un criterio SDD
- **WHEN** el Agente, siguiendo la plantilla, necesita tocar más archivos de los permitidos
- **THEN** frena, lo escribe en `## Progreso` del documento y avisa "escalar a SDD"
