## Why

Hoy no existe ninguna skill del workflow que produzca un SRS (Software Requirements Specification). La referencia que se usó para este change (un documento con la estructura ISO/IEC/IEEE 29148) es del tipo de artefacto que alguien redacta y mantiene a mano, separado de `openspec/specs/`, que es la fuente de verdad viva del workflow SDD Híbrido. Un SRS mantenido a mano se desincroniza apenas hay un change nuevo, y hoy tampoco hay forma de generar uno para proyectos que ya están terminados o que no tienen historial de OpenSpec.

## What Changes

- Nueva skill `srs-generate` (`skills/srs-generate/`, instalada globalmente igual que las demás) que ensambla/regenera `docs/srs.md` por proyecto.
- **Estructura fija**: `docs/srs.md` sigue siempre el mismo esqueleto de secciones y numeración del documento de referencia del usuario (Introducción; Información del Dominio del Problema; Necesidades de Negocio → Objetivos de Negocio, Actores y Procesos de Negocio, Casos de Uso, Requisitos Funcionales, Requisitos No Funcionales, Matriz de Trazabilidad). El contenido de cada subsección se adapta al proyecto destino — "Requisitos Funcionales" se agrupa por las capabilities reales de ese proyecto, no por los módulos del documento de ejemplo (Chef, Plato, etc., que son específicos de ese proyecto).
- **Requisitos Funcionales / No Funcionales**: por agregación de `openspec/specs/**/*.md` vigentes, igual que antes; cada Requisito No Funcional lleva además una prioridad (Deseable/Alta/Crítica/Media, como en el documento de referencia).
- **Casos de Uso y diagramas**: cada `#### Scenario:` de una spec se convierte en un Caso de Uso con un diagrama UML de caso de uso (PlantUML) y, cuando el escenario tiene varios pasos o más de un actor, un diagrama de flujo o de secuencia (Mermaid) — ambos derivados del `WHEN/THEN` de la spec de origen.
- **Matriz de Trazabilidad**: se arma automáticamente cruzando Casos de Uso y Requisitos Funcionales, sin trabajo manual adicional.
- **Entrevista guiada**: para las secciones que no salen de ninguna spec ni del código (Glosario de Términos, Objetivos de Negocio, Actores y Procesos de Negocio, prioridad de cada Requisito No Funcional), la skill hace una entrevista corta (4-5 preguntas) la primera vez y persiste las respuestas en `docs/srs.meta.yaml`. En regeneraciones siguientes solo pregunta por lo nuevo (por ejemplo, una capability agregada sin prioridad asignada), nunca repite lo ya respondido.
- **Modo bootstrap**: si el proyecto no tiene specs de OpenSpec (o están incompletas), la skill hace una primera pasada leyendo código, README y configuración existente para completar el SRS inicial, marcando cada sección como "inferida del código" o "basada en spec".
- **Regeneración segura**: si ya existe `docs/srs.md`, la skill muestra un resumen de los cambios antes de sobrescribir y pide confirmación, para no pisar ediciones manuales sin avisar.
- **Enganche opcional en `/opsx:archive`**: si el proyecto ya tiene `docs/srs.md`, al final del archive se ofrece regenerarlo (opt-in, no bloqueante; no aparece si el proyecto nunca lo generó).
- **Trazabilidad**: cada requirement del SRS generado indica de qué capability/spec sale (o que viene de la entrevista guiada).

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
- Cada proyecto que invoque la skill gana `docs/srs.md` y `docs/srs.meta.yaml` (respuestas persistidas de la entrevista guiada); `openspec/specs/` de ese proyecto no se toca ni deja de ser la fuente de verdad.
- Proyectos que no invoquen la skill quedan exactamente igual.

## Non-goals

- No reemplaza `openspec/specs/` como fuente de verdad — el SRS es una vista derivada, de solo lectura para humanos/stakeholders.
- No gestiona el workflow de aprobación/firma formal de un SRS.
- No copia el contenido específico del proyecto de ejemplo del usuario (Echalo Fideo: Chef, Plato, Reserva, etc.) — copia su esqueleto de secciones y numeración; el contenido de cada subsección sale siempre del proyecto destino o de la entrevista guiada.
- No genera diagramas UML de clases, arquitectura o base de datos — solo diagramas de caso de uso (PlantUML) y de flujo/secuencia (Mermaid), derivados de los escenarios de las specs.
- No corrige ni reinterpreta specs archivadas: las lee tal cual están.
- No fuerza la adopción en proyectos existentes — es opt-in, proyecto por proyecto.
