## Context

`.claude/commands/` tiene nueve comandos que Claude Code ejecuta como `/opsx:*` y `/odd*`. Cada uno es una copia a mano de su skill de `skills/`, con otro frontmatter:

| Comando | Skill de origen | Qué incluye hoy |
|---|---|---|
| `opsx/apply.md` | `openspec-apply-change` | cuerpo completo |
| `opsx/archive.md` | `openspec-archive-change` | cuerpo completo |
| `opsx/explore.md` | `openspec-explore` | cuerpo completo |
| `opsx/propose.md` | `openspec-propose` | cuerpo completo |
| `opsx/verify.md` | `openspec-verify-change` | cuerpo completo |
| `odd/start.md` | `odd-change` | secciones `Inicio (`/odd`)` y `Escalado` |
| `odd/verify.md` | `odd-change` | secciones `Verify (`/odd:verify`)` y `Escalado` |
| `odd/close.md` | `odd-change` | sección `Cierre (`/odd:close`)` |
| `odd.md` | `odd-change` | idéntico a `odd/start.md` (lo exige el test `clasificacion-odd-sdd`) |

Comparando el cuerpo de cada comando (sin frontmatter) con su skill, hoy hay estas diferencias:

- `opsx/apply`: primera línea (el comando dice "Announce the handoff to the Agent for an OpenSpec change. Claude is the architect: it does NOT implement tasks."; la skill dice "Implement tasks from an OpenSpec change."), el ejemplo de la línea **Input**, `contextFiles`, `/opsx:continue` frente a `openspec-continue-change`, un guion frente a una raya y "This command/skill supports", "the Agent's work/implementation".
- `opsx/archive`: el ejemplo de la línea **Input**, y la skill tiene además la línea "(SRS offer follows here: ...)" dentro del bloque de salida.
- `opsx/explore`: el comando tiene un bloque **Input** (7 líneas) y la línea "If the user mentioned a specific change name, read its artifacts for context." que la skill no tiene; la skill tiene la sección `## Handling Different Entry Points` y el resumen "What We Figured Out" que el comando no tiene.
- `opsx/propose`: el texto de la línea **Input** y "If no (clear) input provided".
- `opsx/verify`: el ejemplo de la línea **Input**, y en `**Architecture Verification**` la skill anida mal **Tool**, **Nivel**, **Tamaño** y **Scope** debajo de **Imports** (el comando los tiene al mismo nivel, que es lo correcto).
- `odd/*` y `odd.md`: solo el título de la sección (el comando lo tiene sin backticks: `## Inicio (/odd)`) y líneas en blanco.

El mecanismo de generación ya existe para las plantillas de los agentes (ADR 0001): `templates/fuente/` + `scripts/generar-plantillas.ps1` + `-Comprobar` en `.github/workflows/plantillas.yml`.

## Goals / Non-Goals

**Goals:**
- Que el texto de un comando se edite en un solo lugar (su skill) y que el CI falle si alguien edita el comando a mano o cambia la skill sin regenerar.
- Reconciliar una sola vez las diferencias actuales, sin perder contenido correcto de ninguno de los dos lados.

**Non-Goals:**
- Cambiar qué instalan `instalar.ps1` o `sincronizar-proyecto.ps1`.
- Generar comandos de otros agentes o las skills.
- Cambiar el comportamiento de los comandos más allá de la reconciliación.

## Decisions

### D1. La skill es la fuente y el comando se genera

Los comandos se generan desde las skills, no al revés, porque las skills son más completas (explore tiene ejemplos que el comando perdió) y son lo que se instala en `~/.claude/skills/` y lo que leen los tests de ODD.

- *Alternativa descartada: el comando como fuente y la skill generada.* Las skills de ODD juntan tres comandos en un archivo; habría que concatenar en vez de recortar, y el frontmatter de skill es más largo.
- *Alternativa descartada: solo comparar en `-Comprobar`, sin generar.* Detecta la diferencia pero sigue obligando a editar dos veces; es la mitad de la propuesta de la deuda.

### D2. Encabezados en `templates/fuente/comandos/` con marcas `incluir-skill`

Cada comando tiene un encabezado en `templates/fuente/comandos/` con la misma ruta relativa que su destino en `.claude/commands/` (`opsx/apply.md`, `opsx/archive.md`, `opsx/explore.md`, `opsx/propose.md`, `opsx/verify.md`, `odd/start.md`, `odd/verify.md`, `odd/close.md`). El encabezado tiene el frontmatter actual del comando, una línea en blanco y una o más marcas separadas por una línea en blanco:

- `<!-- incluir-skill: <skill> -->`: el cuerpo de `skills/<skill>/SKILL.md` sin su frontmatter (todo lo que sigue a la segunda línea `---`), sin las líneas en blanco del principio.
- `<!-- incluir-skill: <skill>#<título> -->`: la sección que empieza en la línea exactamente igual a `## <título>` (fuera de bloques de código) y termina antes del siguiente título `## ` fuera de un bloque de código, o al final del archivo. Una línea que empieza con tres backticks abre o cierra un bloque.

Cada marca se reemplaza por su texto sin las líneas en blanco del final. Los encabezados de ODD llevan los títulos con backticks, como en la skill (`odd-change#Inicio (`/odd`)`, `odd-change#Escalado`, `odd-change#Verify (`/odd:verify`)`, `odd-change#Cierre (`/odd:close`)`), por lo que los comandos generados pasan a tener el título con backticks.

El frontmatter de cada encabezado se copia del comando actual (`name`, `description`, `category` y `tags` si los tiene), sin cambiarlo.

`odd.md` no tiene encabezado propio: la tabla de generación del script lo genera desde `odd/start.md`, para que el test que exige que sean idénticos siga pasando sin duplicar la fuente.

- *Alternativa descartada: tabla de frontmatter dentro del script.* Mezcla texto de prompts con código; un encabezado `.md` se lee y se revisa igual que los esqueletos de las plantillas.
- *Alternativa descartada: reutilizar la marca `<!-- incluir: ... -->` de los esqueletos.* Esa marca busca en `fragmentos/`; una marca distinta deja claro que el origen es `skills/` y evita confundir los dos mecanismos.

### D3. Mismo script y mismo `-Comprobar`

`scripts/generar-plantillas.ps1` suma una tabla `$mapeoComandos` (encabezado → destino, con `odd/start.md` → `.claude/commands/odd/start.md` y `.claude/commands/odd.md`) y genera los comandos en memoria junto con las plantillas, antes de escribir nada. Si una marca falla, termina con código distinto de 0 nombrando el encabezado y la marca, sin escribir ningún archivo. `-Comprobar` compara también los nueve comandos (con `Normalizar-Texto`, sin diferencias de BOM ni de fin de línea) y los lista en el error. El CI ya corre `generar-plantillas.ps1 -Comprobar`, así que `.github/workflows/plantillas.yml` no cambia.

Las dos funciones que no tocan archivos (sacar el frontmatter de un texto y extraer la sección `## <título>` respetando los bloques de código) van en `scripts/comun.ps1` como funciones que reciben texto y devuelven texto, para testearlas sin archivos.

- *Alternativa descartada: un script nuevo `generar-comandos.ps1`.* Suma un paso al CI y un segundo punto de entrada para algo que el mantenedor corre siempre junto (`generar-plantillas.ps1` después de editar una regla o una skill).

### D4. Aviso de archivo generado

Después del frontmatter de cada comando, el script escribe una línea en blanco, `<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->` y otra línea en blanco. Los comandos no llevan `## Propio del proyecto` porque se instalan por máquina, no por proyecto. Salida en UTF-8 sin BOM, LF y terminada en un solo salto de línea.

### D5. Reconciliación previa (lista cerrada)

Antes de la primera generación, el Agente pasa a la skill lo que hoy solo está bien en el comando. Todo lo demás queda como está en la skill:

| Skill | Cambio |
|---|---|
| `skills/openspec-apply-change/SKILL.md` | La primera línea del cuerpo pasa a ser "Announce the handoff to the Agent for an OpenSpec change. Claude is the architect: it does NOT implement tasks." (la skill hoy contradice la regla absoluta del `CLAUDE.md`). |
| `skills/openspec-explore/SKILL.md` | Agregar el bloque **Input** del comando (las 6 líneas desde `**Input**: The argument after` hasta `- Nothing (just enter explore mode)`) en el mismo lugar que en el comando, cambiando "The argument after `/opsx:explore`" por "The user's input". Agregar la línea "If the user mentioned a specific change name, read its artifacts for context." en el mismo lugar que en el comando. |
| `skills/openspec-verify-change/SKILL.md` | En `**Architecture Verification**`, desindentar **Tool**, **Nivel**, **Tamaño** (con sus sub-viñetas) y **Scope** un nivel, para que queden al mismo nivel que **Files** e **Imports**, como en el comando. |

Si al comparar aparece una diferencia que no está en el Context de este design, el Agente frena y pregunta (regla 4).

## Risks / Trade-offs

- [Cambia el texto de los comandos que cada máquina tiene instalados] → `instalar.ps1` clasifica las copias viejas como `atrasado` (coinciden con una versión de git) y las reemplaza sin pedir `-Forzar`; se avisa en el resumen del change.
- [Se pierden los ejemplos con el nombre del comando en la línea **Input** (`/opsx:apply add-auth`)] → la línea de la skill dice lo mismo sin el ejemplo; la skill ya lo usa así.
- [El parser de secciones se equivoca con un bloque de código mal cerrado] → S03 cubre títulos dentro de bloques; el `-Comprobar` muestra cualquier diferencia en el PR.
- [Un mantenedor edita el comando en vez de la skill] → el aviso del D4 y el `-Comprobar` del CI.

## Migration Plan

1. Reconciliar las tres skills (D5).
2. Crear los encabezados y extender el script.
3. Correr `pwsh scripts/generar-plantillas.ps1` y commitear los nueve comandos regenerados junto con la fuente.
4. En cada máquina: `pwsh scripts/instalar.ps1` después del merge.

Rollback: revertir el merge; los comandos vuelven a ser archivos editados a mano.

## Impacto en proyectos existentes

Los proyectos no guardan copias de estos comandos (las guías piden borrar `.claude/commands/opsx/` locales y usar los globales), así que no hay nada que migrar en cada proyecto. El cambio les llega al reinstalar en cada máquina: `/opsx:apply` y `/opsx:verify` quedan con el texto corregido, `/opsx:explore` gana los ejemplos de la skill, y los comandos ODD solo cambian el título de la sección. `sincronizar-proyecto.ps1` no toca `.claude/commands/` y no cambia.

## Impacto en el sistema

**Componentes afectados:** `skills/` pasa a ser fuente de `.claude/commands/`; `scripts/generar-plantillas.ps1` y `scripts/comun.ps1`; la instalación por máquina (`~/.claude/commands/`) recibe el texto nuevo. Ningún otro proyecto ni integración.

**Atributos de calidad:**
- mantenibilidad (alta): mejora; un comando se edita una sola vez y la copia queda controlada por el CI — Verificación: S07, S08 y S09 (`-Comprobar` falla con un comando o una skill editados a mano) y revisión del diff: ningún archivo de `.claude/commands/` sin el aviso de archivo generado.

**Decisiones de arquitectura:** ninguna. Extiende a los comandos el mecanismo del ADR 0001 sin cambiar la tecnología ni el patrón.

**Deuda técnica:** paga: "[media] cada comando de `.claude/commands/` repite el texto de su skill..." de `docs/arquitectura/vision.md`.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `templates/fuente/comandos/opsx/apply.md` (y `archive`, `explore`, `propose`, `verify`) | `templates/` |
| `templates/fuente/comandos/odd/start.md` (y `verify`, `close`) | `templates/` |
| `tests/generar-comandos.Tests.ps1` | `tests/` |

## Security Layer

`project_type: tooling`. Los artefactos modificados son instrucciones para IA.

- Sin secrets ni rutas absolutas personales en encabezados, skills ni comandos generados — Verificación: revisión del diff: ninguna ruta tipo `C:\Users\`, `D:\` ni `/home/` y nada con forma de token en las líneas agregadas.
- El script no ejecuta texto leído de las skills ni de los encabezados (solo lo copia) — Verificación: S10.
- El cambio a las skills y comandos globales va en commit separado con descripción del impacto (regla `tooling/config`) — Verificación: revisión del diff: el commit de las tres skills reconciliadas está separado del de generación y su mensaje dice qué cambia en cada máquina.
- Sin datos personales: el change no toca datos `personal` de `## Datos`.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min), suite completa: los tests existentes `clasificacion-odd` y `aclarar-k2` leen los comandos generados. Cada test lleva el marcador `test-plan: generar-comandos-desde-skills/<ID>` en un comentario. Los tests que generan usan una copia del repo en una carpeta temporal (`Con-CarpetaTemporal`) y no escriben en el repo real.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Comandos generados / Comando con la skill completa | auto | `tests/generar-comandos.Tests.ps1` |
| S02 | Comandos generados / Comando con secciones de una skill | auto | `tests/generar-comandos.Tests.ps1` |
| S03 | Comandos generados / Título dentro de un bloque de código | auto (función de `comun.ps1` con texto inventado) | `tests/generar-comandos.Tests.ps1` |
| S04 | Comandos generados / Mismo texto para /odd y /odd:start | auto | `tests/generar-comandos.Tests.ps1` |
| S05 | Comandos generados / Dato inválido: skill inexistente | auto | `tests/generar-comandos.Tests.ps1` |
| S06 | Comandos generados / Dato inválido: sección inexistente | auto | `tests/generar-comandos.Tests.ps1` |
| S07 | Control / Comando editado a mano | auto | `tests/generar-comandos.Tests.ps1` |
| S08 | Control / Skill editada sin regenerar | auto | `tests/generar-comandos.Tests.ps1` |
| S09 | Control / Todo sincronizado (en el repo real, con comandos incluidos) | auto | `tests/generar-comandos.Tests.ps1` |
| S10 | Security Layer / el script no ejecuta texto leído | auto: `generar-plantillas.ps1` no contiene `Invoke-Expression`, `iex ` ni `& $` | `tests/generar-comandos.Tests.ps1` |
| S11 | Control / Plantilla editada a mano, Reglas con otro título, Workflow de PR (sin cambios) | auto: tests existentes de `tests/generar-plantillas.Tests.ps1` siguen en verde | `tests/generar-plantillas.Tests.ps1` |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `.claude/commands/odd/*.md` y `odd.md` | Copiados antes de tocar nada a `tests/datos/comandos-antes/`; el test fija que el comando generado, sin el aviso, sin líneas en blanco y con los backticks quitados del título de la sección, es igual al de antes con el mismo tratamiento. | Títulos de sección con backticks y aviso de archivo generado (normalizados por el test). |
| C02 | `.claude/commands/opsx/*.md` | Copiados antes de tocar nada a `tests/datos/comandos-antes/`; el test fija que toda línea del comando de antes que no está en el generado es una de las listadas en el Context para ese comando (líneas **Input** con el nombre del comando, incluida la de explore que D5 reescribe, `contextFiles`, `/opsx:continue`, "This command supports", "the Agent's work", el guion, "If no input provided", "When things crystallize..."). Cualquier otra línea perdida falla. | Las diferencias del Context: en esos casos queda el texto de la skill. Las líneas que D5 pasa a la skill no se pierden y el test lo comprueba. |
| C03 | `scripts/generar-plantillas.ps1` | Las cuatro plantillas generadas no cambian (los tests existentes de `generar-plantillas.Tests.ps1`, C01 de `sincronizar-reglas`). | Ninguno. |

## Open Questions

- Ninguna.
