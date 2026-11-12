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
# 1. Instalar reglas globales de Claude, skills, comandos, GEMINI.md y espejo del vault
#    (usar -Simular primero para ver lo que haría sin escribir nada)
pwsh scripts\instalar.ps1 -Simular
pwsh scripts\instalar.ps1

# 2. Declarar ruta del vault de Obsidian en el perfil de PowerShell
# Editar $PROFILE y agregar:
# $env:OBSIDIAN_VAULT = "<ruta-de-tu-vault>"   # ej. D:\vault-sdd
# $env:SDD_CONFIG_REPO = "C:\ruta\a\sdd-global-config"

# 3. Agregar verify al perfil global de OpenSpec
# Editar $env:APPDATA\openspec\config.json
# "workflows": ["propose", "explore", "apply", "verify", "archive"]
```

Las skills y los comandos viven en este repo, en `skills/` y en `.claude/commands/opsx/`:
- `skills/openspec-apply-change/SKILL.md` — apply modificado: Claude anuncia handoff, no escribe código
- `skills/openspec-verify-change/SKILL.md` — verify: valida implementación vs specs
- `skills/openspec-explore/SKILL.md` — explore: lee context.md del vault (solo lectura)
- `skills/srs-generate/SKILL.md` — srs-generate: invocación manual on-demand para generar `docs/srs.md` con estructura fija, entrevista la primera vez y oferta opcional al final de `/opsx:archive`
- `.claude/commands/opsx/*.md` — comandos `/opsx:*` generados desde las skills con `pwsh scripts/generar-plantillas.ps1` (no se editan a mano)

---

## Onboarding: proyecto nuevo

```powershell
# 1. Crear repo
mkdir mi-proyecto; cd mi-proyecto; git init

# 2. Inicializar OpenSpec SOLO con el Agente (elegir según el agente del equipo: antigravity o cursor)
# No incluir claude en --tools: con claude, init genera copias locales por defecto de los comandos
# /opsx y de las skills openspec-* que pisan a las globales de ~/.claude (el workflow híbrido).
# Sin claude, Claude usa los comandos y skills globales.
openspec init --tools antigravity
# o bien:
# openspec init --tools cursor

# 3. Sincronizar las reglas del Agente y el workflow de CI en el proyecto
# (elegir según el agente: cursor, copilot o comun)
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes cursor -PrCheck

# 4. Agregar verify al perfil global de OpenSpec (si no está)
# Editar $env:APPDATA\openspec\config.json
# y asegurarse que "workflows" incluya "verify"

# 5. Completar openspec/config.yaml con project_type, stack, ## Tests y ## Arquitectura
```

En `openspec/config.yaml` declarar:

```yaml
schema: spec-driven

context: |
  project_type: frontend | backend-api | etl | fullstack
  Stack: [describir tecnologías]
  Dominio: [describir el negocio]
  Convenciones: [nombrar archivos, variables, etc.]
  
  ## Tests
  - comando: [comando para correr tests o "ninguno"]
  - timeout: 5

  ## Arquitectura
  - src/app/: rutas y páginas; compone frontend y backend
  - src/backend/: DB, servicios y secretos
  - src/frontend/: componentes y vistas | no importa: src/backend/
  - tests/: espejo de src/

rules:
  proposal:
    - Incluir sección "Non-goals"
  tasks:
    - Referenciar ruta exacta del archivo a modificar
  design:
    - Incluir sección "## Security Layer"
```

---

Cada proyecto declara `## Arquitectura` en su `context:`, y la estructura sugerida para cada tipo de proyecto está en el `CLAUDE.md` global. La arquitectura se clasifica con una escalera de niveles progresivos (0 a 3); la skill `/arquitectura` permite diagnosticar un proyecto existente y recomendar un nivel, complementada por la guía de estudio en `docs/guia-arquitecturas.md`. Cada proyecto puede declarar además su ficha (alcance de la versión, datos y stack) en el `context:`; la skill `/ficha` permite completarla guiando al usuario sin reescribir lo existente.

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

## Onboarding: proyecto existente sin OpenSpec

```powershell
# 1. Inicializar OpenSpec SOLO con el Agente (elegir según el agente: antigravity o cursor)
#    Sin claude en --tools: Claude usa los comandos y skills globales de ~/.claude
cd mi-proyecto
openspec init --tools antigravity
# o bien:
# openspec init --tools cursor

# 2. Sincronizar las reglas del Agente y el workflow de CI en el proyecto
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes cursor -PrCheck

# 3. Completar openspec/config.yaml con project_type, stack real y ## Tests
```

---

## Onboarding: proyecto existente con OpenSpec

```powershell
# 1. Eliminar las copias locales de Claude: son las versiones por defecto y pisan a las globales
#    (Claude implementaría código en /opsx:apply y no usaría el vault)
rm .claude\commands\opsx\*.md
rm -r .claude\skills\openspec-*

# 2. Completar openspec/config.yaml con project_type, stack real y ## Tests
```

Antes de borrar, si sospechás que el proyecto personalizó esas copias, compará con la versión estándar (`git diff`). Si los archivos están versionados, commiteá la eliminación aparte (por ejemplo `chore: usar los comandos globales de OpenSpec`), desde la rama principal y con el árbol limpio: no la hagas dentro de una rama `change/…`, porque mezclaría un commit sin el `Spec-ID` de ese change. `openspec update` no las vuelve a generar mientras el proyecto no use `claude` en `--tools`. Borrá solo `.claude\commands\opsx\` y las skills `openspec-*`, no el resto de `.claude\` (por ejemplo `settings.local.json`).

---

## Agregar Cursor a un proyecto existente

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

---

## Actualizar OpenSpec en un proyecto existente

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

---

## Nota importante

**Nunca eliminar** `.agents\skills\openspec-apply-change\SKILL.md` (si usás Antigravity) ni `.cursor\commands\opsx-apply.md` (si usás Cursor) — el Agente lo necesita para implementar.

**Nunca incluir `claude` en `--tools`** al iniciar un proyecto: `openspec init --tools claude,…` recrea las copias locales de Claude que pisan a las globales.

---

## Flujo por change

```
Claude   /opsx:propose <nombre>                                                        → crea artefactos + branch change/{nombre}
Agente   /openspec-apply-change <nombre> (Antigravity) o /opsx-apply <nombre> (Cursor) → implementa en el branch, marca [x], commitea
Vos      git push + PR                                                                 → abre PR con Spec-ID: {nombre} en el título
Claude   /opsx:verify <nombre>                                                         → valida implementación vs specs sobre la PR
Claude   /opsx:archive <nombre>                                                        → archiva en la rama, antes del merge (specs y SRS)
Vos      merge                                                                         → merge a main solo con verify aprobado y archive en la rama
Claude   /opsx:archive <nombre>                                                        → cierre en el vault después del merge
```

### Descripción de cada paso

**1. Vos pedís una feature o fix**

> "Quiero agregar validación al formulario de licitación"

**2. Claude propone** (`/opsx:propose`)

Lee `context.md` del vault para cargar contexto previo del proyecto. Luego crea los artefactos en `openspec/changes/nombre-del-change/`:
- `proposal.md` — qué se hace y por qué
- `design.md` — cómo se hace, con sección `## Security Layer` según el tipo de proyecto y `## Test Plan` por escenario
- `specs/*.md` — contratos técnicos detallados
- `tasks.md` — lista de tareas con archivos exactos a tocar, ordenando las tareas de tests primero (caracterización antes de modificar código existente, luego escenarios)

Al finalizar: escribe `decisions/YYYY-MM-DD-nombre.md` en el vault, actualiza `context.md` y crea el branch:
```powershell
git checkout -b change/nombre-del-change
```

**3. Vos abrís el Agente y ejecutás**

En Antigravity:
```
/openspec-apply-change nombre-del-change
```

En Cursor:
```
/opsx-apply nombre-del-change
```

El Agente implementa en el branch `change/nombre-del-change`, escribe y corre en verde los tests de caracterización antes de modificar el código existente, marca las tareas `[x]` (solo si el test pasa) y commitea con el formato:
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

Lee el `tasks.md`, el `git diff` y los specs. Ejecuta los tests del plan. Si el change modifica código existente, determina con el diff si debe correr la suite completa en la rama principal y compararla (regresiones). También verifica que el contenido de los tests concuerde con los escenarios. Si es un change antiguo sin Test Plan, usa el método de inferencia. Además, evalúa la puerta de integración con tres preguntas antes del merge: ¿qué pasa si llega un dato inesperado?, ¿hay algo que comprometa la seguridad? y ¿podrías explicar este código a otra persona? El merge solo se hace si verify no reporta desvíos y la puerta de integración está en sí.

**6. Claude archiva en la rama, merge y cierre en el vault** (`/opsx:archive`)

Con verify aprobado, Claude archiva en la rama del change antes del merge: mueve el change a `openspec/changes/archive/`, sincroniza specs, commitea y ofrece el SRS. Luego se mergea a `main`. Tras el merge, Claude cierra en el vault: exporta la nota a Obsidian y actualiza context.md.

---

### Lo que cambia respecto a antes

- Nada se implementa sin spec previa
- Claude nunca escribe código — solo artefactos
- El Agente nunca planifica — solo ejecuta lo que dicen los artefactos
- Cada change queda trazado en git con `Spec-ID: nombre-del-change`

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

1. **`/odd <nombre>` (Inicio):** Claude valida la clasificación, lee la visión de arquitectura si existe, redacta el documento único en `docs/odd/<nombre>.md`, pide confirmación al usuario, crea la rama `odd/<nombre>`, actualiza `context.md` en el vault y anuncia el handoff al Agente ("Ejecutá en el Agente: `/odd-apply <nombre>`").
2. **Implementación (`/odd-apply <nombre>`):** El Agente ejecuta `/odd-apply <nombre>`, valida el arranque, implementa en la rama `odd/<nombre>`, completa la evidencia en `## Evidencia` del documento, commitea con `Spec-ID: odd-<nombre>` y deja `estado: listo-para-verify`. No escribe la nota `apply\` del vault. Se abre la PR con `/branch-pr`.
3. **`/odd:verify <nombre>` (Verificación):** Claude valida checklist con evidencia, criterios de aceptación, alcance del diff, re-clasifica criterios K1-K10 sobre el diff real, corre los tests si están declarados, y evalúa la puerta de integración (dato inesperado en `no aplica (ODD)`). Deja el documento en `estado: verificado`.
4. **`/odd:close <nombre>` (Cierre):** Se ejecuta **después del merge**. Controla que la rama esté mergeada, crea la nota en `archive\AAAA-MM-DD-odd-<nombre>.md` del vault, actualiza `_index.md`, reescribe `arquitectura.md` si el ODD modificó la visión y actualiza `context.md`. No crea commits en el repo del proyecto (el cierre vive en el vault).

### Escalado a SDD y falta en el alcance

- **Falta en el alcance:** Si durante la implementación el Agente necesita tocar un archivo fuera de "Archivos permitidos" y no se cumple ningún criterio SDD (por ejemplo, un test o dato de prueba), avisa "falta en el alcance": Claude amplía el documento ODD, anota en `## Progreso` y el Agente continúa (no se escala).
- **Escalado a SDD:** Si durante la implementación o en `/odd:verify` se detecta que el cambio cumple un criterio SDD (K1 a K10):
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

Al archivar un change, Claude exporta automáticamente una nota resumen al vault configurado en `$env:OBSIDIAN_VAULT`:

```
$env:OBSIDIAN_VAULT\
  _global\
    reglas-globales.md              ← espejo del CLAUDE.md del repo (lo leen Claude y el Agente)
  projects\
    {nombre-proyecto}\
      _index.md                     ← índice con links a todos los changes
      context.md                    ← estado actual del proyecto (actualizado continuamente)
      apply\                        ← resúmenes del apply del Agente (local, no versionada por git)
        AAAA-MM-DD-{change}.md
      decisions\
        YYYY-MM-DD-{change}.md      ← creada al propose
      archive\
        YYYY-MM-DD-{change}.md      ← creada al archive
```

Al iniciar sesión, Claude lee el `_index.md` del proyecto y las últimas 3 notas para recuperar contexto histórico sin re-explicación manual.

### Resúmenes de apply en el vault (`apply\`)

El Agente guarda una copia completa del resumen final del apply con su evidencia en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`. Esta carpeta `projects/*/apply/` está excluida en el `.gitignore` del vault: nunca se commitea ni se sube a git (para no filtrar salidas sensibles ni datos de tests fuera de la máquina). En consecuencia, `/opsx:verify` solo se corre en la máquina del apply, leyendo la copia local de `apply/` y contrastándola con el diff de git.

Al actualizar un proyecto o incorporar cambios a las reglas globales, es necesario volver a copiar las plantillas de reglas en el proyecto (`.cursor/rules/sdd-workflow.mdc`, `.github/copilot-instructions.md`, `AGENTS.md`) y actualizar `GEMINI.md` en cada máquina.

### Reglas globales en el vault (`_global\`)

Además de la memoria por proyecto, el vault espeja las reglas globales del workflow en `_global\reglas-globales.md`. Esto permite que cualquier agente con acceso al filesystem (el Agente, otros chats de Claude) lea las reglas SDD sin depender de `~/.claude/`. Las reglas se editan solo en `.claude/CLAUDE.md` del repo `sdd-global-config`. Todo cambio pasa por un change, su PR y merge, y luego se corre `pwsh scripts/instalar.ps1` en cada máquina, que actualiza el espejo del vault y `~/.claude/CLAUDE.md`. Ninguna copia se edita a mano.

La integración usa PowerShell puro — sin MCP ni plugins. El skill de archive modificado (`skills/openspec-archive-change/SKILL.md`) maneja la escritura al vault. Las reglas de lectura/escritura/eliminación están en el `~/.claude/CLAUDE.md` global, sección `## Capa de Persistencia — Obsidian`.

---

## Archivos gestionados por este repo

| Archivo | Propósito |
|---|---|
| `~/.claude/CLAUDE.md` | Archivo de carga que importa el espejo del vault (o copia completa sin vault) — la fuente se edita en `.claude/CLAUDE.md` de este repo |
| `~/.claude/skills/openspec-apply-change/SKILL.md` | Comportamiento de apply en Claude (handoff al Agente) |
| `~/.claude/skills/openspec-verify-change/SKILL.md` | Skill de verify instalada globalmente |
| `~/.claude/skills/openspec-propose/SKILL.md` | Propose: lee context.md, escribe en decisions/, crea branch |
| `~/.claude/skills/openspec-archive-change/SKILL.md` | Archive: escribe en archive/, actualiza context.md |
| `~/.claude/skills/srs-generate/SKILL.md` | SRS Generate: genera/actualiza `docs/srs.md` con specs vigentes |
| `~/.claude/skills/issue-creation/SKILL.md` | Issue-first: crea issue con template antes del propose |
| `~/.claude/skills/branch-pr/SKILL.md` | Valida commits, abre PR con formato correcto |
| `.github/workflows/pr-check.yml` | GitHub Action: valida branch, título, Spec-ID y secrets en cada PR |
| `CONTRIBUTING.md` | Guía de contribución: flujo completo issue → propose → PR → verify → merge |
| `templates/antigravity/settings.json` | Plantilla de permisos y barra de estado de Antigravity CLI (`~/.gemini/antigravity-cli/settings.json`) |
| `templates/antigravity/GEMINI.md` | Reglas globales del Agente para Antigravity (`~/.gemini/GEMINI.md`) |
| `templates/copilot/copilot-instructions.md` | Instrucciones por proyecto para GitHub Copilot (`.github/copilot-instructions.md`) |
| `templates/cursor/sdd-workflow.mdc` | Reglas por proyecto para Cursor (`.cursor/rules/sdd-workflow.mdc`) |
| `templates/comun/AGENTS.md` | Instrucciones estándar multi-agente por proyecto (`AGENTS.md` en la raíz) |
| `$env:OBSIDIAN_VAULT\projects\` | Vault Obsidian — memoria persistente (context.md + decisions/ + archive/ + apply/) |
| `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` | Espejo del CLAUDE.md del repo en el vault (lo leen Claude y el Agente) |
