# Design

## Context

Ver `proposal.md` (Why). Estado actual que condiciona el diseño:

- `scripts/tablero-comun.ps1` tiene `Leer-ConfigTablero`, que lee el bloque `---` de `tablero.md` (o `-Config`) y valida `owner`, `numero` y `wip-*`. La usan `tablero.ps1` y `metricas.ps1`. Con `-ModoComprobar` devuelve "no configurado" sin mensaje.
- `scripts/metricas.ps1 -Semanas <n>` escribe `metricas.md` en la raíz del vault con resumen, throughput, tiempo por columna, trabajo en curso e issues cerrados del Project configurado (que tiene los issues de todos los repos).
- Las notas de cierre están en `$vault/projects/<proyecto>/archive/AAAA-MM-DD-<change>.md` (los ODD como `AAAA-MM-DD-odd-<nombre>.md`).
- `scripts/instalar.ps1` copia todo `skills/` a `~/.claude/skills/`: una skill nueva no necesita tocar el instalador. `/ficha` y `/arquitectura` son skills sin comando generado.
- El usuario decidió el 17/11: retro una sola y global, con la review adentro, nota en `$vault/retros/AAAA-MM-DD.md`, cadencia semanal con aviso al iniciar sesión configurable en `tablero.md`.

## Goals / Non-Goals

**Goals:**
- Que la retro sea una conversación guiada corta, con evidencia (lo archivado y las métricas) antes de opinar.
- Que el aviso sea una línea, sin ruido cuando no corresponde, igual que `tablero.ps1 -Comprobar` y `sincronizar-proyecto.ps1 -Aviso`.
- Que la parte determinística (fechas, período, lista de lo archivado) esté en un script con tests; la parte conversacional, en la skill.

**Non-Goals:**
- Que el script lea el contenido de las notas de archive o resuma: eso lo hace Claude en la skill.
- Una etiqueta especial para los issues de la retro: el origen va en el cuerpo y la nota de la retro lista sus issues.

## Decisions

### D1. Clave `cadencia-retro` en `Leer-ConfigTablero`

`scripts/tablero-comun.ps1`: en `Leer-ConfigTablero`, después del control de `wip-*`, si existe `cadencia-retro` y no cumple `^[1-9][0-9]*$`, devolver `@{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: cadencia-retro"; Codigo = 0 }`. Sumar `'cadencia-retro'` al hashtable `$cfg` (entero, o `$null` si falta). Sin otros cambios en la función.

Alternativa descartada: leer la clave solo en `retro.ps1` con un parser propio. Duplicaría la lectura del bloque `---` (atributo `mantenibilidad: alta`). Consecuencia aceptada: una `cadencia-retro` mal escrita también hace que `tablero.ps1` y `metricas.ps1` avisen `tablero.md inválido`, igual que pasa hoy con un `wip-*` mal escrito.

### D2. `scripts/retro.ps1`: parámetros y modos

Parámetros: `-Aviso`, `-Periodo` (exactamente uno; si no, `Error: se debe especificar exactamente uno de -Aviso o -Periodo` y código 1), `-Vault <ruta>` (por defecto `$env:OBSIDIAN_VAULT`), `-Config <ruta>` (por defecto `tablero.md` del vault, pasado a `Leer-ConfigTablero -RutaConfig`) y `-Ahora <fecha>` (por defecto la fecha actual; se usa solo la parte de fecha local). Carga `tablero-comun.ps1` con `. "$PSScriptRoot/tablero-comun.ps1"`, salida UTF-8 sin BOM como los otros scripts, y sale sin ejecutar nada si fue importado por dot-sourcing (mismo patrón que `tablero.ps1`), para que los tests puedan probar las funciones.

Funciones puras (sin I/O), separadas de la lectura de archivos:
- `Obtener-FechasRetro` recibe nombres de archivo y devuelve las fechas válidas: nombre exacto `^\d{4}-\d{2}-\d{2}\.md$` y fecha que existe en el calendario (`2026-13-40.md` y `notas.md` se ignoran).
- `Obtener-NotasArchive` recibe pares (proyecto, nombre de archivo) y un rango, y devuelve las de nombre `^(\d{4}-\d{2}-\d{2})-(.+)\.md$` con fecha válida dentro del rango (`desde` y `hasta` inclusive), con `Tipo = ODD` y el prefijo `odd-` quitado si el nombre empieza con `odd-`, y `Tipo = SDD` si no. Ordenadas por fecha y después por proyecto.

**Modo `-Aviso`** (todo silencioso salvo los dos avisos y la línea de inválido):
1. Sin vault (ni `-Vault` ni `OBSIDIAN_VAULT`) y sin `-Config`: código 0 sin salida.
2. `Leer-ConfigTablero -ModoComprobar`: si devuelve no configurado, código 0 sin salida; si devuelve inválido, imprimir su mensaje y código 0.
3. Sin `cadencia-retro`: código 0 sin salida.
4. Fechas de `<vault>/retros/*.md`. Sin ninguna: `Todavía no hay retros en el vault: corré /retro`, código 1.
5. `dias = (Ahora - última).Days`. Si `dias >= cadencia`: `Retro vencida: pasaron <dias> días desde la última (<AAAA-MM-DD>): corré /retro`, código 1. Si no, código 0 sin salida.

**Modo `-Periodo`:**
1. Sin vault: `Sin vault: OBSIDIAN_VAULT no definida`, código 0.
2. La config se lee igual; si no hay tablero, no hay cadencia o es inválida, la cadencia por defecto es 7 (el período no depende del tablero).
3. `desde` = fecha de la última retro, o `Ahora - cadencia` días si no hay ninguna. `hasta` = `Ahora`. `semanas` = techo de `(hasta - desde).Days / 7`, mínimo 1.
4. Salida exacta, una línea por renglón:
   - `Desde: AAAA-MM-DD`
   - `Hasta: AAAA-MM-DD`
   - `Semanas: <n>`
   - `Retro anterior: retros/AAAA-MM-DD.md` o `Retro anterior: ninguna`
   - `Terminado:`
   - una línea `- <proyecto>: <nombre> (AAAA-MM-DD, SDD|ODD)` por nota, o `Sin changes ni ODD archivados en el período.`
5. Código 0.

Las rutas que imprime son relativas al vault, nunca absolutas.

### D3. Skill `skills/retro/SKILL.md`

Frontmatter igual que `skills/ficha/SKILL.md` (`name: retro`, `description`, `license: MIT`, `metadata.version: "1.0"`). Descripción: "Guía la retro global semanal (review de lo terminado y Start / Stop / Continue) y crea un issue por acción acordada."

**Restricciones** (al principio): no crea changes, ramas ni commits en el repo, no escribe código; escribe solo la nota de `retros/` del vault y los issues; mira el proceso y no evalúa personas; no escribe nombres de personas, rutas absolutas ni datos personales en la nota ni en los issues. Si no está `OBSIDIAN_VAULT`, avisa "Sin vault no hay retro: definí OBSIDIAN_VAULT" y termina. Si falta `SDD_CONFIG_REPO`, pide la ruta y no la adivina. Duración objetivo: 15 minutos; Claude lleva el tiempo con las fases cortas y el usuario facilita como Scrum Master.

**Pasos:**

0. `git -C $vault pull --rebase` (si falla por conflicto, avisar y no forzar). Correr `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\retro.ps1" -Periodo` y guardar desde, hasta, semanas, retro anterior y lo terminado.
1. **Preparar:** leer la directiva primaria de Kerth en una frase ("Más allá de lo que descubramos, entendemos y creemos que todos hicieron el mejor trabajo que pudieron con lo que sabían, sus habilidades, los recursos disponibles y la situación"). Si hay retro anterior, leer su `## Acciones` y consultar cada issue con `gh issue view <n> --repo <repo> --json state,title`: mostrar abiertas y cerradas. Una acción cuyo issue `gh` no encuentra se marca `no encontrado`; una sin issue (`issue: pendiente`), `sin issue`; se sigue con la retro.
2. **Review (lo terminado):** correr `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\metricas.ps1" -Semanas <semanas>` y leer `metricas.md`; leer las notas de archive listadas (solo `## Qué se hizo` o el resumen equivalente). Mostrar por proyecto lo terminado (changes y ODD), los issues cerrados, lead time, cycle time y throughput, y el trabajo en curso. Preguntar con **AskUserQuestion** la opinión de quien usa el sistema ("¿Qué te pareció lo entregado? ¿Falta algo?", con opción "Nada que agregar"); lo que pida es candidato a acción. Si `metricas.ps1` avisa (sin `gh`, sin tablero), seguir sin métricas y decirlo.
3. **Recopilar datos (Start / Stop / Continue):** Claude propone candidatos con evidencia del período (verifies con CRITICAL o WARNING, tareas reabiertas, ODD escalados, WIP excedido aceptado, changes con muchas tareas, errores repetidos del Agente en las notas `apply\`) y los presenta con **AskUserQuestion** `multiSelect` en tres preguntas: Start, Stop y Continue; el usuario elige y suma los suyos con "Other".
4. **Analizar:** el usuario elige con **AskUserQuestion** hasta 3 ítems para trabajar. Para cada uno, una pregunta corta de "¿por qué pasa?" (hasta llegar a una causa que se pueda cambiar).
5. **Decidir acciones:** para cada ítem elegido, Claude redacta una acción SMART (qué se hace, cómo se mide que funcionó, quién la hace entre usuario, Claude y Agente, y fecha: la próxima retro por defecto). El usuario la confirma o corrige. Máximo 3 acciones. Por cada una, preguntar repo (por defecto `sdd-global-config`), prioridad (`alta`, `media`, `baja`) y tipo (`feature`, `deuda`, `bug`), y crear el issue (D4).
6. **Cerrar:** pedir con **AskUserQuestion** el ROTI (retorno del tiempo invertido, 1 a 5) y una cosa a mejorar de la retro. Escribir la nota (D5) y sincronizar el vault.

**Salida:** ruta relativa de la nota, issues creados con su URL, acciones pendientes de la retro anterior y aviso si el push falló o si alguna acción quedó con `issue: pendiente`.

### D4. Issue de cada acción

`gh issue create --repo <dueño/repo> --title "[retro] <acción corta>" --label "prioridad:<p>" --label "tipo:<t>" --body <cuerpo>`, con el cuerpo:
- `## Descripción`: la acción SMART completa.
- `## Criterios de aceptación`: una casilla con la medida acordada y otra con "Revisada en la retro siguiente".
- `## Notas`: `Origen: retro AAAA-MM-DD` y el ítem de Start / Stop / Continue que la originó.

No se agrega `status:approved`. Después: `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\tablero.ps1" -Columna backlog -Issue <url>`; un aviso del script no frena. Si `gh` no está, no hay red o la cuenta no tiene permiso en ese repo: la acción queda en la nota con `issue: pendiente` y la salida lo avisa. No se cambia de cuenta de `gh` por cuenta propia.

### D5. Nota de la retro

Ruta: `$vault/retros/AAAA-MM-DD.md` (fecha de hoy), UTF-8 sin BOM, escrita con la herramienta de escritura de archivos. Formato:
- Frontmatter: `tipo: retro`, `fecha`, `desde`, `hasta`, `roti`.
- `## Acciones anteriores`: cada acción de la retro anterior con su estado (`cerrado`, `abierto`, `no encontrado` o `sin issue`), o "Primera retro".
- `## Review`: `### Terminado` (por proyecto), `### Métricas` (lead time, cycle time, throughput y trabajo en curso, copiados de `metricas.md`, o "Sin métricas: <motivo>") y `### Opinión de quien usa el sistema`.
- `## Start / Stop / Continue`: tres listas.
- `## Análisis`: los ítems elegidos con su causa.
- `## Acciones`: `- [ ] <acción SMART> — issue: <repo>#<n> (o pendiente) — vence: AAAA-MM-DD`.
- `## Cierre`: ROTI y la mejora para la próxima retro.

Si el archivo ya existe (segunda retro del día), se agrega al final una sección `## Retro de las HH:MM` con las mismas subsecciones un nivel más abajo, sin tocar lo anterior. Después: `git -C $vault add -A`, commit `chore: retro AAAA-MM-DD` y push; si el push falla, avisar en la salida.

La nota no lleva nombres de personas (se habla de "usuario", "Claude" y "Agente"), rutas absolutas ni datos personales.

### D6. `/retro` es una skill sin comando generado

Se instala con `instalar.ps1` como el resto de `skills/`. No se agrega a `generar-plantillas.ps1` ni a `templates/fuente/comandos/`. Alternativa descartada: un comando en `.claude/commands/retro.md` generado desde la skill: suma una copia más para mantener sin necesidad (`/ficha` y `/arquitectura` ya funcionan así).

### D7. Reglas globales y guía

`.claude/CLAUDE.md` (fuera del bloque generado de reglas del Agente):
- `## Al iniciar cada sesión`, paso 3, después de "Comprobar el tablero": "Comprobar la retro: correr `pwsh $env:SDD_CONFIG_REPO\scripts\retro.ps1 -Aviso`. Si termina con 1, mostrar la línea al usuario; no correr `/retro` por cuenta propia. Si `$env:SDD_CONFIG_REPO` no está definida, saltear."
- `## Scrumban`, después de `### Métricas`: `### Cadencias` con: retro global (una para todo el vault) cada `cadencia-retro` días de `tablero.md` (acordado: 7); `/retro` empieza con la review (lo terminado y las métricas, más la opinión de quien usa el sistema) y sigue con Start / Stop / Continue; cada acción SMART es un issue en Backlog (lo aprueba el usuario); nota en `retros/AAAA-MM-DD.md`; aviso al iniciar sesión.
- `### Estructura del vault`: línea `retros\` con `AAAA-MM-DD.md ← retro global (/retro)`, al nivel de `tablero.md`.
- `### Cuándo actuar`: fila `/retro` | `retros\` anterior + `archive\` de todos los proyectos + `metricas.md` | `retros\AAAA-MM-DD.md` (y recalcula `metricas.md`).

`docs/workflow.md`, en `## Tablero Scrumban`: la línea `cadencia-retro: 7` en el ejemplo de `### 3. Configurar tablero.md en el vault` con su explicación, y una subsección `### Retro semanal` después de `### Métricas de flujo`, con qué hace `/retro`, el aviso al iniciar sesión y dónde queda la nota. Sin rutas absolutas ni nombres de cuentas.

## Impacto en proyectos existentes

Ninguno obligatorio. Un `tablero.md` sin `cadencia-retro` sigue siendo válido y el aviso no imprime nada, así que los proyectos y las máquinas que no actualicen siguen igual. El paso nuevo de inicio de sesión corre en todos los proyectos (la retro es global), pero sin cadencia configurada es silencioso. Los proyectos no reciben archivos nuevos: `sincronizar-proyecto.ps1` no cambia.

## Impacto en el sistema

**Componentes afectados:** vault (carpeta nueva `retros/` y clave nueva en `tablero.md`; lee `projects/*/archive/` y `metricas.md`), GitHub Issues y Project #4 (la retro crea issues en los repos que elija el usuario y los pone en Backlog), `scripts/tablero.ps1` y `scripts/metricas.ps1` (comparten `Leer-ConfigTablero`, que suma una validación), y todas las sesiones de Claude en cualquier proyecto (paso nuevo al iniciar sesión).

**Atributos de calidad:**
- mantenibilidad (alta): sin texto duplicado; la lectura de `tablero.md` se reutiliza de `tablero-comun.ps1` y `/retro` no genera comando — Verificación: S18 (`generar-plantillas.ps1 -Comprobar` sin diferencias) y revisión del diff: `retro.ps1` usa `Leer-ConfigTablero` y no tiene otro parser del bloque `---`.

**Decisiones de arquitectura:** ninguna.

**Deuda técnica:** agrega: el `CLAUDE.md` global suma `### Cadencias` y un paso al iniciar sesión, lo que agrava la deuda de su tamaño (#55); se actualiza su `origen` en la hoja de ruta.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `scripts/retro.ps1` | `scripts/` |
| `skills/retro/SKILL.md` | `skills/` (subcarpeta) |
| `tests/cadencias-scrumban.Tests.ps1` | `tests/` |

Sin señales de arquitectura: `retro.ps1` separa funciones puras de la lectura de archivos (D2) y queda por debajo del umbral de `tamaño`; `tablero-comun.ps1` suma unas líneas.

## Security Layer

`project_type: tooling`. No hay datos personales declarados en `## Datos`.

- Sin secretos ni tokens en scripts, skill, reglas ni notas: `gh` usa la sesión de la máquina — Verificación: revisión del diff: ningún token, password ni clave en las líneas agregadas.
- Sin rutas absolutas sensibles en artefactos que son instrucciones para IA ni en la salida de `retro.ps1` (rutas relativas al vault) — Verificación: S11 (las líneas de `-Periodo` no tienen la ruta del vault) y S18 (`docs/workflow.md` sin rutas absolutas).
- La nota y los issues no llevan nombres de personas ni datos personales (directiva primaria: se evalúa el proceso) — Verificación: S15 (la skill lo dice en sus restricciones).
- La skill no cambia la cuenta activa de `gh` y no agrega `status:approved` (la aprobación es del usuario) — Verificación: S14.
- Cambios al `CLAUDE.md` global y a skills en commits separados con descripción del impacto — Verificación: revisión del diff: `.claude/CLAUDE.md` en su propio commit `docs:`.
- Inputs externos validados: `cadencia-retro` y los nombres de archivo de `retros/` y `archive/` se validan antes de usarlos — Verificación: S02, S08, S09 y S13.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian `tablero-comun.ps1` (lo usan `tablero.ps1` y `metricas.ps1`) y `.claude/CLAUDE.md`. Archivo nuevo `tests/cadencias-scrumban.Tests.ps1`, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: cadencias-scrumban/<ID>` arriba de cada `Probar`. Los tests de `retro.ps1` usan `Con-CarpetaTemporal` como vault (`-Vault`), un `tablero.md` inventado (`owner: dueno-prueba`, `numero: 7`) y `-Ahora 2026-11-17`; ninguno llama a GitHub.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Configuración del tablero en el vault / Configuración con cadencia de retro | auto: `tablero.ps1 -Wip -Columna diseno -Config <tablero con cadencia-retro: 7> -Entrada <tarjetas inventadas>` imprime `Diseño: 0 de 1` y termina con 0 | `tests/cadencias-scrumban.Tests.ps1` |
| S02 | Configuración del tablero en el vault / Dato inválido: cadencia mal escrita | auto: con `cadencia-retro: 0`, `-3` y `abc`, `tablero.ps1 -Wip` imprime `tablero.md inválido: cadencia-retro` y termina con 0 | `tests/cadencias-scrumban.Tests.ps1` |
| S03 | Aviso de retro vencida / Retro vencida | auto: `retros/2026-11-09.md`, cadencia 7: salida `Retro vencida: pasaron 8 días desde la última (2026-11-09): corré /retro`, código 1 | `tests/cadencias-scrumban.Tests.ps1` |
| S04 | Aviso de retro vencida / Retro al día | auto: `retros/2026-11-14.md`, cadencia 7: sin salida, código 0; con `retros/2026-11-10.md` (7 días justos): vencida, código 1 | `tests/cadencias-scrumban.Tests.ps1` |
| S05 | Aviso de retro vencida / Sin ninguna retro | auto: sin carpeta `retros/` y con `retros/` vacía: `Todavía no hay retros en el vault: corré /retro`, código 1 | `tests/cadencias-scrumban.Tests.ps1` |
| S06 | Aviso de retro vencida / Sin cadencia o sin tablero | auto: `tablero.md` sin `cadencia-retro`, vault sin `tablero.md`, y sin `-Vault` con `OBSIDIAN_VAULT` vacía: sin salida, código 0 | `tests/cadencias-scrumban.Tests.ps1` |
| S07 | Aviso de retro vencida / Dato inválido: archivos que no son retros | auto: `retros/` con `2026-11-14.md`, `notas.md` y `2026-13-40.md`: al día (sin salida, código 0); solo con `notas.md` y `2026-13-40.md`: `Todavía no hay retros...` | `tests/cadencias-scrumban.Tests.ps1` |
| S08 | Aviso de retro vencida / Dato inválido: cadencia mal escrita en el aviso | auto: `cadencia-retro: abc`: `tablero.md inválido: cadencia-retro`, código 0 | `tests/cadencias-scrumban.Tests.ps1` |
| S09 | Período de la retro / Notas del período | auto: `retros/2026-11-10.md`, `projects/alfa/archive/2026-11-08-viejo.md`, `projects/alfa/archive/2026-11-12-nuevo.md`, `projects/beta/archive/2026-11-15-odd-texto.md`: líneas `Desde: 2026-11-10`, `Hasta: 2026-11-17`, `Semanas: 1`, `Retro anterior: retros/2026-11-10.md`, `- alfa: nuevo (2026-11-12, SDD)`, `- beta: texto (2026-11-15, ODD)`, sin `viejo` | `tests/cadencias-scrumban.Tests.ps1` |
| S10 | Período de la retro / Primera retro | auto: sin retros, cadencia 7: `Desde: 2026-11-10` y `Retro anterior: ninguna`; sin `tablero.md`: también `Desde: 2026-11-10` | `tests/cadencias-scrumban.Tests.ps1` |
| S11 | Período de la retro / Período sin nada archivado | auto: sin notas de archive en el rango: `Sin changes ni ODD archivados en el período.`; ninguna línea contiene la ruta de la carpeta temporal; sin vault: `Sin vault: OBSIDIAN_VAULT no definida`, código 0 | `tests/cadencias-scrumban.Tests.ps1` |
| S12 | Período de la retro / Dato inválido: nota de archive sin fecha | auto: `projects/alfa/archive/notas-sueltas.md` y `2026-02-30-x.md` no aparecen en la salida | `tests/cadencias-scrumban.Tests.ps1` |
| S13 | Skill de retro con review / Fases de la skill | auto: `skills/retro/SKILL.md` contiene, en este orden, `Preparar`, `Review`, `Start / Stop / Continue`, `Analizar`, `Decidir acciones`, `Cerrar`; y contiene `directiva primaria`, `15 minutos`, `retro.ps1" -Periodo` y `metricas.ps1` | `tests/cadencias-scrumban.Tests.ps1` |
| S14 | Skill de retro con review / Skill instalada | auto: `instalar.ps1 -Destino <carpeta temporal> -SinVault -Simular` lista `.claude/skills/retro/SKILL.md` | `tests/cadencias-scrumban.Tests.ps1` |
| S15 | Skill de retro con review / Dato inválido: acción anterior sin issue | auto: la skill contiene `no encontrado` y `sin issue`, y en sus restricciones `no evalúa personas` y que no escribe nombres de personas ni rutas absolutas | `tests/cadencias-scrumban.Tests.ps1` |
| S16 | Acciones de la retro como issues / Acción creada como issue y Sin gh | auto: la skill contiene `gh issue create`, `prioridad:`, `tipo:`, `Origen: retro`, `-Columna backlog`, `Máximo 3 acciones`, `issue: pendiente` y que no agrega `status:approved` | `tests/cadencias-scrumban.Tests.ps1` |
| S17 | Nota de la retro en el vault / Formato de la nota y Sin vault | auto: la skill contiene `retros/AAAA-MM-DD.md`, `tipo: retro`, las seis secciones de D5, `## Retro de las HH:MM`, `chore: retro` y `Sin vault no hay retro` | `tests/cadencias-scrumban.Tests.ps1` |
| S18 | Cadencias en las reglas y la guía / Reglas y guía | auto: `.claude/CLAUDE.md` contiene `retro.ps1 -Aviso`, `### Cadencias`, `retros\` y la fila de `/retro` dentro de `### Cuándo actuar`; `docs/workflow.md` contiene `cadencia-retro` y `/retro` y no tiene rutas absolutas (`[A-Za-z]:\\` ni `/Users/`); `generar-plantillas.ps1 -Comprobar` termina con 0 | `tests/cadencias-scrumban.Tests.ps1` |
| M01 | Aviso de retro vencida (sesión real) | manual (lo corre el usuario): agregar `cadencia-retro: 7` a `tablero.md` de cada vault, abrir una sesión nueva de Claude Code en otro proyecto (por ejemplo, shorts-factory) y ver la línea `Todavía no hay retros...` | — |
| M02 | Skill de retro con review (retro real) | manual (lo corre el usuario): correr `/retro` en una sesión real; queda `retros/AAAA-MM-DD.md` en el vault con las seis secciones, los issues de las acciones en Backlog y, en una sesión nueva, sin aviso | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/tablero-comun.ps1` (vía `tests/tablero-scrumban.Tests.ps1` y `tests/metricas-de-flujo.Tests.ps1`) | lectura y validación actual de `tablero.md` (`owner`, `numero`, `wip-*`), mensajes y códigos de `tablero.ps1` y `metricas.ps1` | suma la validación de `cadencia-retro`, cubierta por S01, S02 y S08; lo existente no cambia |
| C02 | `.claude/CLAUDE.md` (vía `tests/tablero-scrumban.Tests.ps1`, `tests/metricas-de-flujo.Tests.ps1` y `generar-plantillas.ps1 -Comprobar`) | `## Scrumban`, paso del tablero al iniciar sesión y bloque generado de reglas del Agente | suma `### Cadencias`, el paso de la retro, `retros\` y la fila de `/retro`, cubiertos por S18 |

## Open Questions

Ninguna.
