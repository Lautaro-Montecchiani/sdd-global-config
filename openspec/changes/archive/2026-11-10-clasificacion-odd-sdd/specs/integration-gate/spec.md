## MODIFIED Requirements

### Requirement: Condición de merge
El `CLAUDE.md` global SHALL documentar la puerta de integración y que el merge solo se hace con el verify aprobado y las tres preguntas en `sí` (o la del dato inesperado en `no evaluada`). Para un ODD, SHALL documentar que el merge solo se hace con `/odd:verify` sin CRITICAL, seguridad y explicabilidad en `sí` y el dato inesperado en `no aplica (ODD)`, y que `no aplica (ODD)` no bloquea el merge. El checklist del PR de la skill `branch-pr` SHALL incluir la línea "Puerta de integración en sí (dato inesperado, seguridad, explicabilidad)" para un branch `change/`, y "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)" para un branch `odd/`.

#### Scenario: Reglas documentadas
- **WHEN** se lee la sección "Pull Requests" del `CLAUDE.md` global
- **THEN** la condición de merge menciona la puerta de integración
- **AND** menciona la condición de merge de un ODD con `/odd:verify`

#### Scenario: Checklist del PR
- **WHEN** `branch-pr` arma el cuerpo del PR
- **THEN** el checklist incluye la línea de la puerta de integración

#### Scenario: Checklist del PR de un ODD
- **WHEN** `branch-pr` arma el cuerpo del PR de un branch `odd/typo-bienvenida`
- **THEN** el checklist incluye "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)"
