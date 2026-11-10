# Modo de Uso — SDD Híbrido (Claude + Agente)

## Inicio de proyecto

Estos son los pasos exactos a correr en tu terminal, dentro del proyecto:

### Paso 1 — Init (solo con el Agente)

```powershell
cd "{ruta-del-proyecto}"
# Elegir según el agente que use el equipo:
openspec init --tools antigravity
# o bien:
# openspec init --tools cursor
```

Reemplazar `<agente>` por `antigravity` o `cursor` según tu agente constructor.

**No incluir `claude` en `--tools`.** Con `claude`, `openspec init` genera en el proyecto copias por defecto de los comandos `/opsx` y de las skills `openspec-*` (donde Claude escribe código y no usa el vault) que pisan a las globales de `~/.claude`. Sin `claude`, Claude usa las globales, que anuncian el handoff al Agente en vez de escribir código.

### Paso 2 — Completar openspec/config.yaml

Decile a Claude qué hace el proyecto (frontend, backend, fullstack, qué stack usa) y te arma el config completo. Si el proyecto tiene automatización de tests, indicá también el comando en la subsección `## Tests`.

### Paso 3 — Verificar los comandos o skills del Agente

Si usás Antigravity:
```powershell
ls .agents\skills\openspec-apply-change\
```
Debe mostrar `SKILL.md` — ese es el que usa Antigravity para implementar. Nunca borrarlo.

Si usás Cursor:
```powershell
ls .cursor\commands\opsx-apply.md
```
Debe existir `opsx-apply.md` — ese es el comando que ejecuta Cursor para implementar. Nunca borrarlo.

### Paso 4 — Instalar instrucciones del Agente

El Agente no carga la configuración global de Claude — lee las instrucciones del repo donde trabaja. Sincronizar las reglas y el workflow de CI usando `sincronizar-proyecto.ps1`:

```powershell
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes cursor -PrCheck
# Para Copilot: -Agentes copilot
# Para otros agentes (Codex, Jules, Aider, Zed...): -Agentes comun
# O combinaciones: -Agentes cursor,copilot
```

El script conserva cualquier personalización existente que esté ubicada debajo de `## Propio del proyecto`. Si detecta modificaciones fuera de esa sección, frena para evitar sobrescribir cambios no identificados.

### Paso 5 — Verificar el `.gitignore`

Si el proyecto no tiene `.gitignore`, crearlo antes del primer commit. Mínimo obligatorio: `.env`, `*.env`, `*.key`, `*.pem`, `secrets/`.

### Agregar Cursor a un proyecto existente

Si un proyecto ya está iniciado en el workflow con Antigravity y querés comenzar a usar Cursor:

1. **Sumar la herramienta Cursor en OpenSpec:**  
   Ejecutá en la raíz del proyecto:
   ```bash
   openspec init --tools cursor
   ```
   Esto conserva la configuración existente en `openspec/config.yaml` y genera los comandos `/opsx-*` en `.cursor/commands/`.

2. **Sincronizar la regla del workflow:**
   ```powershell
   pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes cursor
   ```

3. **Limpieza opcional:**  
   Si el equipo deja de usar Antigravity por completo en ese proyecto, se pueden eliminar las carpetas `.agents/` (y la anterior `.agent/` si existía). Esta eliminación debe realizarse en un commit separado directamente en la rama principal (`main`/`master`). Si coexisten personas que usan Antigravity y personas que usan Cursor, ambas configuraciones deben conservarse en el repositorio.

### Actualizar OpenSpec en un proyecto existente

Cuando se actualiza la versión global de OpenSpec (`npm install -g @fission-ai/openspec@<version>`), los proyectos existentes pueden actualizar sus artefactos locales:

1. **Ejecutar la actualización:**
   ```bash
   openspec update
   ```
2. **Revisar cambios:**  
   Revisar con `git status` y `git diff` qué archivos cambiaron antes de commitear. Si el proyecto se originó con una versión anterior de OpenSpec (donde Antigravity usaba `.agent/`), `openspec update` creará `.agents/` y conservará `.agent/` si detecta diferencias.
3. **Manejo de `.agent/` legacy:**  
   Comparar `.agent/` con `.agents/`. Una vez confirmado que `.agents/` tiene las skills actualizadas, eliminar la carpeta legacy `.agent/` en un commit aparte directamente en la rama principal (`main`/`master`), nunca dentro de una rama `change/…`.
4. **Commitear la actualización:**  
   Commitear los cambios generados por `openspec update` en un commit dedicado (por ejemplo, `chore: actualizar artefactos de openspec`).
5. **Validación sin `--strict`:**  
   El flujo de trabajo propio utiliza `openspec validate <nombre>` sin la bandera `--strict` (no se recomienda `--strict` debido a advertencias y fallas por longitud de requirements en specs existentes).

### Si el proyecto ya tiene OpenSpec con copias locales de Claude

Si el proyecto se inició con `claude` en `--tools`, tiene copias locales por defecto que pisan a las globales. Eliminarlas:

```powershell
rm .claude\commands\opsx\*.md
rm -r .claude\skills\openspec-*
```

Si esos archivos están versionados, commiteá la eliminación aparte (por ejemplo `chore: usar los comandos globales de OpenSpec`), desde la rama principal y con el árbol limpio: no la hagas dentro de una rama `change/…`, porque mezclaría un commit sin el `Spec-ID` de ese change. `openspec update` no las vuelve a generar mientras no uses `claude` en `--tools`. Borrá solo esas carpetas, no el resto de `.claude\` (por ejemplo `settings.local.json`).

---

## Setup por máquina (una sola vez, no por proyecto)

Detalle completo en el README del repo `sdd-global-config`. Resumen:

### 1. Pasos comunes (Claude y herramientas)

```powershell
# Desactivar la telemetría de OpenSpec (máquinas de la empresa no envían datos a terceros)
openspec config set telemetry.enabled false
openspec config get telemetry.enabled   # debe devolver false

# Reglas globales de Claude, skills, comandos /opsx, GEMINI.md y espejo del vault (desde el repo clonado)
pwsh scripts\instalar.ps1 -Simular
pwsh scripts\instalar.ps1
```

Seguí a continuación **solo el bloque del agente que uses** (Antigravity o Cursor):

### 2a. Si usás Antigravity como Agente

`templates\antigravity\GEMINI.md` se instala automáticamente en `~/.gemini/GEMINI.md` con `scripts\instalar.ps1` si la carpeta `~/.gemini` existe en la máquina.

```powershell
# Baseline de permisos del Agente (no sobrescribir un settings.json existente: fusionar a mano)
$ag = "$env:USERPROFILE\.gemini\antigravity-cli"
New-Item -ItemType Directory -Force $ag | Out-Null
if (-not (Test-Path "$ag\settings.json")) { cp templates\antigravity\settings.json "$ag\settings.json" }
# Completar en settings.json: {RUTA-DE-TU-USUARIO} y los trustedWorkspaces (ver templates\antigravity\README.md)
# La barra de estado no se copia: se genera con el CLI del Agente (prompt en templates\antigravity\README.md, sección "Barra de estado")
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
# Variables de entorno en $PROFILE
$env:OBSIDIAN_VAULT  = "<ruta-de-tu-vault>"           # ruta real del vault en esta máquina
$env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"  # dónde quedó clonado el repo
```

Claude y el Agente Antigravity cargan su configuración global en todos los proyectos; para Cursor, se copia `templates\cursor\sdd-workflow.mdc` a `.cursor\rules\sdd-workflow.mdc` en cada proyecto.

---

## Flujo por change

```
Claude   /issue-creation                                                               → crea issue, espera status:approved
Claude   /opsx:propose <nombre>                                                        → lee Obsidian, crea artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> (Antigravity) o /opsx-apply <nombre> (Cursor) → implementa en el branch, commitea con Spec-ID:
Claude   /branch-pr <nombre>                                                           → valida commits, abre PR desde Obsidian decisions/
Claude   /opsx:verify <nombre>                                                         → valida vs specs, actualiza Obsidian context.md
Vos      merge                                                                         → solo con verify aprobado
Claude   /opsx:archive <nombre>                                                        → archiva + escribe Obsidian archive/ (post-merge)
```

**1. Crear issue** (`/issue-creation`)

Antes de cualquier cambio, creás un issue con el template. Queda en `status:needs-review`. Un maintainer debe aprobar (`status:approved`) antes de continuar.

**2. Claude propone** (`/opsx:propose`)

Lee `context.md` del vault para recuperar contexto previo. Luego crea los artefactos en `openspec/changes/nombre-del-change/`:
- `proposal.md` — qué se hace y por qué
- `design.md` — cómo se hace, con sección `## Security Layer` y `## Test Plan` por escenario
- `specs/*.md` — contratos técnicos detallados
- `tasks.md` — lista de tareas con archivos exactos a tocar, con las de tests primero (caracterización antes de tocar código viejo, luego escenarios)

Al finalizar: escribe `decisions/YYYY-MM-DD-nombre.md` en Obsidian, actualiza `context.md` y crea el branch `change/nombre-del-change`.

**3. El Agente implementa**

En Antigravity:
```
/openspec-apply-change nombre-del-change
```

En Cursor:
```
/opsx-apply nombre-del-change
```

El Agente implementa en el branch. Escribe y corre en verde los tests de caracterización primero. Marca las tareas `[x]` (solo si el test de la tarea pasa) y commitea con formato:
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

Lee `tasks.md`, `git diff` y specs. Ejecuta los tests del plan. Corre la suite completa en la rama principal y compara si se modificó código existente (regresiones). Verifica que el código de test concuerde con la spec. Actualiza `context.md` con el resultado. Merge solo si no hay desvíos.

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
- El Agente nunca planifica — solo ejecuta lo que dicen los artefactos
- Cada change vive en su propio branch `change/{nombre}` y tiene PR
- Merge a main solo con verify aprobado
- Cada change queda trazado en git (`Spec-ID:`) y en Obsidian (`decisions/` → `archive/`)

---

## Cambios chicos: ODD (Organic Driven Development)

Para cambios chicos y acotados que no tocan specs, datos, seguridad ni contratos, el workflow ofrece un camino liviano basado en un único documento (`docs/odd/<nombre>.md`), sin generar proposal, design, specs ni tasks completas.

### Criterios de clasificación

Antes de iniciar cualquier cambio, Claude evalúa si el pedido debe ir por SDD o puede ir por ODD. Si se cumple **al menos uno** de los siguientes criterios, el cambio va obligatoriamente por **SDD**:

| ID | Criterio | ¿Pasable a ODD? |
|---|---|---|
| K1 | Agrega o quita comportamiento de una spec vigente, crea capability nueva, o modifica más de una capability (modificar requirements existentes de una sola capability va por ODD con cambio mínimo de spec) | **no** |
| K2 | Cambia cómo se procesan datos externos o personales (`## Datos`); usarlos igual que antes no cuenta | **no** |
| K3 | Toca autenticación, permisos, secretos o controles de seguridad | **no** |
| K4 | Agrega, quita o actualiza dependencias | sí |
| K5 | Cambia contratos externos (APIs, schemas, formatos de archivo o flags de CLI) | sí |
| K6 | Cambia nivel de arquitectura o mueve código entre capas | sí |
| K7 | Modifica más de 5 archivos (sin contar tests ni documentación) | sí |
| K8 | El "qué" no está claro (requiere elegir entre alternativas de diseño) | sí |
| K9 | El usuario solicita SDD | — |
| K10 | Cumple criterio de ADR (stack, arquitectura, integración, patrón transversal, calidad) | **no** |

Si no se cumple ninguno, va por **ODD** (typos, textos, estilos, refactors cubiertos por tests, corrección de bugs contra specs vigentes donde la spec no cambia, o modificación de requirements de una sola capability). Si el ODD modifica requirements de una sola capability, Claude incluye un change mínimo en `openspec/changes/odd-<nombre>/` que `/odd:verify` valida y archiva en la misma rama antes del merge. Ante la duda, se clasifica como SDD.

### Comandos del flujo ODD

1. **`/odd <nombre>` (Inicio):** Claude valida la clasificación, lee la visión de arquitectura si existe, redacta el documento único en `docs/odd/<nombre>.md`, pide confirmación al usuario, crea la rama `odd/<nombre>`, actualiza `context.md` en el vault y anuncia el handoff al Agente.
2. **Implementación:** El Agente lee `docs/odd/<nombre>.md`, implementa en la rama `odd/<nombre>`, completa la evidencia en `## Evidencia` del documento y commitea con `Spec-ID: odd-<nombre>`. No escribe la nota `apply\` del vault. Se abre la PR con `/branch-pr`.
3. **`/odd:verify <nombre>` (Verificación):** Claude valida checklist con evidencia, criterios de aceptación, alcance del diff, re-clasifica criterios K1-K10 sobre el diff real, corre los tests si están declarados, y evalúa la puerta de integración (dato inesperado en `no aplica (ODD)`). Deja el documento en `estado: verificado`.
4. **`/odd:close <nombre>` (Cierre):** Se ejecuta **después del merge**. Controla que la rama esté mergeada, crea la nota en `archive\AAAA-MM-DD-odd-<nombre>.md` del vault, actualiza `_index.md`, reescribe `arquitectura.md` si el ODD modificó la visión y actualiza `context.md`. No crea commits en el repo del proyecto (el cierre vive en el vault).

### Escalado a SDD

Si durante la implementación o en `/odd:verify` se detecta que el cambio requiere dependencias, toca más archivos de los permitidos o activa cualquier criterio SDD:
- Claude pasa el documento a `estado: escalado` y anota el criterio y motivo en `## Progreso`.
- La rama `odd/<nombre>` no se mergea.
- Claude ofrece iniciar `/opsx:propose <nombre>` utilizando el documento ODD como base.

### Requisito en proyectos existentes

Para que un proyecto existente pueda utilizar el flujo ODD, es necesario sincronizarlo con:
```powershell
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes <agente> -PrCheck
```
Esto actualiza las reglas del Agente incorporando la sección `## Handoff ODD` y actualiza `pr-check.yml` para que el CI admita ramas `odd/*`.

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

## Arquitectura de software

Claude actúa además como arquitecto de software del sistema, sumando cuatro responsabilidades al flujo sin modificar ninguna regla vigente:

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

Claude no escribe los documentos de arquitectura del repositorio (ADRs y visión): los escribe el Agente: las decisiones se plasman en el `design.md`, el usuario las aprueba con el change y el Agente las implementa.

---

## Capa de Persistencia — Obsidian

El vault en `$env:OBSIDIAN_VAULT` actúa como memoria persistente del proyecto — equivalente a Engram pero sobre el filesystem local. Claude lee y escribe automáticamente en cada operación OPSX, sin MCP ni plugins.

### Estructura del vault

```
$env:OBSIDIAN_VAULT\
  _global\
    reglas-globales.md              ← espejo del CLAUDE.md global (lo lee el Agente)
  projects\
    {nombre-proyecto}\
      _index.md                     ← índice con links a todos los changes
      context.md                    ← estado actual del proyecto (actualizado continuamente)
      arquitectura.md               ← resumen de arquitectura (nivel, calidad, ADRs, deuda)
      apply\                        ← resúmenes del apply del Agente (local, no versionada por git)
        AAAA-MM-DD-{change}.md
      decisions\
        YYYY-MM-DD-{change}.md      ← creada al propose
      archive\
        YYYY-MM-DD-{change}.md      ← creada al archive
```

### Cuándo actúa Claude

| Comando | Lee | Escribe |
|---|---|---|
| Inicio de sesión | `context.md` + `arquitectura.md` (si existe) + últimas 3 notas de `archive\` | — |
| `/issue-creation` | — | actualiza `context.md` con issue creado |
| `/opsx:explore` | `context.md` + `arquitectura.md` (si existe) | — |
| `/opsx:propose` | `context.md` + `arquitectura.md` (si existe) | `decisions\YYYY-MM-DD-{change}.md` + actualiza `context.md` |
| `/opsx:apply` | `decisions\{change}.md` | actualiza `context.md` con progreso (el Agente escribe `apply\AAAA-MM-DD-{change}.md`) |
| `/branch-pr` | `decisions\{change}.md` | actualiza `context.md` con PR abierta |
| `/opsx:verify` | `apply\AAAA-MM-DD-{change}.md` | actualiza `context.md` con resultado |
| `/opsx:archive` | — | `archive\YYYY-MM-DD-{change}.md` + reescribe `arquitectura.md` + actualiza `context.md` |

### Vault compartido via GitHub

El vault es un repo git privado (`sdd-vault`) — la memoria del workflow viaja entre máquinas y programadores:

- Claude hace `git pull --rebase` al iniciar sesión y commit+push tras cada operación que escribe en el vault.
- Si dos personas trabajan el mismo proyecto en paralelo, coordinar: `context.md` se reescribe en cada operación.
- `projects/*/apply/` está en el `.gitignore` del vault: las copias de los resúmenes del apply nunca se suben a git para evitar filtrar datos personales o credenciales fuera de la máquina. Por esta razón, `/opsx:verify` solo se corre en la máquina del apply.
- Al actualizar un proyecto existente o incorporar cambios a las reglas globales, hay que volver a copiar las plantillas de reglas (`.cursor/rules/sdd-workflow.mdc`, `.github/copilot-instructions.md`, `AGENTS.md`) y actualizar `GEMINI.md` en cada máquina.

### Portabilidad entre máquinas

En cada máquina nueva:

```powershell
git clone <url-de-tu-vault> "<ruta-de-tu-vault>"   # o la ruta que prefieras

# Agregar a $PROFILE
$env:OBSIDIAN_VAULT = "<ruta-de-tu-vault>"   # la misma ruta del clone
```

El repo no hardcodea rutas — funciona en cualquier equipo.
