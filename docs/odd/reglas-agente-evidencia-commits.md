---
tipo: odd
nombre: reglas-agente-evidencia-commits
creado: 2026-11-12
estado: abierto
branch: odd/reglas-agente-evidencia-commits
---

## Objetivo
Las reglas 1 y 5 de ejecución del Agente impiden tres cosas que pasaron el 12/11/2026: simular una tarea manual que tenía que correr el usuario, commitear con un tipo no permitido (`style:`) y cambiar la cuenta activa de `gh`.

## Problema
- En `srs-en-rama-del-change` y `sugerir-arquitectura`, el Agente marcó `[x]` la tarea M01 simulándola, aunque la tarea decía que la corría el usuario.
- En `desindentar-nivel-tamano`, commiteó con `style:`, que no está entre los tipos permitidos del `CLAUDE.md` global.
- En varios applies dejó activa la cuenta `Lautaro-Montecchiani`, y eso rompió el pull y el push del vault de trabajo.

Las reglas de ejecución no dicen nada de estos casos.

## Alcance
- Incluye: agregar texto al final de las reglas 1 y 5 en `templates/fuente/fragmentos/reglas-ejecucion.md` y regenerar con `pwsh scripts/generar-plantillas.ps1`.
- No incluye: reglas nuevas (siguen siendo 8 con los mismos títulos), cambios a las demás reglas ni a otros fragmentos.
- Cambio de spec: ninguno. Las specs controlan los títulos y la cantidad de reglas, que no cambian.
- Archivos permitidos:
  - `templates/fuente/fragmentos/reglas-ejecucion.md`
  - `templates/antigravity/GEMINI.md`
  - `templates/comun/AGENTS.md`
  - `templates/copilot/copilot-instructions.md`
  - `templates/cursor/sdd-workflow.mdc`
  - `.claude/CLAUDE.md` (solo el bloque generado entre `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`)
  - `docs/odd/reglas-agente-evidencia-commits.md`

## Clasificación
SDD por K7 (6 archivos sin contar documentación). K7 se pasó por alto a pedido del usuario el 2026-11-12, porque se edita un solo archivo a mano y los otros 5 se regeneran desde él. No se cumple ningún otro criterio:
- K1: no se agrega ni se quita comportamiento de ninguna spec.
- K2, K3: no toca datos ni seguridad.
- K4, K5, K6: no toca dependencias, contratos ni arquitectura.
- K8: el texto está definido abajo.
- K10: no cumple ningún criterio de ADR.

## Checklist
- [ ] 1. En `templates/fuente/fragmentos/reglas-ejecucion.md`, al final de la regla 1 (después de "Sin evidencia, la tarea queda `[ ]` y avisás."), agregar con un espacio delante, exacto: `Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda [ ] y en el resumen le pedís al usuario que la corra.` Escribir `[ ]` entre comillas invertidas, igual que en el resto de la regla.
- [ ] 2. En el mismo archivo, al final de la regla 5 (después de "los artefactos de spec van en un commit aparte."), agregar con un espacio delante, exacto: `Usá solo los tipos feat, fix, chore, refactor, docs y test. No cambies la cuenta activa de gh (gh auth switch): si un push o un PR falla por permisos, frená y avisá.` Escribir cada tipo, `gh` y `gh auth switch` entre comillas invertidas.
- [ ] 3. Regenerar con `pwsh scripts/generar-plantillas.ps1` y comprobar con `pwsh scripts/generar-plantillas.ps1 -Comprobar`.
- [ ] 4. Correr la suite: `pwsh -NoProfile -File tests/ejecutar.ps1`.
- [ ] 5. Commitear con un tipo permitido (`docs:`) y `Spec-ID: odd-reglas-agente-evidencia-commits`, sin cambiar la cuenta de `gh`.

## Criterios de aceptación
- CA1: las dos oraciones nuevas aparecen, idénticas, en el fragmento, en las 4 plantillas y en el bloque generado de `.claude/CLAUDE.md`. — Evidencia esperada: salida de `Select-String -SimpleMatch` de cada oración, con 6 coincidencias por oración.
- CA2: siguen siendo 8 reglas, con los mismos títulos. — Evidencia esperada: salida de `Select-String` de `^\d\. \*\*` sobre el fragmento (8 líneas).
- CA3: el diff solo toca los archivos permitidos. — Evidencia esperada: salida de `git diff --stat master`.
- CA4: la generación y los tests siguen en verde. — Evidencia esperada: `-Comprobar` con código 0 y suite con código 0.

## Evidencia
<la completa el Agente: por tarea y por criterio>

## Progreso
2026-11-12: documento redactado — Claude.

## Próximo paso
El Agente implementa el checklist en la rama `odd/reglas-agente-evidencia-commits`.
