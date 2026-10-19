## 1. Archive

- [x] 1.1 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: reemplazar el paso 7 por el texto exacto de D1 del `design.md`
- [x] 1.2 En `skills/openspec-archive-change/SKILL.md`: reemplazar la línea del ejemplo "Output On Success" como dice D2; en los dos archivos, reemplazar el Guardrail del SRS por el de D2
- [x] 1.3 Confirmar que el paso 7 y el Guardrail del SRS son idénticos en los dos archivos (comparar el bloque del paso 7 entre ambos y pegar la salida)
  - Evidencia (2026-10-19, reproducida en el verify): bloque del paso 7 idéntico en los dos archivos e igual al texto de D1; Guardrail y ejemplo de salida iguales a D2, sin textos viejos.
- [x] 1.4 Reinstalar `skills/openspec-archive-change/` en `~/.claude/skills/` y `.claude/commands/opsx/archive.md` en `~/.claude/commands/opsx/`; confirmar con hash (ignorando fin de línea) que las copias instaladas son iguales al repo
  - Evidencia (2026-10-19, reproducida en el verify): hash SHA-256 ignorando fin de línea, repo = instalado — skill `ed69fde7af19`, comando `d5aee90ff73f`. Commit de código c09608d.

## 2. Verificación con Claude (la ejecuta el usuario con Claude, no el Agente)

- [x] 2.1 S01 — En un repo descartable en `%TEMP%` con `docs/srs.md`, archivar un change chico y confirmar la pregunta de regenerar con "Regenerar ahora" y "Más tarde"
  - Evidencia (2026-10-19): repo descartable `s0x-consrs` con `docs/srs.md`; archive sin interfaz de `nota-uno`: ofreció regenerar el SRS ("`docs/srs.md` existe… Lo tomé como 'más tarde' y no lo regeneré") y recordó el commit aparte `docs: regenerar SRS`.
- [x] 2.2 S02 — En un repo descartable sin `docs/srs.md`, archivar un change chico y confirmar la pregunta de generar con "Generar ahora", "Más tarde" y el aviso de la entrevista
  - Evidencia (2026-10-19): repo descartable `s0x-sinsrs` sin `docs/srs.md`; archive sin interfaz de `nota-uno`: "este proyecto todavía no tiene SRS… ¿Lo genero ahora? La primera vez incluye una entrevista corta". En una sesión interactiva (archive de `nota-tres`) el usuario vio el menú con "Generar ahora" y "Más tarde"; eligió "Generar ahora" y se crearon `docs/srs.md`, `docs/srs.meta.yaml` y la entrevista en `config.yaml`.
- [x] 2.3 S03 — En el repo de S02, contestar "Más tarde", confirmar que no se crearon `docs/srs.md` ni `docs/srs.meta.yaml`, archivar un segundo change y confirmar que vuelve a ofrecerlo; borrar los repos descartables
  - Evidencia (2026-10-19): tras el "Más tarde" de `nota-uno` no existía `docs/`; el archive siguiente (`nota-dos`) volvió a ofrecer generarlo ("el próximo archivo te lo va a ofrecer de nuevo"). Repos descartables y sus carpetas de sesión borrados.
- [x] 2.4 Verificar que el cambio aplica en un proyecto de prueba
  - Evidencia (2026-10-19): cubierta por 2.1–2.3, corridas en proyectos de prueba con los comandos instalados en `~/.claude`.
