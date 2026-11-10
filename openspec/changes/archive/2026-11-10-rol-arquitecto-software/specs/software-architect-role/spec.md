# Spec Delta

## Purpose
Define el rol de arquitecto de software de Claude, que se suma al rol de arquitecto del workflow sin cambiar sus reglas: los ADRs del proyecto, la visión con hoja de ruta de deuda técnica, la revisión de impacto en el `design.md`, los atributos de calidad en el propose, el resumen de arquitectura en el vault y los controles del verify.

## ADDED Requirements

### Requirement: Rol de arquitecto de software en las reglas globales
El `CLAUDE.md` global SHALL tener una sección `## Rol de arquitecto de software` que defina cuatro responsabilidades de Claude: ADRs del proyecto, atributos de calidad, visión con hoja de ruta, y revisión de impacto. La sección SHALL decir que el rol se suma a las reglas vigentes sin cambiarlas, que Claude no escribe código ni archivos del proyecto (los documentos de arquitectura del repo los escribe el Agente desde el `design.md`) y que toda decisión de arquitectura se propone con alternativas y la aprueba el usuario. La tabla de roles SHALL nombrar a Claude como arquitecto de software.

#### Scenario: Sección presente
- **WHEN** se lee el `CLAUDE.md` global
- **THEN** existe `## Rol de arquitecto de software` con las cuatro responsabilidades
- **AND** dice que las reglas vigentes no cambian y que el Agente escribe los documentos de arquitectura del repo

#### Scenario: Reglas vigentes intactas
- **WHEN** se compara el `CLAUDE.md` global antes y después del change
- **THEN** ninguna línea de las reglas globales 1 a 10, de las reglas de ejecución del Agente ni de la puerta de integración se borró ni cambió de sentido

### Requirement: Revisión de impacto en el design
`/opsx:propose` SHALL incluir en todo `design.md` nuevo una sección `## Impacto en el sistema`, antes de `## Ubicación de archivos`, con cuatro partes en negrita: **Componentes afectados** (módulos, integraciones, datos u otros proyectos fuera de los archivos del change, o "ninguno fuera del change"), **Atributos de calidad**, **Decisiones de arquitectura** (ADR nuevo, ADR que se reemplaza o "ninguna") y **Deuda técnica** (la que el change agrega, paga o descubre, o "ninguna").

#### Scenario: Change que toca una integración
- **WHEN** se propone un change que modifica el módulo que llama a una API externa usada por otros dos módulos
- **THEN** `## Impacto en el sistema` nombra los otros dos módulos en **Componentes afectados**

#### Scenario: Change chico sin impacto
- **WHEN** se propone un change que corrige un texto en un solo archivo
- **THEN** `## Impacto en el sistema` existe y sus cuatro partes dicen "ninguno" o "ninguna"

### Requirement: ADR para decisiones que duran más que un change
Cuando un change toma una decisión que dura más que él (elegir o cambiar una tecnología de `## Stack`, cambiar el `nivel` de `## Arquitectura`, sumar o cambiar una integración externa, adoptar un patrón transversal, o resolver un compromiso entre dos atributos de calidad), `/opsx:propose` SHALL incluir en el `design.md` una sección `## ADR` con el texto completo del ADR y SHALL agregar en `tasks.md` una tarea para que el Agente lo guarde en `docs/adr/NNNN-<slug>.md`, con `NNNN` el número siguiente al mayor existente (o `0001`). El ADR SHALL tener título `# NNNN. <título>`, las líneas `Estado: aceptada`, `Fecha: AAAA-MM-DD` y `Change: <nombre>`, y las secciones `## Contexto`, `## Alternativas`, `## Decisión` y `## Consecuencias`. Si reemplaza a un ADR anterior, SHALL decir `Reemplaza a: NNNN` y la tarea SHALL cambiar el estado del anterior a `reemplazada por NNNN`. Claude NO SHALL escribir el archivo del ADR.

#### Scenario: Cambio de base de datos
- **WHEN** se propone un change que reemplaza SQLite por PostgreSQL en `## Stack` y el proyecto tiene `docs/adr/0001-*.md` y `docs/adr/0002-*.md`
- **THEN** el `design.md` tiene `## ADR` con `# 0003. ...`, `Estado: aceptada` y las cuatro secciones
- **AND** `tasks.md` tiene una tarea para que el Agente cree `docs/adr/0003-<slug>.md`

#### Scenario: Recomendación de arquitectura aplicada
- **WHEN** el usuario elige "Aplicar en este change" en una `## Recomendación de arquitectura` que sube el `nivel`
- **THEN** el `design.md` también tiene `## ADR` con esa decisión

#### Scenario: Decisión local
- **WHEN** el change solo decide el nombre de una función interna
- **THEN** el `design.md` no tiene `## ADR` y **Decisiones de arquitectura** dice "ninguna"

### Requirement: Atributos de calidad en el propose
Si `## Calidad` declara atributos con prioridad `alta`, `/opsx:propose` SHALL escribir en **Atributos de calidad** de `## Impacto en el sistema` una línea por cada uno: cómo lo afecta el change ("sin efecto" es válido) y, si lo afecta, `— Verificación: <cómo>` con `Sxx`, `revisión del diff: <qué se busca>` o `manual: <pasos>`. Si el proyecto no declara `## Calidad`, la parte SHALL decir "sin `## Calidad` declarada" y el resumen final SHALL sugerir `/ficha`, sin preguntar ni bloquear.

#### Scenario: Atributo de prioridad alta afectado
- **WHEN** `## Calidad` declara `- rendimiento: respuesta de la API < 500 ms p95 | alta` y el change agrega una consulta a la base en un endpoint
- **THEN** **Atributos de calidad** tiene una línea de rendimiento con `— Verificación:`

#### Scenario: Proyecto sin calidad declarada
- **WHEN** se propone un change en un proyecto sin `## Calidad`
- **THEN** **Atributos de calidad** dice "sin `## Calidad` declarada"
- **AND** el resumen final sugiere `/ficha`

### Requirement: Visión y hoja de ruta del proyecto
Cada proyecto SHALL tener un documento vivo `docs/arquitectura/vision.md` con las secciones `## Propósito`, `## Contexto e integraciones`, `## Componentes`, `## Decisiones vigentes` (lista de ADRs aceptados con su link) y `## Hoja de ruta` (deuda técnica con el formato `- [alta|media|baja] <deuda> — origen: <change o ADR> — propuesta: <cómo pagarla>`). No SHALL copiar la ficha: el propósito y los atributos de calidad se referencian a `openspec/config.yaml`. Si el documento no existe, `/opsx:propose` SHALL incluir en el `design.md` su contenido inicial (inferido del repo y la ficha) y una tarea para que el Agente lo cree. Si `## Impacto en el sistema` nombra un ADR nuevo, componentes nuevos o deuda que se agrega o se paga, SHALL agregar una tarea para que el Agente lo actualice con lo que dice el `design.md`. Claude NO SHALL escribir el archivo.

#### Scenario: Proyecto sin visión
- **WHEN** se propone el primer change de un proyecto sin `docs/arquitectura/vision.md`
- **THEN** el `design.md` trae el contenido inicial de la visión
- **AND** `tasks.md` tiene una tarea para que el Agente cree el archivo

#### Scenario: Change que paga deuda
- **WHEN** **Deuda técnica** dice que el change paga una deuda de la hoja de ruta
- **THEN** `tasks.md` tiene una tarea para quitarla de `## Hoja de ruta` en `docs/arquitectura/vision.md`

### Requirement: Resumen de arquitectura en el vault
`/opsx:archive` SHALL reescribir `$vault\projects\<proyecto>\arquitectura.md` con frontmatter (`project`, `updated`) y las secciones `## Nivel` (el `nivel` de `## Arquitectura` o "sin evaluar"), `## Atributos de calidad` (los de `## Calidad` o "sin declarar"), `## Decisiones vigentes` (número y título de cada ADR aceptado) y `## Deuda prioritaria` (hasta 3 ítems de `## Hoja de ruta`, de mayor prioridad), más el link al documento del repo. Lo SHALL incluir en el commit del vault del archive. El inicio de sesión y `/opsx:explore` SHALL leerlo si existe. La nota NO SHALL copiar código ni valores sensibles. Si el vault no existe, se saltea y se avisa, como el resto de las operaciones del vault.

#### Scenario: Archive con ADR nuevo
- **WHEN** se archiva un change que creó `docs/adr/0003-postgresql.md`
- **THEN** `arquitectura.md` del vault lista `0003` en `## Decisiones vigentes`
- **AND** el commit del vault del archive lo incluye

#### Scenario: Inicio de sesión
- **WHEN** se abre una sesión nueva en un proyecto con `arquitectura.md` en el vault
- **THEN** Claude lo lee junto con `context.md`

### Requirement: El verify controla la arquitectura de software
`/opsx:verify` SHALL agregar al reporte una tabla "Arquitectura de software" con: **Impacto en el sistema** (SUGGESTION si el `design.md` no tiene la sección); **Atributos de calidad** (aplica cada `— Verificación:` de esa parte; WARNING por cada una que no se cumple y WARNING "atributo sin verificación declarada" por cada atributo afectado sin ella); **ADR** (si el `design.md` tiene `## ADR`, WARNING si el diff no tiene el archivo en `docs/adr/` o si su título y su `## Decisión` no coinciden con el `design.md`); y **Visión** (WARNING si el `design.md` pide crear o actualizar `docs/arquitectura/vision.md` y el diff no lo toca). Estos controles NO SHALL dar CRITICAL ni cambiar la puerta de integración.

#### Scenario: ADR que no llegó al repo
- **WHEN** el `design.md` tiene `## ADR` y el diff no agrega ningún archivo en `docs/adr/`
- **THEN** el reporte tiene un WARNING de ADR
- **AND** la evaluación final no cambia por este control a "no listo para archive"

#### Scenario: Atributo de calidad que no se cumple
- **WHEN** la verificación declarada para rendimiento falla
- **THEN** el reporte tiene un WARNING de rendimiento con el motivo en una línea

#### Scenario: Design anterior al change
- **WHEN** se verifica un change cuyo `design.md` no tiene `## Impacto en el sistema`
- **THEN** el reporte tiene una SUGGESTION y ningún WARNING por esa falta
