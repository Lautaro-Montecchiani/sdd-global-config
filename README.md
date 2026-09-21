# SDD Global Config

Repositorio de configuración global del workflow SDD Híbrido — Claude (arquitecto) + Agente (constructor).

## Qué contiene

| Archivo / Carpeta | Propósito |
|---|---|
| `.claude/CLAUDE.md` | Reglas globales de Claude — copia versionada, se instala en `~/.claude/CLAUDE.md` |
| `templates/` | Plantillas de instrucciones para el Agente (`.github/copilot-instructions.md` por proyecto y `~/.gemini/GEMINI.md` por máquina — el nombre de archivo lo impone cada herramienta) |
| `skills/openspec-apply-change/` | Apply: Claude anuncia handoff al Agente, no escribe código |
| `skills/openspec-propose/` | Propose: lee context.md, escribe decisions/, crea branch |
| `skills/openspec-archive-change/` | Archive: escribe en archive/, actualiza context.md |
| `skills/openspec-verify-change/` | Verify: valida implementación vs specs |
| `skills/openspec-explore/` | Explore: modo de pensamiento; lee context.md del vault (solo lectura) |
| `.claude/commands/opsx/` | Comandos `/opsx:*` (explore, propose, apply, verify, archive): son los que ejecuta Claude Code; se instalan en `~/.claude/commands/opsx/` |
| `skills/issue-creation/` | Issue-first: crea issue antes del propose |
| `skills/branch-pr/` | Valida commits y abre PR con formato correcto |
| `.github/workflows/pr-check.yml` | GitHub Action: valida branch, título, Spec-ID y secrets |
| `CONTRIBUTING.md` | Guía de contribución completa |
| `docs/workflow.md` | Referencia del flujo completo |
| `docs/modo-de-uso.md` | Guía paso a paso para usuarios |

## Setup (una sola vez por máquina)

```powershell
# 1. Clonar el repo
git clone <url> sdd-global-config
cd sdd-global-config

# 2. Instalar las reglas globales de Claude
cp .claude\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"

# 3. Copiar todas las skills y los comandos /opsx al global de Claude
#    (los comandos son lo que ejecutan /opsx:*; en Claude Code lo del proyecto pisa a lo global)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands\opsx" | Out-Null
cp -r skills\* "$env:USERPROFILE\.claude\skills\"
cp .claude\commands\opsx\*.md "$env:USERPROFILE\.claude\commands\opsx\"

# 4. Instalar el contexto global del Agente (fusionar si ya existe con contenido)
cp templates\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"

# 5. Instalar la baseline de permisos del CLI del Agente
#    Si ya existe un settings.json NO se sobrescribe: fusionar a mano con la plantilla.
#    Luego completar en settings.json los placeholders (ver templates\README.md):
#    {RUTA-DE-TU-USUARIO} y la lista de trustedWorkspaces.
#    La barra de estado NO se copia: se genera con el CLI (prompt en templates\README.md,
#    sección "Barra de estado").
$ag = "$env:USERPROFILE\.gemini\antigravity-cli"
New-Item -ItemType Directory -Force $ag | Out-Null
if (-not (Test-Path "$ag\settings.json")) { cp templates\antigravity-settings.json "$ag\settings.json" }

# 6. Clonar el vault compartido (memoria persistente del workflow)
git clone https://github.com/lmontecchiani-dev/sdd-vault "C:\TPA"   # o la ruta que prefieras

# 7. Declarar variables de entorno en el perfil de PowerShell ($PROFILE)
# $env:OBSIDIAN_VAULT  = "C:\TPA"                       # la misma ruta donde clonaste el vault
# $env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado este repo
```

Las rutas viven en `$env:OBSIDIAN_VAULT` y `$env:SDD_CONFIG_REPO` — el repo no hardcodea rutas y funciona en cualquier equipo.

**Sincronización continua:** la fuente canónica de las reglas es `~/.claude/CLAUDE.md`. Cada vez que se modifica, Claude re-sincroniza automáticamente el espejo del vault (`$vault\_global\reglas-globales.md`) y la copia versionada de este repo (`.claude/CLAUDE.md`), y commitea — la regla está en la sección `## Capa de Persistencia — Obsidian` del propio CLAUDE.md.

## Sumar un proyecto al workflow

```powershell
# Desde la raíz del proyecto nuevo. Iniciar OpenSpec SOLO con el Agente (reemplazar <agente> por su id:
# copilot, antigravity, etc.). No incluir claude en --tools: con claude, init genera copias locales por
# defecto de los comandos y skills que pisan a las globales de ~/.claude.
openspec init --tools <agente>

# El Agente lee este archivo en cada sesión de ese repo
New-Item -ItemType Directory -Force .github | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\copilot-instructions.md" .github\copilot-instructions.md
```

Claude (`~/.claude/CLAUDE.md`) y el Agente (`~/.gemini/GEMINI.md`, paso 4) cargan su configuración global en todas las sesiones: no requieren nada por proyecto. El paso por proyecto (`.github/copilot-instructions.md`) aplica al agente que lee ese archivo.

## Flujo resumido

```
Claude   /opsx:propose <nombre>          → artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> → implementa en el branch, commitea
Vos      git push + PR                   → título: [nombre] descripción, body: Spec-ID:
Claude   /opsx:verify <nombre>           → valida vs specs sobre la PR
Vos      merge                           → solo con verify aprobado
Claude   /opsx:archive <nombre>          → archiva + exporta a Obsidian (post-merge)
```

## Reglas de Git

| Regla | Convención |
|---|---|
| Branch | `change/{nombre-change}` — creado por Claude al finalizar propose |
| Commit | `{type}: {desc}` + trailer `Spec-ID: {nombre-change}` |
| PR | Título `[{nombre}] descripción` — merge solo con verify aprobado |
| .gitignore | Mínimo obligatorio: `.env`, `*.env`, `*.key`, `*.pem`, `secrets/` |
| .env | Nunca commitear — verificar en `.gitignore` antes de cada push |

Ver `docs/workflow.md` y `docs/modo-de-uso.md` para el detalle completo.

