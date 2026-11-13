# Design

## Context

- **Lo pendiente hoy:** la hoja de ruta de `docs/arquitectura/vision.md` (7 líneas con prioridad), los changes activos, los "Pendientes" del `context.md` del vault y los issues de GitHub. Los issues están desactualizados: #9 (verify basado en tests) y #6 (glosario y actores en `config.yaml`) siguen abiertos, pero los resolvieron `test-driven-verification` y la sección 5.3 de `srs-generate`. Desde el #39, ningún change salió de un issue.
- **`issue-creation`** (`skills/issue-creation/SKILL.md`) crea el issue con `--label "status:needs-review"` y pide `status:approved` antes del propose. Ninguna de las dos etiquetas existe en el repo: solo están las de GitHub por defecto.
- **`openspec-propose`** no lee ningún issue. **`branch-pr`** pone `Spec-ID:` en el PR, pero no `Closes`. **`openspec-archive-change`** ofrece el SRS en la fase de la rama (paso 6). **`srs-generate`** guarda IDs y atributos en `docs/srs.meta.yaml`.
- **Repos:** 16 de los 17 proyectos que usan el workflow están en GitHub, con tres dueños (Toyota-Yacopini, lmontecchiani-dev y Lautaro-Montecchiani). analisis-LO-Saleforce no tiene remoto.
- **Generados:** `.claude/commands/opsx/propose.md` y `archive.md`, `.claude/commands/odd.md` y `odd/start.md` salen de las skills con `scripts/generar-plantillas.ps1`. `branch-pr`, `issue-creation` y `srs-generate` no tienen comando generado.

## Goals / Non-Goals

**Goals:**
- Una sola fuente de lo pendiente por proyecto (los issues), con prioridad y tipo.
- Traza completa: issue → proposal → PR que lo cierra → requirement del SRS.
- Una vista `docs/backlog.md` generada y reproducible, que conviva con el SRS.

**Non-Goals:**
- Lo operativo entre proyectos, GitHub Projects, la migración de otros proyectos y el control en el CI (ver proposal).

## Decisions

### D1. Script `scripts/generar-backlog.ps1`

- **Uso:** `pwsh scripts/generar-backlog.ps1 -Proyecto <ruta> [-Entrada <archivo.json>]`. Se corre desde `$env:SDD_CONFIG_REPO` sobre cualquier proyecto, igual que `sincronizar-proyecto.ps1`.
- **Lectura:** sin `-Entrada`, corre `gh issue list --state open --limit 500 --json number,title,labels,url` con la carpeta del proyecto como directorio de trabajo. Con `-Entrada`, lee el mismo formato JSON desde el archivo (para los tests).
- **Falla de lectura:** si `gh` no existe, termina con error o devuelve algo que no es JSON (sin red, sin permiso o carpeta sin repo de GitHub), escribe una línea `No se pudo leer los issues del proyecto: <motivo>.` sin rutas absolutas, no crea ni modifica `docs/backlog.md` y termina con 1.
- **Cálculo separado de la entrada y la salida:** una función `Formatear-Backlog` recibe la lista de issues, el nombre del proyecto y la fecha, y devuelve el texto. No lee ni escribe archivos, no llama a `gh` y no escribe en consola. El resto del script hace la lectura y la escritura.
- **Formato de `docs/backlog.md`** (UTF-8 sin BOM):
  - Línea 1: `<!-- Generado con scripts/generar-backlog.ps1 desde los issues abiertos de GitHub. No editar a mano. -->`
  - `# Backlog — <nombre de la carpeta del proyecto>`
  - `Generado el DD/MM/AAAA. Fuente: issues abiertos del repositorio. Lo ya implementado está en docs/srs.md.`
  - Cuatro secciones, siempre en este orden: `## Prioridad alta`, `## Prioridad media`, `## Prioridad baja` y `## Sin prioridad`. Cada una tiene una tabla `| Issue | Título | Tipo |` con los issues ordenados por número ascendente, o la línea `Ninguno.` si no hay issues.
  - Columna Issue: `[#NN](<url>)`. Columna Tipo: `feature`, `deuda` o `bug` según la etiqueta `tipo:*`, o `—` si no tiene. Si el issue tiene la etiqueta `bloqueado`, el título termina en ` (bloqueado)`.
  - Prioridad: según la etiqueta `prioridad:alta|media|baja`. Si tiene más de una, gana la más alta. Sin etiqueta, va a `## Sin prioridad`.
  - Última línea: `Total: N issues abiertos.`
- **Datos inválidos:** en el título, `|` se escribe `\|` y los saltos de línea pasan a un espacio. Un issue sin `number` o sin `title` se descarta. Si hubo descartados, la consola agrega `Issues descartados por datos incompletos: N.`
- **Consola en el caso normal:** una línea `Backlog generado: docs/backlog.md (N issues).` y código 0.
- **No copia** el cuerpo, los comentarios ni los autores de los issues. No ejecuta texto leído (ni `Invoke-Expression` ni similares).
- **Alternativas descartadas:**
  - *Que Claude arme el backlog leyendo los issues en cada archive (como el SRS):* no es reproducible ni se puede testear. Un script da siempre la misma salida y se prueba con `-Entrada`.
  - *Generarlo en el CI:* cada proyecto necesitaría un workflow nuevo, y eso queda para el change de la huella.

### D2. `skills/issue-creation/SKILL.md`

- En el paso 1 ("Gather context"), agregar esta viñeta al final de la lista: "- Its priority (`prioridad:alta`, `prioridad:media` or `prioridad:baja`) and its type (`tipo:feature`, `tipo:deuda` or `tipo:bug`). Ask both in one **AskUserQuestion** call when the description does not make them clear."
- Agregar un paso nuevo "3. **Ensure labels**" antes de "Create the issue" (los pasos siguientes se renumeran a 4 y 5), con este texto: "Run `gh label list --limit 100 --json name` and create each missing label of the catalog below with `gh label create <name> --color <color> --description \"<description>\"`. If `gh` fails because the active account has no permission on the repo, stop and tell the user: \"La cuenta activa de gh (<cuenta>) no tiene permiso en <owner>/<repo>: activá la cuenta dueña del repo con `gh auth switch -u <cuenta>` y volvé a correr /issue-creation\"." Debajo va la tabla del catálogo:

| Etiqueta | Color | Descripción |
|---|---|---|
| `status:needs-review` | `ededed` | Issue pendiente de aprobación |
| `status:approved` | `0e8a16` | Issue aprobado para proponer el change |
| `prioridad:alta` | `b60205` | Prioridad alta en el backlog |
| `prioridad:media` | `fbca04` | Prioridad media en el backlog |
| `prioridad:baja` | `c2e0c6` | Prioridad baja en el backlog |
| `tipo:feature` | `1d76db` | Funcionalidad nueva |
| `tipo:deuda` | `5319e7` | Deuda técnica |
| `tipo:bug` | `d73a4a` | Error a corregir |
| `bloqueado` | `000000` | Bloqueado por otra tarea o decisión |

- En el comando de creación, `--label "status:needs-review"` pasa a `--label "status:needs-review" --label "<prioridad>" --label "<tipo>"`.

### D3. `skills/openspec-propose/SKILL.md` (y `/opsx:propose`)

Agregar un paso "1b. **Issue del change**" entre el paso 1 y el paso 2 ("Create the change directory"), con este texto:

"Ask for the issue number if the user did not give it, or find it with `gh issue list --search \"<name> in:body\" --json number,title`. Run `gh issue view <NN> --json state,labels,title`:
- If the issue does not exist or its state is `CLOSED`: stop without creating the change and suggest `/issue-creation`.
- If it lacks the `status:approved` label: ask the user with **AskUserQuestion** \"¿El issue #NN está aprobado?\" with options \"Sí, aprobado\" and \"No, cancelar\". \"Sí, aprobado\" adds the label with `gh issue edit <NN> --add-label status:approved`; \"No, cancelar\" stops.
- If `gh` is not installed, there is no network or the active account has no permission on the repo: warn the user, use `Issue: pendiente` and continue.
Write `Issue: #<NN>` (or `Issue: pendiente`) as the first line of `proposal.md`, followed by a blank line."

En la guía de visión ("For `design.md`: initial vision…"), la viñeta de `## Hoja de ruta` pasa a: "`## Hoja de ruta`: prioritized technical debt `- [alta|media|baja] <deuda> — origen: <change o ADR> — propuesta: <cómo pagarla> — issue: #NN` (the trailing `— issue: #NN` is optional, added when the debt has an issue)."

Después se regenera `.claude/commands/opsx/propose.md` con `pwsh scripts/generar-plantillas.ps1`.

### D4. `skills/branch-pr/SKILL.md`

- En el paso 6 ("Create PR"), antes de los bloques de comando, agregar: "Read the first line of `openspec/changes/{nombre}/proposal.md` (or of its archived copy in `openspec/changes/archive/*-{nombre}/`) for SDD, or the `Issue:` line of `docs/odd/{nombre}.md` for ODD. If it is `Issue: #NN`, add the line `Closes #NN` right below the `Spec-ID:` line of the PR body. If it is `Issue: pendiente` or there is no `Issue:` line, open the PR without `Closes` and say so in step 7."
- En los dos cuerpos de ejemplo (SDD y ODD), debajo de la línea `Spec-ID:`, agregar `Closes #{NN}  # solo si hay Issue: #NN`.

### D5. `skills/openspec-archive-change/SKILL.md` (y `/opsx:archive`)

Agregar en la fase de la rama un paso "6b. **Backlog en la rama:**" después del paso 6 (Oferta del SRS), con este texto:

"Si el proyecto tiene `docs/backlog.md`, regenerarlo sin preguntar con `pwsh $env:SDD_CONFIG_REPO\scripts\generar-backlog.ps1 -Proyecto .`. Si no lo tiene, preguntar con **AskUserQuestion** \"¿Generar el backlog del proyecto (`docs/backlog.md`) desde los issues abiertos?\" con las opciones `(Recommended) Generar ahora` y `Más tarde`. Si el script termina con 0, commitear en la rama `change/<nombre>`: `git add docs/backlog.md` y `git commit -m \"docs: regenerar backlog\" -m \"Spec-ID: <nombre>\"` (o `docs: generar backlog` la primera vez). Si termina con otro código (sin `gh`, sin red, sin permiso o sin `SDD_CONFIG_REPO`), avisar con su mensaje y seguir con el archive: el backlog nunca bloquea el archive."

En "Output On Success (Fase de la rama)", debajo de la línea `**SRS:**`, agregar: `**Backlog:** ✓ Regenerado / Generado / Postergado / No se pudo (<motivo>)`. Después se regenera `.claude/commands/opsx/archive.md`.

### D6. `skills/srs-generate/SKILL.md`

- En la sección "3.4 Atributos Adicionales por Requirement", agregar después de la lista de atributos: "- **Issue:** `#NN` del change que agregó el requirement, tomado de la primera línea `Issue: #NN` del `proposal.md` del change archivado (`openspec/changes/archive/*-<change>/`) cuya delta spec contiene el requirement. Se guarda en `issues:` de `docs/srs.meta.yaml` (ID jerárquico → número) y no se recalcula. Si el change no tiene issue o dice `pendiente`, el atributo se omite."
- En la sección 7, en el YAML de ejemplo de `docs/srs.meta.yaml`, agregar al final: un comentario `# Issue de origen de cada requirement (ID jerárquico -> número de issue)` y `issues:` con la entrada `"3.5.1.2": 52`.

### D7. Formato de la hoja de ruta en `.claude/CLAUDE.md`

En "## Rol de arquitecto de software", punto 3, el formato `` `- [alta|media|baja] <deuda> — origen: <change o ADR> — propuesta: <cómo pagarla>` `` pasa a `` `- [alta|media|baja] <deuda> — origen: <change o ADR> — propuesta: <cómo pagarla> — issue: #NN` (el final `— issue: #NN` es opcional y se suma cuando la deuda tiene issue) ``. No se toca el bloque generado de reglas del Agente.

### D8. ODD en `skills/odd-change/SKILL.md` (y `/odd`)

En el paso 3 del inicio ("Redacción del documento ODD y change mínimo"), antes de la plantilla del documento, agregar: "Si el pedido tiene un issue de GitHub, la primera línea del documento es `Issue: #NN`; si no, se omite: en ODD el issue no es obligatorio." Después se regeneran `.claude/commands/odd.md` y `.claude/commands/odd/start.md`.

### D9. Migración de este repo (con `gh` y la cuenta Lautaro-Montecchiani)

1. Crear las 9 etiquetas del catálogo de D2 que falten.
2. Cerrar #9 con `gh issue close 9 --comment "Resuelto: el verify corre los tests del Test Plan (capability test-driven-verification, openspec/specs/test-driven-verification/spec.md)."`.
3. Cerrar #6 con `gh issue close 6 --comment "Resuelto: glosario, actores y objetivos viven en el context: de openspec/config.yaml (srs-generate, sección 5.3)."`.
4. Agregarle a #52 las etiquetas `status:approved`, `prioridad:media` y `tipo:feature` (el usuario lo aprobó el 13/11/2026).
5. Por cada una de las 7 líneas de `## Hoja de ruta` de `docs/arquitectura/vision.md`, crear un issue:
   - título `[deuda] <texto de la deuda>` (sin la prioridad ni el origen);
   - cuerpo con dos líneas: `Origen: <origen>` y `Propuesta: <propuesta>`;
   - etiquetas `tipo:deuda`, `prioridad:<la de la línea>` y `status:needs-review`.
   Después, sumarle `— issue: #NN` al final de esa línea.
6. Generar el primer `docs/backlog.md` con `pwsh scripts/generar-backlog.ps1 -Proyecto .`. Esta corrida es la M01.

Si la cuenta activa de `gh` no es Lautaro-Montecchiani, el Agente frena y avisa (regla 5: no cambia de cuenta).

## ADR

```markdown
# 0004. Issues de GitHub como fuente única del backlog

Estado: aceptada
Fecha: 2026-11-13
Change: backlog-desde-issues

## Contexto

Lo pendiente de cada proyecto vivía en cinco lugares con formatos distintos: la hoja de ruta del `vision.md`, los "no incluye" de `## Alcance`, los changes activos, los issues de GitHub y los "Pendientes" del `context.md` del vault. La regla "no hay propose sin issue aprobado" no se cumplía y los issues estaban desactualizados. El SRS describe lo que el sistema ya hace, pero no había una vista de lo que falta. 16 de los 17 proyectos que usan el workflow están en GitHub.

## Alternativas

- **Vista generada desde todas las fuentes:** `docs/backlog.md` se arma leyendo las cinco fuentes. Se descartó porque hereda el desorden de las fuentes y no hay una prioridad común entre ellas.
- **Archivo de backlog como fuente:** `docs/backlog.md` reemplaza a la hoja de ruta y a los pendientes, y Claude lo mantiene desde las skills. Se descartó porque compite con el issue como puerta de entrada, no lo ve el equipo en GitHub y no sirve para lo operativo entre proyectos.
- **GitHub Projects o una herramienta externa:** se descartó por la configuración extra en cada repo, y porque los repos tienen tres dueños distintos.
- **Dejarlo como está:** se descartó porque la regla del issue seguiría sin cumplirse y lo pendiente seguiría disperso.

## Decisión

Los issues de GitHub son la fuente única de lo pendiente de cada proyecto, con etiquetas `prioridad:*` y `tipo:*`. El propose exige el issue (`Issue: #NN` en el proposal), el PR lo cierra con `Closes #NN`, el SRS anota el issue de origen de cada requirement y `scripts/generar-backlog.ps1` genera `docs/backlog.md` desde los issues abiertos, ofrecido en el archive. La hoja de ruta sigue en el `vision.md` y suma el número de issue. Sin `gh`, sin red o sin permiso, el flujo avisa y sigue. Lo operativo entre proyectos queda en el vault.

## Consecuencias

- Positivas: una lista priorizada por proyecto que el equipo ve en GitHub, traza completa de la idea al requirement, cierre automático de los issues al mergear y un backlog reproducible y testeable.
- Negativas: el flujo depende de `gh` y de tener la cuenta con permiso en cada repo (tres dueños). Los proyectos fuera de GitHub quedan con `Issue: pendiente`. Mantener las etiquetas al día depende de la disciplina de `/issue-creation`.
```

## Impacto en proyectos existentes

- Los changes en curso no cambian. Desde el próximo propose, Claude pide el issue. Si el proyecto no está en GitHub, o la cuenta no tiene permiso, sigue con `Issue: pendiente`.
- Las etiquetas se crean en cada repo la primera vez que se usa `/issue-creation`.
- `docs/backlog.md` aparece en un proyecto solo cuando el usuario acepta generarlo en un archive. Después se regenera en cada archive.
- Retrocompatible: un `proposal.md` sin `Issue:` sigue siendo válido para `branch-pr` (PR sin `Closes`) y para `srs-generate` (requirement sin atributo "Issue").
- Las máquinas reciben las skills y los comandos nuevos con `pwsh scripts/instalar.ps1`.

## Impacto en el sistema

**Componentes afectados:** el propose y el archive de Claude en todos los proyectos; el repositorio de GitHub de cada proyecto (etiquetas e issues); `docs/srs.md` y `docs/srs.meta.yaml` de los proyectos con SRS; y `scripts/`, que suma `generar-backlog.ps1` y se corre desde `$env:SDD_CONFIG_REPO`, como `sincronizar-proyecto.ps1`.

**Atributos de calidad:**
- mantenibilidad (alta): el backlog lo genera un script con su función de formato separada, testeable con `-Entrada`; los comandos de Claude se regeneran desde las skills, sin editar a mano — Verificación: S07 a S12 y revisión del diff: los cambios en `.claude/commands/` coinciden con los de las skills (`generar-plantillas.ps1 -Comprobar` con código 0 en la suite).

**Decisiones de arquitectura:** ADR nuevo: 0004.

**Deuda técnica:**
- paga: lo pendiente disperso y la regla del issue que no se cumplía (no estaba en la hoja de ruta).
- descubre: el CI de los PR no controla la línea `Issue:`. Queda dentro de la deuda media del CI de los proyectos, que suma este punto en su propuesta.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `scripts/generar-backlog.ps1` | `scripts/` |
| `tests/backlog-desde-issues.Tests.ps1` | `tests/` |
| `docs/adr/0004-issues-de-github-como-fuente-unica-del-backlog.md` | `docs/` (implícita) |
| `docs/backlog.md` | `docs/` (implícita) |

## Security Layer

Tipo de proyecto: `tooling`.

- Sin secretos: el script usa la sesión de `gh` y no lee, guarda ni imprime tokens — Verificación: revisión del diff: ningún `GH_TOKEN`, `ghp_`, `gho_` ni token literal en las líneas agregadas fuera de `openspec/`.
- No ejecuta texto leído de los issues — Verificación: revisión del diff: sin `Invoke-Expression` ni ejecución de contenido en `scripts/generar-backlog.ps1`.
- Entradas externas validadas antes de usarlas (issues de GitHub) — Verificación: S10.
- Manejo de errores con código de salida distinto de 0 y sin tocar el archivo si falla la lectura — Verificación: S11.
- Sin rutas absolutas ni del usuario en lo que se genera o se muestra — Verificación: S11 y S12.
- `docs/backlog.md` no copia el cuerpo, los comentarios ni los autores de los issues — Verificación: S07 (las filas solo tienen número, título y tipo) y revisión del diff: el `--json` pide solo `number,title,labels,url`.
- Los cambios al `CLAUDE.md` global y a las skills van en commits separados con una línea de impacto — Verificación: revisión del diff: un commit por cada una de D2 a D8 que toque `.claude/CLAUDE.md` o `skills/`, cada uno con "Impacto:".

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian skills que generan comandos que se controlan en el CI. Cada test lleva `# test-plan: backlog-desde-issues/<ID>` arriba del `Probar`. Los tests del script usan carpetas temporales y archivos JSON con issues inventados pasados por `-Entrada`; ningún test llama a GitHub salvo S11, que corre el script sin `-Entrada` en una carpeta temporal sin repo para provocar la falla.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Issue de entrada con prioridad y tipo / Issue con prioridad y tipo | auto: `skills/issue-creation/SKILL.md` pide prioridad y tipo, tiene las 9 etiquetas del catálogo con su color y el comando con las tres `--label` | `tests/backlog-desde-issues.Tests.ps1` |
| S02 | Issue de entrada con prioridad y tipo / Cuenta sin permiso | auto: la skill tiene el mensaje con `gh auth switch -u` y "volvé a correr /issue-creation" | `tests/backlog-desde-issues.Tests.ps1` |
| S03 | Issue en el proposal / Issue abierto y aprobado | auto: `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md` tienen el paso 1b con `gh issue view` y "as the first line of `proposal.md`" | `tests/backlog-desde-issues.Tests.ps1` |
| S04 | Issue en el proposal / Dato inválido: issue cerrado o inexistente | auto: el paso 1b dice "does not exist or its state is `CLOSED`" y "suggest `/issue-creation`" | `tests/backlog-desde-issues.Tests.ps1` |
| S05 | Issue en el proposal / Sin gh o sin permiso | auto: el paso 1b dice "use `Issue: pendiente` and continue" | `tests/backlog-desde-issues.Tests.ps1` |
| S06 | Cierre del issue con el PR / PR que cierra el issue | auto: `skills/branch-pr/SKILL.md` tiene la instrucción de D4 y `Closes #` en los dos cuerpos de ejemplo | `tests/backlog-desde-issues.Tests.ps1` |
| S07 | Generación del backlog / Issues agrupados por prioridad | auto: con issues inventados de las tres prioridades, `docs/backlog.md` tiene las secciones en orden, tablas ordenadas por número, filas con solo número, título y tipo, y la línea `Total:` | `tests/backlog-desde-issues.Tests.ps1` |
| S08 | Generación del backlog / Tipo y bloqueado | auto: un issue con `tipo:deuda` y `bloqueado` muestra `deuda` y el título termina en `(bloqueado)` | `tests/backlog-desde-issues.Tests.ps1` |
| S09 | Generación del backlog / Issues sin prioridad y secciones vacías | auto: un issue sin prioridad va a `## Sin prioridad`; una sección sin issues dice `Ninguno.`; con dos prioridades gana la más alta | `tests/backlog-desde-issues.Tests.ps1` |
| S10 | Generación del backlog / Dato inválido: título con barra o salto de línea, o issue incompleto | auto: `|` escapado, salto de línea pasado a espacio, issue sin `title` descartado y la línea "Issues descartados por datos incompletos: 1." en la consola | `tests/backlog-desde-issues.Tests.ps1` |
| S11 | Generación del backlog / No se pueden leer los issues | auto: sin `-Entrada`, en una carpeta temporal sin repo: código 1, sin `docs/backlog.md` y salida sin la ruta de la carpeta | `tests/backlog-desde-issues.Tests.ps1` |
| S12 | Generación del backlog / Archivo generado | auto: sin BOM (primeros bytes distintos de `EF BB BF`), primera línea igual al comentario de D1 y sin la ruta de la carpeta temporal ni del repo | `tests/backlog-desde-issues.Tests.ps1` |
| S13 | Backlog en el archive / Backlog regenerado en el archive | auto: `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` tienen el paso 6b con `generar-backlog.ps1`, `docs: regenerar backlog` y "el backlog nunca bloquea el archive" | `tests/backlog-desde-issues.Tests.ps1` |
| S14 | Issue de origen en el SRS / Requirement con issue | auto: `skills/srs-generate/SKILL.md` tiene el atributo "Issue", el mapa `issues:` y "el atributo se omite" | `tests/backlog-desde-issues.Tests.ps1` |
| S15 | Hoja de ruta con número de issue / Formato con issue | auto: `.claude/CLAUDE.md` y `skills/openspec-propose/SKILL.md` contienen `— propuesta: <cómo pagarla> — issue: #NN` | `tests/backlog-desde-issues.Tests.ps1` |
| S16 | Issue opcional en el ODD / ODD con o sin issue | auto: `skills/odd-change/SKILL.md` y `.claude/commands/odd.md` contienen "en ODD el issue no es obligatorio" | `tests/backlog-desde-issues.Tests.ps1` |
| M01 | Generación del backlog con issues reales | manual (lo hace el Agente en el apply, sin marca de usuario): después de la migración de D9, `pwsh scripts/generar-backlog.ps1 -Proyecto .` en este repo con la cuenta Lautaro-Montecchiani. Pegar la salida de consola y las primeras 15 líneas de `docs/backlog.md`. Tiene que mostrar los 7 issues de deuda y el #52, y no #9 ni #6 | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `skills/openspec-propose/SKILL.md`, `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md`, `skills/issue-creation/SKILL.md`, `skills/branch-pr/SKILL.md`, `skills/srs-generate/SKILL.md` y `.claude/CLAUDE.md` (con `tests/generar-comandos.Tests.ps1`, `tests/generar-plantillas.Tests.ps1`, `tests/srs-en-rama-del-change.Tests.ps1` y los controles del CI de `tests/ejecutar.ps1`) | Generación de los comandos desde las skills, orden del archive en la rama y textos vigentes de las reglas | Suma los pasos y oraciones de D2 a D8 (S01 a S06 y S13 a S16). Lo existente no cambia y esos tests no se modifican |

## Open Questions

- Ninguna.
