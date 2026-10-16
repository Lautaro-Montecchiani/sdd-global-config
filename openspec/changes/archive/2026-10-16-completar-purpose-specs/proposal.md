## Why

8 de las 9 specs vigentes de `openspec/specs/` tienen como `## Purpose` el texto que deja el CLI al archivar una capability nueva: "TBD - created by archiving change <nombre>. Update Purpose after archive." Nadie lo actualizó después, así que esas specs no dicen qué cubren, y el SRS generado el 16/10/2026 (`docs/srs.md`) queda en estado "borrador" con 8 propósitos pendientes. Además, el problema se repite en cada archive que crea una capability: pasó de nuevo con `test-driven-verification`.

## What Changes

- Reemplazar el `## Purpose` en TBD de las 8 specs por el texto definido en `design.md` (D1): `agent-cli-permissions`, `doc-folder-structure`, `docs-portable-paths`, `project-claude-md`, `project-onboarding`, `security-layer-matrix`, `srs-generation` y `test-driven-verification`. Solo cambia la sección `## Purpose`; los requirements y escenarios no se tocan.
- El archive (skill y comando) pasa a completar el `## Purpose` de cada capability nueva que cree el sync, a partir de la descripción de esa capability en el `proposal.md` del change, y lo muestra en el resumen. Las specs que ya tienen propósito no se tocan.
- Regenerar `docs/srs.md` después del cambio, para que deje de estar en borrador por los propósitos pendientes.

Archivos globales que se modifican y por qué:
- `openspec/specs/<capability>/spec.md` (8 archivos): completar el propósito.
- `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: evitar que vuelva a quedar un propósito en TBD después de un archive.

## Capabilities

### New Capabilities
- `spec-purpose`: toda spec vigente tiene un `## Purpose` redactado, y el archive lo completa al crear una capability nueva.

### Modified Capabilities
- (ninguna: el `## Purpose` no es un requirement, y los requirements de las 8 specs no cambian)

## Non-goals

- No se reescriben ni se reordenan requirements o escenarios de ninguna spec.
- No se cambia el CLI de OpenSpec: el texto "TBD" lo sigue escribiendo el CLI; el archive lo reemplaza después del sync.
- No se completan los propósitos de specs de otros proyectos (cada proyecto lo hace en su propio change, ya con el archive corregido).
- No se cambian la clasificación Funcional/No Funcional ni los IDs del SRS.

## Impact

- **Specs:** 8 archivos de `openspec/specs/`, solo la sección `## Purpose`.
- **Skills y comandos de Claude:** archive (2 archivos), reinstalados en `~/.claude`.
- **SRS:** `docs/srs.md` regenerado con `srs-generate`; los IDs de `docs/srs.meta.yaml` no cambian.
- **Otros proyectos:** a partir del próximo archive que cree una capability, el propósito queda completo.
