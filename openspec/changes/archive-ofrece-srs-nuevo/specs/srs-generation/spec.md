## MODIFIED Requirements

### Requirement: Enganche opcional en el archive
`skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` SHALL ofrecer, al final de todo archive, el SRS del proyecto: regenerarlo si `docs/srs.md` ya existe, o generarlo por primera vez si no existe, invocando `srs-generate` solo si el usuario acepta. La oferta SHALL hacerse en todos los proyectos y en cada archive. El archive NO SHALL bloquearse ni generar el SRS sin la aceptación del usuario.

#### Scenario: Archive en un proyecto que ya usa SRS
- **WHEN** se completa `/opsx:archive` en un proyecto que tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece regenerar el SRS, con las opciones "Regenerar ahora" y "Más tarde"
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

#### Scenario: Archive en un proyecto sin SRS
- **WHEN** se completa `/opsx:archive` en un proyecto que no tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece generar el SRS, con las opciones "Generar ahora" y "Más tarde"
- **AND** la pregunta avisa que la primera generación incluye una entrevista corta
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

#### Scenario: Usuario que posterga la generación
- **WHEN** en un proyecto sin `docs/srs.md` el usuario contesta "Más tarde"
- **THEN** no se crea ningún archivo de SRS
- **AND** el próximo archive del proyecto vuelve a ofrecerlo
