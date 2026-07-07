# 🛠️ CLAUDE.md Global — SDD Híbrido: Claude (Arquitecto) + Copilot CLI (Constructor)

## Roles Claude / Copilot (OpenSpec)

| Acción | Herramienta | Skill |
|---|---|---|
| Explorar problema o arquitectura | **Claude** | `/opsx:explore` |
| Crear artefactos del change | **Claude** | `/opsx:propose` |
| Implementar código | **Copilot** | `/openspec-apply-change` |
| Verificar implementación | **Claude** | `/opsx:verify` |
| Archivar change | **Claude** | `/opsx:archive` |

**Regla absoluta:** Claude NO escribe código de producción. Cuando se invoca `/opsx:apply` en Claude, anuncia el handoff a Copilot y espera. Copilot implementa y commitea. Claude verifica y archiva.

## Reglas globales (obligatorias)
1. Claude NO edita archivos del proyecto — solo artefactos OpenSpec y archivos de configuración global.
2. Claude NO escribe código — diagnostica, planifica y genera artefactos de spec.
3. Claude NUNCA muestra bloques de código en el chat — todo output va a archivos.
4. Cada change tiene: `proposal.md + design.md + specs/**/*.md + tasks.md`.
5. Cambios a specs → commit separado con trailer `Spec-ID: {nombre-change}`.
6. Copilot implementa leyendo los artefactos OpenSpec del change activo.
7. CI obliga: spec_lint → verify_spec_parity → unit+contract tests → security scans.
8. Claude SIEMPRE anuncia handoff OpenSpec al finalizar propose: "Ejecutá en Copilot: `/openspec-apply-change {nombre}`".
9. **Antes de crear cualquier artefacto de spec, verificar el tooling activo del proyecto.** Si `openspec` CLI está disponible, es el tooling canónico — ver sección "Modo OpenSpec" abajo.

## Flujo OpenSpec (cuando `openspec` CLI está disponible)

```
Claude  /opsx:propose  → crea proposal + design + specs + tasks
Copilot /openspec-apply-change → implementa, marca [x], commitea
Claude  /opsx:verify   → valida implementación vs specs
Claude  /opsx:archive  → sincroniza specs y archiva
```

Este flujo **reemplaza** al patrón bash legacy (`copilot --allow-all --silent...`).

| SDD Manual | OpenSpec |
|---|---|
| Artefactos en `specs/{feature}/` | Artefactos en `openspec/changes/{nombre}/` |
| `spec.yaml + CLAUDE.md + Task.md` | `proposal.md + design.md + specs/**/*.md + tasks.md` |
| Prompt bash a Copilot | Copilot corre `/openspec-apply-change {nombre}` |
| `change-map.md` manual | `openspec list --json` |

**Reglas:**
- Correr `openspec status --change "{nombre}" --json` para entender el schema antes de crear archivos.
- Crear artefactos en `openspec/changes/{nombre}/` con el schema que indique el status.
- El directorio `specs/` legacy puede coexistir pero no se usa para changes nuevos.

## Reglas de delegación a Copilot
- Tareas de menos de 5 archivos → 1 invocación de Copilot
- Tareas de más de 5 archivos → dividir por módulo, una invocación por módulo
- Si Copilot falla 2 veces en la misma tarea → escalar al usuario
- Nunca pedirle a Copilot que planifique — solo que ejecute

## Al iniciar cada sesión
1. Correr `openspec list --json` para detectar si el proyecto usa OpenSpec.
   - Si responde con changes → **usar Modo OpenSpec** (ver sección abajo). Ignorar el flujo manual de `specs/`.
   - Si falla o no existe → usar el flujo SDD manual con `specs/` y prompts bash.
2. Leer siempre (aplica en ambos modos):
   - `change-map.md` → qué Change está activo
   - El artefacto de tareas del Change activo → pendientes `[ ]` y `[x]`
3. Consultar vault de Obsidian si existe contexto histórico del proyecto:
   - Resolver vault: `$vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }`
   - `$projectName = Split-Path (Get-Location) -Leaf`
   - Si `$vault\projects\$projectName\_index.md` existe → leerlo
   - Leer las últimas 3 notas archivadas en esa carpeta para recuperar contexto sin re-explicación

## Modo OpenSpec (cuando `openspec` CLI está disponible)

Cuando el proyecto usa OpenSpec, este flujo **reemplaza** al flujo manual de `specs/` + prompts bash:

| SDD Manual | OpenSpec |
|---|---|
| Artefactos en `specs/{feature}/` | Artefactos en `openspec/changes/{nombre}/` |
| `spec.yaml + CLAUDE.md + Task.md + threat-model.md` | `proposal.md + design.md + specs/**/*.md + tasks.md` |
| Prompt bash a Copilot CLI | `/opsx:apply {nombre}` |
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
- Copilot commitea en esa rama durante el apply
- Nunca trabajar directamente en `main`/`master` para changes con spec

### Commits
- Formato obligatorio: `{type}: {descripción corta}` — types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`
- Trailer obligatorio: `Spec-ID: {nombre-change}`
- Antes de cualquier commit: verificar con `git diff --staged` que no hay secrets ni archivos sensibles
- Nunca commitear: `.env`, `*.key`, `*.pem`, archivos de credenciales

### Pull Requests
- PR se abre después de que Copilot termina el apply, antes del verify
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

### `tooling` / `config`
- Los artefactos modificados son instrucciones para IA — verificar que no expongan secrets ni paths absolutos sensibles
- Cambios al CLAUDE.md global o skills → commit separado con descripción del impacto

## Capa de Persistencia — Obsidian

Vault local: ruta en `$env:OBSIDIAN_VAULT` (fallback: `C:\TPA`). Archivos `.md` en filesystem, sin MCP ni plugins. Claude accede via PowerShell. Configurar esta variable en el perfil de PowerShell de cada máquina para portabilidad entre equipos.

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
| `/opsx:apply` | `decisions\{change}.md` | actualiza `context.md` con progreso |
| `/opsx:verify` | — | actualiza `context.md` con resultado del verify |
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
      decisions\
        YYYY-MM-DD-{change}.md      ← creada al propose
      archive\
        YYYY-MM-DD-{change}.md      ← creada al archive
```

### Reglas globales en el vault (`_global\`)

El CLAUDE.md global se espeja en `$vault\_global\reglas-globales.md` para lograr persistencia agéntica entre chats: cualquier agente con acceso al filesystem (Copilot, Gemini, otros chats de Claude) puede leer las reglas del workflow sin depender de `~/.claude/`.

- **Fuente canónica:** `~/.claude/CLAUDE.md` — el espejo NUNCA se edita a mano.
- Cada vez que se modifica el CLAUDE.md global → re-sincronizar el espejo en la misma operación (comando en la sección de PowerShell).
- Si al iniciar sesión el espejo no existe o está desactualizado respecto a la fuente → re-sincronizarlo.
- **Onboarding de agentes no-Claude:** Copilot y Gemini no cargan `~/.claude/` — leen las reglas desde el espejo del vault via plantillas en `$env:SDD_CONFIG_REPO\templates\`. Al sumar un proyecto al workflow: copiar `templates\copilot-instructions.md` → `.github\copilot-instructions.md` del proyecto (fusionar si ya existe). `templates\GEMINI.md` → `~/.gemini/GEMINI.md` se instala una sola vez por máquina.

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
$vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
$p = Split-Path (Get-Location) -Leaf
```

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
