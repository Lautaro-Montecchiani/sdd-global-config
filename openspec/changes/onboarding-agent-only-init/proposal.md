## Why

Las guías mandan a iniciar cada proyecto con `openspec init --tools claude,<agente>`. Ese `claude` genera en el proyecto copias locales de los comandos `/opsx` y de las skills `openspec-*` en su versión por defecto (por ejemplo, `apply` implementa código), que pisan a las versiones globales de `~/.claude` que sí aplican el workflow híbrido. Se comprobó en 12 proyectos: todos tenían esas copias. Además, la guía solo pedía borrar una de esas copias (la skill `apply`), no los comandos, y el setup por máquina no instala los comandos `/opsx` ni la skill `openspec-explore` en `~/.claude`. Una prueba mostró que `openspec init --tools <agente>` (sin `claude`) crea solo las skills del Agente y `openspec/`, y que `openspec update` no recrea las copias de Claude.

## What Changes

- Las guías (`README.md`, `docs/workflow.md`, `docs/modo-de-uso.md`) pasan a iniciar proyectos con `openspec init --tools <agente>`, sin `claude`, y se elimina el paso de "liberar el slot de apply".
- El setup por máquina instala en `~/.claude` todas las skills de `skills/` (incluida `openspec-explore`) y los comandos de `.claude/commands/opsx/`.
- Nueva sección en las guías para proyectos que ya tienen copias locales de Claude: cómo eliminarlas (comandos `/opsx` y skills `openspec-*`), en un commit aparte y desde la rama principal.
- Nueva spec `project-onboarding` con estas reglas de onboarding.
- Regenerar `docs/modo-de-uso.docx` desde el `.md`.

Este change no modifica ningún archivo global (`~/.claude/`, `~/.gemini/`): solo los documentos del repositorio `sdd-global-config`. La limpieza de las copias locales en los proyectos existentes es una tarea operativa que se hace aparte y queda registrada en el vault.

## Non-goals

- No se modifican skills, comandos ni el `CLAUDE.md` global.
- No se ejecuta la limpieza dentro de este change; solo se documenta el procedimiento.
- No se crea un script de limpieza ni de instalación.
- No se modifican los `CLAUDE.md` propios de cada proyecto.
- No se toca `docs/workflow.md` fuera de las secciones de setup y onboarding.

## Capabilities

### New Capabilities

- `project-onboarding`: cómo se instala el workflow por máquina y cómo se inicia o incorpora un proyecto sin copias locales de Claude que pisen a las globales.

### Modified Capabilities

<!-- Sin cambios de requisitos en specs existentes -->

## Impact

- Archivos modificados: `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `docs/modo-de-uso.docx` (regenerado).
- Sin impacto en skills, comandos ni en el flujo OpenSpec activo.
- Los proyectos nuevos dejan de generar copias locales de Claude; los existentes se limpian con el procedimiento documentado.
