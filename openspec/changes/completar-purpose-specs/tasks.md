## 1. Propósitos de las specs vigentes

- [x] 1.1 En `openspec/specs/agent-cli-permissions/spec.md`, `openspec/specs/doc-folder-structure/spec.md`, `openspec/specs/docs-portable-paths/spec.md`, `openspec/specs/project-claude-md/spec.md`, `openspec/specs/project-onboarding/spec.md`, `openspec/specs/security-layer-matrix/spec.md`, `openspec/specs/srs-generation/spec.md` y `openspec/specs/test-driven-verification/spec.md`: reemplazar la línea "TBD - created by archiving change …" de `## Purpose` por el texto exacto de la tabla D1 del `design.md`, sin tocar ninguna otra línea

## 2. Archive

- [x] 2.1 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` (igual en los dos): agregar el paso 5.2 y la línea del resumen del paso 6 como dice D2 del `design.md`, y una línea en Guardrails: "Purpose: only replace the exact TBD text left by the CLI in new capabilities; never edit specs that already have a Purpose"
- [x] 2.2 Reinstalar `skills/openspec-archive-change/` en `~/.claude/skills/` y `.claude/commands/opsx/archive.md` en `~/.claude/commands/opsx/`; confirmar con hash (ignorando fin de línea) que las copias instaladas son iguales al repo

## 3. Verificación manual

- [x] 3.1 S01 — Buscar "TBD - created by archiving change" en `openspec/specs/**/spec.md` y pegar la salida (0 coincidencias)
  - Evidencia: `Select-String -Path "openspec/specs/*/spec.md" -Pattern "TBD - created by archiving change" -SimpleMatch` → `Coincidencias: 0` (antes del cambio: 8 coincidencias en las 8 specs).
- [x] 3.2 S02 — Comparar el `## Purpose` de las 8 specs con la tabla D1 del `design.md` y pegar la salida de la comparación
  - Evidencia:
    - `agent-cli-permissions : match=True | Define cómo se replica en cada máquina la configuración del CLI del Agente sin versionar la configuración personal: baseline de permisos, allowlist base de comandos, workspaces de confianza declarados por máquina, barra de estado especificada por comportamiento e instalación documentada paso a paso.`
    - `doc-folder-structure : match=True | Define que la documentación de reglas de negocio del proyecto vive en una carpeta docs/ en la raíz (workflow.md y la guía de uso) y que README.md la referencia como punto de entrada.`
    - `docs-portable-paths : match=True | Garantiza que la documentación de docs/ funcione en cualquier máquina sin exponer datos del entorno local: sin rutas absolutas con el usuario de la PC y con el .docx de la guía de uso siempre alineado con su .md.`
    - `project-claude-md : match=True | Define el contenido de los CLAUDE.md de cada proyecto: conservan lo propio del proyecto y remiten al flujo OpenSpec global, sin instruir el flujo SDD manual y nombrando al constructor como "el Agente".`
    - `project-onboarding : match=True | Define cómo se prepara una máquina y cómo se inicia un proyecto en el workflow: el setup instala las skills y los comandos globales de Claude, los proyectos se inician solo con el Agente (openspec init --tools <agente>) y los que tienen copias locales de Claude se limpian para que no pisen a las globales.`
    - `security-layer-matrix : match=True | Define los controles de seguridad mínimos por tipo de proyecto: la matriz en el CLAUDE.md global, la declaración de project_type en cada proyecto, la sección ## Security Layer obligatoria en cada design.md y el rol de Claude en el apply.`
    - `srs-generation : match=True | Define la skill srs-generate, que arma y mantiene docs/srs.md por agregación de las specs vigentes: estructura fija, IDs jerárquicos estables, casos de uso con diagramas, matriz de trazabilidad, entrevista guiada para las secciones de negocio, modo bootstrap, regeneración segura y exclusión de secrets.`
    - `test-driven-verification : match=True | Define cómo se verifica un change con tests ejecutados en vez de inferencia: Test Plan por escenario en el design.md, marcadores de ID, tests primero y de caracterización en tasks.md, ejecución segura en el verify con suite completa cuando se modifica código existente, verificación manual justificada y compatibilidad con changes sin Test Plan.`
- [x] 3.3 S03 — Correr `git diff master -- openspec/specs` y confirmar que solo cambian las líneas de `## Purpose`; pegar el `--stat`
  - Evidencia: `git diff master --stat -- openspec/specs` → 8 files changed, 8 insertions(+), 8 deletions(-) (`agent-cli-permissions/spec.md`, `doc-folder-structure/spec.md`, `docs-portable-paths/spec.md`, `project-claude-md/spec.md`, `project-onboarding/spec.md`, `security-layer-matrix/spec.md`, `srs-generation/spec.md`, `test-driven-verification/spec.md`, cada uno `2 +-` únicamente en la línea debajo de `## Purpose`).

## 4. Verificación con Claude (la ejecuta el usuario con Claude, no el Agente)

- [ ] 4.1 S04 — En un repo descartable en `%TEMP%` con `openspec init`, proponer y archivar un change con una capability nueva; confirmar que el `## Purpose` quedó con el texto derivado del proposal y que el resumen del archive lo muestra; pegar el `## Purpose` resultante
- [ ] 4.2 S05 — En el mismo repo, archivar un segundo change que modifique esa capability y confirmar que su `## Purpose` no cambió; pegar el `## Purpose` antes y después; borrar el repo descartable
- [ ] 4.3 Regenerar `docs/srs.md` con `srs-generate` (D3); confirmar que la portada ya no indica propósitos pendientes y que `docs/srs.meta.yaml` no cambió sus IDs
- [ ] 4.4 Verificar que el cambio aplica en un proyecto de prueba
