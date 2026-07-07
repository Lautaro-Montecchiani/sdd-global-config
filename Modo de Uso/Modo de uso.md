# Modo de Uso — SDD Híbrido (Claude + Copilot)

## Inicio de proyecto

Estos son los pasos exactos a correr en tu terminal, dentro del proyecto:

### Paso 1 — Init

```powershell
cd "C:\Users\analistapi\Desktop\Proyectos\{nombre-proyecto}"
openspec init --tools claude,copilot
```

### Paso 2 — Liberar el slot de apply

`openspec init` crea `.claude\skills\openspec-apply-change\SKILL.md` con el comportamiento default donde Claude escribe código. Al borrarlo, el directorio queda vacío y Claude Code cae al skill global modificado — el que anuncia handoff a Copilot en vez de escribir código.

```powershell
rm .claude\skills\openspec-apply-change\SKILL.md
```

> **Nota:** `.agent\skills\openspec-apply-change\SKILL.md` es distinto — lo usa Copilot, no Claude Code. No borrarlo.

### Paso 3 — Completar openspec/config.yaml

Decile a Claude qué hace el proyecto (frontend, backend, fullstack, qué stack usa) y te arma el config completo.

### Paso 4 — Verificar que `.agent\skills\openspec-apply-change\SKILL.md` sigue intacto

```powershell
ls .agent\skills\openspec-apply-change\
```

Debe mostrar `SKILL.md` — ese es el que usa Copilot para implementar. Nunca borrarlo.

### Paso 5 — Instalar instrucciones de Copilot

Copilot no carga configuración global — lee `.github\copilot-instructions.md` del repo donde trabaja. Copiar la plantilla del repo de configuración:

```powershell
New-Item -ItemType Directory -Force .github | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\copilot-instructions.md" .github\copilot-instructions.md
```

Si el proyecto ya tiene un `copilot-instructions.md` propio, fusionar la sección "Workflow SDD" al principio en vez de reemplazarlo.

### Paso 6 — Verificar el `.gitignore`

Si el proyecto no tiene `.gitignore`, crearlo antes del primer commit. Mínimo obligatorio: `.env`, `*.env`, `*.key`, `*.pem`, `secrets/`.

---

## Setup por máquina (una sola vez, no por proyecto)

Detalle completo en el README del repo `sdd-global-config`. Resumen:

```powershell
# Reglas globales de Claude + skills (desde el repo clonado)
cp .claude\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"
# ... skills según README

# Contexto global de Gemini
cp templates\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"

# Variables de entorno en $PROFILE
$env:OBSIDIAN_VAULT  = "C:\TPA"                       # ruta real del vault en esta máquina
$env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado el repo
```

Claude y Gemini cargan su configuración global en todos los proyectos — solo Copilot necesita el paso 5 por proyecto.

---

## Flujo por change

```
Claude   /issue-creation               → crea issue, espera status:approved
Claude   /opsx:propose <nombre>        → lee Obsidian, crea artefactos + branch change/{nombre}
Copilot  /openspec-apply-change        → implementa en el branch, commitea con Spec-ID:
Claude   /branch-pr <nombre>           → valida commits, abre PR desde Obsidian decisions/
Claude   /opsx:verify <nombre>         → valida vs specs, actualiza Obsidian context.md
Vos      merge                         → solo con verify aprobado
Claude   /opsx:archive <nombre>        → archiva + escribe Obsidian archive/ (post-merge)
```

**1. Crear issue** (`/issue-creation`)

Antes de cualquier cambio, creás un issue con el template. Queda en `status:needs-review`. Un maintainer debe aprobar (`status:approved`) antes de continuar.

**2. Claude propone** (`/opsx:propose`)

Lee `context.md` del vault para recuperar contexto previo. Luego crea los artefactos en `openspec/changes/nombre-del-change/`:
- `proposal.md` — qué se hace y por qué
- `design.md` — cómo se hace, con sección `## Security Layer`
- `specs/*.md` — contratos técnicos detallados
- `tasks.md` — lista de tareas con archivos exactos a tocar

Al finalizar: escribe `decisions/YYYY-MM-DD-nombre.md` en Obsidian, actualiza `context.md` y crea el branch `change/nombre-del-change`.

**3. Copilot implementa**

```
/openspec-apply-change nombre-del-change
```

Copilot implementa en el branch, marca las tareas `[x]` y commitea con formato:
```
feat: descripción corta

Spec-ID: nombre-del-change
```

**4. Abrir PR** (`/branch-pr`)

```
/branch-pr nombre-del-change
```

El skill lee `decisions/{change}.md` del vault para armar el body, valida commits y abre la PR con el formato correcto. El GitHub Action `pr-check.yml` valida automáticamente branch, título y `Spec-ID:`.

**5. Claude verifica** (`/opsx:verify`)

Lee `tasks.md`, `git diff` y specs. Confirma que Copilot cumplió la spec. Actualiza `context.md` con el resultado. Merge solo si no hay desvíos.

**6. Merge + Claude archiva** (`/opsx:archive`)

Merge a `main` con verify aprobado. Claude archiva el change y escribe la nota final en Obsidian:
```
$env:OBSIDIAN_VAULT\projects\{proyecto}\archive\YYYY-MM-DD-{change-name}.md
```

---

## Lo que cambia respecto a antes

- Ningún change sin issue aprobado primero
- Nada se implementa sin spec previa
- Claude nunca escribe código — solo artefactos y notas en Obsidian
- Copilot nunca planifica — solo ejecuta lo que dicen los artefactos
- Cada change vive en su propio branch `change/{nombre}` y tiene PR
- Merge a main solo con verify aprobado
- Cada change queda trazado en git (`Spec-ID:`) y en Obsidian (`decisions/` → `archive/`)

---

## Reglas de Git

### Branches
- `change/{nombre-change}` — una rama por change, creada por Claude al finalizar propose
- Nunca commitear directo en `main`/`master`

### Commits
- Formato: `{type}: {descripción}` — types: `feat` `fix` `chore` `refactor` `docs` `test`
- Trailer obligatorio en todos los commits del change: `Spec-ID: {nombre-change}`

### .env y .gitignore
- `.gitignore` mínimo obligatorio: `.env`, `*.env`, `*.key`, `*.pem`, `secrets/`
- Verificar que `.env` está en `.gitignore` antes de cada push
- Nunca commitear credenciales, tokens ni API keys

---

## Capa de Persistencia — Obsidian

El vault en `$env:OBSIDIAN_VAULT` actúa como memoria persistente del proyecto — equivalente a Engram pero sobre el filesystem local. Claude lee y escribe automáticamente en cada operación OPSX, sin MCP ni plugins.

### Estructura del vault

```
$env:OBSIDIAN_VAULT\
  _global\
    reglas-globales.md              ← espejo del CLAUDE.md global (lo leen Copilot y Gemini)
  projects\
    {nombre-proyecto}\
      _index.md                     ← índice con links a todos los changes
      context.md                    ← estado actual del proyecto (actualizado continuamente)
      decisions\
        YYYY-MM-DD-{change}.md      ← creada al propose
      archive\
        YYYY-MM-DD-{change}.md      ← creada al archive
```

### Cuándo actúa Claude

| Comando | Lee | Escribe |
|---|---|---|
| Inicio de sesión | `context.md` + últimas 3 notas de `archive\` | — |
| `/issue-creation` | — | actualiza `context.md` con issue creado |
| `/opsx:explore` | `context.md` | — |
| `/opsx:propose` | `context.md` | `decisions\YYYY-MM-DD-{change}.md` + actualiza `context.md` |
| `/opsx:apply` | `decisions\{change}.md` | actualiza `context.md` con progreso |
| `/branch-pr` | `decisions\{change}.md` | actualiza `context.md` con PR abierta |
| `/opsx:verify` | — | actualiza `context.md` con resultado |
| `/opsx:archive` | — | `archive\YYYY-MM-DD-{change}.md` + actualiza `context.md` |

### Vault compartido via GitHub

El vault es un repo git privado (`sdd-vault`) — la memoria del workflow viaja entre máquinas y programadores:

- Claude hace `git pull --rebase` al iniciar sesión y commit+push tras cada operación que escribe en el vault.
- Si dos personas trabajan el mismo proyecto en paralelo, coordinar: `context.md` se reescribe en cada operación.

### Portabilidad entre máquinas

En cada máquina nueva:

```powershell
git clone https://github.com/lmontecchiani-dev/sdd-vault "C:\TPA"   # o la ruta que prefieras

# Agregar a $PROFILE
$env:OBSIDIAN_VAULT = "C:\TPA"   # la misma ruta del clone
```

El repo no hardcodea rutas — funciona en cualquier equipo.
