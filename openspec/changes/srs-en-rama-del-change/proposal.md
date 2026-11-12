# Proposal

## Why

El SRS se arma desde las specs vigentes de `openspec/specs/`, y esas specs se actualizan recién en el archive. Como la regla global obliga a archivar después del merge, la regeneración del SRS siempre termina en un PR aparte desde una rama que no es `change/` ni `odd/`. El check "Validate PR conventions" de `pr-check.yml` rechaza ese PR, como pasó con el PR #43. Así, el SRS queda fuera del PR del change o se commitea directo en `master`.

## What Changes

- **BREAKING (flujo):** `/opsx:archive` pasa a tener dos fases:
  - **Fase de la rama**, antes del merge y en `change/<nombre>`: sincroniza las specs, mueve el change a `openspec/changes/archive/`, completa el `## Purpose`, commitea el archive en la rama y ofrece regenerar el SRS. Si el usuario acepta, también lo commitea en la rama.
  - **Fase del vault**, después del merge: escribe las notas del vault (archive, decisions, `context.md`, `_index.md` y `arquitectura.md`), como hoy, sin crear commits en el repo del proyecto.
- Cambia la regla global de Git en `.claude/CLAUDE.md`. Hoy dice "el archive se ejecuta después del merge, nunca antes". Pasa a decir "el archive de specs se ejecuta en la rama del change antes del merge, y el cierre en el vault después del merge". El mismo criterio ya se aplica al change mínimo de spec de un ODD.
- Un change que se mergeó sin archivar, con el flujo anterior, se archiva en una rama `change/<nombre>-archive` creada desde la rama principal, con su propio PR.
- `/odd:verify` ofrece regenerar el SRS en el branch `odd/<nombre>` después de archivar el change mínimo de spec. `/odd:close` deja de recomendar `/srs-generate` después del merge.
- Las guías (`README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`), el cierre del verify (`skills/openspec-verify-change/SKILL.md`) y el checklist del PR (`skills/branch-pr/SKILL.md`) muestran el orden nuevo: verify → archive en la rama (y SRS) → merge → `/opsx:archive` para cerrar en el vault.
- Los comandos `.claude/commands/opsx/archive.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd/close.md` se regeneran desde las skills con `scripts/generar-plantillas.ps1`.

## Capabilities

### New Capabilities
- `change-archive`: momento y fases del archive de un change SDD. Abarca el archive de specs en la rama del change antes del merge, el cierre en el vault después del merge, los changes que se mergearon sin archivar y la documentación del orden en las reglas y las guías.

### Modified Capabilities
- `srs-generation`: el enganche del archive ofrece el SRS en la rama del change, antes del merge, y el resultado se commitea en esa rama. En un ODD con cambio mínimo de spec, el SRS lo ofrece `/odd:verify`.
- `odd-workflow`: `/odd:verify` ofrece regenerar el SRS en el branch después de archivar el change mínimo, y `/odd:close` deja de recomendar `/srs-generate`.

## Non-goals

- No se cambia `pr-check.yml`: sigue aceptando solo ramas `change/` y `odd/`.
- No se cambia cómo `srs-generate` arma el SRS. Sigue leyendo solo las specs vigentes, sin aplicar deltas sin archivar (alternativa 2 descartada en el design).
- No se crea un comando nuevo: las dos fases viven en `/opsx:archive`.
- No se re-verifica el change después del archive en la rama. El archive y el SRS solo tocan `openspec/` y `docs/srs*`, y el CI del PR vuelve a correr con el push.

## Impact

- Archivos globales modificados:
  - `.claude/CLAUDE.md`: reglas de Git, flujo OpenSpec y tabla "Cuándo actuar" del vault. Se distribuye con `scripts/instalar.ps1` después del merge porque cambia el orden de trabajo de todos los proyectos.
  - Skills `openspec-archive-change`, `openspec-verify-change`, `branch-pr` y `odd-change`, más sus comandos generados.
- Proyectos existentes: un change abierto en otro proyecto con el PR ya mergeado se archiva con la rama `change/<nombre>-archive`. Los changes sin mergear siguen el orden nuevo.
- Sin dependencias nuevas.
