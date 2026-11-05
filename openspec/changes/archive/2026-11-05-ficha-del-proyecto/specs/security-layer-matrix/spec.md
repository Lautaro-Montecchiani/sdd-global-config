# Spec Delta

## ADDED Requirements

### Requirement: Controles para datos personales
La Capa de Seguridad del `CLAUDE.md` global SHALL incluir controles mínimos para datos personales, válidos para cualquier `project_type`: no loguearlos, pedir solo los campos necesarios, enmascararlos en salidas no productivas, no usar datos reales en tests ni fixtures y no exponerlos en URLs. Si `## Datos` declara un dato `personal` y el change lo toca, la `## Security Layer` del `design.md` SHALL incluir estos controles.

#### Scenario: Change que toca datos personales
- **WHEN** `## Datos` declara `- leads (nombre, teléfono, email): formulario web (externo) | personal` y el change agrega un campo al formulario de leads
- **THEN** la `## Security Layer` del design incluye los controles para datos personales

#### Scenario: Change que no toca datos personales
- **WHEN** el change solo modifica estilos de la web
- **THEN** la `## Security Layer` no está obligada a incluir los controles para datos personales

#### Scenario: Controles en el CLAUDE.md global
- **WHEN** se lee la Capa de Seguridad del `CLAUDE.md` global
- **THEN** hay una subsección de datos personales con los cinco controles del requirement
