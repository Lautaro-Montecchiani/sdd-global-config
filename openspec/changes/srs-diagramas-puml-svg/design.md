## Context

`skills/srs-generate/SKILL.md` §4.1 pide "un diagrama UML de caso de uso en PlantUML (usando un bloque de código plantuml)", y §4.5 pide un diagrama por capability en modo agrupado. El SRS de este repo (`docs/srs.md`, 117 casos de uso, modo agrupado) tiene 11 bloques `plantuml` inline que GitHub y Obsidian muestran como texto. Mermaid sí se ve en esos visores y no se toca.

En esta máquina hay Java 21 (`java -version`). PlantUML publica sus releases en GitHub con un digest SHA-256 por asset. Al proponer este change (02/11/2026), la última versión era v1.2026.9 (17/10/2026); se fija v1.2026.8 (05/09/2026), que lleva casi dos meses publicada.

## Goals / Non-Goals

**Goals:**
- Que el SRS muestre los diagramas de caso de uso como imagen en GitHub y Obsidian.
- Que la fuente PlantUML siga versionada y editable al lado del SVG.
- Que la falta de Java no rompa la generación: el SRS sale igual, en "borrador".

**Non-Goals:**
- Tocar Mermaid, los IDs `CU-…`, el umbral del modo agrupado o la entrevista guiada.
- Usar un servidor de render online o Graphviz.
- Instalar Java desde la skill.

## Decisions

**D1. Nombres y ubicación.** Todo en `docs/diagramas/` del proyecto destino (relativo a `docs/srs.md`):
- Por escenario: `CU-<ID del caso de uso sin el prefijo CU->`. Ejemplo: `CU-3.5.1.2.1.puml` y `CU-3.5.1.2.1.svg`.
- Modo agrupado: `CAP-<ID de la capability>`. Ejemplo: `CAP-3.5.1.puml` y `CAP-3.5.1.svg`.
- Patrones propios de la skill: nombre que empieza con `CU-` o `CAP-`, sigue con dígitos y puntos, y termina en `.puml` o `.svg`. Cualquier otro archivo de la carpeta es ajeno y no se toca.

**D2. Contenido de cada `.puml`.** UTF-8 sin BOM, con este orden: línea `@startuml`, línea `!pragma layout smetana` (motor interno, sin Graphviz), actor(es) inferido(s) del `WHEN`, un `rectangle` con el nombre del sistema que contiene el/los `usecase` (en modo agrupado, todos los de la capability) y las asociaciones actor–caso de uso, y por último `@enduml`. Los textos van entre comillas dobles; una comilla doble dentro del texto del escenario se reemplaza por comilla simple. La skill NO escribe `!include`, `!includeurl`, `!import` ni ninguna otra directiva `!` salvo el `!pragma` de arriba.

**D3. Jar fijo.**
- Versión: `1.2026.8`, asset `plantuml-1.2026.8.jar` (29.871.497 bytes).
- URL: `https://github.com/plantuml/plantuml/releases/download/v1.2026.8/plantuml-1.2026.8.jar`
- SHA-256: `5e1ecfa8ecd32c90b03bbf3b1eb6f020943f98ab0fcf4032be31a0002ee2c462`. Es el digest publicado por GitHub para ese asset; se consultó con `gh api repos/plantuml/plantuml/releases/tags/v1.2026.8`.
- Caché: `~/.claude/tools/plantuml/plantuml-1.2026.8.jar`. `~` es el home del usuario (`$HOME` o `%USERPROFILE%`). Queda fuera de cualquier repo y nunca se escribe una ruta absoluta en el SRS ni en el resumen.
- La skill guarda la versión, la URL y el hash juntos en una tabla de §4.6. Para actualizar la versión se cambian los tres en un change nuevo.

**D4. Obtención y verificación del jar.** En cada generación:
1. Si el jar está en la caché, calcular su SHA-256. Si coincide, usarlo. Si no coincide, borrarlo y seguir con el paso 2 (un solo reintento).
2. Bajar desde la URL fija a `plantuml-1.2026.8.jar.part` en la misma carpeta, calcular el SHA-256 y, solo si coincide, renombrarlo a `.jar`. Si no coincide o falla la descarga, borrar el `.part` y aplicar el fallback (D8).
Para el hash: `Get-FileHash -Algorithm SHA256` en PowerShell, `sha256sum` en bash y `certutil -hashfile <archivo> SHA256` como alternativa en Windows. La comparación no distingue mayúsculas.

**D5. Java.** Se detecta con `java -version`: tiene que existir y ser la versión 11 o superior (la que pide el jar estándar de PlantUML). Si `java` no está o es anterior a 11, se aplica el fallback (D8) sin intentar bajar el jar.

**D6. Render incremental, uno por archivo.** Antes de escribir un `.puml`, la skill lo compara con el que ya está en disco:
- Si el contenido es idéntico y el `.svg` existe, no se renderiza y se sigue usando ese SVG.
- Si es nuevo, cambió o le falta el `.svg`, se escribe y se renderiza con una invocación por archivo: `java -Djava.awt.headless=true -DPLANTUML_SECURITY_PROFILE=SANDBOX -jar <jar> -tsvg -charset UTF-8 docs/diagramas/<archivo>.puml`. Así el `.svg` queda al lado del `.puml`.
- Si el exit code es distinto de 0, el diagrama tiene un error: se borra el `.svg` que PlantUML haya dejado y ese diagrama pasa al fallback puntual (D8). Con un error de sintaxis, PlantUML devuelve exit 200 y deja una imagen del error. Si no encuentra diagrama (por ejemplo, falta `@enduml`), devuelve exit 100 y no deja `.svg`. Se comprobó en el verify del 02/11/2026.
- Invariante: un `.svg` en disco siempre corresponde al `.puml` actual. Por eso, todo `.puml` nuevo o cambiado que no se renderiza pierde su `.svg` anterior (D8). Sin esta regla, D6 reutilizaría en la corrida siguiente una imagen vieja, porque el `.puml` en disco ya sería idéntico.
La invocación por archivo permite saber cuál falló. El modo agrupado tiene pocos archivos y el modo por escenario está limitado por el umbral (~40).

**D7. Cómo se ve en el SRS.** En cada Caso de Uso (o al inicio de cada capability en modo agrupado), en lugar del bloque inline:
- Con SVG: una línea de imagen Markdown `![Diagrama CU-3.5.1.2.1](diagramas/CU-3.5.1.2.1.svg)` y debajo `Fuente: [CU-3.5.1.2.1.puml](diagramas/CU-3.5.1.2.1.puml)`.
- Sin SVG: solo `Diagrama sin renderizar — fuente: [CU-3.5.1.2.1.puml](diagramas/CU-3.5.1.2.1.puml)`.
Las rutas son relativas a `docs/`. Mermaid sigue en bloque inline después de la imagen, igual que hoy.

**D8. Fallback.**
- Por entorno (sin Java, Java menor que 11, jar no obtenido o no verificado): se escriben igual todos los `.puml`. Los diagramas cuyo `.puml` no cambió y ya tienen `.svg` lo conservan (D6). Los demás se muestran "sin renderizar" (D7).
- Puntual (error al renderizar un archivo): solo ese diagrama queda "sin renderizar".
- En los dos casos, si el `.puml` es nuevo o cambió y no se renderiza, se borra el `.svg` anterior con su mismo nombre (invariante de D6).
- En los dos casos, el resumen final dice cuántos diagramas quedaron sin SVG y por qué (sin Java, hash, descarga, o el nombre del archivo con error), y el encabezado del SRS queda en "borrador".

**D9. Huérfanos.** Con la lista de diagramas vigentes (por escenario o agrupados, según el modo de esta corrida), se borran de `docs/diagramas/` los `.puml` y `.svg` con patrón propio (D1) que no estén en la lista. Un cambio de modo deja huérfanos todos los del modo anterior.

**D10. Integración con la regeneración segura (§6.3).** El resumen previo a la confirmación agrega cuántos `.puml` se crean, cambian y borran, y los nombres de los que se borran. Si el usuario no confirma, no se escribe ni se borra nada en `docs/diagramas/`. El render ocurre después de la confirmación.

**D11. Cambios en `SKILL.md`.**
- §3.1: suma "diagramas sin renderizar" a las causas de "borrador".
- §4.1: reemplaza la viñeta del bloque `plantuml` por D1, D2 y D7.
- §4.2: aclara que Mermaid sigue inline.
- §4.5: el archivo del modo agrupado es `CAP-<ID>.puml`.
- §4.6 nueva, "Renderizado a SVG": D3 a D9, con la tabla de versión, URL y hash.
- §6.3: suma D10.
- `metadata.version` pasa de `1.0.0` a `1.1.0`.
- El resto de la skill no cambia.

## Security Layer

Proyecto `tooling`: el artefacto modificado es una instrucción para IA, y además pasa a ejecutar un binario descargado.
- **Integridad del binario:** solo se ejecuta un jar cuyo SHA-256 coincida con el fijado (D3, D4). Se baja de una única URL HTTPS de GitHub con versión explícita, nunca `latest`. Mientras no está verificado queda como `.part`.
- **Sin terceros:** prohibido usar servidores de render online (plantuml.com, kroki u otros). Mandarían el contenido de las specs afuera.
- **Sandbox de PlantUML:** `-DPLANTUML_SECURITY_PROFILE=SANDBOX` y ninguna directiva `!include` o `!import` en los `.puml` (D2). PlantUML no lee archivos ni URLs durante el render.
- **Secrets:** los `.puml` solo contienen texto de escenarios ya filtrados por §6.2 (exclusión de secrets). Ningún dato del entorno entra a los diagramas.
- **Rutas:** la caché vive en el home del usuario y nunca se escribe una ruta absoluta en el SRS, en los `.puml` ni en el resumen. En `SKILL.md` la caché aparece como `~/.claude/tools/plantuml/`.
- **Commit:** el cambio a `skills/srs-generate/SKILL.md` va en un commit aparte con la descripción del impacto (skill global usada por otros proyectos).

## Impacto en proyectos existentes

- Los SRS ya generados no cambian hasta la próxima regeneración. Ahí se reemplazan los bloques inline, se crea `docs/diagramas/` y la regeneración segura lo muestra antes de confirmar.
- Proyectos en máquinas sin Java: el SRS sale en "borrador" con links a los `.puml`. Es retrocompatible: no falla, solo avisa.
- Los IDs de casos de uso y de requirements no cambian. El requirement nuevo va al final de la spec (siguiente ID libre) y los escenarios nuevos van al final de sus requirements.
- Primera corrida por máquina: baja unos 30 MB a la caché del usuario.
- Los `.svg` y `.puml` se versionan en cada proyecto. Ningún `.gitignore` los excluye por defecto, y el `.gitignore` mínimo del workflow no los toca.

## Risks / Trade-offs

- Smetana es menos maduro que Graphviz: algunos diagramas grandes del modo agrupado pueden verse menos prolijos. Se acepta a cambio de no depender de Graphviz.
- Si GitHub mueve o borra el asset, la descarga falla y se usa el fallback. El SRS no se rompe.
- El render incremental se basa en comparar el texto del `.puml`. Si alguien edita un `.svg` a mano, se pisa recién cuando cambie su `.puml`.
- La versión fija se desactualiza con el tiempo. Actualizarla es un change explícito.

## Migration Plan

1. El Agente edita `skills/srs-generate/SKILL.md`, lo instala en `~/.claude/skills/srs-generate/SKILL.md` y comprueba que el jar fijo baja, verifica y renderiza un `.puml` de muestra.
2. Después del archive, Claude regenera `docs/srs.md` de este repo con la oferta del archive (modo agrupado) y verifica los 11 `CAP-*.svg`.

Rollback: revertir el PR y reinstalar la skill anterior. Los `docs/diagramas/` que hayan quedado en otros proyectos se pueden borrar sin efecto en el SRS anterior.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): el artefacto es Markdown y la skill la ejecuta Claude. Todo el plan es manual. No hay tests de caracterización porque no se modifica código. El cambio intencional de comportamiento (bloque inline → `.puml` + SVG) queda cubierto por S04–S07 y S11–S16. Un test automático que se agregue en el futuro debe llevar el marcador `test-plan: srs-diagramas-puml-svg/<ID>`.

El proyecto de prueba es un repo descartable fuera de los repos reales (`$env:TEMP\srs-prueba`), con `openspec init` y una spec `demo` con un requirement y tres escenarios: uno simple (un actor, un paso), uno con varios pasos de un actor y uno con dos actores. Lo arma Claude en el verify.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Portada / Encabezado y estado del documento | manual: en el proyecto de prueba, con todo renderizado y sin pendientes, el encabezado dice "completo" | `$env:TEMP\srs-prueba\docs\srs.md` |
| S02 | Portada / Secciones en formato de tabla | manual: confirmar que 3.1/3.2, 3.3 y 3.6 siguen en tablas en el SRS de prueba | ídem |
| S03 | Portada / Diagramas sin renderizar | manual: si se ejecuta S14, el encabezado dice "borrador". Si no, se revisa que §3.1 de la skill sume "diagramas sin renderizar" a las causas de "borrador" | ídem + `skills/srs-generate/SKILL.md` |
| S04 | Casos de Uso / Caso de uso simple | manual: el CU del escenario simple tiene `![…](diagramas/CU-….svg)`, el link `Fuente:` al `.puml` y ningún bloque Mermaid | ídem + `docs\diagramas\` |
| S05 | Casos de Uso / Varios pasos de un actor | manual: imagen + link + bloque `flowchart` Mermaid | ídem |
| S06 | Casos de Uso / Interacción entre actores | manual: imagen + link + bloque `sequenceDiagram` Mermaid | ídem |
| S07 | Casos de Uso / Sin bloques PlantUML inline | manual: `Select-String -Pattern '```plantuml'` sobre los dos SRS (prueba y este repo) devuelve 0, y cada `.puml` contiene `!pragma layout smetana` | ídem + `docs\srs.md` de este repo |
| S08 | Guard / Por debajo del umbral | manual: el proyecto de prueba (3 CU) genera un `CU-*.puml` por escenario sin pedir acotar | `$env:TEMP\srs-prueba\docs\diagramas\` |
| S09 | Guard / Por encima del umbral | manual: al regenerar este repo (117 CU), la skill pide confirmar y genera `CAP-<ID>.puml` + `.svg` por capability (11) | `docs\diagramas\` de este repo |
| S10 | Guard / Alcance acotado | manual: regenerar este repo acotado a una capability con menos de 40 escenarios. Vuelven los `CU-*` de esa capability. Se descarta sin escribir (cancelar en la confirmación) | ídem |
| S11 | Renderizado / Java y jar disponibles | manual: cada `.puml` tiene su `.svg`, y el `.svg` se ve en la vista previa Markdown de VS Code o en GitHub | ídem |
| S12 | Renderizado / Jar ausente | manual: borrar la caché `~/.claude/tools/plantuml/`, regenerar el SRS de prueba y confirmar que la skill baja el jar, verifica el hash y queda `plantuml-1.2026.8.jar` (sin `.part`) | `~/.claude/tools/plantuml/` |
| S13 | Renderizado / Hash que no coincide | manual: reemplazar el jar cacheado por un archivo cualquiera con el mismo nombre. La skill lo detecta, lo borra, lo baja de nuevo y el hash final coincide con D3 | ídem |
| S14 | Renderizado / Sin Java | manual: requiere una máquina o sesión sin `java` en el PATH. Pasos: generar el SRS de prueba, confirmar que quedan los `.puml`, que los CU dicen "Diagrama sin renderizar", que el resumen avisa y que el estado es "borrador". Si no hay entorno sin Java, se verifica por revisión de §4.6 y se deja anotado en el verify | `$env:TEMP\srs-prueba\docs\` |
| S15 | Renderizado / Diagramas huérfanos | manual: en el proyecto de prueba, agregar un archivo ajeno `docs\diagramas\notas.txt`, borrar un escenario de la spec `demo` y regenerar. Se borran su `.puml` y su `.svg`, `notas.txt` sigue y el resumen previo los lista | `$env:TEMP\srs-prueba\docs\diagramas\` |
| S16 | Renderizado / Un diagrama con error | manual: la skill reescribe cada `.puml` desde la spec, así que un error no se puede forzar desde el SRS. Pasos: (a) correr el comando de D6 sobre un `.puml` sin `@enduml` en una carpeta descartable y confirmar que el exit code es distinto de 0 y que PlantUML deja un `.svg` (la premisa de D6, evidencia del apply en 2.3); (b) revisar que §4.6 diga que, ante un exit code distinto de 0, se borra el `.svg`, ese CU queda "sin renderizar" y el resumen nombra el archivo | carpeta descartable + `skills/srs-generate/SKILL.md` |
| S17 | Renderizado / SVG desactualizado | manual: en el proyecto de prueba ya renderizado, cambiar el texto de un escenario y regenerar sin `java` en el PATH. El `.svg` de ese CU desaparece y el CU dice "Diagrama sin renderizar". Después regenerar con Java: se renderiza de nuevo y el `.svg` muestra el texto nuevo | `$env:TEMP\srs-prueba\docs\diagramas\` |

Además, el Agente deja como evidencia del apply (tarea 2.x) la descarga y el hash del jar y el render de un `.puml` de muestra con el comando exacto de D6.

## Open Questions

Sin preguntas abiertas.
