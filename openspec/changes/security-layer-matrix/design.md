# Design: Security Layer Matrix

## Decisiones técnicas

**1. Dónde vive la matriz:** En `~/.claude/CLAUDE.md` global, sección nueva `## Capa de Seguridad por Tipo de Proyecto`. Al ser global aplica a todos los proyectos sin necesidad de copiarla.

**2. Cómo se declara el tipo de proyecto:** Dentro del bloque `context:` de `openspec/config.yaml` de cada proyecto, como campo `project_type`. OpenSpec inyecta el bloque `context` en todos los artefactos que genera, por lo que Claude lo leerá automáticamente al crear proposals y designs.

**3. Dónde aplica la seguridad en cada change:** En el `design.md` de cada change se agrega una sección `## Security Layer` que lista los controles relevantes para ese cambio específico. En `tasks.md` se agrega una tarea de seguridad si el cambio implica nuevo código expuesto.

**4. Modificación del SKILL.md de apply en Claude:** Se crea `~/.claude/skills/openspec-apply-change/SKILL.md` (nivel global) con paso 6 reemplazado: en lugar de escribir código, Claude anuncia a Copilot qué change debe aplicar y sugiere ejecutar `/opsx:verify` al terminar. El SKILL.md de Copilot en `.agent/skills/` no se toca.

## Impacto en proyectos existentes

- **TPA-Yacopini:** `openspec/config.yaml` se actualiza con contexto real y `project_type: fullstack`. Changes activos no se ven afectados — la inyección aplica desde el próximo change nuevo.
- **Proyectos futuros:** Al hacer `openspec init`, el `config.yaml` generado viene vacío — hay que completarlo manualmente con `project_type` y `context`.
- **Retrocompatibilidad:** El SKILL.md global de apply en Claude sobreescribe el de cada proyecto solo si no existe a nivel proyecto. Si el proyecto tiene su propio SKILL.md, ese tiene precedencia.

## Security Layer

Este change modifica solo archivos de configuración e instrucciones — no hay superficie de ataque nueva.
