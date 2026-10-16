## Context

`/opsx:verify` (skill `openspec-verify-change` + comando `.claude/commands/opsx/verify.md`, cada uno con su copia de la lógica) verifica hoy en tres dimensiones — completitud, correctitud y coherencia — sin ejecutar nada: cuenta checkboxes y busca palabras clave en el código por cada requirement y escenario. `/opsx:propose` genera `design.md` y `tasks.md` sin ninguna noción de tests; solo algunos changes (por ejemplo, `patentamientos-etl-multiformato` en PLANEAMIENTO) piden tests por escenario, a mano.

Restricciones:
- El Agente usa en cada proyecto las skills por defecto de `openspec init` (`.agent/skills/`, `.github/skills/`), que este repo no controla. Lo que el Agente tiene que hacer debe viajar en `tasks.md`, en las plantillas (`templates/`) o en las reglas globales que lee desde el espejo del vault.
- El CLI de OpenSpec solo reconoce `schema`/`context`/`rules` en el primer nivel de `openspec/config.yaml`; cualquier configuración nueva va como subsección Markdown dentro de `context:` (capability `project-context-schema`, límite de 50KB).
- Casi ningún proyecto tiene tests hoy, y algunos no pueden tenerlos (Power Query, scripts sin estructura).
- Este repo (`project_type: tooling`) tampoco tiene tests automáticos: sus artefactos son instrucciones en Markdown.

## Goals / Non-Goals

**Goals:**
- Que cada escenario de un change nuevo tenga un test automático o una verificación manual justificada, definidos en el diseño.
- Que el verify ejecute esos tests y dé un resultado objetivo y reproducible.
- Que un change que modifica código existente no pueda romper lo existente sin que el verify lo detecte.
- Que el verify lea menos: los tests y el diff, no todo el repo.
- No romper los changes en curso.

**Non-Goals:**
- CI nueva, cobertura mínima o cambios al schema de OpenSpec.
- Tests para el código existente que el change no toca.
- Tocar las skills del Agente de cada proyecto.
- Sacar la duplicación skill/comando (change aparte).

## Decisions

### D1. `## Test Plan` en `design.md`, con IDs por change
Una sección `## Test Plan` al final de `design.md`, antes de `## Open Questions`, con:
- Encabezado: comando de tests (de `## Tests`), si se fuerza la suite completa y por qué.
- Tabla de escenarios: `ID | Requirement / Escenario | Verificación | Archivo previsto` — `ID` = `S01`…, `Verificación` = `auto` o `manual: <motivo>`; las filas manuales llevan los pasos debajo de la tabla o referencian un procedimiento (`P1`…).
- Tabla de caracterización (solo si el change modifica código existente): `ID | Archivo existente | Qué fija | Cambio intencional`.

**Por qué en `design.md` y no un artefacto nuevo:** el schema `spec-driven` tiene artefactos fijos; agregar uno implica un schema propio. El design ya es el lugar del "cómo".
**Alternativa descartada:** poner el ID en el título del escenario de la spec — ensucia las specs principales al archivar y los IDs dejarían de ser por change.

### D2. Marcador `test-plan: <change>/<ID>`
El test lleva el marcador en nombre, comentario o docstring. El verify lo busca con una búsqueda literal sobre los archivos de test. El marcador incluye el nombre del change para que no choquen IDs de changes distintos, y el mapeo sigue legible después del archive (el Test Plan queda en `openspec/changes/archive/`).
**Alternativa descartada:** atar al nombre o ruta del test — se rompe si el Agente reorganiza archivos.
**Relación con el SRS:** los IDs jerárquicos del SRS (`docs/srs.meta.yaml`) son por requirement y solo existen en proyectos con SRS; se puede cruzar más adelante (fuera de alcance).

### D3. Configuración de tests en `## Tests` del `context:`
Claves fijas: `comando`, `comando-rapido`, `timeout`, `entorno`, `excluir` (ver delta de `project-context-schema`). Una vez por proyecto, no por change. Si falta, el propose la pregunta una vez y la escribe con la edición quirúrgica y la advertencia de 40KB que ya define `project-context-schema`. `comando: ninguno` marca un proyecto sin tests automáticos.
**Alternativa descartada:** repetir el comando en cada `design.md` — se desactualiza.

### D4. Tests primero en `tasks.md`
Propose genera un grupo de tareas de tests antes de las de implementación: primero las de caracterización (`Cxx`, correr en verde antes de modificar), después las de escenarios (`Sxx`). Cada tarea nombra sus IDs y el comando. No se exige ver los tests en rojo ni se controla el orden en el historial de git: alcanza con el orden de las tareas, que el Agente sigue.
**Alternativa descartada:** controlar en el verify que el commit de tests preceda al de implementación — rígido y fácil de romper con commits mezclados.

### D5. Qué cuenta como "modifica código existente"
`git diff --diff-filter=M --name-only <principal>...HEAD`, excluyendo `openspec/`, `docs/`, `*.md`, las carpetas de tests y las rutas de `excluir`. La rama principal se toma de `origin/HEAD` (`main` o `master`). Si queda algún archivo: suite completa + control de `Cxx` por archivo. El control de caracterización es por archivo (objetivo, CRITICAL); si una función modificada dentro del archivo no parece cubierta, es WARNING (juicio de la lectura del diff).
**Por qué por archivo y no por símbolo:** detectar funciones o variables modificadas de forma confiable en cualquier lenguaje no es viable en una skill; el archivo es el nivel objetivo.

### D6. Suite completa comparada contra la rama principal
Se corre el mismo comando en la rama del change y en un worktree temporal de la rama principal (en el scratchpad o `%TEMP%`, fuera del repo, borrado al terminar). Se comparan los resultados por nombre de test: pasa en principal y falla en rama → CRITICAL; falla en ambas → WARNING. Si hay `comando-rapido`, se usa ese y el reporte lo avisa.

### D7. Nueva estructura del verify
1. Si no hay `## Test Plan` → método anterior, con aviso (compatibilidad).
2. Completitud: checkboxes de `tasks.md` (incluye las tareas manuales).
3. Ejecución: comando de tests; IDs automáticos buscados por marcador; suite completa según D5/D6.
4. Contenido de los tests: cada test contra el THEN de su escenario (WARNING si no lo comprueba o si mockea lo que tiene que probar).
5. Diseño y seguridad: lectura del diff y de los archivos que toca.
6. Reporte: se agrega una tabla `ID | Tipo | Resultado` y el porcentaje manual; el resto del formato (CRITICAL/WARNING/SUGGESTION, scorecard, vault) se mantiene.

### D8. La regla viaja al Agente por tres vías
`tasks.md` (siempre), plantillas `templates/copilot-instructions.md` y `templates/GEMINI.md`, y una regla en el `CLAUDE.md` global (el Agente la lee en el espejo `_global/reglas-globales.md` del vault). Orden al modificar el `CLAUDE.md`: editar `~/.claude/CLAUDE.md` → sincronizar el espejo → copiar a `.claude/CLAUDE.md` del repo (regla global vigente).

## Security Layer

`project_type: tooling` — los artefactos modificados son instrucciones para IA:
- **Ejecución de comandos:** el verify pasa a ejecutar código del proyecto. Se acota a los comandos literales de `## Tests`, con tiempo máximo, nunca comandos derivados de la salida de los tests o del repo (evita que un test o un archivo del repo induzca a ejecutar otra cosa).
- **Entorno:** si `entorno` declara requisitos no disponibles, el verify no improvisa (no levanta servicios por su cuenta ni usa `.env` de producción): reporta CRITICAL "no se pudo ejecutar".
- **Worktree temporal:** fuera del repo, borrado al terminar; no se hace checkout en el working tree del usuario.
- **Datos sensibles:** el reporte y el vault guardan solo nombres de tests, IDs y una línea de motivo; nunca trazas completas (pueden tener datos de base, rutas o variables de entorno).
- **Sin secrets ni rutas absolutas:** los cambios a skills, comandos, plantillas y `CLAUDE.md` no agregan rutas con usuario local ni valores sensibles; las rutas de ejemplo usan `~/.claude/`, `$env:OBSIDIAN_VAULT` o placeholders.
- **Commits:** el cambio al `CLAUDE.md` global va en commit separado con descripción del impacto (regla `tooling/config`).

## Impacto en proyectos existentes

- **Changes en curso** (por ejemplo, `patentamientos-etl-multiformato`): no tienen `## Test Plan` → el verify usa el método anterior con aviso. Se les puede agregar el Test Plan a mano si se quiere el verify nuevo.
- **Primer propose en cada proyecto:** va a preguntar la subsección `## Tests` una vez. Proyectos que no pueden tener tests responden `ninguno`.
- **Proyectos sin infraestructura de tests:** su primer change con tests suma una tarea para armarla (más trabajo en ese change).
- **Agente:** las plantillas cambian; los proyectos que ya copiaron `copilot-instructions.md` necesitan actualizar su copia (`.github/copilot-instructions.md`) para tener la regla — la vía `tasks.md` funciona igual sin esa actualización.
- **Este repo:** su `config.yaml` suma `## Tests` con `comando: ninguno`.
- **Retrocompatibilidad del CLI:** sin cambios al schema; solo se usa `context:`.

## Migration Plan

1. Implementar propose (skill + comando), verify (skill + comando), reglas del Agente y documentación.
2. Instalar en `~/.claude/skills` y `~/.claude/commands/opsx`, sincronizar el espejo del `CLAUDE.md` en el vault.
3. Probar con el repo de prueba descartable (P1–P3 del Test Plan) y con un verify de un change sin Test Plan (P4).
Rollback: revertir los commits del change y reinstalar las skills y comandos anteriores desde `master`; los `## Tests` ya agregados a los `config.yaml` de los proyectos son inofensivos (el CLI los inyecta como texto) y pueden quedar.

## Risks / Trade-offs

- **[Riesgo] El Agente escribe tests débiles que pasan siempre** → D4 (tests primero, desde la spec) y la revisión de contenido del verify (WARNING por test sin afirmaciones o con mocks de lo que prueba).
- **[Riesgo] Falsos CRITICAL por entorno** (Windows, dependencias, Docker) → el motivo queda en el reporte; `entorno` en `## Tests` documenta qué hace falta; se corrige el entorno, no se rebaja el control.
- **[Riesgo] Verify más lento** (suite en dos ramas) → solo cuando el change modifica código existente; `comando-rapido` como salida para suites lentas.
- **[Trade-off] Control de caracterización por archivo, no por función** → objetivo y portable entre lenguajes; la cobertura fina queda como WARNING por lectura.
- **[Riesgo] Uso de `manual` para zafar** → motivo obligatorio y WARNING por encima del 50% en proyectos con tests.
- **[Trade-off] Más tareas por change** → es el costo de tener verificación real; la infraestructura se arma una sola vez por proyecto.

## Test Plan

Comando de tests: `ninguno` — este repo no tiene tests automáticos (sus artefactos son instrucciones en Markdown para IA), así que todo el plan es manual. Se verifica con procedimientos sobre un repo de prueba descartable y sobre proyectos reales, que el grupo 8 de tareas ejecuta:

- **P1 — Propose de prueba.** Crear un repo git descartable fuera de los proyectos (en `%TEMP%`), con un módulo Python chico, un archivo de tests con pytest y `openspec init`, sin `## Tests` en su `config.yaml`. Correr `/opsx:propose` de un change chico que agregue una función nueva y modifique una existente. Revisar `config.yaml`, `design.md` y `tasks.md` generados.
- **P2 — Verify que ejecuta.** Sobre el repo de P1, implementar a mano el change con sus tests y marcadores y correr `/opsx:verify` en estas variantes: todo en verde; un test del plan fallando; un marcador borrado; un test sin afirmaciones; un test viejo roto por el change (regresión); un test que ya fallaba en la rama principal; `entorno` declarado y no disponible; `comando-rapido` declarado; salida de un test que sugiere otro comando.
- **P3 — Proyecto sin tests.** En el repo de P1, cambiar `## Tests` a `comando: ninguno`, hacer propose y verify de un change con todo manual.
- **P4 — Change sin Test Plan.** Correr `/opsx:verify` sobre un change creado antes de esta regla (por ejemplo, `patentamientos-etl-multiformato` en PLANEAMIENTO) sin modificarlo.
- **P5 — Lectura de reglas.** Leer `templates/copilot-instructions.md`, `templates/GEMINI.md`, `~/.claude/CLAUDE.md` y el espejo del vault.

| ID | Requirement / Escenario | Verificación |
|---|---|---|
| S01 | Subsecciones estructuradas / Proyecto sin subsecciones previas | manual: sin tests en este repo — P1 (el `config.yaml` sin subsecciones recibe `## Tests` al final, resto intacto) |
| S02 | Subsecciones estructuradas / Proyecto con subsecciones ya presentes | manual: P1 con un `config.yaml` que ya tenga `## Glosario` — solo se agrega `## Tests` |
| S03 | Formato de cada subsección / Formato consistente | manual: P1 — revisar formato `- clave: valor` |
| S04 | Formato de cada subsección / Subsección Tests con las claves fijas | manual: P1 — claves `comando` y `timeout` presentes, ninguna clave ajena |
| S05 | Formato de cada subsección / Proyecto sin tests automáticos | manual: P3 — `comando: ninguno` y sin volver a preguntar en un segundo propose |
| S06 | Test Plan por escenario / Change con escenarios testeables | manual: P1 — `## Test Plan` con una fila por escenario y el comando |
| S07 | Test Plan por escenario / Escenario sin forma de testearse | manual: P1 con un escenario de UI — fila `manual` con motivo y pasos |
| S08 | Test Plan por escenario / Proyecto sin subsección Tests | manual: P1 — pregunta una sola vez y escribe `## Tests` antes del plan |
| S09 | Marcador de ID / Test movido o renombrado | manual: P2 — test con otro nombre y marcador correcto, sin issue |
| S10 | Marcador de ID / Test sin marcador | manual: P2 — marcador borrado → CRITICAL "sin test" |
| S11 | Tests primero / Orden de las tareas | manual: P1 — tareas de tests antes que las de implementación, con IDs y comando |
| S12 | Tests primero / Proyecto sin infraestructura de tests | manual: P1 en variante sin carpeta de tests — primera tarea la arma y el proposal lo menciona |
| S13 | Caracterización / Change que mueve funciones existentes | manual: P1 — `Cxx` para el archivo modificado, antes de la tarea que lo modifica |
| S14 | Caracterización / Cambio de comportamiento intencional | manual: P1 con un cambio de comportamiento pedido — el `Cxx` lo explica, o lo deja afuera indicándolo en "Cambio intencional" con el `Sxx` que lo cubre |
| S15 | Verify ejecuta / Todos los tests del plan pasan | manual: P2 variante en verde |
| S16 | Verify ejecuta / Un test del plan falla | manual: P2 variante con test fallando |
| S17 | Verify ejecuta / Entorno de test no disponible | manual: P2 variante con `entorno` no disponible |
| S18 | Suite completa / Change que solo agrega archivos | manual: P2 con un change que solo agrega archivos — corre solo los tests del plan |
| S19 | Suite completa / Regresión fuera del diff | manual: P2 variante con regresión |
| S20 | Suite completa / Test que ya fallaba | manual: P2 variante con test roto en la principal |
| S21 | Suite completa / Archivo existente modificado sin caracterización | manual: P2 quitando el `Cxx` del plan |
| S22 | Suite completa / Suite lenta | manual: P2 variante con `comando-rapido` |
| S23 | Revisión de los tests / Test que no prueba el escenario | manual: P2 variante con test sin afirmaciones |
| S24 | Revisión de los tests / Revisión de diseño sobre el diff | manual: P2 — el verify lee solo el diff y sus archivos |
| S25 | Manual justificada / Escenario manual sin motivo | manual: P2 con una fila `manual` sin motivo |
| S26 | Manual justificada / Demasiados escenarios manuales | manual: P2 con más del 50% manual y comando declarado |
| S27 | Manual justificada / Proyecto sin tests automáticos | manual: P3 |
| S28 | Seguridad / Salida de tests con un comando sugerido | manual: P2 variante con salida que sugiere un comando |
| S29 | Seguridad / Reporte sin logs | manual: P2 variante con traza larga — reporte y vault sin la traza |
| S30 | Compatibilidad / Change creado antes de la regla | manual: P4 |
| S31 | Regla para el Agente / Test en rojo al terminar la tarea | manual: P5 — la regla está en las tres fuentes |
| S32 | Subsecciones estructuradas / Proyecto sin config.yaml | manual: P1 en variante sin `openspec/config.yaml` (lo que deja `openspec init` en 1.4.1) — el propose lo crea con `schema`, `project_type` y `context:` antes de `## Tests` |
| S33 | Subsecciones estructuradas / config.yaml sin context activo ni project_type | manual: P1 en variante con el `config.yaml` que genera `openspec init` en 1.14.x — se agregan `project_type` y `context:` en una sola pregunta junto con `## Tests`, comentarios intactos |
| S34 | Formato de cada subsección / Claves opcionales no declaradas | manual: P1 en frío — `## Tests` sin `comando-rapido`, `entorno` ni `excluir` de relleno; la pregunta muestra `<n> min` |
| S35 | Subsecciones estructuradas / Usuario que no sabe el tipo de proyecto | manual: P1 en frío respondiendo "no sé" — `project_type` deducido con `# inferido — revisar` y mencionado en el resumen |
| S36 | Subsecciones estructuradas / Usuario que no sabe cómo se corren los tests | manual: P1 en frío respondiendo "no sé" en un repo con pytest — `comando` deducido y mencionado como inferido; variante sin tests detectables — no se escribe `## Tests` |

No hay tests de caracterización: el change no modifica código (solo Markdown).

## Open Questions

Sin preguntas abiertas.
