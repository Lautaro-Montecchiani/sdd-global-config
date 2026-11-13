## ADDED Requirements

### Requirement: Marca de tareas del usuario en el propose
`openspec-propose` y `/opsx:propose` SHALL escribir la marca literal `(lo corre el usuario)` justo después del ID en toda tarea manual de `tasks.md` que necesita al usuario (una sesión real de Claude Code o del Agente, otro proyecto, otra máquina o credenciales propias), y SHALL indicar en la tarea que queda `[ ]` hasta que el usuario la confirme.

#### Scenario: Marca en las tareas del usuario
- **WHEN** se lee la guía de `tasks.md` en `skills/openspec-propose/SKILL.md` y en `.claude/commands/opsx/propose.md`
- **THEN** las dos piden la marca `(lo corre el usuario)` después del ID en las tareas manuales que necesitan al usuario
- **AND** indican que esas tareas quedan `[ ]` hasta que el usuario las confirme

### Requirement: Control de tareas del usuario en el verify
`openspec-verify-change` y `/opsx:verify` SHALL buscar la marca `(lo corre el usuario)` en `tasks.md` sin distinguir mayúsculas. Una tarea con la marca en `[x]` SHALL contar solo si el usuario confirma en el verify que la corrió él; si no, SHALL reportar CRITICAL "tarea del usuario sin confirmar". Una tarea con la marca en `[ ]` SHALL seguir siendo CRITICAL de completitud hasta que el usuario pegue la salida de sus pasos. Las tareas sin la marca SHALL controlarse como hasta ahora.

#### Scenario: Tarea del usuario marcada y confirmada
- **WHEN** el verify encuentra una tarea `(lo corre el usuario)` en `[x]` y el usuario responde que la corrió él
- **THEN** no reporta CRITICAL por esa tarea y anota la confirmación en el reporte

#### Scenario: Tarea del usuario marcada por el Agente
- **WHEN** el verify encuentra una tarea `(lo corre el usuario)` en `[x]` y el usuario responde que no la corrió él
- **THEN** reporta CRITICAL "tarea del usuario sin confirmar" con el ID
- **AND** recomienda que el usuario corra los pasos y pegue la salida

#### Scenario: Verify sin interfaz interactiva
- **WHEN** el verify corre sin `AskUserQuestion` y hay una tarea `(lo corre el usuario)` en `[x]`
- **THEN** reporta CRITICAL "tarea del usuario sin confirmar" con el ID, aunque el pedido traiga una respuesta escrita

#### Scenario: Evidencia del usuario en el verify
- **WHEN** una tarea `(lo corre el usuario)` está en `[ ]` y el usuario pega en el verify la salida de sus pasos
- **THEN** Claude la marca `[x]` en `tasks.md`
- **AND** el reporte dice que la evidencia la entregó el usuario en el verify

#### Scenario: Dato inválido: marca escrita de otra forma
- **WHEN** una tarea dice "(Lo Corre El Usuario)" con otras mayúsculas
- **THEN** el verify la trata igual que `(lo corre el usuario)`
- **AND** una tarea manual sin la marca se controla como una tarea manual cualquiera, sin la pregunta al usuario
