## Why

La skill `srs-generate` escribe los diagramas de caso de uso como bloques ```` ```plantuml ```` dentro de `docs/srs.md`. GitHub, Obsidian y la mayoría de los visores no renderizan PlantUML inline, así que el SRS muestra código en vez de diagramas (hoy `docs/srs.md` de este repo tiene 11 bloques así). Cada regeneración los vuelve a escribir. Issue [#22](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/22).

## What Changes

- Los diagramas de caso de uso siguen escritos en PlantUML, pero en archivos aparte: `docs/diagramas/CU-<ID>.puml` (uno por caso de uso) o `docs/diagramas/CAP-<ID de capability>.puml` (modo agrupado). Usan el motor de layout interno (`!pragma layout smetana`), así no dependen de Graphviz.
- La skill genera el `.svg` de cada `.puml` con Java y `plantuml.jar`, con una versión fija descargada de una URL fija y verificada por SHA-256. En el SRS se ve la imagen más un link a la fuente `.puml`, nunca el bloque inline.
- Fallback: si no hay Java, si el jar no se puede obtener o si no coincide el hash, quedan los `.puml`, el SRS enlaza solo a la fuente, el resumen lo avisa y el documento queda en estado "borrador".
- La regeneración borra los `.puml` y `.svg` de casos de uso o capabilities que ya no existen. Solo toca archivos con el patrón de nombre de la skill.
- Mermaid (flujo y secuencia) no cambia: sigue inline, porque se ve sin nada extra.
- **BREAKING (menor)** para los proyectos que ya tienen SRS: la próxima regeneración reemplaza los bloques inline por imágenes y crea `docs/diagramas/`.

## Non-goals

- Cambiar los diagramas Mermaid o el criterio de cuándo se generan.
- Cambiar los IDs de casos de uso o el umbral del modo agrupado.
- Instalar Java en las máquinas: si no hay Java, se usa el fallback.
- Renderizar con un servidor online de PlantUML: mandaría el contenido de las specs a un tercero.
- Agregar tests automáticos al repo (`comando: ninguno`).

## Capabilities

### New Capabilities
<!-- ninguna -->

### Modified Capabilities
- `srs-generation`: el requirement de Casos de Uso pasa de bloque PlantUML inline a `.puml` + SVG con link; el de Portada suma "diagramas sin renderizar" como causa de "borrador"; el Guard de escala nombra el archivo por capability del modo agrupado. Se agrega el requirement "Renderizado de diagramas PlantUML a SVG" (Java, jar fijo verificado, fallback, limpieza de huérfanos).

## Impact

- Archivo global modificado: `skills/srs-generate/SKILL.md`, que se instala en `~/.claude/skills/srs-generate/SKILL.md`. Cambia porque es la fuente del comportamiento que escribe los bloques inline. Lo usan todos los proyectos que generan SRS.
- Spec: `openspec/specs/srs-generation/spec.md` (sync en el archive).
- `README.md`: una línea en el setup sobre Java opcional.
- Dependencia nueva, opcional y por máquina: Java 11+ y `plantuml-1.2026.8.jar` en una caché del usuario fuera de los repos (`~/.claude/tools/plantuml/`).
- Proyectos destino: aparece `docs/diagramas/` con `.puml` y `.svg` versionables.
- `docs/srs.md` de este repo se regenera tras el archive (modo agrupado, 11 diagramas).
