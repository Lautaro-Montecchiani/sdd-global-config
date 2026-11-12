# Spec Delta

## MODIFIED Requirements

### Requirement: Enganche opcional en el archive
`skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` SHALL ofrecer el SRS del proyecto al final de la fase de la rama del archive, antes del merge: regenerarlo si `docs/srs.md` ya existe, o generarlo por primera vez si no existe, invocando `srs-generate` solo si el usuario acepta. La oferta SHALL hacerse en todos los proyectos y en cada archive. Si el usuario acepta, el resultado SHALL commitearse en la misma rama del change con `docs: regenerar SRS` (o `docs: generar SRS`) y el trailer `Spec-ID: <nombre>`, aparte del commit del archive, para que entre en el mismo PR. La fase del vault NO SHALL ofrecer el SRS. El archive NO SHALL bloquearse ni generar el SRS sin la aceptación del usuario.

#### Scenario: Archive en un proyecto que ya usa SRS
- **WHEN** se completa la fase de la rama de `/opsx:archive saludo` en `change/saludo` de un proyecto que tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece regenerar el SRS, con las opciones "Regenerar ahora" y "Más tarde"
- **AND** si el usuario elige "Regenerar ahora", la rama `change/saludo` tiene un commit `docs: regenerar SRS` con `Spec-ID: saludo`, separado de `chore: archive saludo`
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

#### Scenario: Archive en un proyecto sin SRS
- **WHEN** se completa la fase de la rama de `/opsx:archive` en un proyecto que no tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece generar el SRS, con las opciones "Generar ahora" y "Más tarde"
- **AND** la pregunta avisa que la primera generación incluye una entrevista corta
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

#### Scenario: Usuario que posterga la generación
- **WHEN** en un proyecto sin `docs/srs.md` el usuario contesta "Más tarde"
- **THEN** no se crea ningún archivo de SRS
- **AND** el próximo archive del proyecto vuelve a ofrecerlo

#### Scenario: El cierre en el vault no ofrece el SRS
- **WHEN** se corre `/opsx:archive saludo` después del merge para cerrar en el vault
- **THEN** el resumen no ofrece generar ni regenerar el SRS
