## Context

- Motivación en `proposal.md` (Why). La idea sale de la conversación del 07/11/2026 sobre el exceso de ceremonia para cambios chicos y de Organic Driven Development (ODD), el protocolo por defecto de Gentle AI v3.0.0. Este change toma el paso de clasificar y el documento único por cambio. El usuario decidió no usar Engram y seguir con Obsidian, y pidió que el cambio chico se guarde en el vault al terminar.
- Hoy el `CLAUDE.md` global dice "Cada change tiene: `proposal.md + design.md + specs/**/*.md + tasks.md`" (regla 4) y exige `## Test Plan` en los changes nuevos (regla 9). `openspec/config.yaml` declara OBJ-01: "todo cambio de código pasa por una spec aprobada antes de implementarse".
- La tabla "Cuándo actuar" de la capa de Obsidian define qué lee y escribe cada comando. Al iniciar sesión, Claude lee `context.md` y las últimas 3 notas de `archive\`.
- `pr-check.yml` exige branches `change/*`, título `[nombre] descripción` y `Spec-ID:` en el body.
- Las cuatro plantillas de reglas del Agente repiten las mismas secciones. Su duplicación se resuelve en otro change.
- La puerta de integración del `CLAUDE.md` y de la spec `integration-gate` admite `sí`, `no`, `pendiente` y `no evaluada`, y `### Pull Requests` dice que el merge solo se hace con `/opsx:verify` aprobado. La regla 7 del Agente pide siempre la nota `apply\` del vault.
- Decisiones del usuario del 09/11/2026: OBJ-01 queda con el texto de D11; K7 queda en 5 archivos; `/odd:verify` y `/odd:close` siguen separados; el documento ODD del repo termina en `verificado` y el cierre queda registrado solo en el vault (D8), para no commitear en la rama principal.
- Retomado el 10/11/2026, después de mergear y archivar `rol-arquitecto-software` (#33). Desde ese change, Claude es arquitecto de software: todo design nuevo lleva `## Impacto en el sistema`, las decisiones que cumplen los criterios de ADR se registran en `docs/adr/`, cada proyecto tiene `docs/arquitectura/vision.md` con su hoja de ruta, y el archive reescribe `arquitectura.md` en el vault. Este design se ajusta a eso (D18, `## Impacto en el sistema` y `## Visión inicial`).
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

**D13. Plantillas del Agente.** En las cuatro plantillas (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`), una sección `## Handoff ODD` después de `## Reglas de ejecución (obligatorias)`, con el contenido de D6. El texto es idéntico en las cuatro. Además, la regla 7 de cada plantilla suma al final la oración "En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault.", idéntica en las cuatro (es el equivalente en segunda persona de la oración de D12).

**D14. CI y `branch-pr`.**
- `pr-check.yml`, paso "Check branch name": acepta `change/` u `odd/`. El mensaje de error lista las dos convenciones. Los demás pasos no cambian: el título `[nombre] descripción` y el `Spec-ID:` valen igual.
- `skills/branch-pr/SKILL.md`: acepta `odd/{nombre}`. Con `odd/`, controla que exista `docs/odd/{nombre}.md` en vez de los artefactos OpenSpec, que el trailer sea `Spec-ID: odd-{nombre}` y que el checklist del PR diga "`/odd:verify` pendiente de ejecutar" en vez de "`/opsx:verify` pendiente de ejecutar". La línea de la puerta pasa a "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)".

**D15. Skill y comandos.** `skills/odd-change/SKILL.md` describe los tres pasos (D5, D7 y D8) con el escalado (D10). `.claude/commands/odd/start.md`, `verify.md` y `close.md` tienen el mismo texto que la sección correspondiente de la skill, como hoy pasa entre `skills/openspec-*` y `.claude/commands/opsx/`. En Claude Code, `.claude/commands/odd/start.md` se invoca como `/odd:start`. Para que `/odd` funcione sin sufijo, se agrega también `.claude/commands/odd.md` con el mismo contenido que `start.md`.

**D16. Instalación.** Igual que en los changes anteriores: chequeo previo de cada archivo instalado contra `git show master:<ruta>` ignorando el fin de línea (frenar ante cambios locales). Después se copian a `~/.claude` el `CLAUDE.md`, todas las carpetas de `skills/` y todos los comandos de `.claude/commands/` (`opsx/`, `odd/` y `odd.md`), y se sincroniza el espejo `_global/reglas-globales.md`. En cada máquina con Antigravity, se actualiza `~/.gemini/GEMINI.md`. Se verifica con hashes.

**D17. Commits.** Cuatro commits de código, separados de `openspec/`, cada uno con un único bloque final de trailers con `Spec-ID: clasificacion-odd-sdd`:
1. `.claude/CLAUDE.md` y `openspec/config.yaml`, con la descripción del impacto;
2. `skills/odd-change/`, `.claude/commands/odd/`, `.claude/commands/odd.md` y `skills/branch-pr/`;
3. las cuatro plantillas y `.github/workflows/pr-check.yml`;
4. `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `docs/arquitectura/vision.md` (D18).

**D18. Relación con el rol de arquitecto de software.**
- **Ubicación del documento ODD:** `docs/odd/<nombre>.md` en vez de `odd/tasks/<nombre>.md`. Alternativas descartadas: (a) `odd/tasks/` sumando `odd/` a las carpetas implícitas, que obliga a modificar la regla en el `CLAUDE.md`, en propose y verify (skill y comando) y en la spec `project-architecture`, y a volver a copiar todo en cada máquina; (b) `openspec/odd/`, que mezcla un documento sin schema OpenSpec con los artefactos que lee el CLI y que el verify excluye por completo. `docs/` ya es implícita en todos los proyectos y el criterio K7 ya no cuenta la documentación.
- **ADR:** un ODD nunca genera ADR. Todo pedido que cumple un criterio de ADR es SDD por K10, que no se puede pasar por alto, porque el ADR se redacta en el `design.md` y un ODD no tiene design.
- **Visión:** al escribir el documento, Claude lee `docs/arquitectura/vision.md` si existe. Si el ODD paga una deuda de `## Hoja de ruta` (por ejemplo, un refactor sin cambio de comportamiento), `## Checklist` incluye la tarea de quitarla y "Archivos permitidos" incluye `docs/arquitectura/vision.md`. El `/odd:verify` controla que el diff lo toque (WARNING, D7) y el `/odd:close` reescribe `arquitectura.md` del vault (D8). Un ODD no agrega deuda a la hoja de ruta: si al implementar aparece deuda nueva, el Agente la anota en `## Progreso` y Claude la lleva al próximo propose.
- **Revisión de impacto:** el documento ODD no lleva `## Impacto en el sistema`. Los criterios K1 a K10 cumplen esa función: si un cambio afecta algo fuera de los archivos permitidos, es SDD.

## Visión inicial

Este repositorio todavía no tiene `docs/arquitectura/vision.md`. La tarea 4.3 lo crea con este contenido (el Agente lo copia; los enlaces a ADRs quedan vacíos porque no hay `docs/adr/`):

```markdown
# Visión de arquitectura: sdd-global-config

## Propósito
Configuración global del workflow SDD Híbrido (Claude arquitecto + Agente constructor). Ver la descripción y `## Objetivos de Negocio` (U-01 a U-03 y OBJ-01 a OBJ-06) en `openspec/config.yaml`.

## Contexto e integraciones
- Actores: usuario del workflow, Claude (arquitecto de software), Agente (constructor: Antigravity, Cursor, Copilot u otro) y mantenedor de este repositorio.
- Sistemas externos: OpenSpec CLI (artefactos y validación), GitHub (`gh`, PR y Actions con `pr-check.yml`), vault de Obsidian versionado en git (contexto, notas y espejo de reglas) y las carpetas de instalación `~/.claude/` y `~/.gemini/`.

## Componentes
- `.claude/CLAUDE.md`: reglas globales; fuente que se instala en `~/.claude/CLAUDE.md` y se espeja en el vault.
- `.claude/commands/`: comandos de Claude Code (`opsx/` y `odd/`), con el mismo texto que su skill.
- `skills/`: skills de Claude que se instalan en `~/.claude/skills/`.
- `templates/`: plantillas de reglas para agentes no-Claude, que se copian a cada proyecto.
- `.github/workflows/`: chequeos de convención de los PR.
- `openspec/`: specs vigentes del workflow y changes.
- `docs/`: guías, SRS y esta visión.

## Decisiones vigentes
Sin ADRs todavía (`docs/adr/` no existe).

## Hoja de ruta
- [media] las cuatro plantillas del Agente repiten las mismas reglas — origen: changes de reglas del Agente y clasificacion-odd-sdd — propuesta: change de fuente única de plantillas que genere las cuatro desde un solo texto
- [media] cada comando de `.claude/commands/` repite el texto de su skill y la paridad se controla a mano en cada apply — origen: changes anteriores — propuesta: script que compare skill y comando, o comandos que solo deleguen en la skill
- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software y clasificacion-odd-sdd — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas
- [baja] la ficha de este repo no declara `## Alcance`, `## Datos`, `## Stack` ni `## Calidad`, y `## Arquitectura` no declara `nivel` — origen: ficha del proyecto — propuesta: correr `/ficha` y `/arquitectura`
```

## Impacto en el sistema

**Componentes afectados:**
- Todos los proyectos que usan el workflow: Claude clasifica sus pedidos desde la instalación. Para usar ODD hay que volver a copiar las plantillas del Agente y el `pr-check.yml`.
- Vault: `archive\` recibe notas ODD (`tipo: odd`) y `/odd:close` puede reescribir `arquitectura.md`. El inicio de sesión las lee sin cambios.
- Specs vigentes: `integration-gate` (condición de merge) y `agent-templates` (handoff ODD). `project-architecture` no cambia, porque el documento ODD va en `docs/`.
- `/opsx:propose`, `/opsx:verify` y `/opsx:archive` no cambian. El SRS no cambia, porque un ODD no cambia specs.

**Atributos de calidad:** sin `## Calidad` declarada en este repo. Mantenibilidad del workflow: el `CLAUDE.md` suma una sección, y las cuatro plantillas suman la misma sección `## Handoff ODD`.

**Decisiones de arquitectura:** ninguna. El change no cumple ningún criterio de ADR: no cambia `## Stack` ni `nivel`, no suma integraciones, no adopta un patrón transversal y no hay `## Calidad` con atributos en compromiso.

**Deuda técnica:**
- Agrega: la sección `## Handoff ODD` repetida en cuatro plantillas, y `odd.md` igual a `odd/start.md` (tercera copia del mismo texto con la skill). Quedan en la hoja de ruta de la visión inicial.
- Descubre: el `CLAUDE.md` global largo y la ficha incompleta de este repo, también en la hoja de ruta.
- Paga: ninguna.

## Ubicación de archivos

Archivos nuevos en el repo:
- `docs/arquitectura/vision.md` (tarea 4.3, desde `## Visión inicial`)
- `skills/odd-change/SKILL.md`
- `.claude/commands/odd.md`
- `.claude/commands/odd/start.md`
- `.claude/commands/odd/verify.md`
- `.claude/commands/odd/close.md`

En cada proyecto, los documentos ODD van en `docs/odd/`. Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo, con un vault falso.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, la skill, los comandos ni las plantillas. — Verificación: revisión del diff y `Select-String -SimpleMatch 'C:\Users'` sin resultados en los archivos nuevos y modificados.
- Un ODD nunca toca datos externos o personales ni controles de seguridad: K2 y K3 no se pueden pasar por alto, y el verify los vuelve a evaluar sobre el diff real. — Verificación: S04, S05 y S10.
- La nota del vault no copia código ni valores sensibles. — Verificación: revisión del texto de D9 en la skill y en `close.md`, y S12.
- `/odd:close` no crea commits ni pushea en el repo del proyecto y no cambia la cuenta activa de `gh`. — Verificación: revisión del texto de D8 y S12.
- Commit aparte del `CLAUDE.md` con el impacto. La instalación tiene chequeo previo de cambios locales (D16). — Verificación: tareas 2.4 y 6.1.

## Impacto en proyectos existentes

- **SDD sin cambios:** propose, apply, verify y archive siguen igual. Los changes en curso no se ven afectados.
- **Clasificación:** desde la instalación, Claude clasifica los pedidos nuevos. Algunos que antes iban por SDD ahora se proponen como ODD; el usuario puede pedir SDD siempre.
- **Para usar ODD en un proyecto** hay que volver a copiar las plantillas del Agente y el `pr-check.yml`. Sin la plantilla nueva, el Agente no sabe qué hacer con un handoff ODD. Sin el `pr-check.yml` nuevo, el PR de un branch `odd/*` falla el chequeo de branch.
- **Vault:** las notas ODD van en el mismo `archive\` que las de SDD, con `tipo: odd` en el frontmatter. El inicio de sesión las lee igual.
- **SRS:** los ODD no aparecen en el SRS, porque no cambian specs.

## Risks / Trade-offs

- [Un cambio que parece chico cambia el comportamiento descrito en una spec y entra por ODD] → El verify re-clasifica sobre el diff real y da CRITICAL "escalar a SDD". K2 y K3 no se pueden pasar por alto. Ante la duda, el criterio se considera cumplido.
- [El límite de 5 archivos de K7 es arbitrario] → Es el mismo umbral que ya usan las reglas de delegación al Agente. Se puede pasar por alto con aviso en el documento.
- [Menos rastro que un SDD] → El documento ODD queda en el repo y la nota en el vault, con evidencia y PR. Lo que no hay es delta spec, porque no cambia ninguna.
- [Se suma la misma sección en cuatro plantillas] → La tarea de evidencia compara que el texto sea idéntico. La duplicación de fondo se resuelve en otro change.
- [Duplicación skill/comandos] → Igual que en los changes anteriores: la evidencia compara que el texto sea idéntico.

## Migration Plan

Primero se edita y se instala (D16). Después, en cada proyecto que quiera usar ODD, se vuelven a copiar las plantillas del Agente y el `pr-check.yml`. Rollback: revertir el PR, reinstalar desde `master`, volver a sincronizar el espejo y volver a copiar las plantillas anteriores en los proyectos.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude o el Agente. Todo el plan es manual. No hay tests de caracterización porque no hay código. Un test automático futuro llevaría `test-plan: clasificacion-odd-sdd/<ID>`.

Las pruebas automáticas usan sesiones nuevas de `claude -p --permission-mode acceptEdits --add-dir <vault falso> --allowedTools` acotados (lectura, edición, `PowerShell`, `git`, `openspec`, `gh` y `python`), de a 3 como máximo, con el vault falso en `OBSIDIAN_VAULT`. `PowerShell` y `--add-dir` hacen falta para leer la variable y escribir en el vault falso: sin ellos, `claude -p` saltea el vault (aprendido en `rol-arquitecto-software`). Las que necesitan respuestas humanas (aprobación del documento y explicabilidad) las hace el usuario en una sesión interactiva.

Fixtures:
- **Repo P** (`$env:TEMP\odd-prueba-p`): `project_type: etl`; `## Tests` con `- comando: python -m unittest discover -s tests -q` y `- timeout: 2`; ficha con `- leads (nombre, teléfono, email): formulario web (externo) | personal`; una spec vigente `openspec/specs/mensajes/spec.md` que dice que el mensaje de bienvenida es "Hola, {nombre}"; `src/mensajes.py` con el texto "Hla, {nombre}" (bug contra la spec) y su test; `src/leads.py` que lee los campos del formulario; `## Stack` con `- lenguaje: Python 3.11`; `## Arquitectura` con `- src/: código` y `- tests/: tests`; `docs/arquitectura/vision.md` con `## Hoja de ruta` que tiene la deuda `- [baja] nombres de variables en inglés y castellano mezclados en src/mensajes.py — origen: fixture — propuesta: renombrar a castellano`.
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
| S16 | Plantillas / Handoff ODD | manual: `Select-String -SimpleMatch "## Handoff ODD"` da un resultado en cada una de las cuatro plantillas, y el texto de la sección es idéntico en las cuatro | `templates/` |
| S17 | CI / Branch odd | manual: `pr-check.yml` acepta `odd/x` y rechaza `feature/x`, revisado en el diff y con un PR de prueba si hay repo de prueba en GitHub | `.github/workflows/pr-check.yml` |
| S18 | Reglas documentadas | manual: `Select-String` de "## Clasificación ODD / SDD" en `.claude/CLAUDE.md` y de "documento ODD aprobado" en `openspec/config.yaml` | `.claude/CLAUDE.md`, `openspec/config.yaml` |
| S19 | Puerta y merge en ODD | manual: `Select-String -SimpleMatch "no aplica (ODD)"` da resultado en las secciones "Pull Requests" y "Puerta de integración" de `.claude/CLAUDE.md` y en `skills/branch-pr/SKILL.md` | `.claude/CLAUDE.md`, `skills/branch-pr/SKILL.md` |
| S20 | Regla 7 con excepción ODD | manual: `Select-String -SimpleMatch "handoff ODD"` da resultado en la regla 7 de `.claude/CLAUDE.md` y de las cuatro plantillas, con la misma oración en las cuatro plantillas | `.claude/CLAUDE.md`, `templates/` |
| S21 | Clasificación / Criterio de ADR | manual: en P, "agregá logging estructurado en todos los módulos" da SDD por K10, y al pedir ODD Claude lo rechaza | repo P |
| S22 | Visión / ODD que paga deuda | manual: en P, `/odd renombrar-variables` para la deuda de la visión: el documento tiene la tarea de quitarla de `## Hoja de ruta` y `docs/arquitectura/vision.md` en "Archivos permitidos"; en una rama `odd/renombrar-variables` armada a mano cuyo diff no toca la visión, el verify da WARNING de visión; con la visión tocada y mergeada, `/odd:close` reescribe `arquitectura.md` en V | repo P y vault V |
| S23 | Documento en `docs/odd/` | manual: el documento de S06 está en `docs/odd/typo-bienvenida.md` y el verify de S09 no reporta archivos fuera de las carpetas permitidas ni lo incluye en la explicabilidad | repo P |
| S24 | Visión inicial del repo | manual: `docs/arquitectura/vision.md` de este repo tiene las cinco secciones y su contenido coincide con `## Visión inicial` del design | `docs/arquitectura/vision.md` |

## Open Questions

Sin preguntas abiertas. Resueltas por el usuario el 09/11/2026:
- `/odd:verify` y `/odd:close` siguen separados (verify antes del merge, vault después).
- K7 queda en 5 archivos, el mismo umbral de las reglas de delegación. Se puede revisar después de algunos ODD reales.
- OBJ-01 queda con el texto de D11.
