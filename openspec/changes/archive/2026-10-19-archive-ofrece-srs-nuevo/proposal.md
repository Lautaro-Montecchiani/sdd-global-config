## Why

Hoy el archive solo ofrece **regenerar** el SRS cuando el proyecto ya tiene `docs/srs.md`. En un proyecto sin SRS no dice nada, así que el SRS nunca se arranca salvo que alguien se acuerde de pedir `/srs-generate` a mano. Pasó en un proyecto real: se archivó un change y no hubo ningún aviso. El usuario esperaba que el archive se lo ofreciera.

Además, la skill (`skills/openspec-archive-change/SKILL.md`) y el comando (`.claude/commands/opsx/archive.md`) tienen el paso del SRS redactado distinto: el comando usa el AskUserQuestion y pide commit aparte; la skill pregunta "(sí/no)" en texto y no dice nada del commit.

## What Changes

- El archive ofrece el SRS **en todos los proyectos**, al final de cada archive:
  - **Sin `docs/srs.md`:** pregunta si se genera ahora, con "Generar ahora" y "Más tarde", y avisa que la primera generación incluye una entrevista corta.
  - **Con `docs/srs.md`:** como hoy, pregunta si se regenera, con "Regenerar ahora" y "Más tarde".
- No hay opción de dejar de ofrecerlo: la pregunta aparece en cada archive.
- El paso del SRS queda igual en la skill y en el comando.

Archivos globales que se modifican y por qué:
- `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: el paso 7 (oferta del SRS), el ejemplo de salida y el Guardrail.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `srs-generation`: el requirement "Enganche opcional en el archive" pasa a ofrecer también la primera generación del SRS en proyectos que no lo tienen.

## Non-goals

- No se genera el SRS sin preguntar, ni se bloquea el archive por esto.
- No se agrega una forma de desactivar la oferta por proyecto.
- No se cambia la skill `srs-generate` (la entrevista y el guard de escala siguen igual).
- No se agrega la oferta a otros comandos (propose, verify).

## Impact

- **Skills y comandos de Claude:** archive (2 archivos), reinstalados en `~/.claude`.
- **Specs:** `srs-generation` (~1 requirement).
- **Otros proyectos:** en el próximo archive de un proyecto sin SRS aparece la pregunta; contestar "Más tarde" no cambia nada.
