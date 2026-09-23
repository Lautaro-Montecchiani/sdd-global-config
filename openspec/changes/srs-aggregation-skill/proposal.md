## Why

Hoy no existe ninguna skill del workflow que produzca un SRS (Software Requirements Specification). La referencia que se usó para este change (un documento con la estructura ISO/IEC/IEEE 29148) es del tipo de artefacto que alguien redacta y mantiene a mano, separado de `openspec/specs/`, que es la fuente de verdad viva del workflow SDD Híbrido. Un SRS mantenido a mano se desincroniza apenas hay un change nuevo, y hoy tampoco hay forma de generar uno para proyectos que ya están terminados o que no tienen historial de OpenSpec.

## What Changes

- Nueva skill `srs-generate` (`skills/srs-generate/`, instalada globalmente igual que las demás) que ensambla/regenera `docs/srs.md` por proyecto, con la estructura ISO/IEC/IEEE 29148 (Introduction/Scope, Stakeholder Requirements, System/Functional Requirements, Non-Functional Requirements), a partir de `openspec/specs/**/*.md` vigentes y del historial de `proposal.md`/`design.md` de los changes archivados de ese proyecto.
- Modo bootstrap: si el proyecto no tiene specs de OpenSpec (o están incompletas), la skill hace una primera pasada leyendo código, README y configuración existente para completar el SRS inicial, marcando cada sección como "inferida del código" o "basada en spec".
- Regeneración segura: si ya existe `docs/srs.md`, la skill muestra un resumen de los cambios antes de sobrescribir y pide confirmación, para no pisar ediciones manuales sin avisar.
- Enganche opcional en `/opsx:archive`: si el proyecto ya tiene `docs/srs.md`, al final del archive se ofrece regenerarlo (opt-in, no bloqueante; no aparece si el proyecto nunca lo generó).
- Trazabilidad: cada requirement del SRS generado indica de qué capability/spec sale.

## Capabilities

### New Capabilities
- `srs-generation`: skill que genera y mantiene actualizado el SRS de un proyecto por agregación de las specs vigentes de OpenSpec, con modo bootstrap para proyectos sin historial y enganche opcional al archive.

### Modified Capabilities
(sin capacidades existentes modificadas — el comportamiento de `openspec-archive-change` no está capturado hoy como spec propia; el ajuste queda descrito como parte de `srs-generation`)

## Impact

- Archivo nuevo: `skills/srs-generate/SKILL.md` — la skill en sí.
- Archivo nuevo: `openspec/specs/srs-generation/spec.md` — spec de la nueva capability.
- Modificado: `skills/openspec-archive-change/SKILL.md` — agrega el paso opcional de ofrecer regenerar el SRS al final del archive.
- Modificados: `README.md` y `docs/workflow.md` — suman `srs-generate` a la lista de skills instaladas por el setup de máquina.
- Cada proyecto que invoque la skill gana un `docs/srs.md` nuevo; `openspec/specs/` de ese proyecto no se toca ni deja de ser la fuente de verdad.
- Proyectos que no invoquen la skill quedan exactamente igual.

## Non-goals

- No reemplaza `openspec/specs/` como fuente de verdad — el SRS es una vista derivada, de solo lectura para humanos/stakeholders.
- No gestiona el workflow de aprobación/firma formal de un SRS.
- No migra el contenido del documento de ejemplo del usuario — solo toma su estructura de secciones (ISO/IEC/IEEE 29148) como plantilla de referencia.
- No corrige ni reinterpreta specs archivadas: las lee tal cual están.
- No fuerza la adopción en proyectos existentes — es opt-in, proyecto por proyecto.
