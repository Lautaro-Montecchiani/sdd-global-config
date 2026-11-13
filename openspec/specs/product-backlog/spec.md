# product-backlog Specification

## Purpose
Define a los issues de GitHub como fuente única de lo pendiente de cada proyecto, con prioridad y tipo, su traza desde el proposal hasta el PR que los cierra y el SRS, y la vista generada `docs/backlog.md` que convive con el SRS.

## Requirements

### Requirement: Issue de entrada con prioridad y tipo
`issue-creation` SHALL pedir la prioridad (`prioridad:alta`, `prioridad:media` o `prioridad:baja`) y el tipo (`tipo:feature`, `tipo:deuda` o `tipo:bug`) del issue, SHALL crear en el repo las etiquetas del catálogo que falten y SHALL crear el issue con `status:needs-review` más esas dos etiquetas. Si la cuenta activa de `gh` no tiene permiso en el repo, SHALL frenar y decir qué cuenta activar.

#### Scenario: Issue con prioridad y tipo
- **WHEN** se lee `skills/issue-creation/SKILL.md`
- **THEN** pide prioridad y tipo, tiene el catálogo de 9 etiquetas con su color y crea el issue con `status:needs-review`, la prioridad y el tipo

#### Scenario: Cuenta sin permiso
- **WHEN** se lee `skills/issue-creation/SKILL.md`
- **THEN** dice que, si `gh` falla por permisos, frena y le pide al usuario activar la cuenta dueña del repo con `gh auth switch`

### Requirement: Issue en el proposal
`openspec-propose` y `/opsx:propose` SHALL controlar con `gh` el issue del change antes de crearlo y SHALL escribir `Issue: #NN` como primera línea de `proposal.md`. SHALL frenar si el issue no existe o está cerrado. Si el issue no tiene `status:approved`, SHALL preguntarle al usuario y, si confirma, agregar la etiqueta. Sin `gh`, sin red o sin permiso, SHALL avisar, escribir `Issue: pendiente` y seguir.

#### Scenario: Issue abierto y aprobado
- **WHEN** se lee el paso del issue en `skills/openspec-propose/SKILL.md` y en `.claude/commands/opsx/propose.md`
- **THEN** los dos piden el issue, lo controlan con `gh issue view` y escriben `Issue: #NN` como primera línea del proposal

#### Scenario: Dato inválido: issue cerrado o inexistente
- **WHEN** el issue indicado está cerrado o no existe
- **THEN** el propose frena sin crear el change y sugiere `/issue-creation`

#### Scenario: Sin gh o sin permiso
- **WHEN** `gh` no está, no hay red o la cuenta no tiene permiso
- **THEN** el propose avisa, escribe `Issue: pendiente` y sigue

### Requirement: Cierre del issue con el PR
`branch-pr` SHALL agregar `Closes #NN` al cuerpo del PR cuando el `proposal.md` del change, o el documento ODD, tiene `Issue: #NN`. Con `Issue: pendiente` o sin línea `Issue:`, SHALL abrir el PR sin `Closes` y decirlo en el resumen.

#### Scenario: PR que cierra el issue
- **WHEN** se lee el paso de creación del PR en `skills/branch-pr/SKILL.md`
- **THEN** agrega `Closes #NN` cuando el proposal o el documento ODD tiene `Issue: #NN`
- **AND** con `Issue: pendiente` o sin línea abre el PR sin `Closes` y lo dice en el resumen

### Requirement: Generación del backlog
`scripts/generar-backlog.ps1 -Proyecto <ruta>` SHALL escribir `docs/backlog.md` en el proyecto con los issues abiertos de su repo, agrupados por prioridad (alta, media, baja y sin prioridad) y ordenados por número, con su tipo y la marca `(bloqueado)` si corresponde. NO SHALL copiar el cuerpo de los issues. Si no puede leer los issues, NO SHALL tocar `docs/backlog.md` y SHALL terminar con 1. Con `-Entrada <archivo.json>` SHALL leer los issues de ese archivo en lugar de `gh`.

#### Scenario: Issues agrupados por prioridad
- **WHEN** se genera el backlog con issues de prioridad alta, media y baja
- **THEN** `docs/backlog.md` tiene una sección por prioridad, en ese orden, con una tabla de issues ordenada por número
- **AND** termina con el total de issues abiertos

#### Scenario: Tipo y bloqueado
- **WHEN** un issue tiene `tipo:deuda` y `bloqueado`
- **THEN** su fila muestra `deuda` como tipo y el título termina en `(bloqueado)`

#### Scenario: Issues sin prioridad y secciones vacías
- **WHEN** un issue no tiene etiqueta de prioridad y no hay issues de prioridad baja
- **THEN** el issue aparece en `## Sin prioridad` y la sección de prioridad baja dice `Ninguno.`

#### Scenario: Dato inválido: título con barra o salto de línea, o issue incompleto
- **WHEN** un issue tiene `|` o un salto de línea en el título, y otro no tiene número o título
- **THEN** la barra se escapa, el salto pasa a espacio y el issue incompleto se descarta
- **AND** la consola informa cuántos issues se descartaron

#### Scenario: No se pueden leer los issues
- **WHEN** `gh` falla (sin red, sin permiso o carpeta sin repo de GitHub)
- **THEN** el script termina con 1, no crea ni modifica `docs/backlog.md` y el mensaje no tiene rutas absolutas

#### Scenario: Archivo generado
- **WHEN** se genera `docs/backlog.md`
- **THEN** está en UTF-8 sin BOM, su primera línea es el comentario de archivo generado y no contiene rutas absolutas

### Requirement: Backlog en el archive
`openspec-archive-change` y `/opsx:archive` SHALL, en la fase de la rama y después del SRS, regenerar `docs/backlog.md` con `scripts/generar-backlog.ps1` desde `$env:SDD_CONFIG_REPO` si el archivo existe, o preguntarle al usuario si generarlo si no existe. SHALL commitear el archivo en la rama del change. Si el script falla, SHALL avisar y seguir con el archive.

#### Scenario: Backlog regenerado en el archive
- **WHEN** se lee la fase de la rama en `skills/openspec-archive-change/SKILL.md` y en `.claude/commands/opsx/archive.md`
- **THEN** los dos tienen el paso del backlog después del SRS, con el commit `docs: regenerar backlog` y el aviso si el script falla

### Requirement: Issue de origen en el SRS
`srs-generate` SHALL anotar en cada requirement nuevo el issue del change que lo agregó, tomado de la línea `Issue: #NN` del `proposal.md` del change archivado, como atributo "Issue" en `docs/srs.md` y en el mapa `issues:` de `docs/srs.meta.yaml`. Si el change no tiene issue, SHALL omitir el atributo.

#### Scenario: Requirement con issue
- **WHEN** se lee `skills/srs-generate/SKILL.md`
- **THEN** describe el atributo "Issue" de los requirements y el mapa `issues:` de `docs/srs.meta.yaml`, y que se omite si el change no tiene issue

### Requirement: Hoja de ruta con número de issue
El formato de las líneas de `## Hoja de ruta` de `docs/arquitectura/vision.md`, en `.claude/CLAUDE.md` y en la guía de visión de `openspec-propose`, SHALL admitir un final opcional `— issue: #NN`.

#### Scenario: Formato con issue
- **WHEN** se busca el formato de la hoja de ruta en `.claude/CLAUDE.md` y en `skills/openspec-propose/SKILL.md`
- **THEN** los dos incluyen el final opcional `— issue: #NN`

### Requirement: Issue opcional en el ODD
`odd-change` y `/odd` SHALL permitir la línea `Issue: #NN` al principio del documento ODD cuando el pedido tiene un issue, y NO SHALL exigirla.

#### Scenario: ODD con o sin issue
- **WHEN** se lee la redacción del documento ODD en `skills/odd-change/SKILL.md` y en `.claude/commands/odd.md`
- **THEN** los dos dicen que el documento lleva `Issue: #NN` solo si el pedido tiene un issue
