## Context

`srs-generate` (change `srs-aggregation-skill`, implementado, pendiente de merge) persiste en `docs/srs.meta.yaml` dos tipos de datos distintos: contabilidad del SRS (IDs jerárquicos, atributos por requirement) y conocimiento de negocio del proyecto (glosario, actores, procesos de negocio, objetivos de negocio). Este change mueve solo lo segundo.

Al diseñar dónde debía vivir ese conocimiento, se leyó el código fuente del CLI de OpenSpec instalado (`@fission-ai/openspec@` en `node_modules`, archivo `dist/core/project-config.js`). El `ProjectConfigSchema` (Zod) de `readProjectConfig()` solo reconoce tres campos de primer nivel en `openspec/config.yaml`: `schema` (string), `context` (string, límite duro de 50KB) y `rules` (record de artifact ID → string[]). Cualquier otra clave de primer nivel que se agregue al YAML se ignora silenciosamente — `readProjectConfig()` solo copia a `config` lo que pasa validación de esos tres campos. Esto se confirmó ejecutando `openspec instructions proposal --json` en el change anterior y viendo que el campo `context` devuelto es exactamente el string de `context:` del config.yaml, nada más.

Esto descarta la lectura literal de "sub-claves" del issue original si se interpretaba como nuevas claves YAML (`glosario:`, `actores:`, etc.) — nunca llegarían a Claude ni al Agente. La única vía real para que este conocimiento se inyecte en cada operación (razón #2 del issue) es que viva dentro del string de `context:`.

## Goals / Non-Goals

**Goals:**
- Que glosario/actores/procesos/objetivos vivan en un solo lugar (`context:`) y se reusen en toda operación de OpenSpec, no solo en el SRS.
- Que `docs/srs.meta.yaml` quede reducido a lo que genuinamente es contabilidad del SRS.
- Migración automática y no destructiva de lo que ya se haya generado con la versión anterior de `srs-generate`.

**Non-Goals:**
- No cambiar el `ProjectConfigSchema` del CLI de OpenSpec (es un paquete externo, `@fission-ai/openspec`, fuera de este repo).
- No resolver el límite de 50KB con compresión o paginado — solo advertir.
- No tocar `context:` de proyectos que no usan `srs-generate`.

## Decisions

### D1: El conocimiento estructurado vive como texto dentro de `context:`, no como claves YAML nuevas

Ver Context: es la única forma de que el CLI lo inyecte en cada operación. Las subsecciones usan encabezados Markdown fijos para que sean reconocibles tanto por un humano leyendo `config.yaml` como por la skill al parsear el string:

```
## Glosario
- <término>: <definición>

## Actores y Procesos de Negocio
### Actores
- <nombre>: <descripción>
### Procesos
- <nombre>: <descripción>

## Objetivos de Negocio
- <id>: <descripción>
```

Se appendean al final del `context:` existente, separadas por una línea en blanco, sin tocar lo que ya hay (`project_type`, propósito, reglas de seguridad, etc.).

Alternativas consideradas:
- Claves YAML nuevas de primer nivel (`glosario:`, `actores:`, ...) — descartada: el CLI las ignora (D del Context).
- Anidar todo dentro de un `context:` que deje de ser string y pase a ser objeto — descartada: rompe la validación Zod (`context` debe ser `string`) y el `context:` existente de cada proyecto, que hoy es texto libre.
- Un archivo separado (`openspec/project-context.yaml`) leído a mano por `srs-generate` — descartada: no lo inyecta el CLI en las demás operaciones, no resuelve la razón #2 del issue.

**Decisión:** subsecciones Markdown con encabezados fijos, appendeadas al string de `context:`.

### D2: Actualización de una subsección existente reemplaza solo esa subsección

Cuando `srs-generate` necesita agregar un actor o término nuevo, localiza el bloque entre su encabezado (`## Glosario`, etc.) y el siguiente `##` (o el final del texto), y lo reemplaza completo — no reescribe todo `context:` ni reordena las demás subsecciones o el contenido previo a ellas.

Alternativas consideradas:
- Reescribir todo `context:` de punta a punta en cada corrida — descartada: arriesga perder contenido manual que alguien haya agregado entre corridas de `srs-generate` (ej. una nota nueva sobre `project_type`).

**Decisión:** edición quirúrgica por subsección, nunca reescritura completa de `context:`.

### D3: Advertencia de tamaño, no compresión automática

Antes de escribir, la skill calcula el tamaño resultante de `context:` en bytes. Si supera un umbral de alerta (40KB, dejando margen bajo el límite duro de 50KB del CLI), avisa y deja que el usuario decida qué recortar — no trunca ni comprime nada por su cuenta, porque el CLI descarta *todo* el campo `context` (no solo el exceso) si se pasa del límite, y una skill que corte contenido sin avisar podría silenciar reglas de seguridad importantes que vivían ahí.

**Decisión:** advertencia en 40KB, nunca escritura silenciosa que arriesgue superar 50KB.

### D4: Migración automática y de una sola vía

Si `docs/srs.meta.yaml` tiene glosario/actores/procesos/objetivos de una corrida anterior (formato de `srs-aggregation-skill` antes de este change), `srs-generate` los migra a las subsecciones de `context:` en la primera corrida después de este change, y los borra de `srs.meta.yaml`. Es de una sola vía: no hay rollback automático que los vuelva a `srs.meta.yaml`.

Alternativas consideradas:
- Dejar ambos lugares poblados como fallback — descartada: recrea la segunda fuente de verdad que este change busca eliminar.
- Migración manual (el usuario copia y pega) — descartada: fricción innecesaria para algo mecánico.

**Decisión:** migración automática, una sola vez, con log de qué se movió.

## Risks / Trade-offs

- **[Riesgo] Dos proyectos corriendo `srs-generate` en paralelo escriben `context:` al mismo tiempo y se pisan** → Fuera de alcance de este change (mismo riesgo ya existe hoy con cualquier edición manual de `config.yaml`); no se agrega ningún mecanismo de lock.
- **[Riesgo] Un proyecto con `context:` ya cerca de 50KB no puede sumar glosario/actores sin superar el límite** → D3 avisa antes de escribir; la decisión de qué recortar queda en manos del usuario.
- **[Trade-off] Parsear subsecciones Markdown dentro de un string YAML es menos robusto que un schema tipado** → Aceptado: es la única opción que el CLI realmente inyecta; el "parser" es una skill LLM leyendo texto convencionalmente formateado, no código rígido, así que tolera variaciones razonables.
- **[Riesgo] La migración de D4 corre sin que el usuario la pida explícitamente** → Es no-destructiva (mueve, no borra información) y se loguea en el resumen de la skill; si algo sale mal, el `context:` es un archivo versionado y `git diff` lo muestra antes de commitear.

## Security Layer

`project_type: tooling` — mismo criterio que `srs-aggregation-skill`: el glosario, los actores, los procesos y los objetivos de negocio son información de dominio, no secrets, pero la skill no debe copiar ahí ningún valor que parezca credencial si en algún momento se completa por bootstrap en vez de por entrevista (no aplica hoy: estas cuatro secciones siempre vienen de entrevista, nunca de bootstrap, por el requirement ya existente de `srs-generation`).

## Impacto en proyectos existentes

- **Proyectos que nunca corrieron `srs-generate`:** sin cambios — no tienen `docs/srs.meta.yaml` ni subsecciones en `context:`.
- **Proyectos que ya corrieron la versión anterior de `srs-generate`:** en la próxima corrida, migración automática (D4) de `docs/srs.meta.yaml` a `context:`.
- **`openspec/config.yaml` de otros proyectos que no usan `srs-generate`:** no se tocan.
- **Retrocompatibilidad del CLI:** no se cambia el schema de `config.yaml` que el CLI valida — solo se usa mejor el campo `context` que ya existe.

## Migration Plan

1. Implementar en `skills/srs-generate/SKILL.md` la lectura/escritura de las subsecciones de `context:` (D1, D2).
2. Implementar la advertencia de tamaño (D3).
3. Implementar la migración automática desde `docs/srs.meta.yaml` (D4).
4. Verificar en un proyecto de prueba: correr `srs-generate` con datos previos en `docs/srs.meta.yaml` (formato anterior) y confirmar que migran a `context:` sin duplicarse ni perderse, y que `context:` original (project_type, propósito, reglas) queda intacto.

Rollback: revertir los commits de este change; `docs/srs.meta.yaml` de los proyectos ya migrados no se restaura automáticamente (D4 es de una sola vía) — si hiciera falta, se recupera del historial de git de cada proyecto.

## Open Questions

Sin preguntas abiertas.
