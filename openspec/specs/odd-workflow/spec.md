# odd-workflow Specification

## Purpose
Flujo ODD para cambios chicos: documento único `docs/odd/<nombre>.md`, cambio mínimo de spec cuando se modifican requirements de una sola capability, comandos `/odd`, `/odd:verify` y `/odd:close`, verify liviano con la puerta de integración y cierre en el vault de Obsidian.

## Requirements

### Requirement: Documento ODD único y aprobado
`/odd <nombre>` SHALL crear un único documento `docs/odd/<nombre>.md` en el proyecto, con frontmatter (`tipo: odd`, `nombre`, `creado`, `estado`, `branch`) y las secciones Objetivo, Problema, Alcance (con "Archivos permitidos"), Clasificación, Checklist, Criterios de aceptación (cada uno con su evidencia esperada), Evidencia, Progreso y Próximo paso. Claude SHALL pedir aprobación al usuario antes de crear el branch `odd/<nombre>` y anunciar el handoff. Un ODD NO SHALL tener `design.md` ni `tasks.md`. Si el pedido modifica requirements existentes de una sola capability, Claude SHALL escribir además un change mínimo `openspec/changes/odd-<nombre>/` con un `proposal.md` corto y un delta con solo `## MODIFIED Requirements`, SHALL validarlo con `openspec validate odd-<nombre> --strict` antes de pedir aprobación, y el checklist SHALL incluir ajustar el test de ese requirement. Si el proyecto tiene `docs/arquitectura/vision.md` y el ODD paga una deuda de su `## Hoja de ruta`, el `## Checklist` SHALL incluir la tarea de quitarla y "Archivos permitidos" SHALL incluir `docs/arquitectura/vision.md`.

#### Scenario: Inicio de un ODD
- **WHEN** el usuario corre `/odd typo-bienvenida` en una sesión interactiva
- **THEN** existe `docs/odd/typo-bienvenida.md` con todas las secciones
- **AND** Claude pide aprobación antes de crear `odd/typo-bienvenida`
- **AND** después de aprobar, anuncia el handoff al Agente

#### Scenario: ODD que paga deuda de la visión
- **WHEN** el usuario corre `/odd renombrar-variables` para una deuda listada en `## Hoja de ruta` de `docs/arquitectura/vision.md`
- **THEN** el `## Checklist` tiene la tarea de quitar esa deuda de la visión
- **AND** "Archivos permitidos" incluye `docs/arquitectura/vision.md`

#### Scenario: ODD que modifica una spec
- **WHEN** el usuario corre `/odd saludo-sin-coma` para que el saludo sea "Hola {nombre}" y la spec vigente dice "Hola, {nombre}"
- **THEN** existen `docs/odd/saludo-sin-coma.md` y `openspec/changes/odd-saludo-sin-coma/` con `proposal.md` y un delta con solo `## MODIFIED Requirements`
- **AND** `openspec validate odd-saludo-sin-coma --strict` pasa
- **AND** el checklist incluye ajustar el test del saludo

#### Scenario: Estado en el vault al iniciar
- **WHEN** se aprueba el documento de `typo-bienvenida`
- **THEN** `## Estado actual` de `context.md` dice "ODD activo: `typo-bienvenida`"
- **AND** el vault tiene un commit nuevo

### Requirement: El Agente deja la evidencia en el documento
En un handoff ODD, el Agente SHALL trabajar solo en el branch `odd/<nombre>` y en los archivos permitidos, SHALL marcar `[x]` solo con evidencia pegada en `## Evidencia`, SHALL commitear con el trailer `Spec-ID: odd-<nombre>` y SHALL dejar `estado: listo-para-verify`. NO SHALL escribir la nota `apply\` del vault.

#### Scenario: Implementación completa
- **WHEN** el Agente termina el ODD `typo-bienvenida`
- **THEN** todas las tareas tienen `[x]` con evidencia
- **AND** los commits tienen `Spec-ID: odd-typo-bienvenida`
- **AND** el documento dice `estado: listo-para-verify`

### Requirement: Verify liviano
`/odd:verify <nombre>` SHALL reportar CRITICAL si: alguna tarea no tiene `[x]` con evidencia; algún criterio de aceptación no tiene la evidencia esperada; el diff toca archivos fuera de "Archivos permitidos"; algún criterio SDD que `## Clasificación` no anota como pasado por alto se cumple sobre el diff real (CRITICAL "escalar a SDD"); el change mínimo `openspec/changes/odd-<nombre>/`, si existe, no pasa `openspec validate --strict`, tiene secciones distintas de `## MODIFIED Requirements` o más de una capability (CRITICAL "escalar a SDD" por K1), o el diff no toca el test del requirement modificado cuando el proyecto declara `comando` en `## Tests`; falla un test en el branch que no falla en la rama principal, si el proyecto declara `comando` en `## Tests`; o la seguridad o la explicabilidad de la puerta de integración dan `no` o `pendiente`. La pregunta del dato inesperado SHALL quedar `no aplica (ODD)`. El control de alcance y la explicabilidad NO SHALL incluir el propio documento ODD. SHALL reportar WARNING si el documento pide actualizar `docs/arquitectura/vision.md` y el diff no lo toca. Sin CRITICAL, SHALL dejar `estado: verificado` y, si existe el change mínimo, SHALL correr `openspec archive odd-<nombre> -y` en el branch y commitear la spec actualizada con `Spec-ID: odd-<nombre>`, para que el código, el test y la spec entren en el mismo merge. Después de ese archive, SHALL ofrecer el SRS como el archive de un change SDD (regenerarlo si `docs/srs.md` existe, generarlo si no) y, si el usuario acepta, SHALL commitearlo en el mismo branch con `docs: regenerar SRS` (o `docs: generar SRS`) y `Spec-ID: odd-<nombre>`. El control de alcance SHALL permitir los archivos de ese change, `openspec/changes/archive/`, la spec de la capability declarada, `docs/srs.md`, `docs/srs.meta.yaml` y `docs/diagramas/`.

#### Scenario: ODD aprobado
- **WHEN** se verifica `typo-bienvenida` con todo en orden y el usuario confirma que entiende el cambio
- **THEN** el reporte no tiene CRITICAL
- **AND** la puerta muestra seguridad `sí`, explicabilidad `sí` y dato inesperado `no aplica (ODD)`
- **AND** el documento dice `estado: verificado`

#### Scenario: ODD con cambio de spec aprobado
- **WHEN** se verifica `saludo-sin-coma` con el código y el test cambiados, todo en orden y la explicabilidad confirmada
- **THEN** el reporte no tiene CRITICAL
- **AND** `openspec/specs/mensajes/spec.md` del branch dice "Hola {nombre}" y existe `openspec/changes/archive/AAAA-MM-DD-odd-saludo-sin-coma/`

#### Scenario: ODD con cambio de spec y SRS
- **WHEN** se verifica `saludo-sin-coma` sin CRITICAL en un proyecto con `docs/srs.md` y el usuario elige "Regenerar ahora"
- **THEN** el branch `odd/saludo-sin-coma` tiene un commit `docs: regenerar SRS` con `Spec-ID: odd-saludo-sin-coma`
- **AND** el control de alcance no marca `docs/srs.md` como fuera de alcance

#### Scenario: Delta que agrega un requirement
- **WHEN** el change mínimo de un ODD tiene `## ADDED Requirements`
- **THEN** el reporte tiene CRITICAL "escalar a SDD" por K1 y no se archiva nada

#### Scenario: Criterio pasado por alto
- **WHEN** el documento anota que K7 se pasó por alto a pedido del usuario y el diff toca 8 archivos de código
- **THEN** el reporte no tiene CRITICAL de re-clasificación por K7

#### Scenario: El diff toca datos externos
- **WHEN** el diff de un ODD modifica el código que lee los campos del formulario declarado `(externo)`
- **THEN** el reporte tiene CRITICAL "escalar a SDD" por K2

#### Scenario: Fuera de alcance
- **WHEN** el diff de un ODD toca un archivo que no está en "Archivos permitidos"
- **THEN** el reporte tiene un CRITICAL de alcance con el nombre del archivo

#### Scenario: Visión sin actualizar
- **WHEN** el documento de un ODD pide quitar una deuda de `docs/arquitectura/vision.md` y el diff no toca ese archivo
- **THEN** el reporte tiene un WARNING de visión

### Requirement: Cierre en el vault de Obsidian
Después del merge, `/odd:close <nombre>` SHALL escribir una nota en `$vault\projects\<proyecto>\archive\AAAA-MM-DD-odd-<nombre>.md` con frontmatter `tipo: odd`, `change`, `proyecto`, `fecha`, `status: cerrado` y `pr`, y las secciones Objetivo, Qué cambió, Evidencia, Clasificación y Documento completo, más la línea `Spec:` con la capability modificada y la carpeta archivada (o "sin cambios de spec") y la línea `SRS:` que dice si el SRS se regeneró en el branch (o "sin cambios de spec"). NO SHALL recomendar `/srs-generate` después del merge. SHALL agregar el link en `_index.md`, reescribir `arquitectura.md` del vault solo si el diff del ODD tocó `docs/arquitectura/vision.md`, actualizar `context.md` (`## Estado actual` y `## Último change`), y commitear el vault con `chore: {proyecto} — odd-close {nombre}` y pushearlo. NO SHALL crear commits ni pushear en el repo del proyecto: el documento ODD queda con `estado: verificado` y el cierre queda registrado solo en la nota del vault. NO SHALL copiar código ni valores sensibles en la nota. NO SHALL usar otra capa de memoria que el vault.

#### Scenario: Cierre después del merge
- **WHEN** el branch `odd/typo-bienvenida` está mergeado y se corre `/odd:close typo-bienvenida`
- **THEN** existe `archive/AAAA-MM-DD-odd-typo-bienvenida.md` en el vault con `tipo: odd` y `status: cerrado`
- **AND** `_index.md` tiene el link a la nota
- **AND** `## Último change` de `context.md` dice "ODD `typo-bienvenida`" con la fecha
- **AND** el vault tiene un commit `chore: odd-prueba-p — odd-close typo-bienvenida` pusheado
- **AND** el repo del proyecto no tiene commits nuevos y el documento sigue con `estado: verificado`

#### Scenario: Cierre de un ODD con cambio de spec
- **WHEN** el branch `odd/saludo-sin-coma` mergeado archivó su change mínimo y regeneró el SRS, y se corre `/odd:close saludo-sin-coma`
- **THEN** la nota tiene la línea `SRS:` que dice que se regeneró en el branch
- **AND** el resumen final no recomienda `/srs-generate`

#### Scenario: Cierre de un ODD que tocó la visión
- **WHEN** el branch `odd/renombrar-variables` mergeado modificó `docs/arquitectura/vision.md` y se corre `/odd:close renombrar-variables`
- **THEN** `arquitectura.md` del vault se reescribe y ya no lista la deuda pagada

#### Scenario: Cierre sin merge
- **WHEN** se corre `/odd:close` sobre un branch `odd/*` que no está mergeado
- **THEN** Claude frena y lo dice
- **AND** no escribe nada en el vault

#### Scenario: El inicio de sesión lee la nota
- **WHEN** se abre una sesión nueva en el proyecto después de un `/odd:close`
- **THEN** Claude lee `context.md` y la nota ODD entre las últimas 3 de `archive\`

### Requirement: Branches odd en el PR
`pr-check.yml` SHALL aceptar branches que empiecen con `change/` o con `odd/`, y SHALL rechazar los demás. `branch-pr` SHALL aceptar `odd/{nombre}` y, en ese caso, controlar que exista `docs/odd/{nombre}.md` y que el trailer sea `Spec-ID: odd-{nombre}`.

#### Scenario: PR de un ODD
- **WHEN** se abre un PR desde `odd/typo-bienvenida` con título `[typo-bienvenida] Corregir typo del saludo` y `Spec-ID: odd-typo-bienvenida` en el body
- **THEN** los chequeos de branch, título y Spec-ID pasan

#### Scenario: Branch fuera de convención
- **WHEN** se abre un PR desde `feature/x`
- **THEN** el chequeo de branch falla y el mensaje nombra `change/{nombre}` y `odd/{nombre}`

### Requirement: Estado del archive del ODD en el vault y en el PR
Si `/odd:verify` archiva el change mínimo en el branch, SHALL dejar en `## Estado actual` de `context.md` "ODD `<nombre>` archivado en el branch, pendiente de merge"; sin cambio de spec, "ODD `<nombre>` verificado, pendiente de merge". Para un branch `odd/`, `branch-pr` SHALL sumar al checklist "Archive del change mínimo en el branch (si hay cambio de spec)" y pedir ese archive para el merge solo si hay cambio de spec.

#### Scenario: ODD con cambio de spec archivado
- **WHEN** `/odd:verify saludo-sin-coma` termina sin CRITICAL y archiva `openspec/changes/odd-saludo-sin-coma/` en el branch
- **THEN** `## Estado actual` de `context.md` dice "ODD `saludo-sin-coma` archivado en el branch, pendiente de merge"

#### Scenario: ODD sin cambio de spec
- **WHEN** `/odd:verify typo-bienvenida` termina sin CRITICAL y el ODD no tiene change mínimo
- **THEN** `## Estado actual` de `context.md` dice "ODD `typo-bienvenida` verificado, pendiente de merge"

#### Scenario: PR de un ODD
- **WHEN** `branch-pr` arma el PR de `odd/typo-bienvenida`
- **THEN** el checklist incluye "Archive del change mínimo en el branch (si hay cambio de spec)"
- **AND** el mensaje final dice que el merge espera el archive en el branch solo si hay cambio de spec

### Requirement: Handoff ODD con comando del Agente
Al aprobar un ODD, `/odd` SHALL anunciar el handoff con la línea "Ejecutá en el Agente: `/odd-apply <nombre>`". Si al implementar el Agente avisa "falta en el alcance", Claude SHALL ampliar "Archivos permitidos" del documento con el motivo en `## Progreso` y pedir que el Agente siga, sin escalar a SDD si no se cumple ningún criterio de K1 a K10.

#### Scenario: Handoff con el comando
- **WHEN** el usuario aprueba el documento de `typo-bienvenida`
- **THEN** el mensaje final de `/odd` dice "Ejecutá en el Agente: `/odd-apply typo-bienvenida`"

#### Scenario: Falta en el alcance
- **WHEN** el Agente avisa "falta en el alcance" porque necesita tocar `tests/saludo.Tests.ps1`, que no está en "Archivos permitidos"
- **THEN** Claude suma ese archivo a "Archivos permitidos", anota el motivo en `## Progreso` y pide al Agente que siga
- **AND** el documento no pasa a `estado: escalado`
