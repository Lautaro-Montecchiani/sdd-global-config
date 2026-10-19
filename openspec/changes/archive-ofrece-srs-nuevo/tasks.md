## 1. Archive

- [ ] 1.1 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: reemplazar el paso 7 por el texto exacto de D1 del `design.md`
- [ ] 1.2 En `skills/openspec-archive-change/SKILL.md`: reemplazar la línea del ejemplo "Output On Success" como dice D2; en los dos archivos, reemplazar el Guardrail del SRS por el de D2
- [ ] 1.3 Confirmar que el paso 7 y el Guardrail del SRS son idénticos en los dos archivos (comparar el bloque del paso 7 entre ambos y pegar la salida)
- [ ] 1.4 Reinstalar `skills/openspec-archive-change/` en `~/.claude/skills/` y `.claude/commands/opsx/archive.md` en `~/.claude/commands/opsx/`; confirmar con hash (ignorando fin de línea) que las copias instaladas son iguales al repo

## 2. Verificación con Claude (la ejecuta el usuario con Claude, no el Agente)

- [ ] 2.1 S01 — En un repo descartable en `%TEMP%` con `docs/srs.md`, archivar un change chico y confirmar la pregunta de regenerar con "Regenerar ahora" y "Más tarde"
- [ ] 2.2 S02 — En un repo descartable sin `docs/srs.md`, archivar un change chico y confirmar la pregunta de generar con "Generar ahora", "Más tarde" y el aviso de la entrevista
- [ ] 2.3 S03 — En el repo de S02, contestar "Más tarde", confirmar que no se crearon `docs/srs.md` ni `docs/srs.meta.yaml`, archivar un segundo change y confirmar que vuelve a ofrecerlo; borrar los repos descartables
- [ ] 2.4 Verificar que el cambio aplica en un proyecto de prueba
