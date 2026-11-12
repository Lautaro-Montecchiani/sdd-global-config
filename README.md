# SDD Global Config

Repositorio de configuración global del workflow SDD Híbrido — Claude (arquitecto) + Agente (constructor).

## Qué contiene

| Archivo / Carpeta | Propósito |
|---|---|
| `.claude/CLAUDE.md` | Reglas globales de Claude — copia versionada, se instala en `~/.claude/CLAUDE.md` |
| `scripts/` | Scripts de PowerShell 7 para generar plantillas (`generar-plantillas.ps1`), instalar en la máquina (`instalar.ps1`) y sincronizar proyectos (`sincronizar-proyecto.ps1`) |
| `templates/` | Plantillas de instrucciones y configuración por agente (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md` y `templates/cursor/sdd-workflow.mdc` por proyecto; `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json` por máquina) |
| `templates/fuente/` | Fuente única de las reglas del Agente (fragmentos compartidos y esqueletos por plantilla) |
| `tests/` | Tests automáticos de los scripts (ejecutados con PowerShell 7) |
| `skills/openspec-apply-change/` | Apply: Claude anuncia handoff al Agente, no escribe código |
| `skills/openspec-propose/` | Propose: lee context.md, escribe decisions/, crea branch |
| `skills/openspec-archive-change/` | Archive: escribe en archive/, actualiza context.md |
| `skills/openspec-verify-change/` | Verify: valida implementación vs specs |
| `skills/openspec-explore/` | Explore: modo de pensamiento; lee context.md del vault (solo lectura) |
| `skills/odd-change/` | Flujo ODD: inicio (`/odd`), verify (`/odd:verify`) y cierre en el vault (`/odd:close`) |
| `skills/srs-generate/` | Genera/actualiza `docs/srs.md` con estructura ISO/IEC/IEEE |
| `.claude/commands/opsx/` | Comandos `/opsx:*` (explore, propose, apply, verify, archive): se ejecutan en Claude Code y se instalan en `~/.claude/commands/opsx/`; se generan desde las skills con `pwsh scripts/generar-plantillas.ps1` y no se editan a mano |
| `.claude/commands/odd/` | Comandos `/odd:*` (`start`, `verify`, `close` y `odd.md` para `/odd` directo); se instalan en `~/.claude/commands/`; se generan desde las skills con `pwsh scripts/generar-plantillas.ps1` y no se editan a mano |
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

# 3. Instalar reglas globales de Claude, skills, comandos, GEMINI.md y espejo del vault
#    (usar -Simular primero para ver lo que haría sin escribir nada)
pwsh scripts\instalar.ps1 -Simular
pwsh scripts\instalar.ps1
```

Java 11+ es opcional y solo hace falta para que `srs-generate` renderice los diagramas de caso de uso a SVG. Sin Java, el SRS sale en "borrador" con links a los `.puml`.

Seguí a continuación **solo el bloque del agente que uses** (Antigravity o Cursor):

### 2a. Si usás Antigravity como Agente

`templates\antigravity\GEMINI.md` se instala automáticamente en `~/.gemini/GEMINI.md` con `scripts\instalar.ps1` si la carpeta `~/.gemini` existe en la máquina.

```powershell
# Instalar la baseline de permisos del CLI del Agente
# Si ya existe un settings.json NO se sobrescribe: fusionar a mano con la plantilla.
# Luego completar en settings.json los placeholders (ver templates\antigravity\README.md):
# {RUTA-DE-TU-USUARIO} y la lista de trustedWorkspaces.
# La barra de estado NO se copia: se genera con el CLI (prompt en templates\antigravity\README.md,
# sección "Barra de estado").
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
# 6. Clonar tu vault de Obsidian (memoria persistente del workflow), o crear uno nuevo si no existe
git clone <url-de-tu-vault> "<ruta-de-tu-vault>"   # o New-Item + git init si es nuevo

# 7. Declarar variables de entorno en el perfil de PowerShell ($PROFILE)
# $env:OBSIDIAN_VAULT  = "<ruta-de-tu-vault>"           # la misma ruta donde clonaste o creaste el vault
# $env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado este repo
```

Las rutas viven en `$env:OBSIDIAN_VAULT` y `$env:SDD_CONFIG_REPO` — el repo no hardcodea rutas y funciona en cualquier equipo.

El vault contiene la memoria persistente del workflow (`projects/<proyecto>/context.md`, `decisions/`, `archive/`). Además, contiene la carpeta `projects/<proyecto>/apply/`, donde el Agente guarda una copia completa del resumen del apply con su evidencia. La carpeta `projects/*/apply/` está excluida en el `.gitignore` del vault, por lo que nunca se sube a git y el verify solo se corre en la máquina del apply.

**Sincronización continua:** la fuente de las reglas es `.claude/CLAUDE.md` de este repo. Todo cambio de reglas pasa por un change, su PR y el CI. Después del merge se corre `pwsh scripts/instalar.ps1` en cada máquina, que actualiza el espejo del vault (`$vault\_global\reglas-globales.md`) y `~/.claude/CLAUDE.md`.

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

# Sincronizar las reglas del Agente y el workflow de CI en el proyecto:
# -Agentes acepta: cursor, copilot, comun (o combinaciones separadas por coma).
# -PrCheck copia pr-check.yml a .github/workflows/ si no existe.
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes cursor -PrCheck
```

Claude (`~/.claude/CLAUDE.md`) y el Agente Antigravity (`~/.gemini/GEMINI.md`) cargan su configuración global en todas las sesiones: no requieren nada por proyecto. Para Cursor, Copilot u otros agentes, se sincronizan las plantillas correspondientes (`.cursor/rules/sdd-workflow.mdc`, `.github/copilot-instructions.md`, `AGENTS.md`) con `scripts\sincronizar-proyecto.ps1`. Al actualizar un proyecto existente o las reglas globales, correr `scripts\sincronizar-proyecto.ps1 -Proyecto <ruta> -Agentes <agentes>` para sincronizar los archivos conservando lo que el proyecto haya agregado debajo de `## Propio del proyecto`, y actualizar `GEMINI.md` en cada máquina corriendo `scripts\instalar.ps1`. Para que un proyecto existente pueda usar el flujo ODD, es necesario correr `scripts\sincronizar-proyecto.ps1` en el proyecto para incorporar la sección `## Handoff ODD` en las reglas del Agente y actualizar `pr-check.yml` para aceptar branches `odd/*`. Cada proyecto declara `## Arquitectura` en su `context:` de `openspec/config.yaml`, y la estructura sugerida está en el `CLAUDE.md` global. La arquitectura se clasifica con una escalera de niveles progresivos (0 a 3); la skill `/arquitectura` permite diagnosticar un proyecto existente y recomendar un nivel, complementada por la guía de estudio en `docs/guia-arquitecturas.md`. Cada proyecto puede declarar además su ficha (alcance de la versión, datos y stack) en el `context:`; la skill `/ficha` permite completarla guiando al usuario sin reescribir lo existente. En cada change, `/opsx:verify` evalúa la puerta de integración con tres preguntas antes del merge: dato inesperado (manejo de datos externos inválidos), seguridad (controles cumplidos, sin credenciales ni escaneos fallidos) y explicabilidad (código comprendido por el usuario).

## Plantillas del Agente

Las reglas del Agente para las distintas herramientas (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`) no se editan directamente: se generan desde una fuente única en `templates/fuente/`.

- `templates/fuente/fragmentos/`: fragmentos de texto compartidos (`aviso-vault.md`, `rol-constructor.md`, `reglas-ejecucion.md`, `git.md`, `memoria-proyecto.md`).
- `templates/fuente/esqueletos/`: estructura de cada plantilla con directivas `<!-- incluir: fragmento.md -->`.

Para regenerar las plantillas luego de modificar un fragmento o esqueleto:

```powershell
pwsh scripts\generar-plantillas.ps1
```

El script también genera el bloque de reglas de `.claude/CLAUDE.md` desde `templates/fuente/fragmentos/reglas-ejecucion.md` y valida que cada plantilla contenga la cabecera generada y la sección `## Propio del proyecto`. En CI, el flag `-Comprobar` controla que el texto del bloque de reglas de `.claude/CLAUDE.md` sea igual al fragmento y falla si alguna plantilla o comando está desincronizado o fue modificado a mano sin regenerar:

```powershell
pwsh scripts\generar-plantillas.ps1 -Comprobar
```

## Arquitectura de software

Claude actúa además como arquitecto de software del sistema, sumando cuatro responsabilidades sin modificar ninguna regla vigente:

1. **ADRs del proyecto (`docs/adr/`):** registro de decisiones de arquitectura que duran más que un change (elección o cambio de stack, nivel de arquitectura, integración externa, patrones transversales o compromisos entre atributos de calidad).
2. **Atributos de calidad (`## Calidad`):** definición de objetivos y prioridades (`rendimiento`, `disponibilidad`, `escalabilidad`, `costo`, `mantenibilidad`) en la ficha del proyecto, evaluados en cada change con verificación explícita.
3. **Visión y hoja de ruta (`docs/arquitectura/vision.md`):** documento vivo con propósito, contexto e integraciones, componentes, decisiones vigentes y hoja de ruta de deuda técnica priorizada.
4. **Revisión de impacto (`## Impacto en el sistema`):** sección en cada `design.md` que analiza componentes fuera del change, atributos de calidad, decisiones de arquitectura y deuda técnica.

### Documentos y responsabilidades

| Documento | Ubicación | Quién lo escribe |
|---|---|---|
| ADRs | `docs/adr/NNNN-<slug>.md` (en el repo) | El Agente, a partir de la sección `## ADR` del `design.md` mediante tareas en `tasks.md` |
| Visión y hoja de ruta | `docs/arquitectura/vision.md` (en el repo) | El Agente, a partir de `## Visión inicial` o actualizaciones en el `design.md` mediante tareas |
| Resumen de arquitectura | `$vault\projects\<proyecto>\arquitectura.md` (en el vault) | Claude, al archivar (`/opsx:archive`), sintetizando nivel, calidad, ADRs y deuda técnica |

Claude no escribe los documentos de arquitectura del repositorio (ADRs y visión): los escribe el Agente; el usuario aprueba toda decisión al aprobar el change.

## Flujo resumido

Todo pedido se clasifica antes de empezar: si agrega o quita comportamiento de specs, toca datos, seguridad, contratos o dependencias va por **SDD**; para cambios chicos, acotados o que modifican requirements de una sola capability va por **ODD** (con change mínimo de spec en `openspec/changes/odd-<nombre>/` si aplica).

### Flujo SDD (cambios con specs)

```
Claude   /opsx:propose <nombre>                                                        → artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> (Antigravity) o /opsx-apply <nombre> (Cursor) → implementa en el branch, commitea
Vos      git push + PR                                                                 → título: [nombre] descripción, body: Spec-ID:
Claude   /opsx:verify <nombre>                                                         → valida vs specs sobre la PR
Claude   /opsx:archive <nombre>                                                        → en la rama, antes del merge: specs + SRS
Vos      merge                                                                         → solo con verify aprobado y archive en la rama
Claude   /opsx:archive <nombre>                                                        → cierre en el vault después del merge
```

### Flujo ODD (cambios chicos)

```
Claude   /odd <nombre>                                                                 → documento único docs/odd/<nombre>.md + branch odd/<nombre>
Agente   implementa en branch odd/<nombre>                                             → completa evidencia en el documento, commitea
Vos      git push + PR (/branch-pr)                                                    → título: [nombre] descripción, body: Spec-ID: odd-<nombre>
Claude   /odd:verify <nombre>                                                          → verify liviano sobre la PR (deja verificado)
Vos      merge                                                                         → solo con verify aprobado
Claude   /odd:close <nombre>                                                           → registra nota en Obsidian (post-merge; no toca el repo)
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

