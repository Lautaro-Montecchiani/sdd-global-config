## Context

El paso 7 del archive ofrece regenerar el SRS solo cuando existe `docs/srs.md`; si no existe, no dice nada (decisión del 16/10/2026, requirement "Enganche opcional en el archive" de `srs-generation`). El usuario pidió que el archive ofrezca el SRS en todos los proyectos. La skill y el comando tienen además el paso redactado distinto (la skill no usa AskUserQuestion ni pide commit aparte).

## Goals / Non-Goals

**Goals:**
- Ofrecer el SRS al final de todo archive: generarlo si falta, regenerarlo si existe.
- Que la skill y el comando digan exactamente lo mismo en ese paso.

**Non-Goals:**
- Desactivar la oferta por proyecto.
- Cambiar `srs-generate`.

## Decisions

### D1. Texto del paso 7, igual en la skill y en el comando
Reemplazar el paso 7 de `skills/openspec-archive-change/SKILL.md` ("SRS Regeneration Offer") y de `.claude/commands/opsx/archive.md` ("Offer SRS regeneration") por este texto, exacto:

> 7. **Offer the SRS**
>
>    After the summary, always offer the SRS, in every project. Check whether `docs/srs.md` exists in the project root and use the **AskUserQuestion tool**:
>    - **If it exists:** ask "¿Regenerar el SRS ahora para incluir este change?" with the options "Regenerar ahora" and "Más tarde".
>    - **If it does not exist:** ask "Este proyecto todavía no tiene SRS. ¿Generarlo ahora? La primera vez incluye una entrevista corta." with the options "Generar ahora" and "Más tarde".
>    - In both cases, if there are still active changes (from `openspec list --json`), mention in the question that they will not be included until they are archived.
>    - **If the user accepts:** invoke the `srs-generate` skill with the Skill tool. Its output (`docs/srs.md`, `docs/srs.meta.yaml`, and the interview answers in the `context:` of `openspec/config.yaml` the first time) is NOT committed automatically: tell the user to commit it separately from the archive commit (`docs: generar SRS` or `docs: regenerar SRS`, with the `Spec-ID: <name>` trailer).
>    - **If the user declines:** remind them they can run `/srs-generate` later; the next archive will offer it again. Never block or undo the archive because of this step.

### D2. Ejemplo de salida y Guardrail
- En la skill, reemplazar la línea `(Optional SRS offer follows here if docs/srs.md exists)` del ejemplo "Output On Success" por `(SRS offer follows here: generate if docs/srs.md is missing, regenerate if it exists)`.
- En los dos archivos, reemplazar el Guardrail del SRS por: `- SRS offer: always, in every project — generate if docs/srs.md is missing, regenerate if it exists; it is optional and never blocks the archive`.

Alternativa descartada: una opción "No ofrecer en este proyecto" guardada en `config.yaml`. El usuario pidió que se ofrezca en todos los proyectos, sin excepciones.

## Risks / Trade-offs

- [La pregunta aparece en cada archive de proyectos que no quieren SRS] → Es un clic ("Más tarde") y no cambia nada; aceptado por decisión del usuario.
- [La primera generación es larga (entrevista + guard de escala)] → La pregunta lo avisa y "Más tarde" lo posterga.

## Impacto en proyectos existentes

- Proyectos con `docs/srs.md`: sin cambios en el comportamiento.
- Proyectos sin `docs/srs.md`: a partir del próximo archive aparece la oferta de generarlo. No se crea nada si no se acepta.

## Security Layer

Tipo `tooling`:
- Los archivos modificados son instrucciones para IA en Markdown: sin secrets ni rutas con el usuario local.
- El paso solo invoca `srs-generate` con aceptación explícita; esa skill ya excluye secrets y rutas absolutas en el bootstrap.
- Cambio a skills y comandos globales → commit separado con descripción del impacto.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown sin tests automáticos. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Enganche opcional en el archive / Archive en un proyecto que ya usa SRS | manual: requiere correr el archive. Pasos: en un repo descartable en `%TEMP%` con `docs/srs.md`, archivar un change chico y confirmar que la pregunta es la de regenerar, con "Regenerar ahora" y "Más tarde" | `skills/openspec-archive-change/SKILL.md`, `.claude/commands/opsx/archive.md` |
| S02 | Enganche opcional en el archive / Archive en un proyecto sin SRS | manual: requiere correr el archive. Pasos: en un repo descartable sin `docs/srs.md`, archivar un change chico y confirmar que la pregunta es la de generar, con "Generar ahora" y "Más tarde" y el aviso de la entrevista | `skills/openspec-archive-change/SKILL.md`, `.claude/commands/opsx/archive.md` |
| S03 | Enganche opcional en el archive / Usuario que posterga la generación | manual: requiere correr el archive dos veces. Pasos: en el repo de S02 contestar "Más tarde", confirmar que no aparecieron `docs/srs.md` ni `docs/srs.meta.yaml`, archivar un segundo change y confirmar que vuelve a ofrecerlo | `skills/openspec-archive-change/SKILL.md`, `.claude/commands/opsx/archive.md` |

## Open Questions

Sin preguntas abiertas.
