# Spec Delta

## ADDED Requirements

### Requirement: El verify lee el resumen del apply desde el vault
`/opsx:verify` y `openspec-verify-change` SHALL leer `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault y contrastar cada tarea `[x]` con su evidencia y con el diff. SHALL reportar como CRITICAL un `[x]` sin evidencia o sin respaldo en el diff y la ausencia del archivo, salvo que el usuario entregue la evidencia por otra vía. Las copias no se suben a git, y el reporte SHALL citar la ruta del archivo sin pegar su contenido.

#### Scenario: Resumen presente y consistente
- **WHEN** el verify encuentra el archivo del change y cada `[x]` tiene evidencia y respaldo en el diff
- **THEN** el reporte indica que la evidencia fue contrastada y cita la ruta

#### Scenario: Tarea marcada sin evidencia
- **WHEN** una tarea `[x]` no aparece con evidencia en el archivo
- **THEN** el verify reporta CRITICAL "tarea sin evidencia" con su ID

#### Scenario: Resumen ausente
- **WHEN** no existe el archivo del change en el vault
- **THEN** el verify reporta CRITICAL "sin resumen del apply"
- **AND** recomienda pedirle la copia al Agente o entregar la evidencia

#### Scenario: Vault inexistente
- **WHEN** el vault no existe en la máquina
- **THEN** el verify lo anota en el reporte y no inventa evidencia
