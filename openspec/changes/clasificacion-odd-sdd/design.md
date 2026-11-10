## Context

- Motivación en `proposal.md` (Why). La idea sale de la conversación del 07/11/2026 sobre el exceso de ceremonia para cambios chicos y de Organic Driven Development (ODD), el protocolo por defecto de Gentle AI v3.0.0. Este change toma el paso de clasificar y el documento único por cambio. El usuario decidió no usar Engram y seguir con Obsidian, y pidió que el cambio chico se guarde en el vault al terminar.
- Hoy el `CLAUDE.md` global dice "Cada change tiene: `proposal.md + design.md + specs/**/*.md + tasks.md`" (regla 4) y exige `## Test Plan` en los changes nuevos (regla 9). `openspec/config.yaml` declara OBJ-01: "todo cambio de código pasa por una spec aprobada antes de implementarse".
- La tabla "Cuándo actuar" de la capa de Obsidian define qué lee y escribe cada comando. Al iniciar sesión, Claude lee `context.md` y las últimas 3 notas de `archive\`.
- `pr-check.yml` exige branches `change/*`, título `[nombre] descripción` y `Spec-ID:` en el body. Desde `sincronizar-reglas`, este archivo es también la fuente que `scripts/sincronizar-proyecto.ps1` copia a los proyectos.
- Desde `sincronizar-reglas` (#35, mergeado el 10/11/2026), las cuatro plantillas de reglas del Agente se generan desde `templates/fuente/` con `scripts/generar-plantillas.ps1`, el CI (`plantillas.yml`) falla si una plantilla no coincide con la fuente o si `.github/copilot-instructions.md` del repo está atrasada, la instalación se hace con `scripts/instalar.ps1` y el repo tiene tests (`pwsh -NoProfile -File tests/ejecutar.ps1`). El test `C01` de `tests/generar-plantillas.Tests.ps1` compara las plantillas con la copia anterior a ese change (`tests/datos/plantillas-antes/`). `docs/arquitectura/vision.md` y el ADR 0001 ya existen.
- La puerta de integración del `CLAUDE.md` y de la spec `integration-gate` admite `sí`, `no`, `pendiente` y `no evaluada`, y `### Pull Requests` dice que el merge solo se hace con `/opsx:verify` aprobado. La regla 7 del Agente pide siempre la nota `apply\` del vault.
- Decisiones del usuario del 09/11/2026: OBJ-01 queda con el texto de D11; K7 queda en 5 archivos; `/odd:verify` y `/odd:close` siguen separados; el documento ODD del repo termina en `verificado` y el cierre queda registrado solo en el vault (D8), para no commitear en la rama principal.
- Retomado el 10/11/2026, después de mergear y archivar `rol-arquitecto-software` (#33). Desde ese change, Claude es arquitecto de software: todo design nuevo lleva `## Impacto en el sistema`, las decisiones que cumplen los criterios de ADR se registran en `docs/adr/`, cada proyecto tiene `docs/arquitectura/vision.md` con su hoja de ruta, y el archive reescribe `arquitectura.md` en el vault. Este design se ajusta a eso (D18 y `## Impacto en el sistema`).
- Reajustado el 10/11/2026 después de archivar `sincronizar-reglas`: la sección ODD de las plantillas va en un fragmento de la fuente (D13), el CI se mantiene en verde (D19), la instalación usa `scripts/instalar.ps1` (D16), la visión se actualiza en vez de crearse (D20) y el Test Plan suma tests automáticos.
- Las reglas de arquitectura permiten sin declararlos los archivos sueltos de la raíz, `openspec/`, `docs/` y las carpetas que empiezan con `.`. Una carpeta `odd/` en la raíz de un proyecto con `## Arquitectura` declarada quedaría fuera de las permitidas (regla 8 del Agente y WARNING del verify).

## Goals / Non-Goals

**Goals:**
- Que la clasificación sea predecible: la misma lista cerrada de criterios da el mismo resultado para el mismo pedido.
- Que un ODD tenga un solo archivo de trabajo y un solo comando de inicio.
- Que todo ODD terminado quede en el vault con el mismo nivel de rastro que un SDD archivado: nota en `archive\`, `context.md` y `_index.md`.
- Que nada que toque datos, seguridad o el contrato de una spec pueda entrar por ODD.

**Non-Goals:**
- Medir automáticamente el tamaño de un cambio: los criterios los evalúa Claude y los vuelve a evaluar el verify sobre el diff real.
- Un tercer nivel "trivial" sin documento: todo ODD tiene su documento, aunque sea corto, porque es lo que se guarda en el vault.

## Decisions

**D1. Cuándo se clasifica.** Claude clasifica todo pedido que implique cambiar archivos del proyecto, antes de escribir cualquier artefacto. No clasifica las preguntas, el `/opsx:explore` ni los pedidos que ya nombran el flujo (`/opsx:propose` es SDD; `/odd` es ODD, pero igual corre la verificación de D3 y avisa si algún criterio SDD se cumple).

**D2. Criterios SDD.** El pedido va por SDD si se cumple **al menos uno**:

| ID | Criterio | ¿El usuario puede pasarlo a ODD? |
|---|---|---|
| K1 | Agrega, cambia o quita un comportamiento descrito en una spec vigente de `openspec/specs/`, o crea una capability nueva | sí |
| K2 | Toca un dato declarado en `## Datos` como `(externo)` o `personal` | **no** |
| K3 | Toca autenticación, permisos, manejo de secretos o un control de la Security Layer del tipo de proyecto | **no** |
| K4 | Agrega, quita o actualiza dependencias | sí |
| K5 | Cambia un contrato hacia afuera: endpoints, formato de archivos de entrada o salida, flags de CLI o esquema de base de datos | sí |
| K6 | Cambia el nivel de arquitectura o mueve código entre capas o módulos | sí |
| K7 | Toca más de 5 archivos, sin contar tests ni documentación | sí |
| K8 | El "qué" no está claro: hay alternativas de diseño que el usuario tiene que elegir | sí |
| K9 | El usuario pide SDD | — |
| K10 | Cumple un criterio de ADR del rol de arquitecto: elige o cambia una tecnología de `## Stack`, cambia el `nivel` de `## Arquitectura`, suma o cambia una integración externa, adopta un patrón transversal (manejo de errores, logging, autenticación, acceso a datos) o resuelve un compromiso entre dos atributos de calidad | **no** |

Si no se cumple ninguno, va por **ODD**. Ejemplos de ODD: corregir un texto o un typo, documentación, estilos, un refactor sin cambio de comportamiento cubierto por tests existentes, y un bug cuyo comportamiento correcto ya está descrito en una spec vigente (el código vuelve a cumplir la spec, la spec no cambia). **Ante la duda sobre un criterio, se considera cumplido.**

**D3. Anuncio y cambio de clasificación.** Claude anuncia en una línea la clasificación y los criterios que la justifican. Por ejemplo: "ODD: no toca specs, datos, seguridad ni dependencias; 2 archivos", o "SDD por K1 y K7". El usuario puede:
- pasar un SDD a ODD solo si los criterios cumplidos son todos de los que se pueden pasar (columna "sí" de D2). Claude anota en el documento ODD, en `## Clasificación`, qué criterio se pasó por alto y por pedido de quién;
- pasar un ODD a SDD siempre (K9).

Si se cumple K2, K3 o K10, Claude responde que va por SDD y no ofrece pasarlo a ODD.

**D4. Documento ODD.** Un archivo por cambio en el proyecto, `docs/odd/<nombre>.md`, con `<nombre>` en kebab-case. Va dentro de `docs/` porque es una carpeta permitida en todo proyecto sin declararla (D18):

```markdown
---
tipo: odd
nombre: <nombre>
creado: AAAA-MM-DD
estado: abierto | en-curso | listo-para-verify | verificado | escalado
branch: odd/<nombre>
---

## Objetivo
<una o dos líneas: qué tiene que ser cierto al terminar>

## Problema
<qué pasa hoy y por qué hay que cambiarlo>

## Alcance
- Incluye: <...>
- No incluye: <...>
- Archivos permitidos: <rutas o carpetas>

## Clasificación
ODD: <criterios de D2 evaluados y por qué ninguno se cumple>
<si hubo cambio de clasificación: qué criterio se pasó por alto y por pedido de quién>

## Checklist
- [ ] 1. <tarea con la ruta del archivo>

## Criterios de aceptación
- CA1: <estado verificable> — Evidencia esperada: <salida de test | diff | captura | salida de consola>

## Evidencia
<la completa el Agente: por tarea y por criterio>

## Progreso
<AAAA-MM-DD: qué se hizo — quién>

## Próximo paso
<un paso concreto>
```

Reglas del documento:
- Lo escribe Claude. Antes del handoff, lo muestra y pide aprobación con `AskUserQuestion` ("Aprobar y pasar al Agente" / "Cambiar algo"). Esa aprobación es la que exige OBJ-01 (D11).
- El Agente solo edita `## Checklist` (marca `[x]`), `## Evidencia`, `## Progreso`, `## Próximo paso` y el `estado` (`en-curso` y `listo-para-verify`).
- El documento queda en el repo después del merge, con `estado: verificado`, como rastro junto al código. El cierre no lo modifica: queda registrado solo en la nota del vault (D8 y D9), para no commitear en la rama principal.

**D5. `/odd <nombre>` (inicio).** Claude:
1. lee `context.md` del vault, como en cualquier inicio;
2. corre la clasificación (D2 y D3); si da SDD, lo dice y ofrece `/opsx:propose`;
3. escribe `docs/odd/<nombre>.md` con `estado: abierto` y lo hace aprobar;
4. crea el branch `odd/<nombre>` y commitea el documento con `docs: documento ODD <nombre>` y el trailer `Spec-ID: odd-<nombre>`;
5. actualiza `## Estado actual` de `context.md` con "ODD activo: `<nombre>`", commitea y pushea el vault;
6. anuncia el handoff: "Ejecutá en el Agente: implementá el ODD `docs/odd/<nombre>.md`".

**D6. Handoff ODD en el Agente.** El Agente:
- lee `docs/odd/<nombre>.md` y trabaja solo en el branch `odd/<nombre>` y en los archivos permitidos;
- implementa tarea por tarea con las reglas de ejecución que ya tiene (evidencia antes de `[x]`, test primero = falla primero, no debilitar tests);
- pega la evidencia en `## Evidencia` del documento: no escribe la nota `apply\` del vault, que es del flujo SDD;
- si al implementar se cumple un criterio de D2 (por ejemplo, necesita una dependencia nueva o tocar más archivos de los permitidos), **frena**, lo escribe en `## Progreso` y avisa "escalar a SDD";
- commitea con `{type}: {desc}` y el trailer `Spec-ID: odd-<nombre>`, y deja `estado: listo-para-verify`.

**D7. `/odd:verify <nombre>`.** Corre sobre el branch, antes del merge. Reporte corto con estas secciones:

| Control | Falla si | Severidad |
|---|---|---|
| Checklist | alguna tarea sin `[x]` o con `[x]` sin evidencia | CRITICAL |
| Criterios de aceptación | algún CA sin la evidencia esperada o con evidencia que no lo demuestra | CRITICAL |
| Alcance | el diff contra la rama principal toca archivos fuera de "Archivos permitidos" | CRITICAL |
| Re-clasificación | algún criterio de D2 se cumple sobre el diff real (por ejemplo, cambió el comportamiento de una spec o aparece una dependencia) | CRITICAL "escalar a SDD" |
| Tests | si `## Tests` declara `comando` distinto de `ninguno`: falla algún test en el branch que no falla en la rama principal (mismas reglas de comparación que el verify SDD; se puede usar `comando-rapido`) | CRITICAL |
| Puerta de integración | seguridad o explicabilidad en `no` o `pendiente`, con las mismas reglas que el verify SDD | CRITICAL |
| Visión | el documento pide actualizar `docs/arquitectura/vision.md` (por ejemplo, porque el ODD paga una deuda de `## Hoja de ruta`) y el diff no lo toca | WARNING |

La explicabilidad no incluye el propio documento ODD (`docs/odd/<nombre>.md`), igual que el verify SDD no incluye `openspec/`. El control de alcance siempre permite el documento ODD, aunque no figure en "Archivos permitidos".

En la puerta, la pregunta del dato inesperado queda `no aplica (ODD)`, porque K2 impide que un ODD toque datos externos. Si la re-clasificación encuentra K2, ese CRITICAL ya bloquea.

Si no hay CRITICAL, Claude deja `estado: verificado` en el documento (commit con `Spec-ID: odd-<nombre>`), actualiza `## Estado actual` de `context.md` con "ODD `<nombre>` verificado, pendiente de merge", y commitea y pushea el vault.

**D8. `/odd:close <nombre>` (cierre en Obsidian).** Corre después del merge:
1. controla que el branch `odd/<nombre>` esté mergeado en la rama principal (`git branch -r --merged`, o `gh pr view` si hay PR). Si no lo está, frena y lo dice;
2. escribe la nota del vault (D9) en `$vault\projects\$p\archive\AAAA-MM-DD-odd-<nombre>.md`;
3. agrega el link a la nota en `$vault\projects\$p\_index.md`;
4. si el diff del ODD tocó `docs/arquitectura/vision.md`, reescribe `$vault\projects\$p\arquitectura.md` con el mismo formato y las mismas fuentes que el archive SDD; si no lo tocó, no lo modifica;
5. actualiza `context.md`: `## Estado actual` "sin change activo" (o el change que siga activo), `## Último change` "ODD `<nombre>` (AAAA-MM-DD)", y una línea en `## Decisiones recientes` solo si el ODD dejó una decisión;
6. commitea el vault con `chore: {proyecto} — odd-close {nombre}` y pushea. Si el push falla, sigue y avisa al final, como el resto de las operaciones del vault;
7. **no crea commits ni pushea en el repo del proyecto**: el documento queda `estado: verificado`, tal como se mergeó. El estado `cerrado` vive solo en la nota del vault (`status: cerrado`).

No ofrece generar el SRS.

**D9. Nota del vault.** Va en `archive\` para que el inicio de sesión (últimas 3 notas de `archive\`) la levante sin cambios:

```markdown
---
tipo: odd
change: <nombre>
proyecto: <proyecto>
fecha: AAAA-MM-DD
status: cerrado
pr: <url del PR o "sin PR">
---

## Objetivo
<copiado del documento>

## Qué cambió
- <archivo>: <una línea>

## Evidencia
- CA1: <resumen en una línea>

## Clasificación
<copiada del documento, incluido cualquier criterio pasado por alto>

## Documento completo
`docs/odd/<nombre>.md` en el repo del proyecto
```

La nota no copia código ni valores sensibles. Si el ODD queda `escalado`, la nota no se escribe acá: la escribe el `/opsx:archive` del SDD que lo reemplaza, que menciona el ODD de origen.

**D10. Escalado.** Cuando el Agente avisa "escalar a SDD" o el verify da el CRITICAL de re-clasificación:
- Claude deja `estado: escalado` en el documento, con el criterio y el motivo en `## Progreso`;
- ofrece `/opsx:propose <nombre>` usando el documento ODD como entrada (objetivo, problema, alcance y lo ya hecho);
- el branch `odd/<nombre>` no se mergea. El propose crea su `change/<nombre>` y decide si reutiliza commits;
- en `context.md`, `## Estado actual` pasa a "ODD `<nombre>` escalado a SDD".

**D11. OBJ-01 y glosario.** En `openspec/config.yaml`:
- OBJ-01 pasa a: "todo cambio de código pasa por una spec aprobada (SDD) o un documento ODD aprobado antes de implementarse".
- Glosario, tres entradas nuevas:
  - "ODD: flujo liviano para cambios que no tocan specs, datos, seguridad ni contratos, con un único documento en `docs/odd/<nombre>.md`";
  - "Clasificación: decisión ODD o SDD con los criterios K1 a K10 del `CLAUDE.md` global";
  - "Escalado: paso de un ODD a SDD cuando aparece un criterio SDD".
- En `### Procesos`, la línea "Setup de máquina: clonar el repo y el vault, copiar CLAUDE.md, skills y comandos a ~/.claude" pasa a "Setup de máquina: clonar el repo y el vault y correr scripts/instalar.ps1", y la línea "Onboarding de proyecto: openspec init --tools <agente>, config.yaml y plantillas del Agente" pasa a "Onboarding de proyecto: openspec init --tools <agente>, config.yaml y scripts/sincronizar-proyecto.ps1". Las dos quedaron desactualizadas con `sincronizar-reglas` (lo encontró su verify).

**D12. `CLAUDE.md` global.**
- Sección nueva `## Clasificación ODD / SDD`, después de `## Reglas globales (obligatorias)`, con: cuándo se clasifica (D1), la tabla de criterios (D2), el anuncio y el cambio de clasificación (D3), y el flujo ODD resumido (`/odd`, Agente, PR, `/odd:verify`, merge, `/odd:close`) con el escalado. Sin IDs de este design (los K1 a K10 sí van, porque son los nombres de los criterios). La sección dice además que un ODD nunca genera ADR (K10) y que, si paga una deuda de `## Hoja de ruta`, el documento incluye la tarea de quitarla de `docs/arquitectura/vision.md` (D18).
- Regla 4 pasa a: "Cada change SDD tiene `proposal.md + design.md + specs/**/*.md + tasks.md`. Cada cambio ODD tiene un único `docs/odd/<nombre>.md`."
- Regla 9: se agrega al principio "En SDD,". Al final, una oración: "En ODD, cada criterio de aceptación declara su evidencia esperada y `/odd:verify` corre los tests si el proyecto los tiene."
- `### Branches`: suma `odd/{nombre}`, creado por Claude en `/odd`.
- `### Pull Requests`: la condición de merge suma el caso ODD: "Un ODD se mergea solo con `/odd:verify` sin CRITICAL, seguridad y explicabilidad en `sí` y el dato inesperado en `no aplica (ODD)`. El `/odd:close` se ejecuta después del merge, nunca antes."
- `## Puerta de integración`, "Resultados y condición de merge": suma el resultado `no aplica (ODD)`, que solo usa `/odd:verify` en la pregunta del dato inesperado y no bloquea el merge.
- Regla 7 de "Reglas de ejecución del Agente": suma al final "En un handoff ODD, la evidencia va en `## Evidencia` del documento ODD y no se escribe la nota `apply\` del vault."
- Tabla "Cuándo actuar", tres filas:

  | Comando | Lee | Escribe |
  |---|---|---|
  | `/odd` | `context.md` | actualiza `context.md` (ODD activo) |
  | `/odd:verify` | `docs/odd/<nombre>.md` del repo | actualiza `context.md` (verificado) |
  | `/odd:close` | `docs/odd/<nombre>.md` del repo | `archive\AAAA-MM-DD-odd-{nombre}.md` + `_index.md` + reescribe `arquitectura.md` si el ODD tocó la visión + actualiza `context.md` |

- "Estructura del vault": en `archive\` se agrega el comentario "← también los ODD cerrados (`AAAA-MM-DD-odd-{nombre}.md`)".
- "Comandos PowerShell": un bloque "Escribir nota de ODD (al `/odd:close`)", igual al de archive con el nombre `AAAA-MM-DD-odd-{nombre}.md`.

**D13. Plantillas del Agente (desde la fuente).** Las plantillas no se editan a mano:
- Fragmento nuevo `templates/fuente/fragmentos/handoff-odd.md` con el contenido de D6 en segunda persona (lista de viñetas, sin título).
- En los cuatro esqueletos de `templates/fuente/esqueletos/` (`AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc` y `GEMINI.md`), inmediatamente después de la marca `<!-- incluir: reglas-ejecucion -->` y antes del título siguiente, se agrega el título `## Handoff ODD`, una línea en blanco y la marca `<!-- incluir: handoff-odd -->`, con las mismas líneas en blanco que las demás secciones del esqueleto.
- En `templates/fuente/fragmentos/reglas-ejecucion.md`, la regla 7 suma al final, separada por un espacio, la oración "En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault." (equivalente en segunda persona de la oración de D12). El título de la regla no cambia, así que el control de títulos contra el `CLAUDE.md` sigue pasando.
- Después se corre `pwsh -NoProfile -File scripts/generar-plantillas.ps1` y `-Comprobar`. Como las cuatro salen del mismo fragmento, el texto es idéntico por construcción: esta sección no agrega duplicación a mano.

**D14. CI y `branch-pr`.**
- `pr-check.yml`, paso "Check branch name": acepta `change/` u `odd/`. El mensaje de error lista las dos convenciones (`change/{nombre-change}` y `odd/{nombre}`) con un ejemplo de cada una. Los demás pasos no cambian: el título `[nombre] descripción` y el `Spec-ID:` valen igual.
- Como `pr-check.yml` es la fuente que copia `sincronizar-proyecto.ps1`, los proyectos lo reciben al sincronizar. En este repo queda `igual` por definición.
- `skills/branch-pr/SKILL.md`: acepta `odd/{nombre}`. Con `odd/`, controla que exista `docs/odd/{nombre}.md` en vez de los artefactos OpenSpec, que el trailer sea `Spec-ID: odd-{nombre}` y que el checklist del PR diga "`/odd:verify` pendiente de ejecutar" en vez de "`/opsx:verify` pendiente de ejecutar". La línea de la puerta pasa a "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)".

**D15. Skill y comandos.** `skills/odd-change/SKILL.md` describe los tres pasos (D5, D7 y D8) con el escalado (D10). `.claude/commands/odd/start.md`, `verify.md` y `close.md` tienen el mismo texto que la sección correspondiente de la skill, como hoy pasa entre `skills/openspec-*` y `.claude/commands/opsx/`. En Claude Code, `.claude/commands/odd/start.md` se invoca como `/odd:start`. Para que `/odd` funcione sin sufijo, se agrega también `.claude/commands/odd.md` con el mismo contenido que `start.md`.

**D16. Instalación.** Con `scripts/instalar.ps1` (ADR 0001): primero `pwsh -NoProfile -File scripts/instalar.ps1 -Simular` desde la raíz del repo. Si algún archivo figura `con cambios locales`, se frena y se pregunta al usuario (no se usa `-Forzar` sin su confirmación). Si no, se corre sin `-Simular`: instala `CLAUDE.md`, todas las skills (incluida `odd-change/`) y todos los comandos (`opsx/`, `odd/` y `odd.md`), instala `GEMINI.md` si existe `~/.gemini`, y sincroniza, commitea y pushea el espejo del vault. La tabla de hashes del script es la evidencia.

**D17. Commits.** Cinco commits, separados de `openspec/`, cada uno con un único bloque final de trailers con `Spec-ID: clasificacion-odd-sdd`:
1. `test: tests del flujo ODD` — `tests/clasificacion-odd.Tests.ps1`, `tests/datos/pr-check-antes.yml` y el ajuste de C01 en `tests/generar-plantillas.Tests.ps1` (D19);
2. `feat: flujo ODD (skill, comandos y branch-pr)` — `skills/odd-change/`, `.claude/commands/odd/`, `.claude/commands/odd.md` y `skills/branch-pr/`;
3. `feat: clasificación ODD / SDD en las reglas globales` — `.claude/CLAUDE.md` y `openspec/config.yaml`, con la descripción del impacto;
4. `feat: handoff ODD en las plantillas y branches odd en CI` — `templates/fuente/`, las cuatro plantillas regeneradas, `.github/workflows/pr-check.yml` y `.github/copilot-instructions.md` sincronizada;
5. `docs: flujo ODD en las guías y visión del repo` — `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `docs/arquitectura/vision.md` (D20).

**D18. Relación con el rol de arquitecto de software.**
- **Ubicación del documento ODD:** `docs/odd/<nombre>.md` en vez de `odd/tasks/<nombre>.md`. Alternativas descartadas: (a) `odd/tasks/` sumando `odd/` a las carpetas implícitas, que obliga a modificar la regla en el `CLAUDE.md`, en propose y verify (skill y comando) y en la spec `project-architecture`, y a volver a copiar todo en cada máquina; (b) `openspec/odd/`, que mezcla un documento sin schema OpenSpec con los artefactos que lee el CLI y que el verify excluye por completo. `docs/` ya es implícita en todos los proyectos y el criterio K7 ya no cuenta la documentación.
- **ADR:** un ODD nunca genera ADR. Todo pedido que cumple un criterio de ADR es SDD por K10, que no se puede pasar por alto, porque el ADR se redacta en el `design.md` y un ODD no tiene design.
- **Visión:** al escribir el documento, Claude lee `docs/arquitectura/vision.md` si existe. Si el ODD paga una deuda de `## Hoja de ruta` (por ejemplo, un refactor sin cambio de comportamiento), `## Checklist` incluye la tarea de quitarla y "Archivos permitidos" incluye `docs/arquitectura/vision.md`. El `/odd:verify` controla que el diff lo toque (WARNING, D7) y el `/odd:close` reescribe `arquitectura.md` del vault (D8). Un ODD no agrega deuda a la hoja de ruta: si al implementar aparece deuda nueva, el Agente la anota en `## Progreso` y Claude la lleva al próximo propose.
- **Revisión de impacto:** el documento ODD no lleva `## Impacto en el sistema`. Los criterios K1 a K10 cumplen esa función: si un cambio afecta algo fuera de los archivos permitidos, es SDD.

**D19. Tests y CI de este repo.** El repo tiene tests y el check "plantillas" tiene que seguir en verde:
- `tests/clasificacion-odd.Tests.ps1` (nuevo, mismo estilo que los demás: `Probar`, `Afirmar`, marcador `# test-plan: clasificacion-odd-sdd/<ID>` arriba de cada test) con los tests automáticos del Test Plan: S16, S17, S18, S19, S20 y S25, más C02. Leen archivos del repo y no escriben nada.
- **C01 se ajusta, sin aflojarlo.** Hoy compara cada plantilla, sin el aviso y sin `## Propio del proyecto`, con `tests/datos/plantillas-antes/`; al sumar la sección ODD fallaría. La función `Limpiar-PlantillaParaC01` suma dos quitas exactas y solo si están presentes: (a) el bloque desde la línea `## Handoff ODD` hasta la línea anterior al siguiente título `## `, incluida la línea en blanco que lo separa; (b) la cadena exacta " En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault." (con el espacio inicial). El resto de la comparación no cambia, así que C01 sigue probando que fuera de esas dos adiciones ninguna palabra cambió. Las adiciones las prueban S16 y S20. El test suma el marcador `# test-plan: clasificacion-odd-sdd/C01` debajo del que ya tiene. `tests/datos/plantillas-antes/` no se toca.
- **C02 (caracterización de `pr-check.yml`):** copia de `.github/workflows/pr-check.yml` actual en `tests/datos/pr-check-antes.yml`. El test compara los dos archivos, cada uno sin el paso "Check branch name" (desde la línea `- name: Check branch name` hasta la línea anterior al siguiente `- name:`), con fin de línea normalizado. Verde antes y después del cambio.
- El CI no cambia: `plantillas.yml` ya corre todos los `tests/*.Tests.ps1`, `generar-plantillas -Comprobar` y la sincronización del repo. Después de regenerar las plantillas hay que sincronizar `.github/copilot-instructions.md` del repo con `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot` (debe dar `actualizado` sin `-Forzar`, porque la copia actual es la plantilla anterior) y después `-Comprobar` con código 0.

**D20. Actualización de la visión.** `docs/arquitectura/vision.md` ya existe. Cambios exactos:
- `## Componentes`, línea de `.claude/commands/`: pasa a "- `.claude/commands/`: comandos de Claude Code (`opsx/` para SDD, `odd/` y `odd.md` para ODD), con el mismo texto que su skill."
- `## Componentes`, línea de `.github/workflows/`: "`pr-check.yml` (convenciones de PR, ...)" pasa a "`pr-check.yml` (convenciones de PR con branches `change/` u `odd/`, se copia a los proyectos)", sin cambiar el resto de la línea.
- `## Componentes`, línea de `docs/`: pasa a "- `docs/`: guías, SRS, ADRs y esta visión. En los proyectos, `docs/odd/` guarda los documentos ODD."
- `## Hoja de ruta`, deuda [media] de comandos: el origen pasa a "changes anteriores y clasificacion-odd-sdd (suma `odd.md`, tercera copia del texto de inicio)". La propuesta no cambia.
- `## Hoja de ruta`, deuda [baja] del `CLAUDE.md`: el origen pasa a "rol-arquitecto-software y clasificacion-odd-sdd". La propuesta no cambia.
- `## Propósito`, `## Contexto e integraciones` y `## Decisiones vigentes` no cambian (no hay ADR nuevo).

## Impacto en el sistema

**Componentes afectados:**
- Todos los proyectos que usan el workflow: Claude clasifica sus pedidos desde la instalación. Para usar ODD hay que correr `scripts/sincronizar-proyecto.ps1` en cada proyecto (trae las plantillas con `## Handoff ODD` y el `pr-check.yml` que acepta `odd/*`).
- Vault: `archive\` recibe notas ODD (`tipo: odd`) y `/odd:close` puede reescribir `arquitectura.md`. El inicio de sesión las lee sin cambios.
- Specs vigentes: `integration-gate` (condición de merge) y `agent-templates` (handoff ODD desde la fuente). `project-architecture` no cambia, porque el documento ODD va en `docs/`. `rules-sync` no cambia: el mecanismo se usa tal cual.
- `/opsx:propose`, `/opsx:verify` y `/opsx:archive` no cambian. El SRS no cambia, porque un ODD no cambia specs.
- Tests y CI de este repo: C01 se ajusta y se suman C02 y seis tests (D19).

**Atributos de calidad:** sin `## Calidad` declarada en este repo. Mantenibilidad: el `CLAUDE.md` suma una sección; la sección ODD de las plantillas sale de un solo fragmento.

**Decisiones de arquitectura:** ninguna. El change no cumple ningún criterio de ADR: no cambia `## Stack` ni `nivel` (los tests usan PowerShell 7, ya decidido en el ADR 0001), no suma integraciones, no adopta un patrón transversal y no hay `## Calidad` con atributos en compromiso.

**Deuda técnica:**
- Agrega: `odd.md` igual a `odd/start.md` y una skill nueva con sus comandos en espejo; entra en la deuda [media] de comandos de la visión (D20).
- Paga: el proceso "Setup de máquina" y "Onboarding de proyecto" desactualizados en `openspec/config.yaml` (D11).
- Descubre: ninguna.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `skills/odd-change/SKILL.md` | `skills/` |
| `.claude/commands/odd.md`, `.claude/commands/odd/start.md`, `verify.md`, `close.md` | `.claude/` (carpeta que empieza con `.`) |
| `templates/fuente/fragmentos/handoff-odd.md` | subcarpeta de `templates/` |
| `tests/clasificacion-odd.Tests.ps1`, `tests/datos/pr-check-antes.yml` | `tests/` |

Ningún archivo nuevo en `docs/` de este repo: la visión se actualiza (D20). En cada proyecto, los documentos ODD van en `docs/odd/`. Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo, con un vault falso.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, la skill, los comandos, la fuente, las plantillas ni los tests. — Verificación: S20 de `sincronizar-reglas` repetido con un script en archivo (busca `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex`) en `scripts/`, `tests/`, `templates/`, `skills/odd-change/`, `.claude/commands/odd*` y `.claude/CLAUDE.md`, sin resultados (tarea 4.6).
- Un ODD nunca toca datos externos o personales ni controles de seguridad: K2 y K3 no se pueden pasar por alto, y el verify los vuelve a evaluar sobre el diff real. — Verificación: S04, S05 y S10.
- La nota del vault no copia código ni valores sensibles. — Verificación: revisión del texto de D9 en la skill y en `close.md`, y S12.
- `/odd:close` no crea commits ni pushea en el repo del proyecto y no cambia la cuenta activa de `gh`. — Verificación: revisión del texto de D8 y S12.
- Los tests nuevos solo leen archivos del repo y no escriben en `$HOME` ni en el vault. — Verificación: revisión del diff de `tests/clasificacion-odd.Tests.ps1`.
- Commit aparte del `CLAUDE.md` con el impacto. La instalación frena ante cambios locales (D16). — Verificación: tarea 3.4 y salida de `-Simular` en 6.1.

## Impacto en proyectos existentes

- **SDD sin cambios:** propose, apply, verify y archive siguen igual. Los changes en curso no se ven afectados.
- **Clasificación:** desde la instalación, Claude clasifica los pedidos nuevos. Algunos que antes iban por SDD ahora se proponen como ODD; el usuario puede pedir SDD siempre.
- **Para usar ODD en un proyecto** hay que correr `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .` (con `-Agentes` según el agente). Sin la plantilla nueva, el Agente no sabe qué hacer con un handoff ODD. Sin el `pr-check.yml` nuevo, el PR de un branch `odd/*` falla el chequeo de branch. El script conserva `## Propio del proyecto` y frena ante contenido propio sin marcar.
- **Vault:** las notas ODD van en el mismo `archive\` que las de SDD, con `tipo: odd` en el frontmatter. El inicio de sesión las lee igual.
- **SRS:** los ODD no aparecen en el SRS, porque no cambian specs.

## Risks / Trade-offs

- [Un cambio que parece chico cambia el comportamiento descrito en una spec y entra por ODD] → El verify re-clasifica sobre el diff real y da CRITICAL "escalar a SDD". K2 y K3 no se pueden pasar por alto. Ante la duda, el criterio se considera cumplido.
- [El límite de 5 archivos de K7 es arbitrario] → Es el mismo umbral que ya usan las reglas de delegación al Agente. Se puede pasar por alto con aviso en el documento.
- [Menos rastro que un SDD] → El documento ODD queda en el repo y la nota en el vault, con evidencia y PR. Lo que no hay es delta spec, porque no cambia ninguna.
- [Ajustar C01 podría ocultar cambios] → Las dos quitas son cadenas exactas y solo de lo que este change agrega; S16 y S20 prueban que esas adiciones existen. Cualquier otra diferencia sigue fallando.
- [Duplicación skill/comandos] → S25 compara automáticamente el texto de cada comando ODD con su sección de la skill. La deuda de fondo queda en la hoja de ruta.

## Migration Plan

Primero se edita, se mergea y se instala con `scripts/instalar.ps1` (D16). Después, en cada proyecto que quiera usar ODD, se corre `scripts/sincronizar-proyecto.ps1`. Rollback: revertir el PR, volver a correr `scripts/instalar.ps1` desde `master` (reinstala y resincroniza el espejo) y volver a correr `sincronizar-proyecto.ps1` en los proyectos.

## Test Plan

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5, declarado en `openspec/config.yaml`). Las verificaciones de archivos del repo son automáticas (S16 a S20, S25, C01 y C02 en `tests/clasificacion-odd.Tests.ps1` y `tests/generar-plantillas.Tests.ps1`). El comportamiento de Claude y del Agente es manual: son instrucciones en Markdown que solo se pueden probar con sesiones.

Las pruebas manuales usan sesiones nuevas de `claude -p --permission-mode acceptEdits --add-dir <vault falso> --allowedTools` acotados (lectura, edición, `PowerShell`, `git`, `openspec`, `gh` y `python`), de a 3 como máximo, con el vault falso en `OBSIDIAN_VAULT`. `PowerShell` y `--add-dir` hacen falta para leer la variable y escribir en el vault falso: sin ellos, `claude -p` saltea el vault (aprendido en `rol-arquitecto-software`). Las que necesitan respuestas humanas (aprobación del documento y explicabilidad) las hace el usuario en una sesión interactiva.

Fixtures:
- **Repo P** (`$env:TEMP\odd-prueba-p`): `project_type: etl`; `## Tests` con `- comando: python -m unittest discover -s tests -q` y `- timeout: 2`; ficha con `- leads (nombre, teléfono, email): formulario web (externo) | personal`; una spec vigente `openspec/specs/mensajes/spec.md` que dice que el mensaje de bienvenida es "Hola, {nombre}"; `src/mensajes.py` con el texto "Hla, {nombre}" (bug contra la spec) y su test; `src/leads.py` que lee los campos del formulario; `## Stack` con `- lenguaje: Python 3.11`; `## Arquitectura` con `- src/: código` y `- tests/: tests`; `docs/arquitectura/vision.md` con `## Hoja de ruta` que tiene la deuda `- [baja] nombres de variables en inglés y castellano mezclados en src/mensajes.py — origen: fixture — propuesta: renombrar a castellano`; y las reglas del Agente y el `pr-check.yml` puestos con `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto <P> -PrCheck` desde este repo (después de la instalación).
- **Vault falso V** (`$env:TEMP\odd-prueba-vault`): repo git con `projects/odd-prueba-p/context.md` y `_index.md`, y un remote local bare para que el push funcione.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Clasificación / Pedido ODD | manual: en P, "corregí el typo del mensaje de bienvenida" se clasifica ODD con el motivo en una línea | repo P |
| S02 | Clasificación / Pedido SDD por spec | manual: en P, "cambiá el mensaje de bienvenida a 'Buen día, {nombre}'" se clasifica SDD por K1 | repo P |
| S03 | Clasificación / Duda | manual: en P, un pedido ambiguo sobre "mejorar los mensajes" se clasifica SDD por K8 | repo P |
| S04 | Clasificación / Dato externo no se puede pasar a ODD | manual: en P, "validá que el teléfono no venga vacío" da SDD por K2, y al pedir ODD Claude lo rechaza | repo P |
| S05 | Clasificación / Usuario pasa a ODD con criterio permitido | manual: un pedido que cumple solo K7 pasa a ODD a pedido del usuario y el documento lo anota en `## Clasificación` | repo P |
| S06 | Documento / Formato y aprobación | manual (usuario): `/odd typo-bienvenida` en una sesión interactiva en P crea `docs/odd/typo-bienvenida.md` con todas las secciones de D4, pide aprobación y recién después crea el branch `odd/typo-bienvenida` | repo P |
| S07 | Inicio / Vault actualizado | manual: después de S06, `context.md` de V dice "ODD activo: `typo-bienvenida`" y hay un commit nuevo en V | vault V |
| S08 | Agente / Implementa con evidencia | manual: el Agente implementa el ODD de S06; el documento tiene `[x]` con evidencia, `estado: listo-para-verify` y commits con `Spec-ID: odd-typo-bienvenida` | repo P |
| S09 | Verify / Aprobado | manual (usuario): `/odd:verify typo-bienvenida` en una sesión interactiva da sin CRITICAL, con la puerta en `sí`, `sí` y `no aplica (ODD)`, y deja `estado: verificado` | repo P |
| S10 | Verify / Re-clasificación | manual: en una rama `odd/toca-leads` de P cuyo diff modifica `src/leads.py`, el verify da CRITICAL "escalar a SDD" por K2 | repo P |
| S11 | Verify / Fuera de alcance | manual: en una rama `odd/fuera-de-alcance` cuyo diff toca un archivo no permitido, el verify da CRITICAL de alcance | repo P |
| S12 | Cierre / Nota en Obsidian | manual: después de mergear S09, `/odd:close typo-bienvenida` crea `archive/AAAA-MM-DD-odd-typo-bienvenida.md` en V con el frontmatter de D9, agrega el link a `_index.md`, actualiza `context.md`, commitea y pushea V al remote bare; en P no hay commits nuevos y el documento sigue `estado: verificado` | vault V y repo P |
| S13 | Cierre / Sin merge | manual: `/odd:close` sobre un branch `odd/*` sin mergear frena sin escribir en el vault | repo P |
| S14 | Inicio de sesión / Lee la nota ODD | manual: una sesión nueva en P lee `context.md` y la nota ODD de `archive\` | repo P |
| S15 | Escalado | manual: el Agente avisa "escalar a SDD" en un ODD que necesita una dependencia; Claude deja `estado: escalado` y ofrece `/opsx:propose` con el documento como entrada | repo P |
| S16 | Plantillas / Handoff ODD | auto: `templates/fuente/fragmentos/handoff-odd.md` existe; `## Handoff ODD` aparece exactamente una vez en cada una de las cuatro plantillas generadas, después de `## Reglas de ejecución (obligatorias)`; el cuerpo de la sección (hasta el siguiente `## `) es idéntico en las cuatro y menciona `docs/odd/<nombre>.md`, `odd/<nombre>`, `## Evidencia`, "escalar a SDD" y `Spec-ID: odd-<nombre>` | `tests/clasificacion-odd.Tests.ps1` |
| S17 | CI / Branch odd | auto: el script del paso "Check branch name" de `.github/workflows/pr-check.yml` contiene `'change/'` y `'odd/'`, y su mensaje de error contiene `change/{nombre-change}` y `odd/{nombre}`. Complemento manual: con la instalación, `sincronizar-proyecto.ps1` copia este `pr-check.yml` al repo P (S08 usa un branch `odd/*`) | `tests/clasificacion-odd.Tests.ps1` |
| S18 | Reglas documentadas | auto: `.claude/CLAUDE.md` tiene la sección `## Clasificación ODD / SDD` después de `## Reglas globales (obligatorias)` con las filas K1 a K10; `openspec/config.yaml` contiene "documento ODD aprobado", las tres entradas de glosario y la línea "Setup de máquina" con `scripts/instalar.ps1` | `tests/clasificacion-odd.Tests.ps1` |
| S19 | Puerta y merge en ODD | auto: "no aplica (ODD)" aparece en las secciones `### Pull Requests` y `## Puerta de integración` de `.claude/CLAUDE.md`, y "dato inesperado no aplica en ODD" en `skills/branch-pr/SKILL.md` | `tests/clasificacion-odd.Tests.ps1` |
| S20 | Regla 7 con excepción ODD | auto: la regla 7 de `.claude/CLAUDE.md` termina con la oración ODD de D12, y la regla 7 de las cuatro plantillas y de `templates/fuente/fragmentos/reglas-ejecucion.md` termina con la oración de D13, idéntica | `tests/clasificacion-odd.Tests.ps1` |
| S21 | Clasificación / Criterio de ADR | manual: en P, "agregá logging estructurado en todos los módulos" da SDD por K10, y al pedir ODD Claude lo rechaza | repo P |
| S22 | Visión / ODD que paga deuda | manual: en P, `/odd renombrar-variables` para la deuda de la visión: el documento tiene la tarea de quitarla de `## Hoja de ruta` y `docs/arquitectura/vision.md` en "Archivos permitidos"; en una rama `odd/renombrar-variables` armada a mano cuyo diff no toca la visión, el verify da WARNING de visión; con la visión tocada y mergeada, `/odd:close` reescribe `arquitectura.md` en V | repo P y vault V |
| S23 | Documento en `docs/odd/` | manual: el documento de S06 está en `docs/odd/typo-bienvenida.md` y el verify de S09 no reporta archivos fuera de las carpetas permitidas ni lo incluye en la explicabilidad | repo P |
| S24 | Visión del repo actualizada | manual: `git diff master -- docs/arquitectura/vision.md` muestra solo los cambios de D20 (tres líneas de `## Componentes` y el origen de dos deudas) | `docs/arquitectura/vision.md` |
| S25 | Comandos ODD iguales a la skill | auto: el cuerpo (sin frontmatter) de `.claude/commands/odd/start.md`, `verify.md` y `close.md` contiene el texto de la sección correspondiente de `skills/odd-change/SKILL.md` ("Inicio (`/odd`)", "Verify (`/odd:verify`)" y "Cierre (`/odd:close`)"), `start.md` y `verify.md` contienen además "Escalado", y `.claude/commands/odd.md` es igual a `odd/start.md` | `tests/clasificacion-odd.Tests.ps1` |
| C01 | Plantillas sin cambios fuera de lo ODD | auto: test existente de `tests/generar-plantillas.Tests.ps1`, ajustado según D19; verde antes y después | `tests/generar-plantillas.Tests.ps1` |
| C02 | `pr-check.yml` sin cambios fuera del paso de branch | auto: D19; verde antes y después | `tests/clasificacion-odd.Tests.ps1`, `tests/datos/pr-check-antes.yml` |

## Open Questions

Sin preguntas abiertas. Resueltas por el usuario el 09/11/2026:
- `/odd:verify` y `/odd:close` siguen separados (verify antes del merge, vault después).
- K7 queda en 5 archivos, el mismo umbral de las reglas de delegación. Se puede revisar después de algunos ODD reales.
- OBJ-01 queda con el texto de D11.
