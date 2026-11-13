# Design

## Context

- **Regla 1 vigente** (`templates/fuente/fragmentos/reglas-ejecucion.md`, primera línea): "Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (…), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra." No hay una marca fija para identificar esas tareas: cada propose las redacta a su manera. En `aviso-proyecto-atrasado`, por ejemplo, la 5.3 decía "M01 (manual, LO CORRE EL USUARIO: no la simules ni la marques vos)".
- **Qué pasó:** el Agente marcó la 5.3 en `[x]` con la nota "Ejecutado por solicitud explícita del usuario" y como evidencia pegó una corrida manual del script, no la sesión real que pedía la M01. El verify actual (`skills/openspec-verify-change/SKILL.md`, paso 6 y "Task Completion" del método legacy) solo cuenta casillas y contrasta cada `[x]` con la nota del apply. Una tarea del usuario marcada por el Agente con alguna salida pegada pasa ese control.
- **Generación:** las cuatro plantillas de reglas, el bloque de reglas de `.claude/CLAUDE.md` y los comandos `.claude/commands/opsx/*.md` se generan con `scripts/generar-plantillas.ps1` desde `templates/fuente/` y `skills/`. El CI los compara con `-Comprobar`.

## Goals / Non-Goals

**Goals:**
- Que las tareas del usuario se reconozcan por una marca fija en `tasks.md`.
- Que el Agente no las marque aunque se lo pidan, y que el verify no las dé por hechas sin que el usuario lo confirme.

**Non-Goals:**
- El flujo ODD, los changes ya archivados, la detección por inferencia de tareas sin la marca y los bloqueos técnicos (ver proposal).

## Decisions

### D1. Regla 1 de ejecución del Agente

En `templates/fuente/fragmentos/reglas-ejecucion.md`, al final de la regla 1 (después de "…y en el resumen le pedís al usuario que la corra."), se agrega esta oración, sin tocar el resto:

"Esas tareas llevan la marca `(lo corre el usuario)` en `tasks.md`: aunque el usuario te pida correrla, queda `[ ]`; si corriste algo, lo pegás en el resumen como "evidencia para que confirme el usuario"."


- **Alternativas descartadas:**
  - *Una regla 9 nueva:* las plantillas y el `CLAUDE.md` dicen "8 reglas" en varios lugares, y el tema es de la regla 1.
  - *Una marca en inglés o en mayúsculas ("USER-RUN"):* el resto del `tasks.md` está en castellano, y en este change el verify igual compara sin distinguir mayúsculas.

### D2. Marca en el propose

En `skills/openspec-propose/SKILL.md`, en la guía "For `tasks.md`" (la viñeta que empieza con "group test tasks before implementation tasks"), se agrega al final esta oración:

"Write the literal marker `(lo corre el usuario)` right after the ID of every manual task that needs the user (a real Claude Code or Agent session, another project, another machine or the user's own credentials), and state in the task that it stays `[ ]` until the user confirms it in the verify."

Después se regenera `.claude/commands/opsx/propose.md` con `pwsh scripts/generar-plantillas.ps1`.

### D3. Control en el verify

En `skills/openspec-verify-change/SKILL.md` se agrega la misma viñeta en dos lugares: en el paso 6 ("Verify Completeness (Tasks and Manual)"), después de "Add WARNING for any `manual` row…", y en "Task Completion" del método legacy, después de "Recommendation: "Complete task: <description>"…". El texto es:

"- **Tareas del usuario**: for each task containing `(lo corre el usuario)` (case-insensitive): if it is `[x]`, ask the user with **AskUserQuestion** "¿Corriste vos <ID> y la evidencia es tuya?" with options "Sí, la corrí yo" and "No". "Sí, la corrí yo" is noted in the report and replaces the evidence check of the apply summary for that task. "No", or a session without an interactive interface (even if the request includes a written answer), is CRITICAL "tarea del usuario sin confirmar" with the ID and the recommendation that the user runs the steps and pastes the output. If it is `[ ]`, it stays CRITICAL as an incomplete task; if the user pastes the output of its steps during the verify, mark it `[x]` in `tasks.md` and state in the report that the evidence was provided by the user in the verify. Tasks without the marker are checked as before."

Además, en las dos listas de CRITICAL de "Issues by Priority" (el párrafo del método con Test Plan que empieza "Include CRITICAL for incomplete tasks" y la lista "CRITICAL (Must fix before archive)" del método legacy) se suma "user tasks `(lo corre el usuario)` not confirmed by the user ("tarea del usuario sin confirmar")". Después se regenera `.claude/commands/opsx/verify.md`.

- **Alternativas descartadas:**
  - *CRITICAL automático para todo `[x]` con la marca:* rechazaría también una tarea que el usuario corrió y marcó él mismo.
  - *Pedir una sección "Evidencia del usuario" firmada en la nota del apply:* la nota la escribe el Agente, así que no prueba quién corrió la tarea.

## Impacto en proyectos existentes

- Los `tasks.md` de changes en curso no cambian. Sus tareas del usuario sin la marca se controlan como hasta ahora (non-goal).
- Los proyectos reciben la regla 1 nueva al correr `sincronizar-proyecto.ps1`. Hasta entonces, `-Aviso` (si ya está mergeado `aviso-proyecto-atrasado`) los muestra atrasados.
- Claude recibe el propose y el verify nuevos en cada máquina con `pwsh scripts/instalar.ps1`.
- Retrocompatible: un proyecto con plantillas viejas sigue funcionando. Solo le falta la oración nueva de la regla 1.

## Impacto en el sistema

**Componentes afectados:** las reglas del Agente de todos los proyectos (al sincronizar), el bloque de reglas de `.claude/CLAUDE.md` y su espejo en el vault (al instalar), y los comandos `/opsx:propose` y `/opsx:verify` de Claude en todas las máquinas.

**Atributos de calidad:**
- mantenibilidad (alta): el cambio se hace solo en las fuentes (`templates/fuente/fragmentos/reglas-ejecucion.md` y las dos skills) y lo generado se regenera con el script — Verificación: S09 (`generar-plantillas.ps1 -Comprobar` con código 0) y revisión del diff: los archivos generados cambian solo en las oraciones de D1, D2 y D3.

**Decisiones de arquitectura:** ninguna. No cambia el stack, el nivel ni las integraciones, y no adopta un patrón transversal.

**Deuda técnica:**
- descubre: el flujo ODD no tiene un control equivalente para criterios de aceptación que corre el usuario. Va a la hoja de ruta como baja.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/tareas-del-usuario-sin-marcar.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- Las instrucciones nuevas no exponen secrets ni rutas absolutas con el usuario — Verificación: revisión del diff: ninguna ruta `C:\Users…` ni token en las líneas agregadas fuera de `openspec/`.
- Los cambios al `CLAUDE.md` global y a las skills van en commits separados con una línea de impacto — Verificación: revisión del diff: un commit para D1 (fuente, plantillas y `CLAUDE.md`), uno para D2 y uno para D3, cada uno con la línea "Impacto:".
- La confirmación del usuario no se puede dar por escrito en una corrida sin interfaz — Verificación: S05.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian archivos que se generan y se controlan en el CI. Cada test lleva `# test-plan: tareas-del-usuario-sin-marcar/<ID>` arriba del `Probar`. Los tests leen los archivos del repo. No usan proyectos reales ni datos personales.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Marca de tareas del usuario en el propose / Marca en las tareas del usuario | auto: `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md` contienen la oración de D2 | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S02 | Control de tareas del usuario en el verify / Tarea del usuario marcada y confirmada | auto: la viñeta de D3 está en el paso 6 y en "Task Completion" de la skill y del comando, con la pregunta y la opción "Sí, la corrí yo" | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S03 | Control de tareas del usuario en el verify / Tarea del usuario marcada por el Agente | auto: la skill y el comando contienen "tarea del usuario sin confirmar" en la viñeta y en las dos listas de CRITICAL | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S04 | Control de tareas del usuario en el verify / Evidencia del usuario en el verify | auto: la viñeta dice que se marca `[x]` y que el reporte dice que la evidencia la entregó el usuario en el verify | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S05 | Control de tareas del usuario en el verify / Verify sin interfaz interactiva | auto: la viñeta dice "without an interactive interface (even if the request includes a written answer)" | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S06 | Control de tareas del usuario en el verify / Dato inválido: marca escrita de otra forma | auto: la viñeta dice "case-insensitive" y "Tasks without the marker are checked as before" | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S07 | Regla 1 con tareas del usuario / Regla en la fuente y en lo generado | auto: `(lo corre el usuario)` aparece en la regla 1 de la fuente, de las cuatro plantillas y de `.claude/CLAUDE.md` | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S08 | Regla 1 con tareas del usuario / Pedido del usuario | auto: la regla 1 de la fuente contiene "aunque el usuario te pida correrla, queda `[ ]`" y "evidencia para que confirme el usuario" | `tests/tareas-del-usuario-sin-marcar.Tests.ps1` |
| S09 | Regla 1 con tareas del usuario / Plantillas regeneradas | auto: control `generar-plantillas.ps1 -Comprobar` que ya corre `tests/ejecutar.ps1` | `tests/ejecutar.ps1` (existente) |
| M01 | Las tareas del usuario en un change real | manual (lo corre el usuario): después de `pwsh scripts/instalar.ps1`, en un repo descartable con un change de prueba que tenga una tarea `(lo corre el usuario)`, pedirle al Agente que la corra y ver que la deja `[ ]`; marcarla `[x]` a mano, correr `/opsx:verify` en Claude Code, contestar "No" a la pregunta y ver el CRITICAL "tarea del usuario sin confirmar". Pegar las dos salidas | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `templates/fuente/fragmentos/reglas-ejecucion.md`, `skills/openspec-propose/SKILL.md` y `skills/openspec-verify-change/SKILL.md` (con `tests/generar-plantillas.Tests.ps1`, `tests/generar-comandos.Tests.ps1` y los controles del CI de `tests/ejecutar.ps1`) | Generación de plantillas, bloque de reglas y comandos desde las fuentes | Suma las oraciones de D1, D2 y D3 (S01 a S09). La generación no cambia y esos tests no se modifican |

## Open Questions

- Ninguna.
