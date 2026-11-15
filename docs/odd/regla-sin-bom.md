---
tipo: odd
nombre: regla-sin-bom
creado: 2026-11-14
estado: abierto
branch: odd/regla-sin-bom
---

## Objetivo
Que la regla 5 del Agente le pida guardar todo archivo nuevo o modificado en UTF-8 sin BOM, con los mismos finales de línea, y pegar en el resumen los primeros 3 bytes de cada archivo tocado.

## Problema
El Agente (Antigravity sobre Windows) mete BOM en los archivos que toca aunque la tarea lo prohíba: pasó en la 6.1 de `aviso-proyecto-atrasado`, en la 7.4 y 7.5 de `backlog-desde-issues` y en `statusline-instalable` (hizo falta la tarea 6.4). Cada vez cuesta una tarea de arreglo y una vuelta más de verify. Hoy las reglas de ejecución no lo dicen: solo lo repite cada `tasks.md`.

## Alcance
- Incluye: una oración al final de la regla 5 («Commits separados») en `templates/fuente/fragmentos/reglas-ejecucion.md` y la regeneración de las plantillas y del bloque de reglas con `scripts/generar-plantillas.ps1`.
- No incluye: cambiar el título o la cantidad de reglas, controles automáticos de BOM en el CI ni cambios en las skills.
- Cambio de spec: ninguno. Las specs controlan los títulos y la cantidad de reglas, que no cambian.
- Archivos permitidos:
  - `templates/fuente/fragmentos/reglas-ejecucion.md` (único archivo que se edita a mano)
  - `.claude/CLAUDE.md`, `.github/copilot-instructions.md`, `templates/antigravity/GEMINI.md`, `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md` y `templates/cursor/sdd-workflow.mdc` (solo regenerados)
  - `docs/odd/regla-sin-bom.md`

## Clasificación
SDD por K7 (7 archivos sin contar documentación). K7 se pasó por alto a pedido del usuario el 2026-11-14, porque se edita un solo archivo a mano y los otros 6 se regeneran desde él (mismo criterio que `reglas-agente-evidencia-commits`). No se cumple ningún otro criterio:
- K1: no agrega ni quita comportamiento de ninguna spec; ninguna spec fija el texto de la regla 5.
- K2: no toca datos. K3: no toca autenticación, permisos, secretos ni la Security Layer.
- K4, K5, K6: sin dependencias, contratos ni cambios de arquitectura.
- K8: el qué está claro. K10: no es una decisión de arquitectura.

## Checklist
- [ ] 1. En `templates/fuente/fragmentos/reglas-ejecucion.md`, agregar al final de la regla 5, después de «si un push o un PR falla por permisos, frená y avisá.», la oración: «Todo archivo nuevo o modificado va en UTF-8 sin BOM y conserva sus finales de línea; en el resumen del apply pegá los primeros 3 bytes de cada archivo tocado, que no pueden ser `EF BB BF`.»
- [ ] 2. Correr `pwsh scripts/generar-plantillas.ps1` y después `pwsh scripts/generar-plantillas.ps1 -Comprobar`.
- [ ] 3. Correr la suite `pwsh -NoProfile -File tests/ejecutar.ps1`.
- [ ] 4. Pegar en `## Evidencia` los primeros 3 bytes de cada archivo tocado.
- [ ] 5. Commit con tipo `docs` y trailer `Spec-ID: odd-regla-sin-bom`, aparte del commit de este documento.

## Criterios de aceptación
- CA1: la regla 5 del fragmento y de las 6 copias regeneradas termina con la oración nueva, y la cantidad y los títulos de las 8 reglas no cambian — Evidencia esperada: diff y `git grep -c "que no pueden ser"` con 1 por archivo.
- CA2: `generar-plantillas.ps1 -Comprobar` termina con 0 y la suite está en verde — Evidencia esperada: salida de consola.
- CA3: ninguno de los archivos tocados tiene BOM — Evidencia esperada: primeros 3 bytes de cada archivo.

## Evidencia
<la completa el Agente: por tarea y por criterio>

## Progreso
2026-11-14: documento redactado — Claude.

## Próximo paso
Ejecutá en el Agente: `/odd-apply regla-sin-bom`.
