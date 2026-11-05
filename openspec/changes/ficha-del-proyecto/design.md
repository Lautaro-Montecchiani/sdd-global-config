## Context

- Motivación en `proposal.md` (Why). Decisiones de fondo del `/opsx:explore` del 04/11/2026: ficha en el `context:`, skill aparte para completarla, propose que avisa sin bloquear, `## Alcance` con versión y sin historial.
- Relevamiento del 04/11/2026 de los `openspec/config.yaml` de los proyectos: `seguimiento-Suscripciones`, `normalizacionLeads-contactacion` y `PLANEAMIENTO` tienen un `## Stack` escrito a mano, con formatos distintos. `seguimiento-Suscripciones` tiene además `## Arquitectura de datos` y `## Seguridad`. `toyota-yacopini-web` maneja leads y no declara datos ni stack. Los `context:` miden entre 0,7 y 8,5 KB, lejos del aviso de 40 KB.
- El propose ya completa `project_type`, `## Tests` y `## Arquitectura` en una sola pregunta del paso 0. Sumar tres preguntas más ahí lo volvería pesado: por eso la ficha va en una skill aparte.
- La lógica del propose está duplicada en `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`. Se editan las dos con el mismo texto.
- Lo instalado en `~/.claude` es igual al repo desde la reinstalación del change `asesor-de-arquitectura` (04/11/2026).

## Goals / Non-Goals

**Goals:**
- Que cualquier persona, sin saber arquitectura, pueda completar la ficha respondiendo preguntas simples.
- Que la ficha sea la fuente que después usan la Security Layer, el Agente y el change `puerta-de-integracion`.

**Non-Goals:**
- Validar el contenido de la ficha contra el código, por ejemplo comprobar que el stack declarado sea el real. `/ficha` lo propone desde el repo, pero el usuario confirma.

## Decisions

**D1. Formato de la ficha.** Tres subsecciones del `context:`, con ítems `- clave: valor` como `## Tests`. Solo se escriben las claves declaradas, sin relleno.

- `## Alcance`: `- versión: V1`, una línea `- incluye: <ítem>` por cada funcionalidad y una línea `- no incluye: <ítem>` por cada cosa que queda para después. Las claves repetidas son válidas porque es una lista. Alternativa descartada: dos subsecciones (`### Incluye` y `### No incluye`), porque complica la edición quirúrgica y el control de alcance del propose.
- `## Datos`: `- <dato> (<campos>): <origen> (externo|propio) | <personal|interno|público>`. Ejemplo: `- leads (nombre, teléfono, email): formulario web (externo) | personal`. **Externo** es lo que entra desde afuera del sistema (formularios, Excel, APIs, scraping); **propio** es lo que el sistema genera o ya tiene en su base. **Personal** es todo dato de una persona identificable (Ley 25.326); **interno**, datos del negocio sin personas; **público**, información publicada. El change `puerta-de-integracion` usa `(externo)` para exigir escenarios de dato inválido.
- `## Stack`: claves `lenguaje`, `framework`, `base-de-datos`, `integraciones` y `librerias`, en ese orden, cada una con valores separados por coma y la versión mayor cuando se conoce (por ejemplo `- lenguaje: Python 3.11`).

"¿Qué hace la aplicación?" no lleva sección nueva: la responden la línea de descripción del `context:` y `## Objetivos de Negocio` (formato `- <id>: <descripción>`, ya definido en `project-context-schema`).

**D2. Skill `ficha`** (`skills/ficha/SKILL.md`; se invoca `/ficha`).
1. Lee `openspec/config.yaml`. Si no existe o no tiene `context:` activo o `project_type`, los completa como indica `project-context-schema` (preguntando `project_type` una vez).
2. Revisa cinco partes: la línea de descripción del `context:`, `## Objetivos de Negocio`, `## Alcance`, `## Datos` y `## Stack`. Una parte existe si su encabezado está, **en cualquier formato**: no se reescribe ni se normaliza. La descripción existe si el `context:` tiene al menos una línea de texto antes del primer `##`.
3. Si no falta nada, dice "la ficha está completa" y termina sin escribir.
4. Para lo que falta, hace **una sola** `AskUserQuestion` con hasta cuatro preguntas; si faltan las cinco partes, la descripción y los objetivos van en una pregunta abierta y la segunda tanda cubre lo demás. Propone valores donde puede:
   - **Stack:** inferido de `requirements.txt`, `pyproject.toml`, `package.json`, `*.csproj` o `go.mod` (lenguaje, framework y librerías principales). Se ofrece como "Usar el inferido", "Corregirlo" o "No sé (dejar el inferido con `# inferido — revisar`)".
   - **Datos:** sugiere categorías a partir de nombres de modelos, columnas o campos de formularios que vea en el código (sin leer valores), y pregunta origen y tipo de cada una.
   - **Alcance:** pregunta la versión (por defecto `V1`), qué incluye y qué queda afuera.
5. Escribe cada parte con edición quirúrgica al final del `context:`, en este orden: Alcance, Datos y Stack, con el aviso de 40 KB. "Al final" significa siempre después de todo el contenido existente del `context:`, aunque alguna de las tres partes ya exista más arriba (por ejemplo, un `## Stack` escrito a mano): las que faltan no se intercalan para respetar el orden. Agregado tras el verify del 04/11/2026, en el que la skill insertó `## Alcance` y `## Datos` antes de un `## Stack` existente. La descripción va como primera línea de texto del `context:`, y `## Objetivos de Negocio` sigue el formato existente.
6. Resumen: qué escribió, qué quedó como inferido y el recordatorio de commitear `openspec/config.yaml`.

Restricciones: no crea changes, ramas ni commits, y no escribe en el vault. Solo lee código, sin ejecutarlo, y no lee lo ignorado por `.gitignore` ni `*.env`, `*.key`, `*.pem`, `*.p12` ni `secrets/`. **Nunca escribe valores reales de datos**, solo categorías y campos: si el usuario pega un ejemplo con datos de una persona, la skill usa solo los nombres de los campos y le recuerda que no hace falta pegarlos (Ley 25.326).

**D3. Propose (skill y comando).**
1. **Aviso de ficha faltante:** en el paso 0, si falta `## Alcance`, `## Datos` o `## Stack`, no pregunta nada. En el resumen final agrega: "Falta la ficha del proyecto (`<lo que falta>`): corré `/ficha`".
2. **Control de alcance:** al crear el `proposal.md`, compara lo que pide el change con cada `- no incluye:` de `## Alcance`, por significado y no por coincidencia literal. Si coincide, hace una `AskUserQuestion` con tres opciones:
   - "Seguir y pasarlo al alcance": cambia esa línea a `- incluye:` con edición quirúrgica, y el commit de artefactos incluye `openspec/config.yaml`;
   - "Seguir sin tocar el alcance": el `proposal.md` lo dice en `## Non-goals` o en `## Impact` ("pide algo marcado como no incluido en <versión>");
   - "Cancelar": no crea el change y borra la carpeta si ya se creó con `openspec new change`.
3. **Datos personales en el design:** si `## Datos` declara algún dato `| personal` y el change lo lee, guarda, muestra o transmite, la `## Security Layer` del `design.md` incluye la subsección "Datos personales" con los controles de D4 que apliquen, diciendo cómo se cumple cada uno.

**D4. Capa de Seguridad del `CLAUDE.md` global.** Subsección nueva `### Datos personales (cualquier tipo de proyecto)`, después de `### tooling / config`, con cinco controles:
- No loguear datos personales (ni en logs, ni en errores, ni en salidas de consola).
- Pedir y guardar solo los campos necesarios.
- Enmascararlos en reportes, capturas y salidas no productivas (por ejemplo `261-***-**34`).
- No usar datos reales en tests ni fixtures: usar datos inventados.
- No exponerlos en URLs ni en parámetros de consulta.

Y una línea: "Se aplica cuando `## Datos` declara un dato `personal` y el change lo toca. La normativa aplicable es la Ley 25.326; ante dudas legales, consultar al área responsable."

**D5. Regla 4 del Agente.** Se agrega al final, literal: "Las librerías y servicios nuevos salen de `## Stack` de `openspec/config.yaml` o del `design.md`; si necesitás uno que no está en ninguno, frená y preguntá." Va en el `CLAUDE.md` global y en las 4 plantillas. Siguen siendo 8 reglas.

**D6. `CLAUDE.md` global: sección `## Ficha del proyecto`**, después de `## Arquitectura del proyecto`:
- Para qué sirve, en una línea: qué hace la app, qué entra en la versión, qué datos maneja y con qué tecnologías.
- El formato de las tres subsecciones (D1), con un ejemplo cada una.
- Responsabilidades: `/ficha` la completa; el propose avisa si falta y cuida el alcance (D3); la Security Layer usa `## Datos` (D4); el Agente usa `## Stack` (D5).
- No cita IDs de este design.

**D7. Instalación.** Igual que en los changes anteriores: chequeo previo de cada instalado contra `git show master:<ruta>` sin el fin de línea (frenar ante cambios locales), copia del `CLAUDE.md`, de todas las carpetas de `skills/` (incluida `ficha/`) y de todos los comandos de `.claude/commands/opsx/` a `~/.claude`, de `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`, y sincronización del espejo `_global/reglas-globales.md`. Se verifica con hashes.

**D8. Commits.** Tres commits de código, separados de `openspec/`, cada uno con un único bloque final de trailers con `Spec-ID: ficha-del-proyecto`:
1. `.claude/CLAUDE.md`, con la descripción del impacto;
2. `skills/` (propose y la skill nueva) y `.claude/commands/opsx/propose.md`;
3. plantillas, `README.md` y `docs/workflow.md`.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `skills/ficha/SKILL.md` | `skills/` (subcarpeta) |

Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, las skills, los comandos ni las plantillas. Las rutas se escriben con `~/.claude/`. Se verifica con un script en archivo.
- `/ficha` solo lee código, sin ejecutarlo, y no lee lo ignorado ni archivos de secretos. **Nunca guarda valores reales de datos personales**, solo categorías y campos (Ley 25.326); si el usuario los pega, usa solo los nombres de los campos y se lo recuerda.
- Las únicas escrituras nuevas son en `openspec/config.yaml` (ficha y alcance), siempre con edición quirúrgica y el aviso de 40 KB.
- Commit aparte del `CLAUDE.md` con el impacto. La instalación tiene el chequeo previo de cambios locales (D7).

## Impacto en proyectos existentes

- **Sin ficha** (casi todos hoy): el propose agrega una línea de aviso en el resumen. Nada se bloquea.
- **Con `## Stack` u otras secciones escritas a mano** (`seguimiento-Suscripciones`, `normalizacionLeads-contactacion`, `PLANEAMIENTO`): `/ficha` las respeta y solo completa lo que falta. `## Arquitectura de datos` de `seguimiento-Suscripciones` no cuenta como `## Datos`: `/ficha` preguntará igual por `## Datos`, y el usuario puede resumir ahí lo que ya tiene.
- **Proyectos con datos personales** (por ejemplo `toyota-yacopini-web`): desde que declaren `## Datos`, los designs que toquen esos datos suman los controles. Mientras no la declaren, no cambia nada.
- **Agentes:** la oración nueva de la regla 4 llega por las plantillas. Los proyectos que ya las copiaron tienen que volver a copiarlas.

## Risks / Trade-offs

- [El control de alcance compara por significado y puede fallar en los dos sentidos] → Es una pregunta, no un bloqueo, y el usuario decide. Sin `## Alcance`, no se controla nada.
- [La ficha puede quedar desactualizada respecto del código] → `/ficha` se puede volver a correr, pero no reescribe lo existente. Actualizarla es tarea del usuario; un control de coherencia queda fuera de alcance.
- [`/ficha` puede inferir mal el stack] → Se ofrece "corregirlo" y "no sé" deja `# inferido — revisar`.
- [Duplicación skill/comando del propose] → La tarea de evidencia compara que el texto agregado sea idéntico.

## Migration Plan

Primero se edita y se instala (D7). Cada proyecto completa su ficha cuando quiera, con `/ficha`. Rollback: revertir el PR, reinstalar desde `master`, borrar `~/.claude/skills/ficha/` y volver a sincronizar el espejo. Las subsecciones ya escritas en algún proyecto no hacen daño sin las skills nuevas.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude o el Agente. Todo el plan es manual. No hay tests de caracterización porque no hay código. Los cambios intencionales de comportamiento del propose los cubren S08 a S11, S14 y S15; los de la regla 4, S12 y S13. Un test automático futuro llevaría `test-plan: ficha-del-proyecto/<ID>`.

Las pruebas con sesiones nuevas se corren con `claude -p` en repos descartables y un vault falso (`OBSIDIAN_VAULT` apuntando a una carpeta temporal), pasando en el pedido la respuesta a cada pregunta, como en el verify de `asesor-de-arquitectura`.

Fixtures:
- **Repo G** (`$env:TEMP\ficha-prueba-g`): `project_type: etl`, `## Tests` con `comando: ninguno`, sin descripción, objetivos ni ficha. `requirements.txt` con `pandas`, `openpyxl` y `simple-salesforce`. `src/leads.py` con una función que lee columnas `nombre`, `telefono` y `email` de un Excel (sin datos reales).
- **Repo H** (`$env:TEMP\ficha-prueba-h`): como G, pero con descripción, `## Objetivos de Negocio` y un `## Stack` escrito a mano en texto libre.
- **Repo I** (`$env:TEMP\ficha-prueba-i`): ficha completa, con `- no incluye: integración con Salesforce` y `- leads (nombre, teléfono, email): formulario web (externo) | personal`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Formato / Alcance con versión | manual: el formato de `## Alcance` del `CLAUDE.md` coincide con D1 y el repo I lo usa | `.claude/CLAUDE.md`, repo I |
| S02 | Formato / Dato personal de origen externo | manual: ídem para `## Datos` | ídem |
| S03 | Formato / Stack sin claves de relleno | manual: la `## Stack` que escribe `/ficha` en el repo G no tiene `base-de-datos` | repo G |
| S04 | Ficha / Proyecto sin ficha | manual: `/ficha` en el repo G pregunta las partes que faltan, propone el stack de `requirements.txt` y escribe al final del `context:` | repo G |
| S05 | Ficha / Stack escrito a mano | manual: `/ficha` en el repo H no toca `## Stack` (diff vacío en esa subsección) | repo H |
| S06 | Ficha / Ficha completa | manual: `/ficha` en el repo I dice "la ficha está completa" y `git status` queda limpio | repo I |
| S07 | Sin datos reales / Usuario que pega un ejemplo real | manual: en el repo G, responder a `/ficha` con un ejemplo con un teléfono y un email inventados con formato real; `## Datos` no contiene los valores | repo G |
| S08 | Aviso / Proyecto sin ficha | manual: `/opsx:propose` en el repo G sigue sin preguntar por la ficha y el resumen sugiere `/ficha` | repo G |
| S09 | Alcance / Pasar el ítem al alcance | manual: propose en el repo I que pide la integración con Salesforce, con la opción "Seguir y pasarlo al alcance"; la línea queda en `incluye` | repo I |
| S10 | Alcance / Seguir sin tocar el alcance | manual: ídem con "Seguir sin tocar el alcance"; `config.yaml` sin cambios y el proposal lo menciona | repo I |
| S11 | Alcance / Cancelar | manual: ídem con "Cancelar"; no queda `openspec/changes/<nombre>/` | repo I |
| S12 | Stack / Librería no prevista | manual: el texto de D5 en las 5 fuentes dice frenar y preguntar | `.claude/CLAUDE.md`, `templates/*` |
| S13 | Stack / Texto en todas las fuentes | manual: `Select-String -SimpleMatch` con la oración de D5 da 5 coincidencias, más `~/.claude/CLAUDE.md` y el espejo del vault | ídem |
| S14 | Datos personales / Change que toca datos personales | manual: propose en el repo I que agrega un campo al formulario de leads; la Security Layer tiene "Datos personales" con los controles | repo I |
| S15 | Datos personales / Change que no toca datos personales | manual: propose en el repo I que cambia solo estilos; sin la subsección "Datos personales" | repo I |
| S16 | Datos personales / Controles en el CLAUDE.md | manual: la subsección de D4 tiene los cinco controles | `.claude/CLAUDE.md` |
| S17 | Context / escenarios existentes | manual: el paso 0 del propose conserva su comportamiento (diff de la skill sin cambios en esas líneas) | `skills/openspec-propose/SKILL.md` |
| S18 | Context / Ficha en el context | manual: en S04, las tres subsecciones quedan después de `## Tests` sin modificarlo | repo G |

S04 a S11, S14 y S15 se hacen en sesiones nuevas de Claude Code abiertas en cada repo descartable, para comprobar que lo instalado en `~/.claude` aplica en otro repo.

## Open Questions

Sin preguntas abiertas. Las decisiones salen del explore del 04/11/2026 y se pueden revisar antes del apply.
