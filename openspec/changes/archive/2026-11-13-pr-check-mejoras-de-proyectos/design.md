# Design

## Context

- **Plantilla actual** (`.github/workflows/pr-check.yml`): no declara `permissions:`; el paso "Check no secrets in diff" usa `const sensitivePatterns = ['.env', '.key', '.pem', '.p12', 'secrets/'];` y avisa con "Verificá que .env y credenciales estén en .gitignore.". No tiene comentario de origen.
- **Proyectos bloqueados** (13/11/2026): los tres agregaron `permissions:` de solo lectura. seguimiento-Suscripciones excluye `.example`, `.sample` y `.template` (había un falso positivo con `.env.example`). pdf_automation_research suma `credentials.json` y `token.json`. normalizacionRTF-python suma un job `validate-specs`.
- **`scripts/sincronizar-proyecto.ps1`:** un `pr-check.yml` que no coincide con ninguna versión de la plantilla queda `bloqueado`. En `-Aviso`, todos los bloqueados van en una sola frase: "Bloqueados por contenido propio: <lista>; pasá ese contenido debajo de "## Propio del proyecto" y volvé a sincronizar." (alrededor de la línea 261). En la sincronización normal, el error dice "Para resolverlo, pase el contenido propio debajo de '## Propio del proyecto' del archivo generado o ejecute con -Forzar." (alrededor de la línea 288). Para `pr-check.yml`, la primera opción no existe.

## Goals / Non-Goals

**Goals:** traer a la plantilla las mejoras que sirven para todos; que el bloqueo de `pr-check.yml` diga qué hacer; dejar escrita la regla de devolver mejoras al origen y el procedimiento para sincronizar varios proyectos.

**Non-Goals:** ver proposal (huella del #58, `## Propio` para YAML, puesta al día operativa de los 3 proyectos, BOM).

## Decisions

### D1. Plantilla `.github/workflows/pr-check.yml`

- Primeras tres líneas (antes de `name: PR Check`):
  - `# Generado desde .github/workflows/pr-check.yml de sdd-global-config con scripts/sincronizar-proyecto.ps1. No editar en los proyectos:`
  - `# - si la mejora sirve para todos los proyectos, abrí un issue en sdd-global-config;`
  - `# - si es propia del proyecto, ponela en otro workflow (por ejemplo, .github/workflows/proyecto.yml).`
- Después del bloque `on:` y antes de `jobs:`, a nivel raíz: `permissions:` con `contents: read` y `pull-requests: read`.
- En el paso "Check no secrets in diff":
  - `const sensitivePatterns = ['.env', '.key', '.pem', '.p12', 'secrets/', 'credentials.json', 'token.json'];`
  - una línea nueva `const safeSuffixes = ['.example', '.sample', '.template'];`;
  - en la cadena de `flagged`, un `.filter(name => !safeSuffixes.some(s => name.endsWith(s)))` antes del filtro de patrones sensibles;
  - el mensaje pasa a `Verificá que .env, credentials.json, token.json y demás credenciales estén en .gitignore.`.
- El job `validate-specs` de normalizacionRTF-python **no** entra a la plantilla: depende de que el proyecto tenga OpenSpec y tests propios.
- **Alternativas descartadas:**
  - *Sección "propia" dentro del YAML con marcas de comentario:* complica el script (combinar YAML) para un caso que se resuelve con otro archivo de workflow.
  - *Sincronizar los 3 proyectos con `-Forzar` sin tocar la plantilla:* se pierden mejoras de seguridad que conviene tener en todos.

### D2. Mensaje de bloqueo en `scripts/sincronizar-proyecto.ps1`

- **`-Aviso`:** la frase "Bloqueados por contenido propio: …" pasa a listar solo los bloqueados que no son `.github/workflows/pr-check.yml`. Si `pr-check.yml` está bloqueado, se agrega en la misma línea: `.github/workflows/pr-check.yml editado a mano: si la mejora sirve para todos, abrí un issue en sdd-global-config; si es propia del proyecto, pasala a otro workflow y sincronizá con -Forzar.` Si el único bloqueado es `pr-check.yml`, no aparece la frase "Bloqueados por contenido propio".
- **Sincronización normal:** después de la línea "Para resolverlo, pase el contenido propio…", si entre los bloqueados está `pr-check.yml`, se agrega la línea `Para .github/workflows/pr-check.yml: si la mejora sirve para todos, abrí un issue en sdd-global-config; si es propia del proyecto, pasala a otro workflow y sincronizá con -Forzar.`. Las líneas existentes no cambian.
- El cálculo de estado, los códigos de salida y la lista de destinos no cambian.

### D3. Regla en `.claude/CLAUDE.md`

En "### Reglas globales en el vault (`_global\`)", después de la viñeta "**Onboarding de agentes no-Claude:** …", agregar:

"- **Mejoras a archivos generados:** `AGENTS.md`, las instrucciones de Copilot y Cursor, los comandos `/odd-apply` y `.github/workflows/pr-check.yml` de cada proyecto se generan desde `sdd-global-config` y no se mejoran en el proyecto. Si la mejora sirve para todos, se abre un issue en `sdd-global-config` (`/issue-creation`). Si es propia del proyecto, va debajo de `## Propio del proyecto` en los `.md`, o en otro workflow en el caso de `pr-check.yml`. Cuando `-Aviso` o la sincronización muestran un archivo bloqueado, Claude le explica al usuario estas dos salidas y no sincroniza con `-Forzar` por su cuenta."

No se toca el bloque generado de reglas del Agente.

### D4. `README.md`

En "Sumar un proyecto al workflow", después del párrafo de `-Aviso`, agregar dos párrafos:

- "**Sincronizar varios proyectos.** Para poner al día varios proyectos: (1) detectá los atrasados corriendo `-Aviso` en cada uno; (2) en cada atrasado, corré primero con `-Simular`; (3) pasá en `-Agentes` solo los agentes que el proyecto ya usa (`comun` si tiene `AGENTS.md`, `copilot` si tiene `.github/copilot-instructions.md`, `cursor` si tiene `.cursor/`), así no se crean archivos que el proyecto no usa; (4) no sincronices si alguno de los archivos a reemplazar tiene cambios sin commitear; (5) el script no commitea: los cambios quedan en el árbol de trabajo y se commitean en la rama que corresponda."
- "**Mejoras a archivos generados.** Los archivos que copia `sincronizar-proyecto.ps1` no se mejoran en el proyecto. Si la mejora sirve para todos, abrí un issue en `sdd-global-config`. Si es propia del proyecto, ponela debajo de `## Propio del proyecto` en los `.md`, o en otro workflow en el caso de `pr-check.yml` (por ejemplo, `.github/workflows/proyecto.yml`), y sincronizá con `-Forzar`."

## Impacto en proyectos existentes

- Los proyectos con `pr-check.yml` lo ven atrasado hasta sincronizar. Con la versión nueva, el workflow corre con permisos de solo lectura. `github.rest.pulls.listFiles` sigue funcionando con `pull-requests: read`.
- Los 3 bloqueados se ponen al día después del merge, como tarea operativa (non-goal).
- Las máquinas reciben el `CLAUDE.md` nuevo con `instalar.ps1`.

## Impacto en el sistema

**Componentes afectados:** el CI de todos los proyectos que tienen `pr-check.yml` (al sincronizar), el inicio de sesión de Claude (la regla nueva del `CLAUDE.md`) y el workflow de PR de este mismo repo, que usa la plantilla.

**Atributos de calidad:**
- mantenibilidad (alta): las mejoras viven en la plantilla y se distribuyen con el script, en vez de quedar copiadas a mano en cada proyecto — Verificación: S01 a S03 y revisión del diff: `tests/sincronizar-proyecto.Tests.ps1` y el control `sincronizar-proyecto.ps1 -Agentes copilot -Comprobar` siguen en verde sin modificarse.

**Decisiones de arquitectura:** ninguna. No cambia el stack, el nivel ni las integraciones, y no adopta un patrón transversal.

**Deuda técnica:**
- paga: mejoras de `pr-check.yml` que quedaban solo en algunos proyectos.
- descubre: `pr-check.yml` no tiene lugar para lo propio dentro del archivo; se resuelve con otro workflow (documentado, sin deuda nueva).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/pr-check-mejoras-de-proyectos.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- El workflow de PR corre con permisos mínimos de solo lectura — Verificación: S01.
- El control de archivos sensibles suma `credentials.json` y `token.json`, y no se afloja para otros archivos (solo excluye los que terminan en `.example`, `.sample` o `.template`) — Verificación: S02 y revisión del diff: los patrones anteriores siguen todos.
- Sin secretos ni rutas absolutas en las líneas agregadas — Verificación: revisión del diff: ningún token, `GITHUB_TOKEN` nuevo ni ruta `C:\Users` fuera de `openspec/`.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/CLAUDE.md`, con "Impacto:".

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian `scripts/sincronizar-proyecto.ps1` y la plantilla que controla el CI. Cada test lleva `# test-plan: pr-check-mejoras-de-proyectos/<ID>` arriba del `Probar`. Los tests de mensajes usan carpetas temporales con un `pr-check.yml` inventado que no coincide con la plantilla y un `AGENTS.md` con texto propio sin marcar.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Plantilla de pr-check con permisos mínimos / Permisos de solo lectura | auto: la plantilla tiene `permissions:` a nivel raíz con `contents: read` y `pull-requests: read` | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S02 | Plantilla de pr-check con permisos mínimos / Patrones sensibles y plantillas de ejemplo | auto: `sensitivePatterns` con los 7 patrones de D1, `safeSuffixes` con los 3 sufijos y el filtro antes de los patrones | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S03 | Plantilla de pr-check con permisos mínimos / Comentario de origen | auto: las 3 primeras líneas son las de D1 | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S04 | Mensaje de bloqueo de pr-check / Aviso con pr-check bloqueado | auto: `-Aviso` con solo `pr-check.yml` bloqueado: código distinto de 0, la línea tiene el texto de D2 y no contiene `## Propio del proyecto` | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S05 | Mensaje de bloqueo de pr-check / Aviso con pr-check y AGENTS.md bloqueados | auto: la línea tiene "Bloqueados por contenido propio: AGENTS.md" y el texto de D2 para `pr-check.yml` | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S06 | Mensaje de bloqueo de pr-check / Sincronización con pr-check bloqueado | auto: sincronización sin `-Forzar`: código distinto de 0, salida con la línea "Para .github/workflows/pr-check.yml: …" de D2 y el hash del archivo sin cambios | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S07 | Mejoras de archivos generados vuelven al origen / Regla documentada | auto: `.claude/CLAUDE.md` tiene la viñeta de D3 y `README.md` el párrafo "Mejoras a archivos generados" de D4 | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| S08 | Sincronizar varios proyectos / Procedimiento documentado | auto: `README.md` tiene el párrafo "Sincronizar varios proyectos" de D4 con `-Aviso`, `-Simular`, `-Agentes` y "no commitea" | `tests/pr-check-mejoras-de-proyectos.Tests.ps1` |
| M01 | Mensaje real en un proyecto bloqueado | manual (lo hace el Agente en el apply, sin marca de usuario; solo lectura): correr `pwsh <repo>/scripts/sincronizar-proyecto.ps1 -Proyecto . -Aviso` en pdf_automation_research y en normalizacionRTF-python, y pegar las dos líneas. Las dos tienen que nombrar `pr-check.yml` con el texto de D2. No se modifica ningún archivo de esos proyectos | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/sincronizar-proyecto.ps1` y `.github/workflows/pr-check.yml` (con `tests/sincronizar-proyecto.Tests.ps1`, `tests/aviso-proyecto-atrasado.Tests.ps1`, S07 a S09 de `tests/odd-apply.Tests.ps1` y los controles del CI de `tests/ejecutar.ps1`) | Sincronización, `-Comprobar`, `-Aviso` y bloqueo de contenido propio en los `.md` | Cambia solo el mensaje cuando el bloqueado es `pr-check.yml` (S04 a S06) y el contenido de la plantilla (S01 a S03). Esos tests no se modifican |

## Open Questions

- Ninguna.
