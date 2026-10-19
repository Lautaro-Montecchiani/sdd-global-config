# Spec Delta

## MODIFIED Requirements

### Requirement: Rol de Claude en apply

Cuando Claude ejecuta `/opsx:apply`, Claude SHALL NOT escribir código; en cambio, SHALL:
1. Leer los artefactos del change (proposal, specs, design, tasks)
2. Anunciar: "Este change está listo para implementación. Ejecutá en el Agente: `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor)"
3. Listar las tareas pendientes como resumen para el Agente
4. Recordar: "Cuando el Agente termine, ejecutá `/opsx:verify {nombre}` aquí"

#### Scenario: apply anuncia el handoff en lugar de implementar
- **WHEN** Claude ejecuta `/opsx:apply` sobre un change con tareas pendientes
- **THEN** anuncia el handoff al Agente y lista las tareas pendientes
- **AND** no realiza cambios de código

#### Scenario: El handoff nombra el comando de cada agente
- **WHEN** Claude anuncia el handoff al terminar `/opsx:propose` o `/opsx:apply`
- **THEN** el anuncio incluye `/openspec-apply-change {nombre}` para Antigravity y `/opsx-apply {nombre}` para Cursor
