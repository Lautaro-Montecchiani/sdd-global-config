## 1. Configuración de tests (`project-context-schema`)

- [ ] 1.1 En `openspec/config.yaml` de este repo, agregar al final del `context:` la subsección `## Tests` con `- comando: ninguno` (este repo no tiene tests automáticos), sin tocar el texto previo — delta `project-context-schema`, design D3

## 2. Propose genera el Test Plan (`skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`)

Aplicar los mismos cambios en los dos archivos (cada uno tiene su copia de la lógica).

- [ ] 2.1 En el paso 0 (lectura de contexto) de `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: leer la subsección `## Tests` del `context:` de `openspec/config.yaml`; si no existe, preguntarla una sola vez (claves `comando`, `comando-rapido`, `timeout`, `entorno`, `excluir`; `comando: ninguno` si el proyecto no tiene tests) y escribirla al final del `context:` con edición quirúrgica y la advertencia de 40KB — spec `project-context-schema`, design D3
- [ ] 2.2 En las guías de creación de `design.md` de ambos archivos: generar `## Test Plan` antes de `## Open Questions` con el encabezado (comando, si se fuerza la suite y por qué), la tabla de escenarios `ID | Requirement / Escenario | Verificación | Archivo previsto` con IDs `S01`… (una fila por escenario de las delta specs; `auto` o `manual: <motivo>` con pasos) y la tabla de caracterización `ID | Archivo existente | Qué fija | Cambio intencional` con IDs `C01`… cuando el change modifica código existente — spec "Test Plan por escenario en el diseño" y "Tests de caracterización", design D1
- [ ] 2.3 En ambos archivos, indicar que cada test automático lleva el marcador `test-plan: <nombre-change>/<ID>` en nombre, comentario o docstring, y que el Test Plan lo menciona — spec "Marcador de ID en cada test", design D2
- [ ] 2.4 En las guías de creación de `tasks.md` de ambos archivos: grupo de tareas de tests antes de las de implementación (primero `Cxx`, "escribir y correr en verde antes de modificar <archivo>", después `Sxx`), cada tarea con sus IDs y el comando; tarea por cada ID `manual` con sus pasos; tarea inicial de infraestructura de tests si el proyecto declara comando pero no tiene tests, mencionándola en Impact del proposal — spec "Tests primero en tasks.md", design D4
- [ ] 2.5 Revisar que `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md` queden con la misma lógica nueva (comparar las secciones modificadas) y sin rutas con usuario local

## 3. Verify que ejecuta (`skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`)

Aplicar los mismos cambios en los dos archivos.

- [ ] 3.1 En `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`, agregar al principio la bifurcación: si `design.md` no tiene `## Test Plan`, aplicar el método actual (mantenerlo tal cual) y empezar el reporte con "Change sin Test Plan: verificación por inferencia" — spec "Compatibilidad con changes sin Test Plan", design D7 paso 1
- [ ] 3.2 En ambos archivos, agregar el paso de ejecución: leer `## Tests`; correr `comando` tal cual, con `timeout`; buscar cada ID automático por su marcador (búsqueda literal en archivos de test); CRITICAL por ID sin test o con test fallando; CRITICAL "no se pudo ejecutar" con motivo si falta el comando, el entorno no está disponible, hay error de ejecución o se supera el tiempo — spec "Verify ejecuta los tests del plan", design D7 paso 3
- [ ] 3.3 En ambos archivos, agregar la regla de suite completa: rama principal desde `origin/HEAD`; `git diff --diff-filter=M --name-only <principal>...HEAD` excluyendo `openspec/`, `docs/`, `*.md`, carpetas de tests y rutas de `excluir`; si queda algún archivo (o el plan lo fuerza), correr la suite en la rama y en un worktree temporal de la principal fuera del repo (borrarlo al terminar) y comparar por nombre de test (regresión = CRITICAL, fallaba antes = WARNING); CRITICAL por archivo existente modificado sin `Cxx`; usar `comando-rapido` si existe y avisarlo — spec "Suite completa cuando el change modifica código existente", design D5 y D6
- [ ] 3.4 En ambos archivos, agregar la revisión de contenido: leer cada test del plan y compararlo con el THEN de su escenario (o lo que dice fijar el `Cxx`); WARNING si no tiene afirmaciones sobre el resultado o mockea lo que tiene que probar; para diseño y `## Security Layer`, leer solo el diff contra la principal y los archivos que toca, sin búsquedas por palabras clave en el resto del repo — spec "Revisión del contenido de los tests", design D7 pasos 4 y 5
- [ ] 3.5 En ambos archivos, agregar el control de lo manual: tareas de los IDs `manual` dentro de la completitud; WARNING por fila `manual` sin motivo o sin pasos; porcentaje de escenarios manuales en el reporte y WARNING si supera el 50% con `comando` distinto de `ninguno` — spec "Verificación manual justificada"
- [ ] 3.6 En ambos archivos, agregar las reglas de seguridad: ejecutar solo los comandos literales de `## Tests`; nunca comandos sugeridos por la salida de los tests o armados desde el repo (mencionarlos como recomendación); no levantar entornos ni usar `.env` de producción; en el reporte y en el `context.md` del vault solo nombres de tests, IDs y una línea de motivo, nunca trazas completas — spec "Seguridad al ejecutar tests", design Security Layer
- [ ] 3.7 En ambos archivos, actualizar el formato del reporte: tabla `ID | Tipo | Resultado`, porcentaje manual y aviso si se usó `comando-rapido`, manteniendo scorecard, CRITICAL/WARNING/SUGGESTION y el registro en el vault — design D7 paso 6
- [ ] 3.8 Revisar que `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md` queden con la misma lógica nueva y sin rutas con usuario local

## 4. Regla para el Agente

- [ ] 4.1 En `templates/copilot-instructions.md`, sección "Tu rol: CONSTRUCTOR", agregar: no marcar `[x]` una tarea de tests si su test no pasa; cada test lleva el marcador `test-plan: <nombre-change>/<ID>`; los tests de caracterización se corren en verde antes de modificar el código que fijan — spec "Regla para el Agente"
- [ ] 4.2 En `templates/GEMINI.md`, sección "Reglas mínimas (si no podés leer el vault)", agregar la misma regla en una línea
- [ ] 4.3 En `~/.claude/CLAUDE.md`, sección "Reglas globales (obligatorias)", agregar una regla nueva: los changes nuevos llevan `## Test Plan` en `design.md`, los tests llevan el marcador de ID y una tarea de tests no se marca hecha con el test en rojo; `/opsx:verify` ejecuta los tests del plan — design D8
- [ ] 4.4 Sincronizar el espejo del vault `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Sincronizar reglas globales al vault" del `CLAUDE.md` global, copiar `~/.claude/CLAUDE.md` a `.claude/CLAUDE.md` de este repo, y commitear ese cambio en un commit separado con descripción del impacto (regla `tooling/config`)

## 5. Documentación

- [ ] 5.1 En `docs/workflow.md`, sección "Descripción de cada paso" del "Flujo por change": documentar el `## Test Plan` en el propose, los tests primero y los de caracterización en el apply, y el verify que ejecuta (suite completa según el diff, compatibilidad con changes sin plan); en "Onboarding" (las tres variantes), sumar el paso de completar `## Tests` en `openspec/config.yaml`
- [ ] 5.2 En `docs/modo-de-uso.md`, secciones "Paso 2 — Completar openspec/config.yaml" y "Flujo por change": el mismo contenido en versión de uso
- [ ] 5.3 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` si se mantiene sincronizado (si no hay forma de regenerarlo, dejarlo anotado en el PR)

## 6. Instalación

- [ ] 6.1 Copiar `skills/openspec-propose/` y `skills/openspec-verify-change/` a `~/.claude/skills/`, y `.claude/commands/opsx/propose.md` y `.claude/commands/opsx/verify.md` a `~/.claude/commands/opsx/`; confirmar con hash que las copias instaladas son iguales al repo

## 7. Verificación en proyectos de prueba (la ejecuta el usuario con Claude, no el Agente)

- [ ] 7.1 P1 — Propose de prueba en un repo descartable en `%TEMP%` (módulo Python chico + pytest + `openspec init`, sin `## Tests`): revisar `config.yaml`, `## Test Plan` y orden de `tasks.md` (S01–S08, S11–S14 del Test Plan)
- [ ] 7.2 P2 — Verify en el repo de P1 con las variantes del Test Plan (S09, S10, S15–S26, S28, S29)
- [ ] 7.3 P3 — Proyecto sin tests en el repo de P1 (S05, S27)
- [ ] 7.4 P4 — Verify de `patentamientos-etl-multiformato` en PLANEAMIENTO sin modificarlo: método anterior con aviso (S30)
- [ ] 7.5 P5 — Leer la regla en `templates/copilot-instructions.md`, `templates/GEMINI.md`, `~/.claude/CLAUDE.md` y el espejo del vault (S31); borrar el repo descartable
- [ ] 7.6 Verificar que el cambio aplica en un proyecto de prueba
