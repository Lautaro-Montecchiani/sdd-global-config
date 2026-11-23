# Design

## Context

`.claude/CLAUDE.md` tiene 580 líneas y unas 7.300 palabras. Claude lo carga en cada sesión de cada proyecto: directo, o a través del espejo `_global/reglas-globales.md` que importa `~/.claude/CLAUDE.md`. Medido por sección: Persistencia Obsidian, unas 1.290 palabras; reglas de delegación, unas 914; clasificación ODD / SDD, unas 803; arquitectura, unas 626.

Al revisar qué se puede mover se encontró esto:
- Los tests vigentes piden frases exactas del `CLAUDE.md`: las filas K1 a K10, `### Métricas` con las cinco métricas, `### Cadencias`, `retros\` y `/retro` en "Cuándo actuar", `tablero.md` en la estructura del vault, la viñeta "Mejoras a archivos generados", `### Fuente de las reglas: repo `sdd-global-config``, la línea D1 de arquitectura, el ítem "Comprobar el proyecto", `### Tablero`, `### WIP`, `### Pull Requests` y la puerta de integración.
- Las specs vigentes piden que el `CLAUDE.md` tenga la tabla "Estructura sugerida por tipo de proyecto" (`project-architecture`), la estructura del vault (`project-onboarding`), `## Scrumban` con sus subsecciones (`scrumban-board`), "Pull Requests" (`change-archive`, `integration-gate`) y el rol de arquitecto (`software-architect-role`). Además, `openspec-propose` lee del `CLAUDE.md` la fila sugerida para el `project_type`.
- Lo que sí se puede sacar ya está en su destino o lo usa una sola skill:
  - "Flujo ODD resumido" y "Escalado a SDD" están completos en `skills/odd-change/SKILL.md` (líneas 296 a 299 para el escalado).
  - La tabla de "Escalera de niveles" está en `skills/arquitectura/references/recetas.md` (líneas 5 a 10), con las **Señales** de cada nivel.
  - Los cuatro ejemplos YAML de la ficha están en `skills/ficha/SKILL.md` (líneas 30, 38, 47 y 56).
  - "Flujo OpenSpec" y "Modo OpenSpec" repiten la misma tabla y casi las mismas reglas.
  - Los "Comandos PowerShell" no están en ninguna skill: cada skill describe sus escrituras con sus propias palabras. Hoy no tienen otro lugar.
  - El detalle de la protección del espejo no está en el README.

## Goals / Non-Goals

**Goals:**
- Sacar del `CLAUDE.md` el detalle operativo que ya tiene otro lugar o que lo necesita, sin perder ninguna regla.
- Dejar escrita la regla que evita que el archivo vuelva a crecer.

**Non-Goals:**
- Cambiar reglas o comportamiento.
- Tocar el bloque generado de las reglas del Agente o las secciones que piden los tests y specs vigentes (ver Context).
- Modificar tests existentes.
- Llegar a las 4.000 palabras: con lo que exigen los tests y specs, el resultado ronda las 6.400.

## Decisions

### D1. Una sola sección "Modo OpenSpec"

Reemplazar la sección `## Flujo OpenSpec (cuando `openspec` CLI está disponible)`, desde su título hasta la línea anterior a `## Reglas de delegación al Agente`, por el texto de abajo, en el mismo lugar. Borrar la sección `## Modo OpenSpec (cuando `openspec` CLI está disponible)` que está después de `## Al iniciar cada sesión`, desde su título hasta la línea anterior a `## Reglas de Git`.

Texto nuevo, que reemplaza a `## Flujo OpenSpec`:

    ## Modo OpenSpec (cuando `openspec` CLI está disponible)

    ```
    Claude  /opsx:propose  → crea proposal + design + specs + tasks
    Agente  /openspec-apply-change (Antigravity) o /opsx-apply (Cursor) → implementa, marca [x], commitea
    Claude  /opsx:verify   → valida implementación vs specs
    Claude  /opsx:archive  → en la rama: sincroniza specs, mueve change y genera SRS (antes del merge)
    Claude  /opsx:archive  → después del merge: cierre y notas en el vault
    ```

    Este flujo **reemplaza** al flujo manual de `specs/` y al patrón bash legacy (prompt bash directo al CLI del agente).

    | SDD Manual | OpenSpec |
    |---|---|
    | Artefactos en `specs/{feature}/` | Artefactos en `openspec/changes/{nombre}/` |
    | `spec.yaml + CLAUDE.md + Task.md + threat-model.md` | `proposal.md + design.md + specs/**/*.md + tasks.md` |
    | Prompt bash al Agente | El Agente corre `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor); en Claude, `/opsx:apply` anuncia el handoff |
    | `change-map.md` manual | `openspec list --json` |

    **Reglas:**
    - Correr `openspec status --change "{nombre}" --json` para entender el schema antes de crear archivos.
    - Crear los artefactos en `openspec/changes/{nombre}/` con el schema que indique el status.
    - Para implementar: invocar el skill `/opsx:apply`; no generar prompts bash manuales.
    - El directorio `specs/` legacy puede coexistir pero no se usa para changes nuevos.

(El bloque va con la sangría de 4 espacios solo en este design; en el `CLAUDE.md` va sin sangría.)

En `## Al iniciar cada sesión`, paso 1, cambiar `**usar Modo OpenSpec** (ver sección abajo)` por `**usar Modo OpenSpec** (ver la sección "Modo OpenSpec")`.

### D2. Flujo ODD y escalado

En `## Clasificación ODD / SDD`, reemplazar las subsecciones `### Flujo ODD resumido` y `### Escalado a SDD` (desde `### Flujo ODD resumido` hasta la línea anterior a `## Scrumban`) por:

    ### Flujo ODD y escalado

    Los pasos del flujo ODD (`/odd`, `/odd-apply` del Agente, PR con `/branch-pr`, `/odd:verify`, merge y `/odd:close`) y del escalado a SDD están en la skill `odd-change`. Valen siempre: el ODD vive en la rama `odd/<nombre>`; el Agente pega la evidencia en `## Evidencia` del documento y no escribe la nota `apply\` del vault; `/odd:close` se corre solo después del merge y no crea commits en el repo del proyecto. Si el Agente o `/odd:verify` encuentran un criterio SDD, el documento pasa a `estado: escalado` con el criterio y el motivo en `## Progreso`, la rama `odd/<nombre>` no se mergea, Claude ofrece `/opsx:propose <nombre>` con el documento ODD como entrada y `## Estado actual` de `context.md` pasa a "ODD `<nombre>` escalado a SDD".

### D3. Escalera de niveles

Reemplazar el contenido de `### Escalera de niveles` (la tabla y las dos líneas que la siguen, hasta la línea anterior a `### Responsabilidades por actor` de `## Arquitectura del proyecto`) por:

    Los niveles son `0`, `1-nucleo-funcional`, `2-tuberias`, `2-capas`, `3-hexagonal` y `3-modular`. Qué resuelve cada uno y cuándo subir (sus señales) están en `~/.claude/skills/arquitectura/references/recetas.md`.
    La guía para estudiar está en `docs/guia-arquitecturas.md` del repo `sdd-global-config`.

### D4. Ficha sin ejemplos

En `### Subsecciones` de `## Ficha del proyecto`, borrar los cuatro bloques ```` ```yaml ```` (de `## Alcance`, `## Datos`, `## Stack` y `## Calidad`) con sus líneas. El resto de las viñetas, la explicación de externo, propio, personal, interno y público, y la línea "¿Qué hace la aplicación?" quedan iguales. Agregar al final de `### Subsecciones`, antes de la línea "¿Qué hace la aplicación?":

    Los ejemplos de cada subsección están en la skill `/ficha`.

### D5. Reglas globales en el vault y fuente de las reglas

Reemplazar `### Reglas globales en el vault (`_global\`)` y `### Fuente de las reglas: repo `sdd-global-config`` (desde el primer título hasta la línea anterior a `### Formato de context.md`) por:

    ### Reglas globales en el vault (`_global\`)

    Las reglas globales se espejan en `$vault\_global\reglas-globales.md`, el archivo que leen Claude y el Agente sin depender de `~/.claude/`.

    - **Fuente única:** `.claude/CLAUDE.md` del repo `sdd-global-config`. Ninguna copia se edita a mano: ni el espejo ni `~/.claude/CLAUDE.md`.
    - **Escritura:** solo `scripts/instalar.ps1` escribe el espejo y `~/.claude/CLAUDE.md` (con vault, un archivo mínimo que importa el espejo con `@`; sin vault, la copia completa). Cómo protege el espejo (ediciones a mano, `-Forzar`, `commit:` y huella `instalacion:`) está en la sección "Espejo del vault" del README.
    - Si al iniciar sesión `instalar.ps1 -Comprobar` termina con error → avisar al usuario; no re-sincronizar a mano.
    - **Agentes no-Claude:** no cargan `~/.claude/`; leen las reglas desde las plantillas de `$env:SDD_CONFIG_REPO\templates\`. Un proyecto se suma con `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .` (y `-Agentes` si hace falta); el detalle está en el README.
    - **Mejoras a archivos generados:** <la viñeta actual, sin cambiar una letra>

    ### Fuente de las reglas: repo `sdd-global-config`

    Las reglas globales se editan solo en el repo `sdd-global-config`, en `.claude/CLAUDE.md` (ruta del repo en `$env:SDD_CONFIG_REPO`). Las 8 reglas de ejecución del Agente se editan en `templates/fuente/fragmentos/reglas-ejecucion.md` y se regeneran.

    - Todo cambio de reglas pasa por un change, su PR y el CI (regla de `tooling/config`).
    - El detalle operativo de un flujo (pasos, comandos y ejemplos) va en la skill que lo usa o en el README; el `CLAUDE.md` lleva las reglas y las tablas.
    - Si `$env:SDD_CONFIG_REPO` no está definida → pedir la ruta al usuario, no adivinarla.
    - Después del merge, en cada máquina: `git pull` y `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1`, que actualiza el espejo del vault y `~/.claude`. Máquina nueva: ver el setup del README.

En `README.md`, agregar antes de `## Plantillas del Agente` una sección `## Espejo del vault` con, tal cual, los textos que salen de las viñetas actuales "Carga en Claude" y "Escritura del espejo" y del párrafo "Onboarding de agentes no-Claude", más las líneas "En una máquina nueva" y "Orden completo ante un cambio de reglas" de la sección actual "Fuente de las reglas". Se pueden cambiar las referencias del tipo "este archivo" para que se entiendan desde el README, sin cambiar el sentido.

### D6. Comandos del vault al README

Reemplazar todo el contenido de `### Comandos PowerShell` (desde la línea después del título hasta el final del archivo) por:

    Cada skill trae sus pasos de lectura y escritura del vault. Los comandos PowerShell de referencia (leer el contexto, escribir las notas de decisions, archive y ODD, actualizar `context.md`, cambiar el estado de una nota, eliminar una nota y sincronizar las reglas) están en la sección "Comandos del vault" del README de `sdd-global-config`. Antes de cualquier operación, `$vault = $env:OBSIDIAN_VAULT`; si está vacía, no asumir ninguna ruta: omitir las operaciones de vault y avisarlo en el resumen.

En `README.md`, agregar al final una sección `## Comandos del vault` con el contenido actual de `### Comandos PowerShell` copiado tal cual (los subtítulos en negrita y los bloques `powershell`), precedido de la línea: "Comandos de referencia para leer y escribir el vault a mano. Las skills describen cada escritura en su propio paso."

### D7. Si un texto que sale no está en su destino

Antes de borrar cada bloque de D2 a D4, el Agente confirma que su contenido está en el destino: D2 en `skills/odd-change/SKILL.md`, D3 en `skills/arquitectura/references/recetas.md` y D4 en `skills/ficha/SKILL.md`. Si falta una oración, la copia tal cual al final de la sección que corresponda del destino y, si tocó una skill, corre `pwsh -NoProfile -File scripts/generar-plantillas.ps1` para regenerar los comandos. Lo anota en el resumen del apply.

## Risks / Trade-offs

- [Claude podría dejar de seguir un paso que antes leía en el `CLAUDE.md`] → Lo que sale ya está en la skill que lo ejecuta, y D7 cubre lo que falte. M01 lo prueba en una sesión real.
- [El ahorro es menor al esperado (unas 900 palabras)] → Las secciones que piden los tests y specs vigentes se quedan. Reducirlas más requiere otro change que modifique esas specs.
- [El README crece] → El README no se carga en las sesiones: lo leen las personas, o Claude cuando lo necesita.

## Migration Plan

1. Merge en `master`.
2. En cada máquina, `git pull` y `pwsh scripts/instalar.ps1`. El espejo y `~/.claude/CLAUDE.md` quedan con el texto nuevo, y la otra máquina ve `repo atrasado` hasta instalar.
3. Para volver atrás, se revierte el merge y se corre `instalar.ps1`.

## Impacto en proyectos existentes

Ningún proyecto tiene que hacer nada. Las reglas que valen en todos los proyectos no cambian, y las plantillas del Agente (`AGENTS.md` y las demás) no se tocan. Las sesiones de Claude en cada proyecto cargan unas 900 palabras menos.

## Impacto en el sistema

**Componentes afectados:** el espejo del vault (`_global/reglas-globales.md`) y `~/.claude/CLAUDE.md` en cada máquina, a través de `instalar.ps1`. Las skills `odd-change`, `ficha` y `arquitectura` solo cambian si D7 encuentra un texto que falta.

**Atributos de calidad:** mantenibilidad (alta): mejora. El detalle queda en un solo lugar, junto a la skill que lo usa, y la regla nueva de D5 evita que se duplique. — Verificación: S01 a S07 y revisión del diff: ningún texto borrado del `CLAUDE.md` sin su copia en el destino.

**Decisiones de arquitectura:** ninguna.

**Deuda técnica:** paga: #55 (detalle operativo en el `CLAUDE.md` global).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/claude-md-liviano.Tests.ps1` | `tests/` |

## Security Layer

`project_type: tooling`. Los artefactos que se modifican son instrucciones para IA.
- No exponer secrets ni rutas absolutas sensibles en `.claude/CLAUDE.md` ni en `README.md` — Verificación: revisión del diff: sin `C:\Users`, sin el nombre de la carpeta del usuario, sin tokens; las rutas van con `$env:OBSIDIAN_VAULT`, `$env:SDD_CONFIG_REPO` o `~`.
- Cambio al `CLAUDE.md` global en un commit separado con la descripción del impacto — Verificación: revisión del diff: el commit de D1 a D6 en `.claude/CLAUDE.md` lleva una línea "Impacto: …".
- Sin ejecución de texto leído (`Invoke-Expression`, `iex`) en el test nuevo — Verificación: revisión del diff.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (suite completa, timeout 5 min). Se corre la suite completa porque los tests vigentes son los que fijan las frases del `CLAUDE.md` que se tienen que quedar. Cada test nuevo lleva el marcador `# test-plan: claude-md-liviano/<ID>` arriba de su `Probar`, en `tests/claude-md-liviano.Tests.ps1`, con `. "$PSScriptRoot/apoyo.ps1"`. Los tests solo leen archivos del repo, y comparan con los saltos de línea normalizados a `\n`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Detalle operativo fuera del CLAUDE.md global / Una sola sección de OpenSpec | auto: un solo `## Modo OpenSpec (cuando `openspec` CLI está disponible)`, ningún `## Flujo OpenSpec`, y dentro de la sección `openspec status --change "{nombre}" --json`, `openspec/changes/{nombre}/`, `/opsx:apply` y `specs/` legacy | `tests/claude-md-liviano.Tests.ps1` |
| S02 | Detalle operativo fuera del CLAUDE.md global / Comandos del vault en el README | auto: el `CLAUDE.md` no tiene ```` ```powershell ```` y nombra "Comandos del vault"; el README tiene `## Comandos del vault` con `context.md`, `decisions\YYYY-MM-DD-{change}.md`, `archive\YYYY-MM-DD-{change}.md`, `AAAA-MM-DD-odd-{nombre}.md`, `'status: activo', 'status: archivado'`, `Remove-Item` e `instalar.ps1` | `tests/claude-md-liviano.Tests.ps1` |
| S03 | Detalle operativo fuera del CLAUDE.md global / Ejemplos de la ficha en la skill | auto: `## Ficha del proyecto` sin ```` ```yaml ````, con `## Alcance`, `## Datos`, `## Stack`, `## Calidad` y `/ficha`; `skills/ficha/SKILL.md` con `- versión: V1`, `- leads (nombre, teléfono, email): formulario web (externo) \| personal`, `- framework: FastAPI` y `- rendimiento: respuesta de la API < 500 ms p95 \| alta` | `tests/claude-md-liviano.Tests.ps1` |
| S04 | Detalle operativo fuera del CLAUDE.md global / Escalera en las recetas | auto: `### Escalera de niveles` (hasta el siguiente `###`) nombra los seis niveles y `recetas.md` y no tiene líneas que empiecen con `\|`; `recetas.md` tiene una fila `\| `<nivel>` \|` por cada nivel y `## <nivel>` con `**Señales**` para los cinco niveles desde `1-nucleo-funcional` | `tests/claude-md-liviano.Tests.ps1` |
| S05 | Detalle operativo fuera del CLAUDE.md global / Flujo ODD en la skill | auto: `## Clasificación ODD / SDD` sin `### Flujo ODD resumido` ni `### Escalado a SDD`, con `odd-change`, `odd/<nombre>`, `/odd:close`, `estado: escalado`, `no se mergea` y `/opsx:propose <nombre>`; `skills/odd-change/SKILL.md` con `estado: escalado`, `no se mergea`, ``ODD `<nombre>` escalado a SDD`` y `/opsx:propose <nombre>` | `tests/claude-md-liviano.Tests.ps1` |
| S06 | Detalle operativo fuera del CLAUDE.md global / Espejo del vault en el README | auto: el `CLAUDE.md` dice que solo `scripts/instalar.ps1` escribe el espejo y nombra "Espejo del vault"; el README tiene `## Espejo del vault` con `-Forzar`, `commit:` e `instalacion:` | `tests/claude-md-liviano.Tests.ps1` |
| S07 | El detalle operativo nuevo va en la skill o en el README / Regla de dónde va el detalle | auto: la sección `### Fuente de las reglas: repo `sdd-global-config`` (hasta el siguiente `###`) contiene `El detalle operativo de un flujo (pasos, comandos y ejemplos) va en la skill que lo usa o en el README` | `tests/claude-md-liviano.Tests.ps1` |
| M01 | Detalle operativo fuera del CLAUDE.md global (comportamiento en una sesión real) | manual (lo corre el usuario): en la rama del change, `pwsh scripts/instalar.ps1`; abrir una sesión nueva de Claude Code en otro proyecto con OpenSpec y comprobar que el inicio de sesión corre igual que antes (openspec list, vault, `-Comprobar` de reglas, tablero y retro). Después, preguntarle a Claude "¿qué pasos sigue un ODD si aparece un criterio SDD?" y confirmar que responde con el escalado (desde la skill `odd-change` o el `CLAUDE.md`). Al terminar, `git checkout master` y `pwsh scripts/instalar.ps1` | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `.claude/CLAUDE.md`, `README.md` (con la suite vigente) | La suite completa en verde antes de tocar nada: fija las frases del `CLAUDE.md` que piden los tests vigentes (K1 a K10, `### Métricas`, `### Cadencias`, "Cuándo actuar", estructura del vault, "Mejoras a archivos generados", `### Fuente de las reglas`, D1 de arquitectura, `### Tablero`, `### WIP`, "Pull Requests", puerta de integración, bloque de reglas del Agente) | Ninguno sobre esas frases: tienen que seguir en verde sin tocar los tests. Lo que sale del `CLAUDE.md` lo cubren S01 a S06 |

## Open Questions

Ninguna.
