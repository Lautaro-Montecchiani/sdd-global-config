## 1. Dependencia previa

- [x] 1.1 Antes de tocar código: confirmar que `openspec/specs/srs-generation/spec.md` existe en el repo (requiere que el change `srs-aggregation-skill` esté mergeado y archivado). Si no existe todavía, NO continuar con este change — avisar y esperar.

## 2. Subsecciones estructuradas en `context:`

- [x] 2.1 En `skills/srs-generate/SKILL.md`, implementar la lectura de las subsecciones `## Glosario`, `## Actores y Procesos de Negocio` (con `### Actores` y `### Procesos`) y `## Objetivos de Negocio` dentro del `context:` de `openspec/config.yaml` del proyecto destino
- [x] 2.2 En `skills/srs-generate/SKILL.md`, implementar la escritura/actualización de esas subsecciones: appendear al final de `context:` si no existen; si ya existen, reemplazar solo el bloque entre su encabezado y el siguiente `##` (o el final del texto), sin tocar el resto de `context:`
- [x] 2.3 En `skills/srs-generate/SKILL.md`, implementar la advertencia de tamaño: calcular el tamaño resultante de `context:` en bytes antes de escribir y advertir (sin bloquear) si supera 40KB, dado que el CLI descarta el campo completo por encima de 50KB

## 3. Cambio de persistencia en la entrevista guiada

- [x] 3.1 En `skills/srs-generate/SKILL.md` (§5 Entrevista Guiada y Persistencia), cambiar el destino de las respuestas de Glosario (2.2), Objetivos de Negocio (3.1/3.2) y Actores/Procesos de Negocio (3.3): de `docs/srs.meta.yaml` a las subsecciones de `context:` en `openspec/config.yaml`. La prioridad de cada Requisito No Funcional (3.6) sigue en `docs/srs.meta.yaml`, sin cambios
- [x] 3.2 En `skills/srs-generate/SKILL.md` (§7 Estructura de `docs/srs.meta.yaml`), quitar `glossary`, `objectives`, `actors` y `processes` del ejemplo YAML — ese archivo queda solo con `ids`, `priorities` y `exceptions`
- [x] 3.3 En `skills/srs-generate/SKILL.md` (§5.2 Detección Incremental de Gaps), actualizar la descripción para que lea las subsecciones de `context:` en vez de `docs/srs.meta.yaml` al comparar qué hay de nuevo (salvo la prioridad de 3.6, que sigue viniendo de `srs.meta.yaml`)

## 4. Migración automática

- [x] 4.1 En `skills/srs-generate/SKILL.md`, implementar la migración: si `docs/srs.meta.yaml` tiene `glossary`, `objectives`, `actors` o `processes` (formato anterior a este change), migrarlos a las subsecciones correspondientes de `context:` en la próxima corrida, quitarlos de `docs/srs.meta.yaml`, y no volver a preguntar por ellos en la entrevista
- [x] 4.2 En `skills/srs-generate/SKILL.md`, agregar al resumen final de la skill una línea que reporte qué se migró (si hubo migración), para que quede visible en el output

## 5. Verificación

- [x] 5.1 Verificar que el cambio aplica en un proyecto de prueba: (a) proyecto sin `context:` previo — correr `srs-generate`, responder la entrevista, confirmar que las 3 subsecciones aparecen appendeadas correctamente en `openspec/config.yaml` y que `docs/srs.meta.yaml` ya no tiene glosario/actores/procesos/objetivos; (b) proyecto con `context:` existente (`project_type`, propósito) — confirmar que ese contenido previo queda intacto después de appendear las subsecciones; (c) simular un `docs/srs.meta.yaml` con datos en formato anterior (glossary/actors/objectives/processes) y confirmar que la migración automática los mueve a `context:` sin duplicarlos y sin volver a preguntar por ellos

## 6. Fixes de verify (ronda 1)

- [x] 6.1 En `skills/srs-generate/SKILL.md` §5.3 (Persistencia en `openspec/config.yaml`), agregar el formato exacto de cada ítem dentro de las subsecciones — hoy no está especificado y el requirement "Formato de cada subsección" de `specs/project-context-schema/spec.md` lo exige: `- <término>: <definición>` en Glosario, `- <nombre>: <descripción>` en Actores y en Procesos (bajo sus sub-encabezados `### Actores`/`### Procesos`), `- <id>: <descripción>` en Objetivos de Negocio (igual que el bloque de ejemplo en `design.md`, decisión D1). De paso, corregir la referencia en §8 ("siguiendo el formato descrito en la sección 5.3") para que apunte a este formato ya explícito.
