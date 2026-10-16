## 1. Propósitos de las specs vigentes

- [ ] 1.1 En `openspec/specs/agent-cli-permissions/spec.md`, `openspec/specs/doc-folder-structure/spec.md`, `openspec/specs/docs-portable-paths/spec.md`, `openspec/specs/project-claude-md/spec.md`, `openspec/specs/project-onboarding/spec.md`, `openspec/specs/security-layer-matrix/spec.md`, `openspec/specs/srs-generation/spec.md` y `openspec/specs/test-driven-verification/spec.md`: reemplazar la línea "TBD - created by archiving change …" de `## Purpose` por el texto exacto de la tabla D1 del `design.md`, sin tocar ninguna otra línea

## 2. Archive

- [ ] 2.1 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` (igual en los dos): agregar el paso 5.2 y la línea del resumen del paso 6 como dice D2 del `design.md`, y una línea en Guardrails: "Purpose: only replace the exact TBD text left by the CLI in new capabilities; never edit specs that already have a Purpose"
- [ ] 2.2 Reinstalar `skills/openspec-archive-change/` en `~/.claude/skills/` y `.claude/commands/opsx/archive.md` en `~/.claude/commands/opsx/`; confirmar con hash (ignorando fin de línea) que las copias instaladas son iguales al repo

## 3. Verificación manual

- [ ] 3.1 S01 — Buscar "TBD - created by archiving change" en `openspec/specs/**/spec.md` y pegar la salida (0 coincidencias)
- [ ] 3.2 S02 — Comparar el `## Purpose` de las 8 specs con la tabla D1 del `design.md` y pegar la salida de la comparación
- [ ] 3.3 S03 — Correr `git diff master -- openspec/specs` y confirmar que solo cambian las líneas de `## Purpose`; pegar el `--stat`

## 4. Verificación con Claude (la ejecuta el usuario con Claude, no el Agente)

- [ ] 4.1 S04 — En un repo descartable en `%TEMP%` con `openspec init`, proponer y archivar un change con una capability nueva; confirmar que el `## Purpose` quedó con el texto derivado del proposal y que el resumen del archive lo muestra; pegar el `## Purpose` resultante
- [ ] 4.2 S05 — En el mismo repo, archivar un segundo change que modifique esa capability y confirmar que su `## Purpose` no cambió; pegar el `## Purpose` antes y después; borrar el repo descartable
- [ ] 4.3 Regenerar `docs/srs.md` con `srs-generate` (D3); confirmar que la portada ya no indica propósitos pendientes y que `docs/srs.meta.yaml` no cambió sus IDs
- [ ] 4.4 Verificar que el cambio aplica en un proyecto de prueba
