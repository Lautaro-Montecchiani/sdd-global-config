# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1`. Cada test nuevo lleva `# test-plan: srs-en-rama-del-change/<ID>` arriba del `Probar`. Los commits de código no incluyen `openspec/`. El cambio a `.claude/CLAUDE.md` va en un commit separado, con la descripción del impacto (cambia el orden archive/merge en todos los proyectos). Los archivos de `.claude/commands/` no se editan a mano: se regeneran con `pwsh scripts/generar-plantillas.ps1`.

Antes de empezar: confirmar que el usuario aprobó la **alternativa 1** de D1 en `design.md`. Si eligió la 2, frenar y avisar.

## 1. Caracterización

- [ ] 1.1 C01 y C02: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada. Verificación: salida en verde pegada en el resumen (incluye `tests/clasificacion-odd.Tests.ps1` y `tests/generar-comandos.Tests.ps1`).

## 2. Tests de contrato (test primero)

- [ ] 2.1 Test primero, S01 a S07 en `tests/srs-en-rama-del-change.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"` como `tests/aclarar-k2.Tests.ps1`): controlar en `skills/openspec-archive-change/SKILL.md` y en `.claude/commands/opsx/archive.md` los textos de "Los textos que controla cada test" en el `## Test Plan` de `design.md`. Verificación: fallan con el código actual (salida en rojo pegada).
- [ ] 2.2 Test primero, S10 a S13 en el mismo archivo: el paso del SRS está en la fase de la rama, nombra `docs: regenerar SRS` y `Spec-ID: <nombre>`, y la fase del vault dice que no ofrece el SRS. Verificación: fallan con el código actual (salida en rojo pegada).
- [ ] 2.3 Test primero, S14 y S15 en el mismo archivo, sobre `skills/odd-change/SKILL.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd/close.md`: oferta del SRS después de `openspec archive odd-<nombre> -y`, `docs/srs.md` permitido en el control de alcance, línea `SRS:` en la nota y ausencia de la recomendación de `/srs-generate`. Verificación: fallan con el código actual (salida en rojo pegada).
- [ ] 2.4 Test primero, S08 y S09 en el mismo archivo, sobre `.claude/CLAUDE.md`, `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md`, `skills/openspec-verify-change/SKILL.md`, `.claude/commands/opsx/verify.md` y `skills/branch-pr/SKILL.md` con los textos de D7 y D8. S08 también controla que no esté la frase "El archive se ejecuta después del merge, nunca antes". Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Skills

- [ ] 3.1 En `skills/openspec-archive-change/SKILL.md`: implementar D2 a D5 de `design.md`.
  - Detección de fase con la tabla de D2.
  - Fase de la rama con los pasos 1 a 9 de D3: reemplaza el paso 3.5 actual y mueve el paso 7 (SRS) a esta fase.
  - Fase del vault con D4, que reusa sin cambios los pasos 5.5 a–f.
  - Change del flujo anterior con D5.
  - Actualizar `metadata.modified` y las salidas de ejemplo ("Output On Success"), que pasan a ser dos: una por fase.

  Verificación: S01 a S07 y S10 a S13 en verde.
- [ ] 3.2 En `skills/odd-change/SKILL.md`, secciones de `/odd:verify` y `/odd:close`: implementar D6 de `design.md`. Verificación: S14 y S15 en verde, y `tests/clasificacion-odd.Tests.ps1` en verde sin modificarlo.
- [ ] 3.3 En `skills/openspec-verify-change/SKILL.md` (las dos apariciones de "Ready for archive") y en `skills/branch-pr/SKILL.md` (paso 2 de control de artefactos, checklist de `change/` y las dos líneas "Merge solo después de que verify no reporte desvíos"): aplicar D8 de `design.md`. Verificación: la parte de S09 sobre estos archivos en verde.
- [ ] 3.4 Correr `pwsh scripts/generar-plantillas.ps1` para regenerar `.claude/commands/`. Verificación: `pwsh scripts/generar-plantillas.ps1 -Comprobar` termina con código 0 y `git diff --stat` muestra solo los comandos de `opsx/` y `odd/` que corresponden a las skills tocadas.

## 4. Reglas globales (commit separado)

- [ ] 4.1 En `.claude/CLAUDE.md`: aplicar D7 de `design.md` (bloque "Flujo OpenSpec", sección "Pull Requests" y fila `/opsx:archive` de la tabla "Cuándo actuar"). No tocar el bloque entre `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`. Commitear solo este archivo con `docs: archive de specs en la rama del change antes del merge`, una línea de impacto en el cuerpo y `Spec-ID: srs-en-rama-del-change`. Verificación: S08 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.

## 5. Guías

- [ ] 5.1 En `README.md` (línea de `/opsx:archive` del bloque del flujo), `docs/workflow.md` y `docs/modo-de-uso.md` (bloque del ciclo y punto "6. Merge + Claude archiva"): aplicar D8 de `design.md`. Verificación: S09 en verde.

## 6. Cierre

- [ ] 6.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S16).
- [ ] 6.2 Revisión de seguridad del diff: `git diff master --stat` y búsqueda de `C:\Users` y de tokens en los archivos modificados. Verificación: salida de la búsqueda sin coincidencias, pegada.
- [ ] 6.3 M01 (manual): verificar que el cambio aplica en un proyecto de prueba con los pasos de M01 del `## Test Plan` de `design.md`, después de `pwsh scripts/instalar.ps1` con las skills nuevas. Verificación: `git log --oneline` de la rama y de la rama principal, y listado de `archive\` del vault, pegados en el resumen.
