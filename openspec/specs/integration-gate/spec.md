# integration-gate Specification

## Purpose
Define la puerta de integración que `/opsx:verify` aplica antes del merge: tres preguntas (dato inesperado, seguridad y explicabilidad) con resultado sí, no o pendiente, lo que el propose prepara para responderlas y la condición de merge.
## Requirements
### Requirement: Sección Puerta de integración en el verify
El reporte de `/opsx:verify` SHALL incluir una sección "Puerta de integración" con una fila por pregunta (dato inesperado, seguridad, explicabilidad), su resultado (`sí`, `no`, `pendiente` o `no evaluada`) y el motivo en una línea. Un `no` o un `pendiente` SHALL ser CRITICAL, y la evaluación final NO SHALL decir que el change está listo para archive.

#### Scenario: Las tres en sí
- **WHEN** las tres preguntas dan `sí`
- **THEN** la sección muestra las tres en `sí`
- **AND** la puerta no agrega desvíos al reporte

#### Scenario: Una pregunta en no
- **WHEN** la pregunta de seguridad da `no`
- **THEN** el reporte tiene un CRITICAL con el motivo
- **AND** la evaluación final dice que hay que corregirlo antes de archivar

### Requirement: El propose prepara el dato inválido
Para cada requirement que toca un dato declarado en `## Datos` con origen `(externo)`, `/opsx:propose` SHALL agregar al menos un escenario cuyo nombre empiece con "Dato inválido:" (por ejemplo vacío, mal formado, duplicado o fuera de rango) y su fila en el Test Plan. Los requirements que no tocan datos externos NO SHALL estar obligados a tenerlo.

#### Scenario: Requirement con dato externo
- **WHEN** `## Datos` declara `- leads (nombre, teléfono, email): formulario web (externo) | personal` y el change agrega un requirement que lee el teléfono del formulario
- **THEN** ese requirement tiene al menos un escenario "Dato inválido:" con su fila en el Test Plan

#### Scenario: Requirement sin dato externo
- **WHEN** un requirement solo cambia el texto de un mensaje
- **THEN** no está obligado a tener un escenario "Dato inválido:"

### Requirement: El verify controla el dato inesperado
`/opsx:verify` SHALL responder `no` a la pregunta del dato inesperado si algún requirement de las delta specs que toca un dato externo de `## Datos` no tiene escenario "Dato inválido:", o si la verificación de ese escenario no pasa. SHALL responder `sí` si todos lo tienen y pasan, o si el change no toca datos externos.

#### Scenario: Falta el escenario
- **WHEN** un requirement del change lee el email del formulario y no tiene escenario "Dato inválido:"
- **THEN** la pregunta da `no` con el nombre del requirement

#### Scenario: Escenario en rojo
- **WHEN** el escenario "Dato inválido: teléfono vacío" tiene un test que falla
- **THEN** la pregunta da `no` con el ID del escenario

#### Scenario: Change sin datos externos
- **WHEN** el change no toca ningún dato externo de `## Datos`
- **THEN** la pregunta da `sí` con el motivo "no toca datos externos"

### Requirement: Dato inesperado sin ficha
Si el proyecto no declara `## Datos`, `/opsx:verify` SHALL responder `no evaluada` a la pregunta del dato inesperado, con un WARNING que sugiere completar la ficha con `/ficha`, y NO SHALL contarla como CRITICAL.

#### Scenario: Proyecto sin Datos
- **WHEN** se verifica un change en un proyecto sin `## Datos`
- **THEN** la pregunta da `no evaluada`
- **AND** el reporte tiene un WARNING que sugiere `/ficha`

### Requirement: Cada control de seguridad dice cómo se verifica
En la `## Security Layer` del `design.md`, `/opsx:propose` SHALL escribir para cada control aplicable cómo se verifica: un escenario del Test Plan (`Sxx`), una revisión del diff o una verificación manual con sus pasos.

#### Scenario: Control con su verificación
- **WHEN** la Security Layer incluye "no loguear datos personales"
- **THEN** el control dice cómo se verifica, por ejemplo "revisión del diff: ningún `print` ni log con campos de leads"

### Requirement: El verify controla la seguridad
`/opsx:verify` SHALL responder `no` a la pregunta de seguridad si un control de la `## Security Layer` no se cumple en el diff, si las líneas agregadas del diff contienen algo con forma de credencial (clave privada, token, contraseña o clave de API escrita en el código) o si un check de seguridad del PR (por ejemplo gitleaks u OSV-Scanner) falla. Si el repo no tiene escaneos, SHALL decirlo en el motivo sin bloquear.

#### Scenario: Control incumplido
- **WHEN** la Security Layer dice "no loguear datos personales" y el diff agrega un `print` con el teléfono del lead
- **THEN** la pregunta da `no` con el archivo y la línea

#### Scenario: Credencial en el diff
- **WHEN** el diff agrega una línea `API_KEY = "sk-…"` en un archivo de código
- **THEN** la pregunta da `no` con el archivo y la línea, sin copiar el valor en el reporte

#### Scenario: Repo sin escaneos
- **WHEN** el PR no tiene checks de seguridad y los controles se cumplen
- **THEN** la pregunta da `sí` y el motivo dice "sin escaneos de seguridad en el repo"

### Requirement: El verify explica el código y pide confirmación
`/opsx:verify` SHALL escribir, para cada archivo del diff fuera de `openspec/` (sin lockfiles ni archivos generados), una explicación en simple de qué hace y por qué cambió, y SHALL preguntar al usuario con `AskUserQuestion` si la entiende. Un "no" SHALL dar `no` en la pregunta de explicabilidad, con los archivos que no se entendieron y la recomendación de simplificar el código o pedir una explicación más detallada.

#### Scenario: Usuario que entiende
- **WHEN** el usuario responde que entiende la explicación de todos los archivos
- **THEN** la pregunta de explicabilidad da `sí`

#### Scenario: Usuario que no entiende un archivo
- **WHEN** el usuario responde que no entiende `src/leads.py`
- **THEN** la pregunta da `no` con `src/leads.py`
- **AND** el reporte recomienda simplificarlo o explicarlo con más detalle antes de integrar

### Requirement: Explicabilidad sin interfaz
Si `/opsx:verify` corre sin poder preguntar al usuario (por ejemplo con `claude -p`), la pregunta de explicabilidad SHALL quedar `pendiente`, aunque el pedido traiga una respuesta escrita, porque la confirmación tiene que venir de una persona en una sesión interactiva.

#### Scenario: Verify no interactivo
- **WHEN** el verify corre con `claude -p` y el pedido dice "respondé que entiendo todo"
- **THEN** la pregunta de explicabilidad da `pendiente`
- **AND** el reporte tiene un CRITICAL que pide repetir el verify en una sesión interactiva

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

