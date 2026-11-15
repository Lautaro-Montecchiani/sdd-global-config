---
tipo: odd
nombre: regla-sin-bom
creado: 2026-11-14
estado: listo-para-verify
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
- [x] 1. En `templates/fuente/fragmentos/reglas-ejecucion.md`, agregar al final de la regla 5, después de «si un push o un PR falla por permisos, frená y avisá.», la oración: «Todo archivo nuevo o modificado va en UTF-8 sin BOM y conserva sus finales de línea; en el resumen del apply pegá los primeros 3 bytes de cada archivo tocado, que no pueden ser `EF BB BF`.»
- [x] 2. Correr `pwsh scripts/generar-plantillas.ps1` y después `pwsh scripts/generar-plantillas.ps1 -Comprobar`.
- [x] 3. Correr la suite `pwsh -NoProfile -File tests/ejecutar.ps1`.
- [x] 4. Pegar en `## Evidencia` los primeros 3 bytes de cada archivo tocado.
- [x] 5. Commit con tipo `docs` y trailer `Spec-ID: odd-regla-sin-bom`, aparte del commit de este documento.

## Criterios de aceptación
- CA1: la regla 5 del fragmento y de las 6 copias regeneradas termina con la oración nueva, y la cantidad y los títulos de las 8 reglas no cambian — Evidencia esperada: diff y `git grep -c "que no pueden ser"` con 1 por archivo.
- CA2: `generar-plantillas.ps1 -Comprobar` termina con 0 y la suite está en verde — Evidencia esperada: salida de consola.
- CA3: ninguno de los archivos tocados tiene BOM — Evidencia esperada: primeros 3 bytes de cada archivo.

## Evidencia

### CA1: Regla 5 en el fragmento y en las 6 copias regeneradas

Salida de `git grep -c "que no pueden ser"`:
```
.claude/CLAUDE.md:1
.github/copilot-instructions.md:1
docs/odd/regla-sin-bom.md:2
templates/antigravity/GEMINI.md:1
templates/comun/AGENTS.md:1
templates/copilot/copilot-instructions.md:1
templates/cursor/sdd-workflow.mdc:1
templates/fuente/fragmentos/reglas-ejecucion.md:1
```

Diff del commit `e50174f` (`git show --stat e50174f`):
```
 .claude/CLAUDE.md                               | 2 +-
 .github/copilot-instructions.md                 | 2 +-
 templates/antigravity/GEMINI.md                 | 2 +-
 templates/comun/AGENTS.md                       | 2 +-
 templates/copilot/copilot-instructions.md       | 2 +-
 templates/cursor/sdd-workflow.mdc               | 2 +-
 templates/fuente/fragmentos/reglas-ejecucion.md | 2 +-
 7 files changed, 7 insertions(+), 7 deletions(-)
```

Línea agregada en la regla 5 de cada archivo:
```markdown
Todo archivo nuevo o modificado va en UTF-8 sin BOM y conserva sus finales de línea; en el resumen del apply pegá los primeros 3 bytes de cada archivo tocado, que no pueden ser `EF BB BF`.
```

Los títulos y la cantidad de las 8 reglas se conservan idénticos.

### CA2: Comprobación de plantillas y suite de tests en verde

Salida de `pwsh scripts/generar-plantillas.ps1 -Comprobar`:
```
OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados.
```
Código de salida: `0`.

Salida de `pwsh -NoProfile -File tests/ejecutar.ps1`:
```
OK S01 texto de K2 en CLAUDE.md, skill y comandos
OK S04 guías tienen versión corta de K2 y visión no contiene la deuda
OK S01 Proyecto al día
...
OK S01 Marca de tareas del usuario en el propose / Marca en las tareas del usuario
OK S02 Control de tareas del usuario en el verify / Tarea del usuario marcada y confirmada
OK S03 Control de tareas del usuario en el verify / Tarea del usuario marcada por el Agente
OK S04 Control de tareas del usuario en el verify / Evidencia del usuario en el verify
OK S05 Control de tareas del usuario en el verify / Verify sin interfaz interactiva
OK S06 Control de tareas del usuario en el verify / Dato inválido: marca escrita de otra forma
OK S07 Regla 1 con tareas del usuario / Regla en la fuente y en lo generado
OK S08 Regla 1 con tareas del usuario / Pedido del usuario
OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados.
OK scripts/generar-plantillas.ps1 -Comprobar
Sincronización en proyecto: C:\Users\Lautaro\sdd-global-config

Archivo                             Estado
-------                             ------
.github/copilot-instructions.md     igual
.github/prompts/odd-apply.prompt.md igual
.github/workflows/pr-check.yml      igual


Comprobar: Todos los archivos están al día.
OK scripts/sincronizar-proyecto.ps1 -Proyecto C:\Users\Lautaro\sdd-global-config -Agentes copilot -Comprobar
```
Código de salida: `0` (suite completa en verde).

### CA3: Ninguno de los archivos tocados tiene BOM

Primeros 3 bytes de cada archivo tocado (en hexadecimal):
- `templates/fuente/fragmentos/reglas-ejecucion.md`: `31-2E-20` (caracteres `1. `)
- `.claude/CLAUDE.md`: `23-20-F0` (caracteres `# `)
- `.github/copilot-instructions.md`: `3C-21-2D` (caracteres `<!-`)
- `templates/antigravity/GEMINI.md`: `3C-21-2D` (caracteres `<!-`)
- `templates/comun/AGENTS.md`: `3C-21-2D` (caracteres `<!-`)
- `templates/copilot/copilot-instructions.md`: `3C-21-2D` (caracteres `<!-`)
- `templates/cursor/sdd-workflow.mdc`: `2D-2D-2D` (caracteres `---`)
- `docs/odd/regla-sin-bom.md`: `2D-2D-2D` (caracteres `---`)

Ningún archivo comienza con `EF-BB-BF`.

## Progreso
2026-11-14: documento redactado — Claude.
2026-11-14: tareas 1 a 5 completadas y evidenciadas, estado: listo-para-verify — Agente (Antigravity).

## Próximo paso
Claude corre `/odd:verify regla-sin-bom`.
