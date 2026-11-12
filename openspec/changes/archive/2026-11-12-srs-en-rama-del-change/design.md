# Design

## Context

- `srs-generate` arma `docs/srs.md` solo desde `openspec/specs/`. Esas specs cambian recién cuando el archive sincroniza los deltas.
- Hoy `/opsx:archive` (`skills/openspec-archive-change/SKILL.md`, paso 3.5) controla que el PR esté mergeado y, si no lo está, pide confirmación. La regla de Git de `.claude/CLAUDE.md` dice "El archive se ejecuta después del merge, nunca antes", con una sola excepción: el change mínimo de spec de un ODD, que `/odd:verify` archiva en su branch.
- El archive no commitea: le pide al usuario que commitee `chore: archive <nombre>`. Por eso los archives y los SRS anteriores terminaron commiteados directo en `master` (por ejemplo `0216afc`, `0227f7a` y `3d16344`) o en un PR desde `docs/regenerar-srs-rules-sync` (PR #43). Ese PR falló "Validate PR conventions" porque `pr-check.yml` solo acepta `change/` y `odd/`.
- `/odd:close` hoy recomienda correr `/srs-generate` después del merge, y eso lleva al mismo problema de rama.
- El usuario eligió regenerar el SRS en la rama del change. Este design plantea dos formas de hacerlo y la elección se confirma al aprobar el change. Las specs están escritas para la alternativa 1, la recomendada.

## Goals / Non-Goals

**Goals:**
- Que el código, las specs vigentes, el archive y el SRS entren en el mismo PR del change.
- Que ningún paso del ciclo necesite commitear en `master` ni abrir un PR desde una rama que el CI rechaza.
- Mantener un solo comando para archivar (`/opsx:archive`) y conservar el cierre en el vault después del merge.

**Non-Goals:**
- Cambiar `pr-check.yml` o el algoritmo de `srs-generate`.
- Automatizar el merge o el push sin confirmación del usuario.

## Decisions

### D1. Alternativas para regenerar el SRS en la rama

**Alternativa 1 (recomendada): archivar en la rama antes del merge.** El orden pasa a ser verify aprobado → `/opsx:archive` en `change/<nombre>` (sync, move, Purpose, commit y SRS) → push → merge → `/opsx:archive` de nuevo para cerrar en el vault.
- A favor: reusa el mecanismo que ya funciona en `/odd:verify`. Las specs vigentes del PR coinciden con el código. `srs-generate` no cambia.
- En contra: cambia una regla global de Git. Si el PR se rechaza después del archive, la rama queda con el change archivado, pero esa rama se descarta y la rama principal no se toca.

**Alternativa 2: SRS con specs vigentes más deltas, sin archivar.** `srs-generate` aplicaría en memoria los deltas de `openspec/changes/<nombre>/specs/` sobre las specs vigentes y escribiría el SRS en la rama. El archive seguiría después del merge.
- A favor: no cambia la regla de Git.
- En contra: duplica en la skill la lógica de sync de deltas (ADDED, MODIFIED, REMOVED y RENAMED), que ya resuelve OpenSpec. Además, el archive después del merge igual necesita un commit en `master` o un PR aparte, que es el problema original. Y el SRS puede quedar desfasado si el sync real resuelve algo distinto.
- **Descartada:** no resuelve el commit del archive fuera de la rama y agrega texto duplicado, lo que va contra el atributo `mantenibilidad | alta`.

**Elegida: alternativa 1**, confirmada por el usuario el 2026-11-12.

### D2. Dos fases en `/opsx:archive`, detectadas por el estado del change

La skill decide la fase con dos datos: dónde está el change y si su PR está mergeado. El PR se consulta con `gh pr list --state merged --head change/<nombre>`, y también con `--head change/<nombre>-archive`.

| Estado | Fase |
|---|---|
| `openspec/changes/<nombre>/` existe y el PR no está mergeado | Fase de la rama (D3) |
| `openspec/changes/<nombre>/` existe y el PR está mergeado | Change del flujo anterior (D5) |
| `openspec/changes/archive/*-<nombre>/` existe en la rama principal y el PR está mergeado | Fase del vault (D4) |
| Archivado en la rama y PR abierto | Frena: "falta el merge" |
| No aparece en ningún lado | Frena: change inexistente |

Si `gh` no puede responder (sin red o sin cuenta), la skill pregunta al usuario si el PR está mergeado en vez de suponerlo.

### D3. Fase de la rama

1. La rama actual tiene que ser `change/<nombre>`, o `change/<nombre>-archive` si se llega desde D5. Si no, frena (escenario "Fuera de la rama del change").
2. Confirma el verify aprobado. Si `context.md` del vault no registra "verify aprobado" para el change, lo pregunta con `AskUserQuestion`; sin confirmación, frena.
3. Revisa artefactos y tareas como hoy (pasos 2 y 3 de la skill).
4. Antes del sync, controla que no exista `openspec/changes/archive/AAAA-MM-DD-<nombre>/` con la fecha del día. Si existe, frena, nombra la carpeta y sugiere renombrarla o esperar otra fecha. Es el control del viejo "Output On Error (Archive Exists)", con su salida de ejemplo. Después hace el sync de specs, el move y el Purpose como hoy (pasos 4, 5 y 5.2).
5. Corre `git add openspec/` y `git diff --staged` para controlar que no haya nada sensible, y commitea `chore: archive <nombre>` con el trailer `Spec-ID: <nombre>`. Es un commit solo de `openspec/`, como manda la regla de commits separados.
6. Ofrece el SRS, como hoy en el paso 7. Si el usuario acepta, invoca `srs-generate` y commitea `docs/srs.md`, `docs/srs.meta.yaml`, `docs/diagramas/` y, la primera vez, `openspec/config.yaml` con `docs: regenerar SRS` (o `docs: generar SRS`) y `Spec-ID: <nombre>`.
7. Actualiza solo `## Estado actual` de `context.md`: "`<nombre>` archivado en la rama, pendiente de merge". Después commitea y pushea el vault (`chore: <proyecto> — archive en rama <nombre>`).
8. Pregunta si pushea la rama. Si el usuario acepta, corre `git push`. Si no, le pide que lo haga.
9. Resumen: "Mergeá el PR y volvé a correr `/opsx:archive <nombre>` para cerrar en el vault".

Claude commitea en esta fase porque los archivos son artefactos de OpenSpec y salidas de `srs-generate`, igual que `/odd:verify` con el change mínimo. No toca código del proyecto.

### D4. Fase del vault

1. Si el árbol de trabajo está limpio, actualiza la rama principal con `git checkout <principal>` y `git pull --ff-only`. Si no está limpio, frena y lo dice.
2. Hace los pasos 5.5 a–f de la skill actual sin cambios: nota de archive, decisions `status: archivado`, `context.md`, `_index.md`, `arquitectura.md` y sync del vault.
3. No ofrece el SRS (escenario "El cierre en el vault no ofrece el SRS") y no crea commits en el repo.

### D5. Change del flujo anterior

Si el PR está mergeado y el change sigue sin archivar, la skill:
1. Con el árbol de trabajo limpio, actualiza la rama principal con `git checkout <principal>` y `git pull --ff-only`, y crea `change/<nombre>-archive` con `git checkout -b`. Si el árbol no está limpio, frena.
2. Hace la fase de la rama (D3), sin el paso 2, porque el verify ya se hizo antes del merge.
3. Pide abrir el PR con `/branch-pr`.

`branch-pr` acepta la rama porque empieza con `change/`. El control de que exista `openspec/changes/<nombre>/` se cumple con la carpeta de archive (D8).

### D6. ODD

- **`/odd:verify`:** después del paso que hoy corre `openspec archive odd-<nombre> -y` y commitea la spec, ofrece el SRS con el mismo texto y las mismas opciones que el archive, y commitea con `Spec-ID: odd-<nombre>`. El control de alcance suma `docs/srs.md`, `docs/srs.meta.yaml` y `docs/diagramas/` solo cuando existe el change mínimo.
- **`/odd:close`:** deja de recomendar `/srs-generate` y suma a la nota la línea `SRS:` ("regenerado en el branch", "postergado" o "sin cambios de spec").
- **Mismo criterio que el SDD (decisión del usuario, 2026-11-12):** el ODD archiva en el branch antes del merge y anota en el vault en dos momentos.
  - **Antes del merge:** `/odd:verify` deja en `## Estado actual` de `context.md` "ODD `<nombre>` archivado en el branch, pendiente de merge" cuando archivó el change mínimo, y "ODD `<nombre>` verificado, pendiente de merge" cuando no hubo cambio de spec.
  - **Después del merge:** `/odd:close` escribe la nota, igual que hoy.
  - **En `skills/branch-pr/SKILL.md`, para `odd/`:** el checklist suma "Archive del change mínimo en el branch (si hay cambio de spec)". El mensaje final pasa a "Merge solo después de que verify no reporte desvíos y, si hay cambio de spec, del archive en el branch". Así se evita pedir un archive a un ODD sin cambio de spec.
  - Un ODD sin cambio de spec no "archiva" nada en el repo: su documento queda en `docs/odd/` con `estado: verificado`, como hoy.

### D7. Texto de `.claude/CLAUDE.md`

- **"Flujo OpenSpec":** el bloque del flujo agrega la línea del archive en la rama antes del merge y la del cierre en el vault después.
- **"Pull Requests":**
  - La línea "El archive se ejecuta después del merge, nunca antes (excepción: …)" pasa a: "El archive de specs (sync, move y SRS) se ejecuta en la rama del change después del verify aprobado y antes del merge; el cierre en el vault (`/opsx:archive` de nuevo) se ejecuta después del merge, nunca antes. El cambio mínimo de spec de un ODD se archiva en su branch durante `/odd:verify`."
  - La condición de merge suma "y con el archive hecho en la rama".
- **Tabla "Cuándo actuar":** la fila `/opsx:archive` pasa a "rama: actualiza `context.md` (pendiente de merge) · después del merge: `archive\…` + reescribe `arquitectura.md` + actualiza `context.md`".

### D8. Guías, verify y branch-pr

- `README.md` (línea del flujo), `docs/workflow.md` y `docs/modo-de-uso.md` (bloque del ciclo y punto "6. Merge + Claude archiva") muestran el orden nuevo y cambian "(post-merge)" por "en la rama, antes del merge" más el cierre posterior.
- `skills/openspec-verify-change/SKILL.md`: "Ready for archive" agrega "Próximo paso: `/opsx:archive <nombre>` en la rama `change/<nombre>`, antes del merge".
- `skills/branch-pr/SKILL.md`:
  - El checklist de `change/` suma "Archive hecho en la rama (specs sincronizadas y SRS si corresponde)".
  - El texto "Merge solo después de que verify no reporte desvíos" del mensaje de `change/` suma "y del archive en la rama". El mensaje de `odd/` sigue lo que dice D6.
  - El control de artefactos del paso 2 (hoy exige `openspec/changes/{nombre}/`) también acepta el change ya archivado en `openspec/changes/archive/*-{nombre}/`. Para una rama `change/{nombre}-archive`, busca `openspec/changes/archive/*-{nombre}/` y el Spec-ID esperado es `{nombre}`.
- Los comandos de `.claude/commands/` se regeneran con `pwsh scripts/generar-plantillas.ps1`.

## Impacto en proyectos existentes

- Retrocompatible para changes que todavía no se mergearon: siguen el orden nuevo sin pasos extra.
- Los changes ya mergeados sin archivar (el caso de PLANEAMIENTO y otros con changes abiertos) se resuelven con D5, sin commitear en la rama principal.
- Los proyectos reciben el comportamiento nuevo cuando cada máquina corre `git pull` en este repo y `pwsh scripts/instalar.ps1`, que instala skills, comandos y el espejo de reglas.
- `pr-check.yml` copiado en los proyectos no cambia.

## Impacto en el sistema

**Componentes afectados:** el vault (las notas de archive cambian de momento, no de formato), los proyectos que usan el workflow (orden de archive y merge) y `pr-check.yml` de los proyectos (sin cambios, pero ahora el SRS entra por `change/` u `odd/`).

**Atributos de calidad:**
- mantenibilidad (alta): mejora. La fase del vault reusa los pasos actuales, `srs-generate` no cambia y los comandos se siguen generando desde las skills — Verificación: `pwsh scripts/generar-plantillas.ps1 -Comprobar` en el CI y revisión del diff: ningún comando de `.claude/commands/` editado a mano.

**Decisiones de arquitectura:** ninguna. No cumple ningún criterio de la lista cerrada de ADR: no cambia el stack, el nivel ni las integraciones, no adopta un patrón transversal y no resuelve un compromiso entre atributos.

**Deuda técnica:** paga la deuda no registrada del SRS fuera del PR, que terminaba con commits directo en `master` o PRs que fallan el check de rama. No es una línea de `## Hoja de ruta` de `docs/arquitectura/vision.md`, así que la visión no cambia.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/srs-en-rama-del-change.Tests.ps1` | `tests/` |

El resto son modificaciones de archivos existentes en `skills/`, `.claude/`, `docs/` y la raíz.

## Security Layer

Tipo de proyecto: `tooling`.

- Los artefactos modificados son instrucciones para IA y no exponen secrets ni rutas absolutas con usuario local — Verificación: revisión del diff: ninguna ruta `C:\Users\…` ni token en skills, comandos, guías ni `CLAUDE.md`.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: `git log` de la rama con un commit propio para `.claude/CLAUDE.md` que describe el cambio de orden archive/merge.
- Antes de cada commit que hace la skill en la fase de la rama, corre `git diff --staged` y no commitea `.env`, `*.key` ni `*.pem` — Verificación: S01 (el texto de la skill exige `git diff --staged` antes del commit).
- El push de la rama solo con confirmación del usuario — Verificación: S01 (el texto de la skill exige preguntar antes de `git push`).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se corre la suite completa porque el change toca `.claude/CLAUDE.md` y skills que leen otros tests.

Los tests son de contrato de texto, como los de `clasificacion-odd` y `aclarar-k2`: controlan que las skills, los comandos generados y las guías tengan las instrucciones de cada escenario. El comportamiento real se controla con M01 en un proyecto de prueba. Cada test automático lleva el marcador `# test-plan: srs-en-rama-del-change/<ID>` arriba del `Probar`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Archive en la rama antes del merge / Archive en la rama del change | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S02 | Archive en la rama antes del merge / Fuera de la rama del change | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S03 | Archive en la rama antes del merge / Verify sin aprobar | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S04 | Change mergeado sin archivar / Change del flujo anterior | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S05 | Cierre en el vault después del merge / Cierre después del merge | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S06 | Cierre en el vault después del merge / PR sin mergear | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S07 | Cierre en el vault después del merge / Dato inválido: config sin calidad ni nivel | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S08 | Orden documentado en reglas y guías / Reglas de Git | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S09 | Orden documentado en reglas y guías / Guías, verify y checklist del PR | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S10 | Enganche opcional en el archive / Archive en un proyecto que ya usa SRS | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S11 | Enganche opcional en el archive / Archive en un proyecto sin SRS | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S12 | Enganche opcional en el archive / Usuario que posterga la generación | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S13 | Enganche opcional en el archive / El cierre en el vault no ofrece el SRS | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S14 | Verify liviano / ODD con cambio de spec y SRS | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S15 | Cierre en el vault de Obsidian / Cierre de un ODD con cambio de spec | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S16 | Verify liviano y Cierre en el vault de Obsidian / escenarios existentes sin cambios | auto: tests existentes de `tests/clasificacion-odd.Tests.ps1` | `tests/clasificacion-odd.Tests.ps1` |
| S17 | Archive en la rama antes del merge / Carpeta de archive ya existente | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S18 | Estado del archive del ODD en el vault y en el PR / ODD con cambio de spec archivado y ODD sin cambio de spec | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| S19 | Estado del archive del ODD en el vault y en el PR / PR de un ODD | auto | `tests/srs-en-rama-del-change.Tests.ps1` |
| M01 | Ciclo completo en un proyecto de prueba | manual: en un repo de prueba con un change chico, correr verify, `/opsx:archive` en la rama (con "Regenerar ahora"), push, merge y `/opsx:archive` de nuevo; capturar `git log --oneline` de la rama y de la rama principal y el listado de `archive\` del vault | — |

Los textos que controla cada test:
- **S01:** la skill nombra la rama `change/<nombre>`, `chore: archive <nombre>`, `Spec-ID: <nombre>`, `git diff --staged` antes del commit y la confirmación antes de `git push`.
- **S02:** la skill frena fuera de la rama del change.
- **S03:** la skill pregunta por el verify aprobado.
- **S04:** la skill nombra `change/<nombre>-archive`, tiene `git pull --ff-only` en "Change del flujo anterior" y el control de rama de la fase de la rama acepta `change/<nombre>-archive`.
- **S17:** la fase de la rama controla la carpeta de archive existente antes del sync y tiene su salida de error.
- **S18:** `skills/odd-change/SKILL.md` y `.claude/commands/odd/verify.md` tienen los dos textos de `## Estado actual`.
- **S19:** `skills/branch-pr/SKILL.md` tiene el ítem de checklist de `odd/` y el mensaje de merge condicionado al cambio de spec. El mensaje de `odd/` ya no dice "y del archive en la rama." a secas.
- **S05:** la fase del vault no crea commits en el repo.
- **S06:** la skill frena con el PR abierto.
- **S07:** la skill escribe "sin declarar" y "sin evaluar".
- **S08:** `.claude/CLAUDE.md` ya no contiene la línea vieja y contiene la nueva.
- **S09:** las guías, el verify y `branch-pr` tienen los textos de D8.
- **S10–S13:** el paso del SRS está en la fase de la rama, con `docs: regenerar SRS` y sin oferta en la fase del vault.
- **S14–S15:** `skills/odd-change/SKILL.md` ofrece el SRS después de `openspec archive odd-<nombre> -y`, tiene la línea `SRS:` y no tiene "recomendar `/srs-generate`".

Todos los tests de contrato controlan también que el comando generado correspondiente (`.claude/commands/opsx/archive.md`, `opsx/verify.md`, `odd/verify.md` y `odd/close.md`) tenga el mismo texto que la skill.

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `skills/odd-change/SKILL.md` (con `tests/clasificacion-odd.Tests.ps1`) | Verify liviano y cierre ODD actuales: `openspec archive odd-<nombre> -y`, puerta y merge en ODD (S19 del change anterior) | Se suma la oferta del SRS y la línea `SRS:`; deja de recomendar `/srs-generate` (lo cubren S14 y S15). Los tests existentes no se modifican |
| C02 | `skills/openspec-archive-change/SKILL.md` (con `tests/generar-comandos.Tests.ps1`, tests S07 a S09 de `generar-comandos-desde-skills`) | El comando `opsx/archive.md` se genera desde la skill y coincide con ella | El contenido cambia a dos fases (lo cubren S01–S13). Estos tests no se modifican |

**Retiro de dos tests de migración (corrección durante el apply, 2026-11-12).** Los tests `generar-comandos-desde-skills/C01` y `/C02` de `tests/generar-comandos.Tests.ps1` no controlan que el comando coincida con la skill. Lo que hacen es comparar `.claude/commands/` contra las copias de los comandos escritos a mano que guardó `tests/datos/comandos-antes/`, para asegurar que la migración a comandos generados no perdiera texto. Este change modifica a propósito `odd/verify.md`, `odd/close.md` y `opsx/archive.md`, y esos dos tests fallan. Va a pasar lo mismo con cualquier change futuro que toque una skill. Por eso se retiran los dos tests y la carpeta `tests/datos/comandos-antes/`:
- La migración ya está cerrada (archivada el 2026-11-10).
- Que el comando coincida con su skill lo siguen controlando `pwsh scripts/generar-plantillas.ps1 -Comprobar` en el CI y los tests S07, S08 y S09 de `generar-comandos-desde-skills`.

Alternativas descartadas:
- Sumar excepciones a la normalización o a `Es-LineaPermitida`: crece con cada change.
- Actualizar las copias: el test pasa a comparar el archivo contra sí mismo.

## Risks / Trade-offs

- **[Archive hecho en una rama que no se mergea]** → La rama se descarta y la rama principal queda intacta. Si se reabre el trabajo en otra rama, se parte de la principal con el change sin archivar.
- **[Correr `/opsx:archive` dos veces confunde]** → El resumen de la fase de la rama dice explícitamente que hay que volver a correrlo después del merge, y `context.md` queda en "pendiente de merge".
- **[El CI re-corre después del archive]** → Es lo buscado: valida el estado final del PR con las specs ya sincronizadas.
- **[`gh` sin acceso al repo]** → La skill pregunta al usuario en vez de adivinar el estado del PR (D2).

## Migration Plan

1. Mergear este change con el flujo nuevo. Este change se archiva con la versión vieja de la skill instalada, así que su archive se hace a mano en la rama antes del merge, siguiendo D3.
2. En cada máquina: `git pull` y `pwsh scripts/instalar.ps1`.
3. Changes abiertos en otros proyectos: si ya están mergeados, usar D5.

## Open Questions

- Ninguna. El usuario confirmó la alternativa 1 de D1 el 2026-11-12, al aprobar el change.
