## MODIFIED Requirements

### Requirement: Mismas reglas de ejecución en todas las plantillas de reglas
Los archivos de reglas de las plantillas (`templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/comun/AGENTS.md`) SHALL incluir las mismas 8 reglas de ejecución del Agente del `CLAUDE.md` global. La regla 7 SHALL pedir además guardar una copia completa del resumen final en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault.

#### Scenario: Reglas presentes en cada plantilla
- **WHEN** se buscan "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en las cuatro plantillas de reglas
- **THEN** aparecen en las cuatro

#### Scenario: Copia del resumen en el vault
- **WHEN** se lee la regla 7 de cada una de las cuatro plantillas y la del `CLAUDE.md` global
- **THEN** indica guardar la copia en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`
- **AND** indica que lleva fecha, rama y commit, sin datos personales ni credenciales
- **AND** indica que el Agente no la commitea ni la pushea

#### Scenario: Regla 8 en cada plantilla
- **WHEN** se busca "Respetar la arquitectura" en las cuatro plantillas de reglas y en el `CLAUDE.md` global
- **THEN** aparece en las cinco
- **AND** el `CLAUDE.md` global dice que las plantillas llevan "estas mismas 8 reglas"
