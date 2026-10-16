## Context

Al archivar un change que crea una capability, el CLI de OpenSpec (1.4.1) escribe la spec nueva con `## Purpose` = "TBD - created by archiving change <nombre>. Update Purpose after archive." Ni la skill ni el comando de archive lo completan, así que 8 de las 9 specs vigentes quedaron así. La única con propósito redactado es `project-context-schema`, que sirve de modelo: una o dos oraciones que dicen qué define la capability. El SRS (`docs/srs.md`) muestra esos 8 propósitos como pendientes y por eso queda en "borrador".

## Goals / Non-Goals

**Goals:**
- Completar los 8 propósitos con un texto fijo, definido acá (D1), para que el Agente no tenga que redactarlo.
- Evitar que el problema se repita en los próximos archives (D2).

**Non-Goals:**
- Modificar requirements o escenarios.
- Cambiar el CLI de OpenSpec.

## Decisions

### D1. Texto del `## Purpose` de cada spec
Reemplazar la línea "TBD - created by archiving change …" por el texto de esta tabla, exacto, en la línea que sigue a `## Purpose`:

| Spec | Purpose |
|---|---|
| `agent-cli-permissions` | Define cómo se replica en cada máquina la configuración del CLI del Agente sin versionar la configuración personal: baseline de permisos, allowlist base de comandos, workspaces de confianza declarados por máquina, barra de estado especificada por comportamiento e instalación documentada paso a paso. |
| `doc-folder-structure` | Define que la documentación de reglas de negocio del proyecto vive en una carpeta `docs/` en la raíz (`workflow.md` y la guía de uso) y que `README.md` la referencia como punto de entrada. |
| `docs-portable-paths` | Garantiza que la documentación de `docs/` funcione en cualquier máquina sin exponer datos del entorno local: sin rutas absolutas con el usuario de la PC y con el `.docx` de la guía de uso siempre alineado con su `.md`. |
| `project-claude-md` | Define el contenido de los `CLAUDE.md` de cada proyecto: conservan lo propio del proyecto y remiten al flujo OpenSpec global, sin instruir el flujo SDD manual y nombrando al constructor como "el Agente". |
| `project-onboarding` | Define cómo se prepara una máquina y cómo se inicia un proyecto en el workflow: el setup instala las skills y los comandos globales de Claude, los proyectos se inician solo con el Agente (`openspec init --tools <agente>`) y los que tienen copias locales de Claude se limpian para que no pisen a las globales. |
| `security-layer-matrix` | Define los controles de seguridad mínimos por tipo de proyecto: la matriz en el `CLAUDE.md` global, la declaración de `project_type` en cada proyecto, la sección `## Security Layer` obligatoria en cada `design.md` y el rol de Claude en el apply. |
| `srs-generation` | Define la skill `srs-generate`, que arma y mantiene `docs/srs.md` por agregación de las specs vigentes: estructura fija, IDs jerárquicos estables, casos de uso con diagramas, matriz de trazabilidad, entrevista guiada para las secciones de negocio, modo bootstrap, regeneración segura y exclusión de secrets. |
| `test-driven-verification` | Define cómo se verifica un change con tests ejecutados en vez de inferencia: Test Plan por escenario en el `design.md`, marcadores de ID, tests primero y de caracterización en `tasks.md`, ejecución segura en el verify con suite completa cuando se modifica código existente, verificación manual justificada y compatibilidad con changes sin Test Plan. |

Alternativa descartada: dejar que el Agente redacte cada propósito leyendo la spec. Iría contra la regla "No inventar" de ejecución del Agente.

### D2. El archive completa el propósito de capabilities nuevas
En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` (igual en los dos), agregar un paso **5.2** después del movimiento a `archive/` (paso 5) y antes de la exportación al vault (5.5):

- Leer la sección "New Capabilities" del `proposal.md` del change archivado.
- Para cada capability listada, si `openspec/specs/<capability>/spec.md` tiene en `## Purpose` el texto "TBD - created by archiving change", reemplazar esa línea por una o dos oraciones derivadas de la descripción de la capability en el proposal, en el idioma de la spec.
- No tocar las specs que ya tienen propósito redactado ni ninguna otra sección.
- Mostrar en el resumen (paso 6) una línea por propósito escrito: `Purpose: <capability> — <texto>`.

Alternativa descartada: completar el propósito en el propose (en la delta spec). El formato delta no tiene sección `## Purpose` y el CLI no la copiaría.

### D3. Regenerar el SRS al final
Después de D1 y D2, regenerar `docs/srs.md` con `srs-generate`. La entrevista ya está respondida en el `context:` de `openspec/config.yaml`, así que no vuelve a preguntar. Los IDs de `docs/srs.meta.yaml` no cambian.

## Risks / Trade-offs

- [El propósito derivado en el archive puede quedar impreciso] → Se muestra en el resumen del archive para que el usuario lo revise y lo corrija antes del commit.
- [Un change que crea varias capabilities sin descripción en el proposal] → El archive deja el TBD y lo avisa en el resumen, en vez de inventar un propósito.

## Impacto en proyectos existentes

- Los proyectos que ya tienen specs con TBD no cambian: este change solo corrige las de `sdd-global-config`.
- A partir de este change, todo archive que cree una capability deja el propósito completo. No hay incompatibilidad: el paso nuevo solo reemplaza el texto TBD exacto del CLI.

## Security Layer

Tipo `tooling`:
- Los artefactos modificados son instrucciones para IA y specs en Markdown: no contienen secrets, tokens ni rutas absolutas con el usuario local.
- El paso nuevo del archive solo lee el `proposal.md` del change y edita la sección `## Purpose` de las specs nuevas; no ejecuta comandos derivados de esos archivos.
- Cambio a skills y comandos globales → commit separado con descripción del impacto.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): el repo no tiene tests automáticos porque sus artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: el change no modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Toda spec vigente tiene propósito / Specs vigentes sin propósito en TBD | manual: sin tests automáticos. Pasos: buscar "TBD - created by archiving change" en `openspec/specs/**/spec.md` y pegar la salida (0 coincidencias) | `openspec/specs/*/spec.md` |
| S02 | Toda spec vigente tiene propósito / Propósito que describe la capability | manual: es una revisión de contenido. Pasos: para cada una de las 8 specs, comparar el `## Purpose` con la tabla de D1 y pegar la salida de la comparación | `openspec/specs/*/spec.md` |
| S03 | Toda spec vigente tiene propósito / Requirements intactos | manual: sin tests automáticos. Pasos: `git diff master -- openspec/specs` y confirmar que solo cambian las líneas de `## Purpose` | `openspec/specs/*/spec.md` |
| S04 | El archive completa el propósito de capabilities nuevas / Archive que crea una capability nueva | manual: requiere correr el archive. Pasos: en un repo descartable en `%TEMP%` con `openspec init`, proponer y archivar un change con una capability nueva; confirmar que su `## Purpose` quedó con el texto derivado del proposal y que el resumen lo muestra; borrar el repo | `skills/openspec-archive-change/SKILL.md`, `.claude/commands/opsx/archive.md` |
| S05 | El archive completa el propósito de capabilities nuevas / Archive que modifica una capability existente | manual: requiere correr el archive. Pasos: en el mismo repo de S04, archivar un segundo change que modifique esa capability y confirmar que su `## Purpose` no cambió | `skills/openspec-archive-change/SKILL.md`, `.claude/commands/opsx/archive.md` |

## Open Questions

Sin preguntas abiertas.
