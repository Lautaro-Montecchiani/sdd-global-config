# Spec Delta

## ADDED Requirements

### Requirement: El verify lee el resumen del apply desde el vault
`/opsx:verify` y `openspec-verify-change` SHALL leer `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault, contrastar cada `[x]` con su evidencia y con el diff, y citar la ruta sin pegar su contenido. SHALL reportar CRITICAL cuando falta evidencia o el archivo, o cuando no existe el vault, y NO SHALL dar la evidencia por verificada, salvo que el usuario la entregue por otra vía.

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
- **THEN** el verify reporta CRITICAL "no se pudo contrastar la evidencia" y lo anota en el reporte
- **AND** no inventa evidencia ni da el change por verificado
