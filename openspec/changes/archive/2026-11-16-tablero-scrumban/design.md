# Design

## Context

El workflow tiene las etapas de un flujo Kanban (issue aprobado, propose, apply, PR y verify, archive), pero ninguna vista las muestra juntas y no hay límite de trabajo en curso. Los issues de GitHub ya son la fuente única del backlog (ADR 0004), con `status:*`, `prioridad:*` y `tipo:*`. El ADR 0004 descartó GitHub Projects por la configuración que pedía en cada repo; un **Project de usuario** resuelve eso porque junta issues de varios repos en un solo tablero.

El usuario trabaja solo con Claude y el Agente, en varios proyectos a la vez y con dos vaults (personal y del trabajo). El WIP es de la persona, no de cada repo, por eso la configuración vive en el vault y no en cada `openspec/config.yaml`.

`gh` tiene los comandos `gh project view`, `field-list`, `item-list`, `item-add` e `item-edit`, que piden el permiso `project` en el token. Al 16/11/2026 el token de esta máquina no lo tiene: se da con `gh auth refresh -s project` (confirmación en el navegador) antes de M01.

## Goals / Non-Goals

**Goals:**
- Un tablero con las 6 columnas del flujo, que se actualiza solo desde las skills.
- Límite de WIP en Diseño, Construcción y Revisión, controlado antes de empezar trabajo nuevo.
- DoR y DoD escritas en las reglas globales, con los roles de un equipo de una persona.
- Que todo siga funcionando igual sin tablero configurado, sin `gh` o sin permiso.

**Non-Goals:**
- Métricas de flujo y cadencias (`/retro`, review): issues aparte.
- Story points o Planning Poker.
- Que el Agente mueva tarjetas: las reglas de ejecución y las plantillas no cambian.
- Crear el Project por script.

## Decisions

### D1. Columnas y quién mueve cada tarjeta

| Columna (opción de `Status`) | Alias de `-Columna` | La mueve | Límite inicial |
|---|---|---|---|
| Backlog | `backlog` | `issue-creation`, al crear el issue | sin límite |
| Listo | `listo` | nadie por skill: el usuario al aprobar (o queda en Backlog hasta el propose) | sin límite |
| Diseño | `diseno` | `openspec-propose`, después del paso 1b (issue controlado) | 1 |
| Construcción | `construccion` | `openspec-propose` al anunciar el handoff; `/odd` al anunciar el handoff | 2 |
| Revisión | `revision` | `branch-pr`, después de crear el PR (SDD y ODD) | 2 |
| Hecho | `hecho` | `openspec-archive-change` en la fase del vault; `/odd:close`; y el flujo integrado "Item closed" del Project | sin límite |

Los límites recomendados salen de que el cuello de botella es el usuario: el diseño y el verify necesitan su aprobación, así que un solo change en diseño y hasta dos en manos del Agente y dos esperando verify o merge. La columna Construcción la marca Claude al anunciar el handoff, porque desde ese momento el trabajo es del Agente; así el Agente no necesita reglas nuevas. Si el verify encuentra CRITICAL, la tarjeta queda en Revisión.

### D2. `tablero.md` en el vault

Archivo `$env:OBSIDIAN_VAULT/tablero.md` (raíz del vault, versionado con el vault). Arranca con un bloque entre líneas `---` con una clave por línea, `clave: valor`:

- `owner`: cuenta dueña del Project (por ejemplo, la cuenta personal en el vault personal y la del trabajo en el vault del trabajo).
- `numero`: número del Project (el de la URL `github.com/users/<owner>/projects/<numero>`).
- `wip-diseno`, `wip-construccion`, `wip-revision`: enteros positivos. Una clave que falta es "sin límite".

Las claves van en ASCII para evitar problemas de codificación; los nombres con tilde solo existen en las opciones de `Status`. Debajo del bloque puede haber texto libre para personas (el script lo ignora). El script lee el bloque con una función pura (texto → objeto con claves y errores), sin módulos externos de YAML.

Validación: falta el archivo → `Tablero no configurado (falta tablero.md en el vault)`; `OBSIDIAN_VAULT` vacía y sin `-Config` → `Tablero no configurado (OBSIDIAN_VAULT no definida)`; falta `owner` o `numero`, o `numero` no es entero positivo, o un `wip-*` no es entero mayor que 0 → `tablero.md inválido: <clave>`. En todos los casos, código 0 y sin llamar a `gh`.

### D3. `scripts/tablero.ps1`

Parámetros: `-Columna` (obligatorio), `-Issue <url>` (para mover), `-Wip` (switch, para contar), `-Config <ruta>` (por defecto `$env:OBSIDIAN_VAULT/tablero.md`), `-Simular` (lee el tablero real pero no ejecuta `item-add` ni `item-edit`; imprime los comandos) y `-Entrada <archivo.json>` (para tests: no llama a `gh` y toma los datos del archivo). `-Issue` y `-Wip` son excluyentes; si no viene ninguno, código 1.

Estructura (nivel 0, pero con las funciones de cálculo separadas de las llamadas a `gh` para poder testearlas):
- `Leer-ConfigTablero` (texto → config o errores), `Resolver-Columna` (alias → nombre de la opción), `Buscar-Opcion` (campos → id del campo `Status` y de la opción), `Contar-Columna` (tarjetas + columna → cuenta y lista).
- Una sola función `Invocar-Gh` que llama a `gh` con los argumentos como arreglo (sin armar un string ni usar `Invoke-Expression`), devuelve el JSON parseado o un error, y nunca imprime el token.

Mover (`-Issue`): 1) `gh project view <numero> --owner <owner> --format json` → id del Project; 2) `gh project field-list <numero> --owner <owner> --format json` → id del campo `Status` y de la opción; 3) `gh project item-add <numero> --owner <owner> --url <url> --format json` → id de la tarjeta (si ya está, `gh` devuelve la misma); 4) `gh project item-edit --id <tarjeta> --project-id <proyecto> --field-id <campo> --single-select-option-id <opcion>`. Salida: `#<n> → <Columna>`. Si falta el campo `Status` o la opción: `el tablero no tiene la columna <Columna>`, sin pasos 3 y 4, código 0.

WIP (`-Wip`): `gh project item-list <numero> --owner <owner> --format json --limit 500`. Cuenta las tarjetas con `status` igual a la opción. Salida: `<Columna>: <cuenta> de <límite>` (o `<Columna>: <cuenta> (sin límite)`), y si está llena, una línea por tarjeta `  #<número> <título>` (sin título: solo el número; sin número, por ejemplo un borrador: el título solo). Código 2 si la cuenta es mayor o igual al límite; 0 si no.

Errores de `gh` (no instalado, sin red, sin permiso, Project inexistente): una línea `Tablero no disponible: <motivo>`; si el error menciona el permiso `project` (`scope` / `project`), agrega `— corré gh auth refresh -s project`. Nunca se imprimen rutas absolutas ni la salida cruda de `gh`. Código 0. Columna desconocida: `Columna desconocida: <valor>. Válidas: backlog, listo, diseno, construccion, revision, hecho`, código 1.

Formato de `-Entrada`: un JSON con tres claves que copian la salida de `gh`: `proyecto` (salida de `project view`, con `id`), `campos` (salida de `field-list`, `{ "fields": [ { "id", "name", "options": [ { "id", "name" } ] } ] }`) y `tarjetas` (salida de `item-list`, `{ "items": [ { "id", "status", "content": { "number", "title", "url" } } ] }`). Con `-Entrada`, mover imprime los comandos de los pasos 3 y 4 como en `-Simular`.

### D4. Skills

Llamada común: `pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\tablero.ps1" -Columna <alias> -Issue <url>`. La URL sale de `gh issue view <NN> --json url --jq .url`. Texto común en cada skill: "Si no hay issue (`Issue: pendiente` o un ODD sin issue) o `SDD_CONFIG_REPO` no está definida, saltear este paso y decirlo en el resumen. Un aviso del script no frena el flujo."

- `skills/issue-creation/SKILL.md`: en el paso 5 (Confirm and instruct), antes del mensaje: mover a `backlog`.
- `skills/openspec-propose/SKILL.md`: paso nuevo **0b. Control de WIP** antes del paso 1: `tablero.ps1 -Wip -Columna diseno`; con código 2, mostrar la salida y preguntar con **AskUserQuestion** "Seguir igual" / "Frenar". "Frenar" detiene el propose sin crear archivos ni ramas; "Seguir igual" sigue y el resumen final dice `WIP excedido en Diseño (aceptado por el usuario)`. Sin interfaz interactiva: avisar y seguir. Al final del paso 1b: mover a `diseno`. En **Output**, junto al anuncio del handoff: mover a `construccion`.
- `skills/odd-change/SKILL.md`: en `/odd`, antes de redactar el documento, el mismo control de WIP con `construccion`; al anunciar el handoff, mover a `construccion` si el documento tiene `Issue: #NN`. En `/odd:close`, mover a `hecho`.
- `skills/branch-pr/SKILL.md`: después de crear el PR (paso 6), mover a `revision`.
- `skills/openspec-archive-change/SKILL.md`: en la fase del vault, mover a `hecho` (el flujo integrado del Project ya lo hace al cerrarse el issue; este paso cubre a quien no lo activó).

Los comandos `.claude/commands/opsx/propose.md`, `.claude/commands/opsx/archive.md`, `.claude/commands/odd.md`, `.claude/commands/odd/start.md` y `.claude/commands/odd/close.md` se regeneran con `scripts/generar-plantillas.ps1`.

### D5. `## Scrumban` en `.claude/CLAUDE.md`

Sección nueva después de `## Clasificación ODD / SDD` (fuera del bloque generado de reglas del Agente), corta, con:
- **Roles:** el usuario es Product Owner (ordena y aprueba issues) y Scrum Master (cuida el proceso y el WIP); Claude y el Agente son los Developers (diseño y verificación; construcción).
- **Tablero:** GitHub Project de usuario configurado en `tablero.md` del vault; tabla de D1 sin la columna de límite; `scripts/tablero.ps1`; sin tablero, el flujo sigue igual.
- **WIP:** "dejar de empezar para empezar a terminar"; límites en `tablero.md`; el propose y `/odd` preguntan "Seguir igual" o "Frenar" si la columna está llena.
- **Definition of Ready:** issue abierto con `status:approved`, prioridad y tipo; criterios de aceptación en el issue; clasificación ODD/SDD hecha; lugar en la columna de destino o excepción aceptada.
- **Definition of Done (SDD):** tareas `[x]` con evidencia en la nota `apply\`; tests en verde ejecutados por el verify; verify sin CRITICAL y puerta de integración en `sí`; archive en la rama (specs, SRS y backlog); PR mergeado con `Closes #NN`; cierre en el vault; tarjeta en Hecho.
- **Definition of Done (ODD):** criterios de aceptación con evidencia; `/odd:verify` sin CRITICAL; merge; `/odd:close`.

En `### Estructura del vault`, sumar `tablero.md` en la raíz del vault con el comentario "← configuración del tablero Scrumban (owner, número y límites de WIP)".

### D6. Guía en `docs/workflow.md`

Sección nueva `## Tablero Scrumban` con: crear el Project de usuario (plantilla Board), renombrar las opciones de `Status` a las 6 de D1 con esos nombres exactos, activar el flujo integrado "Item closed" → `Hecho` y desactivar "Item added" si pone otra opción, `gh auth refresh -s project`, crear `tablero.md` en el vault con las claves de D2 (con valores de ejemplo, sin cuentas reales), probar con `tablero.ps1 -Wip -Columna diseno`, e instalar la página del Project como app desde Edge ("Aplicaciones → Instalar este sitio como aplicación") o Chrome. Una línea por vault: el personal y el del trabajo apuntan a Projects distintos.

### D7b. Aviso de permiso en cada máquina

El permiso `project` es de la llave de `gh` de cada máquina y cuenta: no se puede dar desde otra PC y lo confirma una persona en el navegador. Para que una PC nueva se entere sola, `tablero.ps1` suma el modo `-Comprobar` (excluyente con `-Issue` y `-Wip`; con `-Comprobar`, `-Columna` no es obligatorio):
- Sin tablero configurado (D2): código 0, sin salida. Así no molesta a quien no usa tablero.
- Lee los permisos con `gh auth status` (función pura que toma el texto y devuelve la lista de la línea `Token scopes:`). Con `project`: código 0, sin salida. Sin `project`: `Falta el permiso project en gh de esta máquina: corré ! gh auth refresh -h github.com -s project`, código 1.
- `gh` no instalado o sin línea `Token scopes:`: `No se pudo leer el permiso de gh`, código 0.
- Con `-Entrada`, el texto de permisos sale de la clave `estadoGh` del JSON (copia de la salida de `gh auth status`).

En `.claude/CLAUDE.md`, `## Al iniciar cada sesión`, paso 3, después de "Comprobar el proyecto": "Comprobar el tablero: correr `pwsh $env:SDD_CONFIG_REPO\scripts\tablero.ps1 -Comprobar`. Si termina con 1, mostrar la línea al usuario: el permiso lo da el usuario con `!` en el prompt, porque se confirma en el navegador. No intentar darlo por cuenta propia. Si `$env:SDD_CONFIG_REPO` no está definida, saltear." El vault llega a la otra PC con el `git pull` del inicio de sesión, así que el control se activa ahí sin configurar nada más.

### D7. Ficha del proyecto

En `openspec/config.yaml`: `## Stack` → `integraciones` suma `GitHub Projects (gh project)`; `## Datos` suma `- tarjetas del tablero (issue, columna): GitHub Project de usuario (externo) | interno`. Lo hace el Agente en un commit de `openspec/` aparte.

## ADR

```markdown
# 0006. Tablero Scrumban en un GitHub Project de usuario

Estado: aceptada
Fecha: 2026-11-16
Change: tablero-scrumban

## Contexto

El workflow adopta Scrumban: un tablero con las etapas del flujo (Backlog, Listo, Diseño, Construcción, Revisión y Hecho) y límites de trabajo en curso. El ADR 0004 dejó los issues de GitHub como fuente única del backlog y descartó GitHub Projects por la configuración que pedía en cada repo. El usuario trabaja solo con Claude y el Agente, en varios proyectos a la vez y con un vault personal y uno del trabajo, así que el WIP es de la persona y no de cada repo.

## Alternativas

- **Trello:** simple y conocido, pero las tarjetas son una copia de los issues que hay que mantener a mano o con un Power-Up. Se descartó por duplicar la fuente del backlog.
- **Jira:** completo (sprints, reportes), pero es una segunda fuente del backlog y es pesado para una persona. Se descartó.
- **Tablero generado en el vault (Markdown):** sin dependencias nuevas, pero es de solo lectura, no se puede mover una tarjeta a mano y no se ve desde el celular. Se descartó.
- **App propia en otro repo:** sería un producto nuevo para mantener (pantallas, datos, acceso). Se descartó.
- **Un Project por repo:** repite la configuración en cada repo (el motivo del descarte del ADR 0004) y parte el WIP por proyecto. Se descartó.

## Decisión

El tablero es un GitHub Project de usuario con el campo `Status` en 6 opciones. Las tarjetas son los mismos issues, así que el ADR 0004 sigue vigente: el tablero es una vista, no una fuente. La configuración (dueño, número y límites de WIP) vive en `tablero.md` de cada vault. `scripts/tablero.ps1` mueve las tarjetas y cuenta el WIP con `gh project`, y las skills lo llaman en cada paso del flujo. Sin configuración, sin `gh` o sin el permiso `project`, el flujo avisa y sigue.

## Consecuencias

- Positivas: un tablero que junta todos los proyectos del vault, se actualiza solo y se ve en la web, en el celular y como app de escritorio; WIP controlado antes de empezar trabajo nuevo; sin datos duplicados.
- Negativas: el token de `gh` necesita el permiso `project` en cada máquina y cada cuenta; el Project se crea a mano una vez; los issues de repos de otra cuenta solo se pueden agregar si la cuenta del Project tiene acceso a ellos; cada paso del flujo suma hasta cuatro llamadas a `gh`.
```

## Impacto en proyectos existentes

Retrocompatible. Los proyectos no cambian sus archivos: toman el comportamiento cuando la máquina corre `instalar.ps1` (skills y comandos nuevos). Sin `tablero.md` en el vault, cada paso del tablero imprime una línea `Tablero no configurado` y el flujo sigue como hoy. Las reglas del Agente y `pr-check.yml` no cambian, así que `sincronizar-proyecto.ps1 -Aviso` no marca proyectos atrasados por este change.

## Impacto en el sistema

**Componentes afectados:** `scripts/` (script nuevo), cinco skills y sus comandos generados, `.claude/CLAUDE.md` (y su espejo en el vault al correr `instalar.ps1`), el vault (archivo nuevo `tablero.md`, que crea el usuario) y la integración nueva con GitHub Projects. Los demás proyectos solo a través de las skills instaladas.

**Atributos de calidad:**
- mantenibilidad (alta): los comandos se siguen generando desde las skills y se controlan con `generar-plantillas.ps1 -Comprobar`; la lógica del tablero está en un solo script con funciones puras testeables, y las skills solo lo llaman. — Verificación: S14 (comandos regenerados sin diferencias) y revisión del diff: ninguna skill llama a `gh project` directamente, todas pasan por `tablero.ps1`.

**Decisiones de arquitectura:** ADR nuevo: 0006.

**Deuda técnica:**
- agrega: `.claude/CLAUDE.md` crece con la sección `## Scrumban` (suma a la deuda #55); se mantiene corta y el detalle queda en las skills y en `docs/workflow.md`.
- descubre: el Project de usuario solo agrega issues de repos a los que su cuenta tiene acceso; los proyectos de otras cuentas (repos del trabajo) necesitan su propio Project y vault. Queda documentado en la guía; no hace falta issue.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `scripts/tablero.ps1` | `scripts/` |
| `tests/tablero-scrumban.Tests.ps1` | `tests/` |
| `docs/adr/0006-tablero-scrumban-en-github-project-de-usuario.md` | `docs/` (implícita) |

## Security Layer

Tipo `tooling`:
- Los artefactos son instrucciones para IA: sin secretos ni rutas absolutas en skills, reglas, guía y mensajes del script. — Verificación: S07 (mensaje sin rutas) y revisión del diff: buscar `C:\Users`, `D:\`, `GH_TOKEN`, `ghp_` y `gho_` en las líneas agregadas fuera de `openspec/`.
- El token de `gh` no se lee, no se guarda ni se imprime: el script usa la sesión de `gh` y nunca muestra su salida cruda de error. — Verificación: revisión del diff: `tablero.ps1` no usa `gh auth token`, `GH_TOKEN` ni `GITHUB_TOKEN`.
- Sin ejecución de texto externo: los argumentos de `gh` se pasan como arreglo y los títulos de los issues solo se imprimen. — Verificación: revisión del diff: `tablero.ps1` no usa `Invoke-Expression` ni arma la línea de `gh` concatenando strings.
- Entradas externas validadas antes de usarlas: `tablero.md` y el JSON de `gh` (campo `Status` faltante, tarjetas sin `status` o sin título). — Verificación: S03, S08 y S12.
- Cambios a skills y al `CLAUDE.md` global en commits separados con descripción del impacto. — Verificación: revisión del diff: `git log` de la rama con un commit para `.claude/CLAUDE.md` solo.

No hay datos personales: las tarjetas tienen número, título y estado de issues (interno).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian skills que generan comandos controlados en el CI. Cada test lleva `# test-plan: tablero-scrumban/<ID>` arriba del `Probar`. Los tests del script usan `-Config` con un `tablero.md` temporal y `-Entrada` con JSON inventado; ninguno llama a GitHub salvo S07, que corre el script sin `-Entrada` con `PATH` sin `gh` para provocar la falla.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Configuración del tablero en el vault / Configuración válida | auto: con `tablero.md` válido y `-Entrada`, `-Wip -Columna diseno` usa el límite 1 y `-Wip -Columna construccion` el límite 2 | `tests/tablero-scrumban.Tests.ps1` |
| S02 | Configuración del tablero en el vault / Sin tablero configurado | auto: `-Config` a un archivo que no existe, y `OBSIDIAN_VAULT` vacía sin `-Config`: salida que empieza con `Tablero no configurado` y código 0 | `tests/tablero-scrumban.Tests.ps1` |
| S03 | Configuración del tablero en el vault / Dato inválido: número o límite mal escrito | auto: `numero: tres`, `wip-construccion: 0`, `wip-construccion: -1` y `wip-revision: dos`: salida `tablero.md inválido: <clave>` y código 0 | `tests/tablero-scrumban.Tests.ps1` |
| S04 | Mover la tarjeta de un issue / Issue nuevo en el tablero | auto: con `-Entrada` sin el issue en `tarjetas`, mover a `backlog` imprime el `item-add` con la URL y el `item-edit` con el id de la opción `Backlog` | `tests/tablero-scrumban.Tests.ps1` |
| S05 | Mover la tarjeta de un issue / Issue que cambia de columna | auto: mover a `revision` (y a `REVISION`) imprime el `item-edit` con el id de la opción `Revisión` y una sola tarjeta | `tests/tablero-scrumban.Tests.ps1` |
| S06 | Mover la tarjeta de un issue / Columna desconocida | auto: `-Columna testing`: código 1 y la lista de las 6 columnas válidas | `tests/tablero-scrumban.Tests.ps1` |
| S07 | Mover la tarjeta de un issue / Sin permiso o sin gh | auto: sin `-Entrada` y con `PATH` sin `gh`: salida `Tablero no disponible:`, código 0 y sin la ruta del `tablero.md` temporal; y la función que arma el mensaje agrega `gh auth refresh -s project` ante un error con `scope` | `tests/tablero-scrumban.Tests.ps1` |
| S08 | Mover la tarjeta de un issue / Dato inválido: Project sin la opción de la columna | auto: `campos` sin la opción `Diseño`, y otro sin campo `Status`: salida `el tablero no tiene la columna Diseño`, sin `item-edit` y código 0 | `tests/tablero-scrumban.Tests.ps1` |
| S09 | Control de WIP de una columna / Columna llena | auto: una tarjeta en `Diseño` con límite 1: `Diseño: 1 de 1`, la línea `#12 <título>` y código 2 | `tests/tablero-scrumban.Tests.ps1` |
| S10 | Control de WIP de una columna / Columna con lugar | auto: una tarjeta en `Construcción` con límite 2: `Construcción: 1 de 2` y código 0 | `tests/tablero-scrumban.Tests.ps1` |
| S11 | Control de WIP de una columna / Columna sin límite | auto: `-Wip -Columna backlog` con 5 tarjetas: código 0 y `(sin límite)` | `tests/tablero-scrumban.Tests.ps1` |
| S12 | Control de WIP de una columna / Dato inválido: tarjetas sin Status o sin título | auto: tarjetas sin `status` no se cuentan; una sin título en la columna llena se muestra como `#<número>` solo | `tests/tablero-scrumban.Tests.ps1` |
| S13 | Movimientos del flujo / Pasos que mueven la tarjeta | auto: cada una de las cinco skills contiene `tablero.ps1` con su alias (`backlog`; `diseno` y `construccion`; `construccion` y `hecho`; `revision`; `hecho`) y el texto común de D4 | `tests/tablero-scrumban.Tests.ps1` |
| S14 | Movimientos del flujo / Comandos regenerados | auto: los comandos de D4 contienen `tablero.ps1` y `pwsh scripts/generar-plantillas.ps1 -Comprobar` termina con 0 | `tests/tablero-scrumban.Tests.ps1` |
| S15 | Control de WIP antes de empezar trabajo / WIP lleno en el propose | auto: `skills/openspec-propose/SKILL.md` y `skills/odd-change/SKILL.md` contienen `tablero.ps1 -Wip`, "Seguir igual", "Frenar" y que "Frenar" no crea archivos ni ramas | `tests/tablero-scrumban.Tests.ps1` |
| S16 | Scrumban en las reglas globales / Sección Scrumban | auto: `.claude/CLAUDE.md` tiene `## Scrumban`, las 6 columnas, `Definition of Ready`, `Definition of Done` (SDD y ODD) y `tablero.md` en la estructura del vault | `tests/tablero-scrumban.Tests.ps1` |
| S17 | Guía de configuración del tablero / Guía completa | auto: `docs/workflow.md` tiene `## Tablero Scrumban` con las 6 opciones, `gh auth refresh -s project`, las claves de `tablero.md`, "Instalar este sitio como aplicación" y sin rutas `C:\` ni `D:\` | `tests/tablero-scrumban.Tests.ps1` |
| S18 | Aviso de permiso en cada máquina / Máquina sin el permiso | auto: `tablero.md` válido y `estadoGh` con `Token scopes: 'gist', 'repo'`: salida con `gh auth refresh -h github.com -s project` y código 1 | `tests/tablero-scrumban.Tests.ps1` |
| S19 | Aviso de permiso en cada máquina / Máquina con el permiso o sin tablero | auto: `estadoGh` con `'project'`: código 0 y salida vacía; y `-Config` a un archivo inexistente: código 0 y salida vacía | `tests/tablero-scrumban.Tests.ps1` |
| S20 | Aviso de permiso en cada máquina / Dato inválido: permisos ilegibles | auto: `estadoGh` sin línea `Token scopes:`: salida `No se pudo leer el permiso de gh` y código 0 | `tests/tablero-scrumban.Tests.ps1` |
| S21 | Aviso de permiso en cada máquina / Control al iniciar sesión | auto: `## Al iniciar cada sesión` de `.claude/CLAUDE.md` contiene `tablero.ps1 -Comprobar` y la indicación de que el usuario da el permiso con `!` | `tests/tablero-scrumban.Tests.ps1` |
| M01 | Tablero real configurado | manual (lo corre el usuario): crear el Project de usuario siguiendo `## Tablero Scrumban` de `docs/workflow.md` y escribir `tablero.md` en el vault con `owner`, `numero` y los límites 1, 2 y 2. Evidencia: URL del Project y captura del tablero con las 6 columnas | — |
| M02 | Movimiento real en el tablero | manual (lo hace Claude en el verify, después de M01): `tablero.ps1 -Columna construccion -Issue <url del #66>` y `tablero.ps1 -Wip -Columna construccion`; la tarjeta del #66 aparece en Construcción y la cuenta es correcta | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `skills/issue-creation/SKILL.md`, `skills/openspec-propose/SKILL.md`, `skills/odd-change/SKILL.md`, `skills/branch-pr/SKILL.md`, `skills/openspec-archive-change/SKILL.md`, `.claude/CLAUDE.md` y los comandos generados | La suite actual en verde (incluye `generar-comandos`, `generar-plantillas`, `backlog-desde-issues` y `srs-en-rama-del-change`), que fija los pasos y textos existentes de esas skills | Se agregan pasos del tablero sin quitar ni renumerar los existentes, salvo el paso nuevo 0b del propose; lo nuevo lo cubren S13 a S16 |

## Open Questions

- Ninguna bloqueante. Si `gh project item-list` cambia el nombre de la clave `status` (sale del nombre del campo en minúsculas), el script la toma del nombre del campo `Status` leído en `field-list`.
