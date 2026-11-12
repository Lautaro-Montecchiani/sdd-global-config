# change-archive Specification

## Purpose
Define cuándo y en qué fases se archiva un change SDD: las specs, el archive y el SRS se commitean en la rama del change antes del merge, y el cierre en el vault de Obsidian se escribe después del merge.

## Requirements

### Requirement: Archive en la rama antes del merge
Con el change sin archivar y el verify aprobado, `/opsx:archive <nombre>` SHALL trabajar en `change/<nombre>`: sincronizar specs, mover el change a `openspec/changes/archive/`, completar el `## Purpose`, commitear `chore: archive <nombre>` con `Spec-ID: <nombre>` y ofrecer el SRS. Pushea la rama solo si el usuario confirma. Del vault solo SHALL actualizar `## Estado actual` de `context.md`.

#### Scenario: Archive en la rama del change
- **WHEN** en la rama `change/saludo` con el PR abierto y el verify aprobado se corre `/opsx:archive saludo`
- **THEN** `openspec/specs/` de la rama tiene los requirements del change y existe `openspec/changes/archive/AAAA-MM-DD-saludo/`
- **AND** la rama tiene un commit `chore: archive saludo` con el trailer `Spec-ID: saludo`
- **AND** el vault no tiene `archive/AAAA-MM-DD-saludo.md` y `## Estado actual` de `context.md` dice que `saludo` está archivado en la rama, pendiente de merge
- **AND** el resumen pide mergear el PR y volver a correr `/opsx:archive saludo` para cerrar en el vault

#### Scenario: Fuera de la rama del change
- **WHEN** se corre `/opsx:archive saludo` con el change sin archivar y la rama actual no es `change/saludo`
- **THEN** Claude frena, dice en qué rama hay que estar y no mueve ni commitea nada

#### Scenario: Carpeta de archive ya existente
- **WHEN** se corre `/opsx:archive saludo` en `change/saludo` y ya existe `openspec/changes/archive/AAAA-MM-DD-saludo/` con la fecha del día
- **THEN** Claude frena antes de sincronizar o mover nada, dice qué carpeta existe y sugiere renombrarla o esperar otra fecha

#### Scenario: Verify sin aprobar
- **WHEN** se corre `/opsx:archive saludo` en `change/saludo` y `context.md` del vault no registra el verify aprobado de `saludo`
- **THEN** Claude pregunta si el verify está aprobado sin CRITICAL
- **AND** si el usuario no lo confirma, frena sin mover ni commitear nada

### Requirement: Change mergeado sin archivar
Si el PR del change ya está mergeado y el change sigue sin archivar (flujo anterior), `/opsx:archive <nombre>` SHALL crear la rama `change/<nombre>-archive` desde la rama principal, hacer ahí la fase de la rama y pedir abrir el PR con `/branch-pr`. NO SHALL commitear en la rama principal.

#### Scenario: Change del flujo anterior
- **WHEN** el PR de `change/saludo` está mergeado, `openspec/changes/saludo/` sigue en la rama principal y se corre `/opsx:archive saludo`
- **THEN** Claude actualiza la rama principal con `git pull --ff-only` antes de crear la rama, y la fase de la rama no frena por estar en `change/saludo-archive`
- **AND** existe la rama `change/saludo-archive` con el commit `chore: archive saludo`
- **AND** la rama principal no tiene commits nuevos
- **AND** el resumen pide abrir el PR con `/branch-pr` y, después del merge, volver a correr `/opsx:archive saludo`

### Requirement: Cierre en el vault después del merge
Con el change ya archivado en la rama principal y su PR mergeado, `/opsx:archive <nombre>` SHALL escribir las notas del vault: nota de archive, estado de la nota de decisions, `context.md`, `_index.md` y `arquitectura.md`. Después SHALL commitear y pushear el vault. NO SHALL crear commits en el repo del proyecto. Si el PR no está mergeado, SHALL frenar sin escribir en el vault.

#### Scenario: Cierre después del merge
- **WHEN** el PR de `change/saludo` está mergeado con `openspec/changes/archive/AAAA-MM-DD-saludo/` y se corre `/opsx:archive saludo`
- **THEN** existe `archive/AAAA-MM-DD-saludo.md` en el vault y `_index.md` tiene su link
- **AND** la nota `decisions/*-saludo.md` dice `status: archivado`
- **AND** el vault tiene un commit `chore: <proyecto> — archive saludo`
- **AND** el repo del proyecto no tiene commits nuevos

#### Scenario: PR sin mergear
- **WHEN** `saludo` ya está archivado en `change/saludo`, el PR sigue abierto y se corre `/opsx:archive saludo`
- **THEN** Claude frena, dice que falta el merge y no escribe nada en el vault

#### Scenario: Dato inválido: config sin calidad ni nivel
- **WHEN** se cierra en el vault un change de un proyecto cuyo `openspec/config.yaml` no declara `## Calidad` ni `nivel` en `## Arquitectura`
- **THEN** `arquitectura.md` del vault dice "sin declarar" en `## Atributos de calidad` y "sin evaluar" en `## Nivel`
- **AND** el cierre termina sin error

### Requirement: Orden documentado en reglas y guías
El `CLAUDE.md` global SHALL decir que el archive de specs se hace en la rama del change antes del merge y el cierre en el vault después del merge. `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` SHALL mostrar el orden verify → archive en la rama → merge → cierre en el vault. El verify aprobado SHALL indicar `/opsx:archive` en la rama como próximo paso. El checklist del PR de `branch-pr` SHALL incluir el archive en la rama.

#### Scenario: Reglas de Git
- **WHEN** se lee la sección "Pull Requests" del `.claude/CLAUDE.md`
- **THEN** dice que el archive de specs se hace en la rama del change antes del merge y el cierre en el vault después del merge
- **AND** ya no dice "El archive se ejecuta después del merge, nunca antes"

#### Scenario: Guías, verify y checklist del PR
- **WHEN** se leen `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md`, `skills/openspec-verify-change/SKILL.md` y `skills/branch-pr/SKILL.md`
- **THEN** las guías muestran el archive en la rama antes del merge y el cierre en el vault después
- **AND** el verify aprobado nombra `/opsx:archive <nombre>` en la rama `change/<nombre>` como próximo paso
- **AND** el checklist del PR para `change/` incluye "Archive hecho en la rama (specs sincronizadas y SRS si corresponde)"
