# Spec Delta

## ADDED Requirements

### Requirement: Handoff ODD con comando del Agente
Al aprobar un ODD, `/odd` SHALL anunciar el handoff con la línea "Ejecutá en el Agente: `/odd-apply <nombre>`". Si al implementar el Agente avisa "falta en el alcance", Claude SHALL ampliar "Archivos permitidos" del documento con el motivo en `## Progreso` y pedir que el Agente siga, sin escalar a SDD si no se cumple ningún criterio de K1 a K10.

#### Scenario: Handoff con el comando
- **WHEN** el usuario aprueba el documento de `typo-bienvenida`
- **THEN** el mensaje final de `/odd` dice "Ejecutá en el Agente: `/odd-apply typo-bienvenida`"

#### Scenario: Falta en el alcance
- **WHEN** el Agente avisa "falta en el alcance" porque necesita tocar `tests/saludo.Tests.ps1`, que no está en "Archivos permitidos"
- **THEN** Claude suma ese archivo a "Archivos permitidos", anota el motivo en `## Progreso` y pide al Agente que siga
- **AND** el documento no pasa a `estado: escalado`
