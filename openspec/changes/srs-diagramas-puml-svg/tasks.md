# Tasks

Sin tests automáticos (`comando: ninguno`): las verificaciones son manuales y su evidencia es la salida de consola pegada en el resumen del apply.

## 1. Skill srs-generate

- [ ] 1.1 En `skills/srs-generate/SKILL.md` §3.1, sumar "diagramas de caso de uso sin renderizar a SVG" a las condiciones de estado "borrador" (design D11). Evidencia: `Select-String -Path skills/srs-generate/SKILL.md -Pattern "sin renderizar"`.
- [ ] 1.2 En `skills/srs-generate/SKILL.md` §4.1, reemplazar la viñeta "genera un diagrama UML de caso de uso en PlantUML (usando un bloque de código plantuml)" por las reglas de design D1 (nombres y carpeta `docs/diagramas/`), D2 (contenido del `.puml`, `!pragma layout smetana`, sin directivas `!include`/`!import`) y D7 (imagen + `Fuente:` o "Diagrama sin renderizar"). Dejar explícito que nunca se escribe un bloque `plantuml` inline en `docs/srs.md`. En §4.2, aclarar que Mermaid sigue inline, después de la imagen.
- [ ] 1.3 En `skills/srs-generate/SKILL.md` §4.5 (modo agrupado), indicar que el diagrama por capability es `docs/diagramas/CAP-<ID de la capability>.puml` con su `.svg` (design D1).
- [ ] 1.4 Agregar en `skills/srs-generate/SKILL.md` la sección nueva §4.6 "Renderizado a SVG" con design D3 (tabla con versión `1.2026.8`, URL y SHA-256 copiados literal del design, y caché `~/.claude/tools/plantuml/`), D4 (verificación y `.part`), D5 (Java 11+), D6 (render incremental, una invocación por archivo con el comando literal del design y exit code distinto de 0 = error con borrado del `.svg`), D8 (fallback por entorno y puntual, aviso en el resumen) y D9 (huérfanos solo con patrón propio). Incluir la prohibición de servidores de render online (Security Layer).
- [ ] 1.5 En `skills/srs-generate/SKILL.md` §6.3, sumar design D10: el resumen previo lista cuántos `.puml` se crean, cambian y borran, con los nombres de los que se borran; sin confirmación no se toca `docs/diagramas/`; el render va después de confirmar.
- [ ] 1.6 En el frontmatter de `skills/srs-generate/SKILL.md`, `metadata.version: 1.0.0` → `1.1.0`. Evidencia: `Select-String -Path skills/srs-generate/SKILL.md -Pattern '```plantuml'` sin resultados (la skill ya no indica bloques inline) y `Select-String -Path skills/srs-generate/SKILL.md -Pattern "5e1ecfa8ecd32c90b03bbf3b1eb6f020943f98ab0fcf4032be31a0002ee2c462"` con una coincidencia. Verificar además que el archivo no contiene `C:\Users` con un script en archivo (las barras se pierden en comandos en línea).
- [ ] 1.7 En `README.md`, en el setup por máquina, agregar una línea: Java 11+ es opcional y solo hace falta para que `srs-generate` renderice los diagramas de caso de uso a SVG. Sin Java, el SRS sale en "borrador" con links a los `.puml`.

## 2. Instalación y prueba del render (evidencia del apply)

- [ ] 2.1 Copiar `skills/srs-generate/SKILL.md` a `~/.claude/skills/srs-generate/SKILL.md` y verificar con hash (`Get-FileHash` de los dos, ignorando el fin de línea si hace falta). Pegar los dos hashes.
- [ ] 2.2 Bajar el jar fijo con el procedimiento de design D4 a `~/.claude/tools/plantuml/plantuml-1.2026.8.jar` (vía `.part`) y pegar la salida de `Get-FileHash -Algorithm SHA256`. Tiene que coincidir con el SHA-256 del design D3; si no coincide, frenar y avisar.
- [ ] 2.3 En una carpeta descartable fuera del repo (`$env:TEMP\puml-muestra`), escribir un `CU-9.9.9.9.1.puml` válido según design D2 y un `CU-9.9.9.9.2.puml` sin `@enduml`. Renderizar cada uno con el comando literal de design D6 y pegar, para cada uno, el exit code y si quedó el `.svg` (el primero: 0 y `.svg` presente; el segundo: distinto de 0). Si el comportamiento no coincide con D6, frenar y avisar. Borrar la carpeta al terminar.

## 3. Commits

- [ ] 3.1 Commitear `skills/srs-generate/SKILL.md` en un commit aparte, `feat: srs-generate renderiza casos de uso a SVG desde .puml`. El cuerpo describe el impacto: skill global; la próxima regeneración del SRS en cada proyecto crea `docs/diagramas/` y reemplaza los bloques inline; sin Java, el SRS queda en "borrador". Cerrar con un único bloque final de trailers que incluya `Spec-ID: srs-diagramas-puml-svg`.
- [ ] 3.2 Commitear `README.md` aparte (`docs: Java opcional para los diagramas del SRS`), con el mismo trailer `Spec-ID: srs-diagramas-puml-svg`.

## 4. Verificación con Claude (no la ejecuta el Agente)

- [ ] 4.1 S01–S08 y S11–S15 en el proyecto de prueba `$env:TEMP\srs-prueba` (design, Test Plan).
- [ ] 4.2 S16 con la evidencia de 2.3 y la revisión de §4.6.
- [ ] 4.3 S07, S09 y S10 tras el archive, al regenerar `docs/srs.md` de este repo: 11 `CAP-*.puml` + `.svg` y ningún bloque `plantuml`.
- [ ] 4.4 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[srs-diagramas-puml-svg] Diagramas de caso de uso del SRS como .puml + SVG` desde `change/srs-diagramas-puml-svg`, con `Closes #22`.
- `/opsx:verify srs-diagramas-puml-svg` antes del merge; `/opsx:archive` después; regenerar el SRS y cerrar 4.3.
