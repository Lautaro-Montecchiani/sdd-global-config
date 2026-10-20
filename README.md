# SDD Global Config

Repositorio de configuración global del workflow SDD Híbrido — Claude (arquitecto) + Agente (constructor).

## Qué contiene

| Archivo / Carpeta | Propósito |
|---|---|
| `.claude/CLAUDE.md` | Reglas globales de Claude — copia versionada, se instala en `~/.claude/CLAUDE.md` |
| `templates/` | Plantillas de instrucciones y configuración por agente (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md` y `templates/cursor/sdd-workflow.mdc` por proyecto; `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json` por máquina) |
| `skills/openspec-apply-change/` | Apply: Claude anuncia handoff al Agente, no escribe código |
| `skills/openspec-propose/` | Propose: lee context.md, escribe decisions/, crea branch |
| `skills/openspec-archive-change/` | Archive: escribe en archive/, actualiza context.md |
| `skills/openspec-verify-change/` | Verify: valida implementación vs specs |
| `skills/openspec-explore/` | Explore: modo de pensamiento; lee context.md del vault (solo lectura) |
| `skills/srs-generate/` | Genera/actualiza `docs/srs.md` con estructura ISO/IEC/IEEE |
| `.claude/commands/opsx/` | Comandos `/opsx:*` (explore, propose, apply, verify, archive): son los que ejecuta Claude Code; se instalan en `~/.claude/commands/opsx/` |
| `skills/issue-creation/` | Issue-first: crea issue antes del propose |
| `skills/branch-pr/` | Valida commits y abre PR con formato correcto |
| `.github/workflows/pr-check.yml` | GitHub Action: valida branch, título, Spec-ID y secrets |
| `CONTRIBUTING.md` | Guía de contribución completa |
| `docs/workflow.md` | Referencia del flujo completo |
| `docs/modo-de-uso.md` | Guía paso a paso para usuarios |

## Setup (una sola vez por máquina)

### 1. Pasos comunes (Claude y herramientas)

```powershell
# 1. Clonar el repo
git clone <url> sdd-global-config
cd sdd-global-config

# 2. Desactivar la telemetría de OpenSpec (máquinas de la empresa no envían datos a terceros)
openspec config set telemetry.enabled false
openspec config get telemetry.enabled   # debe devolver false

# 3. Instalar las reglas globales de Claude
cp .claude\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"

# 4. Copiar todas las skills (incluyendo srs-generate) y los comandos /opsx al global de Claude
#    (los comandos son lo que ejecutan /opsx:*; en Claude Code lo del proyecto pisa a lo global)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands\opsx" | Out-Null
cp -r skills\* "$env:USERPROFILE\.claude\skills\"
cp .claude\commands\opsx\*.md "$env:USERPROFILE\.claude\commands\opsx\"
```

Seguí a continuación **solo el bloque del agente que uses** (Antigravity o Cursor):

### 2a. Si usás Antigravity como Agente

```powershell
# 4. Instalar el contexto global del Agente (fusionar si ya existe con contenido)
cp templates\antigravity\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"

# 5. Instalar la baseline de permisos del CLI del Agente
#    Si ya existe un settings.json NO se sobrescribe: fusionar a mano con la plantilla.
#    Luego completar en settings.json los placeholders (ver templates\antigravity\README.md):
#    {RUTA-DE-TU-USUARIO} y la lista de trustedWorkspaces.
#    La barra de estado NO se copia: se genera con el CLI (prompt en templates\antigravity\README.md,
#    sección "Barra de estado").
$ag = "$env:USERPROFILE\.gemini\antigravity-cli"
New-Item -ItemType Directory -Force $ag | Out-Null
if (-not (Test-Path "$ag\settings.json")) { cp templates\antigravity\settings.json "$ag\settings.json" }
```

### 2b. Si usás Cursor como Agente

Cursor administra los permisos de ejecución de comandos desde la configuración del propio IDE (Settings > Features > Terminal / Auto-run commands).

Configurar una allowlist de ejecución automática con los comandos del workflow:
- `git status`
- `git diff`
- `git branch`
- `git restore`
- `openspec`

> [!WARNING]
> **Advertencia sobre shells:** Agregar `powershell` o `cmd.exe` a la allowlist equivale a permitir que el Agente ejecute cualquier comando sin confirmación. Por seguridad, no incluyas shells en la lista de comandos automáticos.

### 3. Pasos comunes finales (Vault y entorno)

```powershell
# 6. Clonar el vault compartido (memoria persistente del workflow)
git clone https://github.com/lmontecchiani-dev/sdd-vault "C:\TPA"   # o la ruta que prefieras

# 7. Declarar variables de entorno en el perfil de PowerShell ($PROFILE)
# $env:OBSIDIAN_VAULT  = "C:\TPA"                       # la misma ruta donde clonaste el vault
# $env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado este repo
```

Las rutas viven en `$env:OBSIDIAN_VAULT` y `$env:SDD_CONFIG_REPO` — el repo no hardcodea rutas y funciona en cualquier equipo.

El vault contiene la memoria persistente del workflow (`projects/<proyecto>/context.md`, `decisions/`, `archive/`). Además, contiene la carpeta `projects/<proyecto>/apply/`, donde el Agente guarda una copia completa del resumen del apply con su evidencia. La carpeta `projects/*/apply/` está excluida en el `.gitignore` del vault, por lo que nunca se sube a git y el verify solo se corre en la máquina del apply.

**Sincronización continua:** la fuente canónica de las reglas es `~/.claude/CLAUDE.md`. Cada vez que se modifica, Claude re-sincroniza automáticamente el espejo del vault (`$vault\_global\reglas-globales.md`) y la copia versionada de este repo (`.claude/CLAUDE.md`), y commitea — la regla está en la sección `## Capa de Persistencia — Obsidian` del propio CLAUDE.md.

## Sumar un proyecto al workflow

```powershell
# Desde la raíz del proyecto nuevo. Iniciar OpenSpec SOLO con el Agente (elegir según el agente del equipo:
# openspec init --tools antigravity   # si el constructor es Antigravity
# openspec init --tools cursor        # si el constructor es Cursor
# No incluir claude en --tools: con claude, init genera copias locales por
# defecto de los comandos y skills que pisan a las globales de ~/.claude.
openspec init --tools antigravity
# o bien:
# openspec init --tools cursor

# Comprobar la instalación según el agente:
# ls .agents\skills\openspec-apply-change\   # si usás Antigravity (debe mostrar SKILL.md)
# ls .cursor\commands\opsx-apply.md          # si usás Cursor

# Si usás Cursor: copiar la regla del Agente al proyecto
New-Item -ItemType Directory -Force .cursor\rules | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\cursor\sdd-workflow.mdc" .cursor\rules\sdd-workflow.mdc

# Si usás Copilot:
New-Item -ItemType Directory -Force .github | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\copilot\copilot-instructions.md" .github\copilot-instructions.md

# Cualquier otro agente (Codex, Jules, Aider, Zed...) lee AGENTS.md en la raíz
cp "$env:SDD_CONFIG_REPO\templates\comun\AGENTS.md" AGENTS.md
```

Claude (`~/.claude/CLAUDE.md`) y el Agente Antigravity (`~/.gemini/GEMINI.md`) cargan su configuración global en todas las sesiones: no requieren nada por proyecto. Para Cursor, se copia `templates\cursor\sdd-workflow.mdc` a `.cursor\rules\sdd-workflow.mdc` en cada proyecto. Al actualizar un proyecto existente o las reglas globales, hay que volver a copiar las plantillas de reglas en el proyecto (`.cursor/rules/sdd-workflow.mdc`, `.github/copilot-instructions.md`, `AGENTS.md`) y actualizar `GEMINI.md` en cada máquina.

## Flujo resumido

```
Claude   /opsx:propose <nombre>                                                        → artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> (Antigravity) o /opsx-apply <nombre> (Cursor) → implementa en el branch, commitea
Vos      git push + PR                                                                 → título: [nombre] descripción, body: Spec-ID:
Claude   /opsx:verify <nombre>                                                         → valida vs specs sobre la PR
Vos      merge                                                                         → solo con verify aprobado
Claude   /opsx:archive <nombre>                                                        → archiva + exporta a Obsidian (post-merge)
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

