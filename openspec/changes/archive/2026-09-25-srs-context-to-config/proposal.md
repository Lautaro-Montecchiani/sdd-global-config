## Why

La skill `srs-generate` (change `srs-aggregation-skill`) persiste glosario, actores, procesos de negocio y objetivos de negocio en `docs/srs.meta.yaml`, que se pensó como contabilidad interna del SRS. Ese conocimiento es del proyecto, no del documento: hoy queda encerrado ahí, no se reusa en el resto del workflow (`/opsx:propose`, apply, verify), y reintroduce el problema de "segunda fuente de verdad" que motivó el enfoque de agregación del SRS (ver [issue #6](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/6)).

## What Changes

- El `context:` de `openspec/config.yaml` (texto libre ya inyectado en toda operación de OpenSpec) gana una convención de subsecciones fijas y opcionales: `## Glosario`, `## Actores y Procesos de Negocio`, `## Objetivos de Negocio`, appendeadas al final del texto existente sin tocar el resto.
- La skill `srs-generate` deja de escribir glosario/actores/procesos/objetivos en `docs/srs.meta.yaml`; los lee y escribe en esas subsecciones de `context:`.
- `docs/srs.meta.yaml` queda reducido a lo que ya no tiene otro lugar: IDs jerárquicos y atributos por requirement (prioridad, riesgo, dependencia, dificultad) — sin cambios ahí.
- Migración automática: si un proyecto ya generó un SRS con la versión anterior de `srs-generate` (glosario/actores/procesos/objetivos en `docs/srs.meta.yaml`), la skill los migra a `context:` en la próxima corrida y los quita de `srs.meta.yaml`.

## Capabilities

### New Capabilities
- `project-context-schema`: convención de subsecciones estructuradas (`## Glosario`, `## Actores y Procesos de Negocio`, `## Objetivos de Negocio`) dentro del campo `context:` de `openspec/config.yaml`, reusable por cualquier skill del workflow, no solo `srs-generate`.

### Modified Capabilities
- `srs-generation`: el requirement "Entrevista guiada para secciones sin fuente formal" cambia su lugar de persistencia para glosario/objetivos/actores/procesos, de `docs/srs.meta.yaml` a las subsecciones de `context:`.

## Impact

- `openspec/config.yaml` — solo de los proyectos que usen `srs-generate`; el resto no ve cambios hasta que la usen.
- `skills/srs-generate/SKILL.md` — implementación de la lectura/escritura en `context:` y la migración.
- `openspec/specs/project-context-schema/spec.md` — spec nueva.
- `openspec/specs/srs-generation/spec.md` — delta MODIFIED (requiere que `srs-aggregation-skill` esté mergeado y archivado primero; ver Non-goals).

## Non-goals

- No agrega claves YAML nuevas de primer nivel a `config.yaml`. El CLI de OpenSpec (`@fission-ai/openspec`) solo reconoce `schema`, `context` y `rules` como campos de primer nivel — cualquier otra clave se descarta en silencio al leer el archivo (verificado en `project-config.js` del propio paquete). Por eso todo el conocimiento estructurado va dentro del string de `context:`, no como claves sibling.
- No migra ni toca el `context:` de proyectos que no usan `srs-generate`.
- No resuelve el límite duro de 50KB de `context:` (impuesto por el CLI) con compresión ni paginado automático — la skill solo advierte si se acerca al límite.
- No incluye el export del SRS a `.docx` (item aparte, futuro, sin issue todavía).
- Este change no se aplica hasta que `openspec/specs/srs-generation/spec.md` exista en el repo — eso requiere que `srs-aggregation-skill` esté mergeado y archivado primero (ver `tasks.md`).
