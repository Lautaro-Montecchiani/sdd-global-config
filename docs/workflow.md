# Workflow SDD Híbrido — Claude (Arquitecto) + Agente (Constructor)

Guía de referencia para iniciar o incorporar cualquier proyecto al workflow SDD con OpenSpec.

---

## Roles

| Herramienta | Rol | Skills que usa |
|---|---|---|
| **Claude Code** | Arquitecto — planifica, especifica, verifica, archiva | `explore`, `propose`, `verify`, `archive` |
| **Agente** | Constructor — implementa, commitea | `apply` |

---

## Setup inicial (una sola vez por máquina)

```powershell
# 1. Copiar todas las skills y los comandos /opsx al global de Claude
#    (los comandos son lo que ejecutan /opsx:*; en Claude Code lo del proyecto pisa a lo global)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands\opsx" | Out-Null
cp -r skills\* "$env:USERPROFILE\.claude\skills\"
cp .claude\commands\opsx\*.md "$env:USERPROFILE\.claude\commands\opsx\"

# 2. Declarar ruta del vault de Obsidian en el perfil de PowerShell
# Editar $PROFILE y agregar:
# $env:OBSIDIAN_VAULT = "C:\TPA"   # cambiar por la ruta real en esta máquina

# 3. Agregar verify al perfil global de OpenSpec
# Editar $env:APPDATA\openspec\config.json
# "workflows": ["propose", "explore", "apply", "verify", "archive"]
```

Las skills y los comandos viven en este repo, en `skills/` y en `.claude/commands/opsx/`:
- `skills/openspec-apply-change/SKILL.md` — apply modificado: Claude anuncia handoff, no escribe código
- `skills/openspec-verify-change/SKILL.md` — verify: valida implementación vs specs
- `skills/openspec-explore/SKILL.md` — explore: lee context.md del vault (solo lectura)
- `.claude/commands/opsx/*.md` — comandos `/opsx:*` con el mismo comportamiento que las skills

---

## Onboarding: proyecto nuevo

```powershell
# 1. Crear repo
mkdir mi-proyecto; cd mi-proyecto; git init

# 2. Inicializar OpenSpec SOLO con el Agente (reemplazar <agente> por su id: copilot, antigravity, etc.)
# No incluir claude en --tools: con claude, init genera copias locales por defecto de los comandos
# /opsx y de las skills openspec-* que pisan a las globales de ~/.claude (el workflow híbrido).
# Sin claude, Claude usa los comandos y skills globales.
openspec init --tools <agente>

# 3. Verificar que el Agente tiene sus skills (sistema distinto al de Claude, no tocar)
# .agent\skills\ (o .github\skills\ según el agente) es lo que lee el Agente
ls .agent\skills\openspec-apply-change\   # debe mostrar SKILL.md

# 4. Agregar verify al perfil global de OpenSpec (si no está)
# Editar $env:APPDATA\openspec\config.json
# y asegurarse que "workflows" incluya "verify"

# 5. Completar openspec/config.yaml con project_type + stack
```

En `openspec/config.yaml` declarar:

```yaml
schema: spec-driven

context: |
  project_type: frontend | backend-api | etl | fullstack
  Stack: [describir tecnologías]
  Dominio: [describir el negocio]
  Convenciones: [nombrar archivos, variables, etc.]

rules:
  proposal:
    - Incluir sección "Non-goals"
  tasks:
    - Referenciar ruta exacta del archivo a modificar
  design:
    - Incluir sección "## Security Layer"
```

---

## Onboarding: proyecto existente sin OpenSpec

```powershell
# 1. Inicializar OpenSpec SOLO con el Agente (reemplazar <agente> por su id: copilot, antigravity, etc.)
#    Sin claude en --tools: Claude usa los comandos y skills globales de ~/.claude
cd mi-proyecto
openspec init --tools <agente>

# 2. Completar openspec/config.yaml con project_type + stack real
```

---

## Onboarding: proyecto existente con OpenSpec

```powershell
# 1. Eliminar las copias locales de Claude: son las versiones por defecto y pisan a las globales
#    (Claude implementaría código en /opsx:apply y no usaría el vault)
rm .claude\commands\opsx\*.md
rm -r .claude\skills\openspec-*

# 2. Completar openspec/config.yaml con project_type + stack real
```

Antes de borrar, si sospechás que el proyecto personalizó esas copias, compará con la versión estándar (`git diff`). Si los archivos están versionados, commiteá la eliminación aparte (por ejemplo `chore: usar los comandos globales de OpenSpec`), desde la rama principal y con el árbol limpio: no la hagas dentro de una rama `change/…`, porque mezclaría un commit sin el `Spec-ID` de ese change. `openspec update` no las vuelve a generar mientras el proyecto no use `claude` en `--tools`. Borrá solo `.claude\commands\opsx\` y las skills `openspec-*`, no el resto de `.claude\` (por ejemplo `settings.local.json`).

---

## Nota importante

**Nunca eliminar** `.agent\skills\openspec-apply-change\SKILL.md` — el Agente lo necesita para implementar.

**Nunca incluir `claude` en `--tools`** al iniciar un proyecto: `openspec init --tools claude,…` recrea las copias locales de Claude que pisan a las globales.

---

## Flujo por change

```
Claude   /opsx:propose <nombre>          → crea artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> → implementa en el branch, marca [x], commitea
Vos      git push + PR                   → abre PR con Spec-ID: {nombre} en el título
Claude   /opsx:verify <nombre>           → valida implementación vs specs sobre la PR
Vos      merge                           → merge a main solo con verify aprobado
Claude   /opsx:archive <nombre>          → archiva + exporta a Obsidian (post-merge)
```

### Descripción de cada paso

**1. Vos pedís una feature o fix**

> "Quiero agregar validación al formulario de licitación"

**2. Claude propone** (`/opsx:propose`)

Lee `context.md` del vault para cargar contexto previo del proyecto. Luego crea los artefactos en `openspec/changes/nombre-del-change/`:
- `proposal.md` — qué se hace y por qué
- `design.md` — cómo se hace, con sección `## Security Layer` según el tipo de proyecto
- `specs/*.md` — contratos técnicos detallados
- `tasks.md` — lista de tareas con archivos exactos a tocar

Al finalizar: escribe `decisions/YYYY-MM-DD-nombre.md` en el vault, actualiza `context.md` y crea el branch:
```powershell
git checkout -b change/nombre-del-change
```

**3. Vos abrís el Agente y ejecutás**

```
/openspec-apply-change nombre-del-change
```

El Agente implementa en el branch `change/nombre-del-change`, marca las tareas `[x]` y commitea con el formato:
```
feat: descripción corta

Spec-ID: nombre-del-change
```

**4. Vos abrís la PR**

```
git push origin change/nombre-del-change
```

Título de la PR: `[nombre-del-change] descripción del change`
Body debe incluir `Spec-ID: nombre-del-change`.

**5. Claude verifica** (`/opsx:verify`)

Lee el `tasks.md`, el `git diff` y los specs. Confirma que lo que el Agente implementó cumple la spec. Si hay desvíos, los reporta. El merge solo se hace si verify no reporta desvíos.

**6. Merge + Claude archiva** (`/opsx:archive`)

Merge a `main` con verify aprobado. Luego Claude archiva: mueve el change a `openspec/changes/archive/`, sincroniza los specs y exporta nota a Obsidian.

---

### Lo que cambia respecto a antes

- Nada se implementa sin spec previa
- Claude nunca escribe código — solo artefactos
- El Agente nunca planifica — solo ejecuta lo que dicen los artefactos
- Cada change queda trazado en git con `Spec-ID: nombre-del-change`

---

## Capa de seguridad por tipo de proyecto

Al crear specs, Claude aplica automáticamente los controles según el `project_type` declarado en `openspec/config.yaml`:

| Tipo | Controles mínimos |
|---|---|
| `frontend` | JWT en httpOnly cookie, CSP, XSS prevention, CSRF |
| `backend-api` | JWT middleware, rate limiting (429), auth (401/403), jsonschema, CORS whitelist |
| `etl` / `scripts` | Secrets en `.env`, sin PII en logs, exit codes, validación de inputs externos |
| `fullstack` | Todo frontend + todo backend-api |

---

## Capa de Persistencia — Obsidian

Al archivar un change, Claude exporta automáticamente una nota resumen al vault `C:\TPA\`:

```
C:\TPA\
  _global\
    reglas-globales.md              ← espejo del CLAUDE.md global (persistencia agéntica)
  projects\
    {nombre-proyecto}\
      _index.md                     ← índice con links a todos los changes
      YYYY-MM-DD-{change-name}.md   ← una nota por change archivado
```

Al iniciar sesión, Claude lee el `_index.md` del proyecto y las últimas 3 notas para recuperar contexto histórico sin re-explicación manual.

### Reglas globales en el vault (`_global\`)

Además de la memoria por proyecto, el vault espeja las reglas globales del workflow en `_global\reglas-globales.md`. Esto permite que cualquier agente con acceso al filesystem (el Agente, otros chats de Claude) lea las reglas SDD sin depender de `~/.claude/`. La fuente canónica sigue siendo `~/.claude/CLAUDE.md` — el espejo se re-sincroniza en cada modificación del CLAUDE.md global y nunca se edita a mano. El comando de sincronización está en la sección `## Capa de Persistencia — Obsidian` del CLAUDE.md global.

La integración usa PowerShell puro — sin MCP ni plugins. El skill de archive modificado (`skills/openspec-archive-change/SKILL.md`) maneja la escritura al vault. Las reglas de lectura/escritura/eliminación están en el `~/.claude/CLAUDE.md` global, sección `## Capa de Persistencia — Obsidian`.

---

## Archivos gestionados por este repo

| Archivo | Propósito |
|---|---|
| `~/.claude/CLAUDE.md` | Reglas globales de Claude para todos los proyectos — copia versionada en `.claude/CLAUDE.md` de este repo |
| `~/.claude/skills/openspec-apply-change/SKILL.md` | Comportamiento de apply en Claude (handoff al Agente) |
| `~/.claude/skills/openspec-verify-change/SKILL.md` | Skill de verify instalada globalmente |
| `~/.claude/skills/openspec-propose/SKILL.md` | Propose: lee context.md, escribe en decisions/, crea branch |
| `~/.claude/skills/openspec-archive-change/SKILL.md` | Archive: escribe en archive/, actualiza context.md |
| `~/.claude/skills/issue-creation/SKILL.md` | Issue-first: crea issue con template antes del propose |
| `~/.claude/skills/branch-pr/SKILL.md` | Valida commits, abre PR con formato correcto |
| `.github/workflows/pr-check.yml` | GitHub Action: valida branch, título, Spec-ID y secrets en cada PR |
| `CONTRIBUTING.md` | Guía de contribución: flujo completo issue → propose → PR → verify → merge |
| `$env:OBSIDIAN_VAULT\projects\` | Vault Obsidian — memoria persistente (context.md + decisions/ + archive/) |
| `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` | Espejo del CLAUDE.md global en el vault — persistencia agéntica entre chats |
