# SDD Global Config

Repositorio de configuración global del workflow SDD Híbrido — Claude (arquitecto) + Copilot (constructor).

## Qué contiene

| Archivo / Carpeta | Propósito |
|---|---|
| `.claude/CLAUDE.md` | Reglas globales de Claude — copia versionada, se instala en `~/.claude/CLAUDE.md` |
| `templates/` | Plantillas para Copilot (`.github/copilot-instructions.md` por proyecto) y Gemini (`~/.gemini/GEMINI.md` por máquina) |
| `skills/openspec-apply-change/` | Apply: Claude anuncia handoff a Copilot, no escribe código |
| `skills/openspec-propose/` | Propose: lee context.md, escribe decisions/, crea branch |
| `skills/openspec-archive-change/` | Archive: escribe en archive/, actualiza context.md |
| `skills/openspec-verify-change/` | Verify: valida implementación vs specs |
| `skills/issue-creation/` | Issue-first: crea issue antes del propose |
| `skills/branch-pr/` | Valida commits y abre PR con formato correcto |
| `.github/workflows/pr-check.yml` | GitHub Action: valida branch, título, Spec-ID y secrets |
| `CONTRIBUTING.md` | Guía de contribución completa |
| `WORKFLOW.md` | Referencia del flujo completo |
| `Modo de Uso/Modo de uso.md` | Guía paso a paso para usuarios |

## Setup (una sola vez por máquina)

```powershell
# 1. Clonar el repo
git clone <url> sdd-global-config
cd sdd-global-config

# 2. Instalar las reglas globales de Claude
cp .claude\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"

# 3. Copiar todos los skills al global de Claude
cp skills\openspec-apply-change\SKILL.md   "$env:USERPROFILE\.claude\skills\openspec-apply-change\SKILL.md"
cp skills\openspec-archive-change\SKILL.md "$env:USERPROFILE\.claude\skills\openspec-archive-change\SKILL.md"
cp skills\openspec-propose\SKILL.md        "$env:USERPROFILE\.claude\skills\openspec-propose\SKILL.md"
cp skills\issue-creation\SKILL.md          "$env:USERPROFILE\.claude\skills\issue-creation\SKILL.md"
cp skills\branch-pr\SKILL.md               "$env:USERPROFILE\.claude\skills\branch-pr\SKILL.md"
cp -r skills\openspec-verify-change        "$env:USERPROFILE\.claude\skills\"

# 4. Instalar el contexto global de Gemini (fusionar si ya existe con contenido)
cp templates\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"

# 5. Clonar el vault compartido (memoria persistente del workflow)
git clone https://github.com/lmontecchiani-dev/sdd-vault "C:\TPA"   # o la ruta que prefieras

# 6. Declarar variables de entorno en el perfil de PowerShell ($PROFILE)
# $env:OBSIDIAN_VAULT  = "C:\TPA"                       # la misma ruta donde clonaste el vault
# $env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado este repo
```

Las rutas viven en `$env:OBSIDIAN_VAULT` y `$env:SDD_CONFIG_REPO` — el repo no hardcodea rutas y funciona en cualquier equipo.

**Sincronización continua:** la fuente canónica de las reglas es `~/.claude/CLAUDE.md`. Cada vez que se modifica, Claude re-sincroniza automáticamente el espejo del vault (`$vault\_global\reglas-globales.md`) y la copia versionada de este repo (`.claude/CLAUDE.md`), y commitea — la regla está en la sección `## Capa de Persistencia — Obsidian` del propio CLAUDE.md.

## Sumar un proyecto al workflow

```powershell
# Desde la raíz del proyecto nuevo — Copilot lee este archivo en cada sesión de ese repo
New-Item -ItemType Directory -Force .github | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\copilot-instructions.md" .github\copilot-instructions.md
```

Claude y Gemini no requieren nada por proyecto: cargan su configuración global (`~/.claude/CLAUDE.md` y `~/.gemini/GEMINI.md`) en todas las sesiones.

## Flujo resumido

```
Claude   /opsx:propose <nombre>          → artefactos + branch change/{nombre}
Copilot  /openspec-apply-change <nombre> → implementa en el branch, commitea
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

Ver `WORKFLOW.md` y `Modo de Uso/Modo de uso.md` para el detalle completo.
