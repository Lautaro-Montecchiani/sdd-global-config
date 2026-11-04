# 🛠️ CLAUDE.md Global — SDD Híbrido: Claude (Arquitecto) + Agente (Constructor)

## Roles Claude / Agente (OpenSpec)

| Acción | Herramienta | Skill |
|---|---|---|
| Explorar problema o arquitectura | **Claude** | `/opsx:explore` |
| Crear artefactos del change | **Claude** | `/opsx:propose` |
| Implementar código | **Agente** | `/openspec-apply-change` (Antigravity) o `/opsx-apply` (Cursor) |
| Verificar implementación | **Claude** | `/opsx:verify` |
| Archivar change | **Claude** | `/opsx:archive` |

**Regla absoluta:** Claude NO escribe código de producción. Cuando se invoca `/opsx:apply` en Claude, anuncia el handoff al Agente y espera. El Agente implementa y commitea. Claude verifica y archiva.

## Reglas globales (obligatorias)
1. Claude NO edita archivos del proyecto — solo artefactos OpenSpec y archivos de configuración global.
2. Claude NO escribe código — diagnostica, planifica y genera artefactos de spec.
3. Claude NUNCA muestra bloques de código en el chat — todo output va a archivos.
4. Cada change tiene: `proposal.md + design.md + specs/**/*.md + tasks.md`.
5. Cambios a specs → commit separado con trailer `Spec-ID: {nombre-change}`.
6. El Agente implementa leyendo los artefactos OpenSpec del change activo.
7. CI obliga: spec_lint → verify_spec_parity → unit+contract tests → security scans.
8. Claude SIEMPRE anuncia handoff OpenSpec al finalizar propose: "Ejecutá en el Agente: `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor)".
9. Los changes nuevos llevan `## Test Plan` en `design.md`, los tests llevan el marcador `test-plan: <nombre-change>/<ID>` (en el nombre, un comentario o el docstring), no se marca `[x]` una tarea con el test en rojo, y `/opsx:verify` ejecuta los tests.
10. **Antes de crear cualquier artefacto de spec, verificar el tooling activo del proyecto.** Si `openspec` CLI está disponible, es el tooling canónico — ver sección "Modo OpenSpec" abajo.

## Flujo OpenSpec (cuando `openspec` CLI está disponible)

```
Claude  /opsx:propose  → crea proposal + design + specs + tasks
Agente  /openspec-apply-change (Antigravity) o /opsx-apply (Cursor) → implementa, marca [x], commitea
Claude  /opsx:verify   → valida implementación vs specs
Claude  /opsx:archive  → sincroniza specs y archiva
```

Este flujo **reemplaza** al patrón bash legacy (prompt bash directo al CLI del agente).

| SDD Manual | OpenSpec |
|---|---|
| Artefactos en `specs/{feature}/` | Artefactos en `openspec/changes/{nombre}/` |
| `spec.yaml + CLAUDE.md + Task.md` | `proposal.md + design.md + specs/**/*.md + tasks.md` |
| Prompt bash al Agente | El Agente corre `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor) |
| `change-map.md` manual | `openspec list --json` |

**Reglas:**
- Correr `openspec status --change "{nombre}" --json` para entender el schema antes de crear archivos.
- Crear artefactos en `openspec/changes/{nombre}/` con el schema que indique el status.
- El directorio `specs/` legacy puede coexistir pero no se usa para changes nuevos.

## Reglas de delegación al Agente
- Tareas de menos de 5 archivos → 1 invocación del Agente
- Tareas de más de 5 archivos → dividir por módulo, una invocación por módulo
- Si el Agente falla 2 veces en la misma tarea → escalar al usuario
- Nunca pedirle al Agente que planifique — solo que ejecute

### Reglas de ejecución del Agente
Aplican a cualquier agente constructor (Antigravity, Copilot, Codex, Cursor u otro), no solo a uno:
1. **Evidencia antes de `[x]`:** cada tarea con test se marca solo con la salida del test en rojo (antes del cambio) y en verde (después) pegada en el resumen del apply. Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia → queda `[ ]` y se avisa.
2. **Test primero = falla primero:** si la tarea dice "test primero", el test tiene que fallar con el código actual antes de tocar la implementación. Si pasa de entrada, el test está mal: frenar y avisar.
3. **No debilitar tests:** no borrar ni aflojar asserts, no convertir fallas en `skip`, no capturar `AssertionError`. Un `skip` solo vale por falta de entorno (`ImportError`, sin conexión), con el motivo escrito.
4. **No inventar:** selectores, rutas, endpoints, nombres de campos y APIs externas salen del `design.md` del change o de lo que confirme el usuario. Si falta algo, frenar y preguntar; nunca escribir "resuelto" sin haberlo verificado. Las librerías y servicios nuevos salen de `## Stack` de `openspec/config.yaml` o del `design.md`; si necesitás uno que no está en ninguno, frená y preguntá.
5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en commit aparte.
6. **Sin comentarios de razonamiento:** nada de monólogo en el código ("wait...", "I will...", dudas). Solo comentarios que expliquen el código.
7. **Resumen final con evidencia:** al terminar, el apply lista las tareas marcadas, cada una con su evidencia (salida del test en rojo y en verde, o salida de consola o captura para tareas manuales), y las que quedaron abiertas con el motivo. Además de incluir este resumen en el output del chat, el Agente guarda una copia completa en el vault: `$env:OBSIDIAN_VAULT\projects\<proyecto>\apply\AAAA-MM-DD-<change>.md`, con `<proyecto>` = nombre de la carpeta del repo. La copia incluye frontmatter con `project`, `change`, `date` y la rama con su commit (`git log --oneline -3`), sección `## Tareas marcadas` con cada ID y su evidencia, y sección `## Tareas abiertas` con el motivo. Salidas sensibles, credenciales o datos personales se reemplazan por `<DATO OMITIDO>`. El Agente solo escribe el archivo: NO hace commit ni push de él (la carpeta está en el `.gitignore` del vault). Si el apply se repite el mismo día, agrega una sección al final en vez de sobrescribirlo. Si el vault no existe en la máquina, lo anota en el resumen del chat y continúa.
8. **Respetar la arquitectura:** los archivos nuevos van en la carpeta que indica el `design.md`, dentro de las declaradas en `## Arquitectura` de `openspec/config.yaml`. No crees carpetas fuera de las declaradas (sí subcarpetas de una declarada) ni agregues imports que una carpeta tiene prohibidos (`no importa:`). Si necesitás una carpeta que el design no prevé, frená y preguntá. Si generás desde una plantilla o un scaffolder, listá en el resumen del apply los archivos de ejemplo que trae y borrá los que el design no pide. Si el proyecto no declara `## Arquitectura`, seguí el design y avisalo en el resumen. Si el `design.md` trae `## Recomendación de arquitectura`, aplicá sus pautas para el Agente aunque el verify no pueda controlarlas.

En `/opsx:verify`, Claude lee la copia del resumen en `projects/<proyecto>/apply/` del vault y contrasta cada `[x]` con su evidencia y con el diff; un `[x]` sin evidencia, sin respaldo en el diff o la ausencia del archivo de resumen es un desvío (CRITICAL).

Distribución a agentes no-Claude: `templates/comun/AGENTS.md` (estándar multi-agente, en la raíz de cada proyecto), `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md` llevan estas mismas 8 reglas.

## Al iniciar cada sesión
1. Correr `openspec list --json` para detectar si el proyecto usa OpenSpec.
   - Si responde con changes → **usar Modo OpenSpec** (ver sección abajo). Ignorar el flujo manual de `specs/`.
   - Si falla o no existe → usar el flujo SDD manual con `specs/` y prompts bash.
2. Leer siempre (aplica en ambos modos):
   - `change-map.md` → qué Change está activo
   - El artefacto de tareas del Change activo → pendientes `[ ]` y `[x]`
3. Consultar vault de Obsidian si existe contexto histórico del proyecto:
   - Resolver vault: `$vault = $env:OBSIDIAN_VAULT`. Si no está definida, avisar y continuar sin vault (no asumir una ruta por defecto).
   - `$projectName = Split-Path (Get-Location) -Leaf`
   - Si `$vault\projects\$projectName\_index.md` existe → leerlo
   - Leer las últimas 3 notas archivadas en esa carpeta para recuperar contexto sin re-explicación

## Modo OpenSpec (cuando `openspec` CLI está disponible)

Cuando el proyecto usa OpenSpec, este flujo **reemplaza** al flujo manual de `specs/` + prompts bash:

| SDD Manual | OpenSpec |
|---|---|
| Artefactos en `specs/{feature}/` | Artefactos en `openspec/changes/{nombre}/` |
| `spec.yaml + CLAUDE.md + Task.md + threat-model.md` | `proposal.md + design.md + specs/**/*.md + tasks.md` |
| Prompt bash al CLI del Agente | `/opsx:apply {nombre}` |
| `change-map.md` manual | `openspec list --json` |

**Reglas en Modo OpenSpec:**
- Correr `openspec status --change "{nombre}" --json` para entender el schema antes de crear archivos.
- Crear los artefactos en `openspec/changes/{nombre}/` con el schema que indique el status.
- Para implementar: invocar el skill `/opsx:apply` — no generar prompts bash manuales.
- El directorio `specs/` legacy puede coexistir pero no se usa para changes nuevos.

## Reglas de Git

### Branches
- Cada change de OpenSpec vive en su propia rama: `change/{nombre-change}`
- Claude crea la rama al finalizar `/opsx:propose`: `git checkout -b change/{nombre-change}`
- El Agente commitea en esa rama durante el apply
- Nunca trabajar directamente en `main`/`master` para changes con spec

### Commits
- Formato obligatorio: `{type}: {descripción corta}` — types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`
- Trailer obligatorio: `Spec-ID: {nombre-change}`
- Antes de cualquier commit: verificar con `git diff --staged` que no hay secrets ni archivos sensibles
- Nunca commitear: `.env`, `*.key`, `*.pem`, archivos de credenciales

### Pull Requests
- PR se abre después de que el Agente termina el apply, antes del verify
- Título: `[{nombre-change}] {descripción del change}`
- Body debe incluir `Spec-ID: {nombre-change}`
- Merge solo con `/opsx:verify` aprobado y sin desvíos reportados
- El archive se ejecuta después del merge, nunca antes

### .env y .gitignore
- Si el proyecto no tiene `.gitignore` al inicializar → crearlo antes del primer commit
- El `.gitignore` DEBE incluir como mínimo: `.env`, `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`
- Antes de cualquier push: verificar que `.env` está en `.gitignore`

## Seguridad universal (aplica a todos los proyectos)
1. NUNCA hardcodear secrets, API keys ni tokens — todo a `.env` (excluido del repo) o Vault/KMS.
2. NUNCA loguear datos sensibles, documentos ni PII.
3. NUNCA usar `eval()` o `exec()` sobre inputs externos.
4. Revisar `git diff --staged` antes de cada commit.
5. Verificar que `.env` esté en `.gitignore` antes de cada push.

## Capa de Seguridad por Tipo de Proyecto

Antes de crear cualquier artefacto (`proposal.md`, `design.md`, `specs/*.md`), leer el campo `project_type` en `openspec/config.yaml` del proyecto activo. Aplicar los requisitos mínimos correspondientes. Todo `design.md` DEBE incluir una sección `## Security Layer` con los controles aplicables al change.

### `frontend`
- JWT: almacenar en httpOnly cookie (nunca localStorage), validar expiración, implementar refresh token
- CSP: Content-Security-Policy header configurado
- XSS: sanitizar todo input del usuario antes de renderizar en el DOM
- CSRF: token anti-CSRF en formularios con estado

### `backend-api`
- JWT: middleware de validación en cada endpoint protegido
- Rate limiting: respuesta 429 con Retry-After header
- Auth/Authz: 401 para no autenticados, 403 para no autorizados
- Validación de inputs: jsonschema o equivalente en todos los endpoints
- CORS: lista blanca de dominios, nunca `*` en producción

### `etl` / `scripts`
- Secrets: NUNCA hardcodeados — `.env` en `.gitignore` o variables del scheduler
- Logging: no loguear PII, documentos ni credenciales
- Error handling: capturar todas las excepciones, exit code != 0 en fallos
- Inputs externos: validar formato antes de procesar

### `fullstack`
- Aplicar todos los controles de `frontend` + `backend-api`
- Definir boundary explícito frontend/backend en el `design.md` del change
- Next.js: los módulos de servidor (DB, secretos, CMS) importan `server-only` (recomendado); cubre las cadenas de imports hacia el cliente que el verify no ve

### `tooling` / `config`
- Los artefactos modificados son instrucciones para IA — verificar que no expongan secrets ni paths absolutos sensibles
- Cambios al CLAUDE.md global o skills → commit separado con descripción del impacto

### Datos personales (cualquier tipo de proyecto)
- No loguear datos personales (ni en logs, ni en errores, ni en salidas de consola).
- Pedir y guardar solo los campos necesarios.
- Enmascararlos en reportes, capturas y salidas no productivas (por ejemplo `261-***-**34`).
- No usar datos reales en tests ni fixtures: usar datos inventados.
- No exponerlos en URLs ni en parámetros de consulta.
Se aplica cuando `## Datos` declara un dato `personal` y el change lo toca. La normativa aplicable es la Ley 25.326; ante dudas legales, consultar al área responsable.

## Arquitectura del proyecto

Cada proyecto puede declarar su estructura en la subsección `## Arquitectura` del `context:` de `openspec/config.yaml`. El formato es una línea por carpeta con ruta relativa a la raíz y `/` final:

- `src/app/: rutas y páginas; compone frontend y backend`
- `src/backend/: Payload, DB, secretos, integraciones`
- `src/frontend/: componentes, estilos, hooks de cliente | no importa: src/backend/`
- `tests/: espejo de src/`

Las claves sin `/` final son reservadas: `comando` y `timeout` (herramienta opcional; `timeout` en minutos y obligatorio si hay `comando`), `estado` (único valor: `inferido — revisar`), `nivel` (`0`, `1-nucleo-funcional`, `2-capas`, `2-tuberias`, `3-hexagonal` o `3-modular`; si falta, el proyecto está sin evaluar), `tamaño` (`<aviso>, <advertencia>` en líneas) y `tamaño-excluir` (rutas con `/` final, separadas por coma). Se permiten siempre, sin declararlos: los archivos sueltos de la raíz, `openspec/`, `docs/`, las carpetas que empiezan con `.` y las subcarpetas de una carpeta declarada. Solo se expresan prohibiciones (`| no importa:`), no listas de "solo puede importar", para que el formato no crezca.

### Estructura sugerida por tipo de proyecto

Punto de partida orientativo (no obligatorio):

| Tipo | Carpetas sugeridas | Prohibiciones |
|---|---|---|
| `frontend` | `src/app/` o `src/pages/` (rutas), `src/components/`, `src/lib/`, `public/`, `tests/` | — |
| `backend-api` | `src/api/` (rutas y controladores), `src/services/`, `src/db/`, `src/config/`, `tests/` | `src/api/` no importa `src/db/` |
| `fullstack` (una app) | `src/app/` (rutas; compone), `src/backend/`, `src/frontend/`, `tests/` (espejo) | `src/frontend/` no importa `src/backend/` |
| `fullstack` (monorepo) | `apps/web/`, `apps/api/`, `packages/shared/` (tipos y utilidades sin secretos) | `apps/web/` no importa `apps/api/`; `packages/shared/` no importa `apps/` |
| `etl` / `scripts` | `src/<paquete>/extract/`, `transform/`, `load/`, `config/`, `scripts/` (entradas), `tests/` | `transform/` no importa `extract/` ni `load/` |
| `tooling` / `config` | `skills/`, `templates/`, `.claude/`, `docs/` | — |

### Escalera de niveles

| `nivel` | Receta | Cuándo subir |
|---|---|---|
| `0` | Sin estilo | — |
| `1-nucleo-funcional` | Núcleo funcional: cálculos separados de conexiones | una función o archivo mezcla I/O (leer o escribir archivos, red, base de datos, APIs, logs) con cálculos |
| `2-tuberias` | Tuberías y filtros (ETL) | los pasos de un ETL (extraer, transformar, cargar) están en un solo archivo o función |
| `2-capas` | Capas: presentación, negocio y datos | rutas, controladores o pantallas con SQL o llamadas a APIs adentro |
| `3-hexagonal` | Hexagonal / Clean: dominio aislado con puertos y adaptadores | hay que poder cambiar una integración (Salesforce por otro CRM, Excel por una API) sin tocar las reglas |
| `3-modular` | Monolito modular: un módulo por dominio de negocio | varios dominios de negocio (ventas, posventa, repuestos) en el mismo código que se pisan |

Las recetas completas están en `~/.claude/skills/arquitectura/references/recetas.md`.
La guía para estudiar está en `docs/guia-arquitecturas.md` del repo `sdd-global-config`.

### Responsabilidades por actor

- **Claude (`/opsx:propose`):** pide o infiere la arquitectura si falta en `context:`, ofreciendo la sugerida o inferida, documenta la tabla `## Ubicación de archivos` en el `design.md`, recomienda un nivel con evidencia cuando el change cruza una señal y escribe `tamaño` en proyectos nuevos.
- **Claude (`/arquitectura`):** diagnostica un proyecto existente y escribe `## Arquitectura` solo con aprobación.
- **Agente (regla 8):** ubica los archivos nuevos según el `design.md`, respeta las prohibiciones de importación (`no importa:`), no crea carpetas fuera de las declaradas (sí subcarpetas) y frena ante carpetas no previstas.
- **Claude (`/opsx:verify`):** controla la arquitectura solo en el diff del change: archivo nuevo fuera de carpetas permitidas (WARNING), import prohibido directo (CRITICAL), comando de análisis fallido o no ejecutable (CRITICAL), proyecto sin `## Arquitectura` declarada (SUGGESTION), coherencia del nivel (SUGGESTION) y tamaño de los archivos que crecen (SUGGESTION/WARNING, solo con `tamaño`).

## Ficha del proyecto

Declara qué hace la aplicación, qué entra en la versión actual, qué datos maneja y con qué tecnologías, dentro del `context:` de `openspec/config.yaml`.

### Subsecciones

- **`## Alcance`**: versión e ítems que incluye y que no incluye todavía.
  ```yaml
  ## Alcance
  - versión: V1
  - incluye: alta de leads desde la web
  - no incluye: integración con Salesforce
  ```
- **`## Datos`**: cada dato con sus campos, su origen (`externo` o `propio`) y su tipo (`personal`, `interno` o `público`).
  ```yaml
  ## Datos
  - leads (nombre, teléfono, email): formulario web (externo) | personal
  ```
  Externo es lo que entra desde afuera del sistema (formularios, Excel, APIs, scraping); propio es lo que el sistema genera o ya tiene en su base. Personal es todo dato de una persona identificable (Ley 25.326); interno, datos del negocio sin personas; público, información publicada.
- **`## Stack`**: tecnologías principales (`lenguaje`, `framework`, `base-de-datos`, `integraciones` y `librerias`, en ese orden). Solo se escriben las claves declaradas, sin relleno.
  ```yaml
  ## Stack
  - lenguaje: Python 3.11
  - framework: FastAPI
  - base-de-datos: PostgreSQL 15
  - integraciones: Salesforce API
  - librerias: pydantic, httpx
  ```

¿Qué hace la aplicación? se responde con la línea de descripción del `context:` y `## Objetivos de Negocio` (formato `- <id>: <descripción>`).

### Responsabilidades por actor

- **Claude (`/ficha`):** entrevista que completa las partes que faltan sin reescribir lo existente y sin guardar datos reales.
- **Claude (`/opsx:propose`):** avisa en el resumen final si falta la ficha (sin bloquear) y cuida el alcance preguntando si un change pide algo marcado en `no incluye`.
- **Seguridad (`Security Layer`):** aplica los controles de datos personales cuando `## Datos` declara un dato `personal` y el change lo toca.
- **Agente (regla 4):** toma las librerías y servicios de `## Stack` o del `design.md`, frenando si necesita uno no previsto.

## Capa de Persistencia — Obsidian

Vault local: ruta en `$env:OBSIDIAN_VAULT`, configurada en el perfil de PowerShell de cada máquina (sin esa variable, no hay vault — no asumir una ruta por defecto). Archivos `.md` en filesystem, sin MCP ni plugins. Claude accede via PowerShell.

### Alcance: memoria nativa vs vault compartido

- La memoria nativa de Claude Code (`~/.claude/projects/{proyecto}/memory/`) es privada y scoped por proyecto — el Agente y las sesiones de Claude en otros proyectos no pueden leerla.
- El vault de Obsidian es la única capa pensada para persistir entre proyectos y agentes.
- Regla: todo lo necesario para un handoff (otra sesión, otro proyecto, otro agente) va al vault (`context.md`), no solo a la memoria nativa. La memoria nativa queda reservada para lo puramente interno a esa sesión/herramienta.

### Vault compartido via GitHub

El vault es un repo git privado (`sdd-vault` en GitHub) compartido entre máquinas y programadores:

- **Al iniciar sesión** (antes de leer contexto): `git -C $vault pull --rebase` — si falla por conflicto, avisar al usuario y no forzar.
- **Tras cada escritura al vault** (propose/apply/verify/archive/sync de reglas): `git -C $vault add -A`, commit `chore: {proyecto} — {operación}` y push.
- Si el push falla (sin red, sin remote): continuar sin bloquear el flujo y avisar al final de la operación.
- `context.md` se reescribe en cada operación — si dos personas trabajan el mismo proyecto en paralelo, coordinar para no pisarse.
- Máquina nueva: clonar `sdd-vault` y apuntar `$env:OBSIDIAN_VAULT` a esa carpeta.

### Cuándo actuar

| Comando | Lee | Escribe |
|---|---|---|
| Inicio de sesión | `context.md` + últimas 3 notas de `archive\` | — |
| `/opsx:explore` | `context.md` | — |
| `/opsx:propose` | `context.md` | `decisions\YYYY-MM-DD-{change}.md` + actualiza `context.md` |
| `/opsx:apply` | `decisions\{change}.md` | actualiza `context.md` con progreso (el Agente escribe `apply\AAAA-MM-DD-{change}.md`) |
| `/opsx:verify` | `apply\AAAA-MM-DD-{change}.md` | actualiza `context.md` con resultado del verify |
| `/opsx:archive` | — | `archive\YYYY-MM-DD-{change}.md` + actualiza `context.md` |
| Change revertido | — | Actualiza `status:` en la nota a `revertido` |
| Cambio al CLAUDE.md global | — | re-sincroniza `_global\reglas-globales.md` + copia en repo `sdd-global-config` |

### Estructura del vault

```
$vault\
  _global\
    reglas-globales.md              ← espejo del CLAUDE.md global (persistencia agéntica)
  projects\
    {nombre-proyecto}\
      _index.md                     ← índice con links a todos los changes
      context.md                    ← estado actual del proyecto (actualizado en cada operación)
      apply\                        ← resúmenes del apply del Agente (local, no versionada por git)
        AAAA-MM-DD-{change}.md
      decisions\
        YYYY-MM-DD-{change}.md      ← creada al propose
      archive\
        YYYY-MM-DD-{change}.md      ← creada al archive
```

### Reglas globales en el vault (`_global\`)

El CLAUDE.md global se espeja en `$vault\_global\reglas-globales.md` para lograr persistencia agéntica entre chats: cualquier agente con acceso al filesystem (el Agente, otros chats de Claude) puede leer las reglas del workflow sin depender de `~/.claude/`.

- **Fuente canónica:** `~/.claude/CLAUDE.md` — el espejo NUNCA se edita a mano.
- Cada vez que se modifica el CLAUDE.md global → re-sincronizar el espejo en la misma operación (comando en la sección de PowerShell).
- Si al iniciar sesión el espejo no existe o está desactualizado respecto a la fuente → re-sincronizarlo.
- **Onboarding de agentes no-Claude:** El Agente no carga `~/.claude/` — lee las reglas desde el espejo del vault via plantillas en `$env:SDD_CONFIG_REPO\templates\`. Al sumar un proyecto al workflow: copiar `templates\copilot\copilot-instructions.md` → `.github\copilot-instructions.md`, `templates\cursor\sdd-workflow.mdc` → `.cursor\rules\sdd-workflow.mdc` y `templates\comun\AGENTS.md` → `AGENTS.md` del proyecto (fusionar si ya existen). `templates\antigravity\GEMINI.md` → `~/.gemini/GEMINI.md` se instala una sola vez por máquina.

### Copia versionada en el repo `sdd-global-config`

El CLAUDE.md global también se versiona en el repo `sdd-global-config` como `.claude/CLAUDE.md` (ruta del repo en `$env:SDD_CONFIG_REPO`, configurada en el perfil de PowerShell igual que `OBSIDIAN_VAULT`).

- Tras modificar el CLAUDE.md global: copiar a `$env:SDD_CONFIG_REPO\.claude\CLAUDE.md` y commitear con descripción del impacto (regla de `tooling/config`).
- Si `$env:SDD_CONFIG_REPO` no está definida → pedir la ruta al usuario, no adivinarla.
- En una máquina nueva el flujo es inverso: clonar el repo y copiar `.claude\CLAUDE.md` → `~/.claude/CLAUDE.md` (ver setup del README).

Orden completo ante un cambio de reglas: editar `~/.claude/CLAUDE.md` → sincronizar espejo del vault → copiar al repo y commitear.

### Formato de context.md

```markdown
---
project: {proyecto}
updated: YYYY-MM-DD
---

## Estado actual
{change activo o "sin change activo"}

## Último change
{nombre y fecha del último change archivado}

## Decisiones recientes
{puntos clave de los últimos 2-3 changes}

## Contexto activo
{información relevante para el próximo trabajo}
```

### Comandos PowerShell

Resolver vault antes de cualquier operación:
```powershell
$vault = $env:OBSIDIAN_VAULT
$p = Split-Path (Get-Location) -Leaf
```
Si `$vault` está vacía, no asumir ninguna ruta: omitir las operaciones de vault y avisarlo en el resumen.

**Leer contexto al iniciar sesión:**
```powershell
Get-Content "$vault\projects\$p\context.md" -ErrorAction SilentlyContinue
Get-ChildItem "$vault\projects\$p\archive\*.md" -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending | Select-Object -First 3 | Get-Content
```

**Escribir nota de decisions (al propose):**
```powershell
$dir = "$vault\projects\$p\decisions"
New-Item -ItemType Directory -Force $dir | Out-Null
$content | Out-File -FilePath "$dir\YYYY-MM-DD-{change}.md" -Encoding utf8
```

**Escribir nota de archive (al archive):**
```powershell
$dir = "$vault\projects\$p\archive"
New-Item -ItemType Directory -Force $dir | Out-Null
$content | Out-File -FilePath "$dir\YYYY-MM-DD-{change}.md" -Encoding utf8
```

**Actualizar context.md:**
```powershell
$content | Out-File -FilePath "$vault\projects\$p\context.md" -Encoding utf8
```

**Actualizar estado de una nota:**
```powershell
(Get-Content "$vault\projects\$p\decisions\YYYY-MM-DD-{change}.md") `
  -replace 'status: activo', 'status: archivado' |
  Set-Content "$vault\projects\$p\decisions\YYYY-MM-DD-{change}.md"
```

**Eliminar nota:**
```powershell
Remove-Item "$vault\projects\$p\decisions\YYYY-MM-DD-{change}.md" -ErrorAction SilentlyContinue
```

**Sincronizar reglas globales al vault (tras modificar el CLAUDE.md global):**
```powershell
$dir = "$vault\_global"
New-Item -ItemType Directory -Force $dir | Out-Null
$src = "$env:USERPROFILE\.claude\CLAUDE.md"
$header = "---`ntype: reglas-globales`nsource: ~/.claude/CLAUDE.md`nupdated: $(Get-Date -Format yyyy-MM-dd)`n---`n`n> [!info] Espejo de solo lectura. Fuente canónica: ``~/.claude/CLAUDE.md``. No editar acá.`n`n"
$header + (Get-Content $src -Raw) | Out-File "$dir\reglas-globales.md" -Encoding utf8
```
