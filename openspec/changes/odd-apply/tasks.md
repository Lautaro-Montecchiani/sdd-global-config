# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1`. Cada test lleva `# test-plan: odd-apply/<ID>` arriba del `Probar`. Los commits de código no incluyen `openspec/`. El cambio a `.claude/CLAUDE.md` va en un commit separado con la descripción del impacto. Nada de `templates/antigravity/skills/`, `templates/cursor/commands/`, `templates/copilot/prompts/` ni `.claude/commands/` se edita a mano: se regenera con `pwsh scripts/generar-plantillas.ps1`. Tipos de commit: `feat`, `fix`, `chore`, `refactor`, `docs` o `test`. No cambies la cuenta activa de `gh`.

Antes de empezar: el ODD `reglas-agente-evidencia-commits` tiene que estar mergeado en `master` y esta rama rebasada sobre `master`. Si no lo está, frená y avisá.

## 1. Caracterización

- [x] 1.1 C01 a C03: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada. Verificación: salida en verde pegada.

## 2. Tests (test primero)

- [x] 2.1 Test primero, S01 a S04, S10 y S12 en `tests/odd-apply.Tests.ps1` (archivo nuevo, con `. "$PSScriptRoot/apoyo.ps1"`), con los textos de D1 a D3 y D5 de `design.md`. Verificación: fallan con el código actual (salida en rojo pegada).
- [x] 2.2 Test primero, S05 a S09 en `tests/odd-apply.Tests.ps1`, con carpetas temporales como `tests/instalar.Tests.ps1` y `tests/sincronizar-proyecto.Tests.ps1`. Verificación: fallan con el código actual (salida en rojo pegada).
- [x] 2.3 S11: sumar `# test-plan: odd-apply/S11` arriba de los tests de `tests/clasificacion-odd.Tests.ps1` que cubren la sección `## Handoff ODD` (solo el comentario). Verificación: siguen en verde.

## 3. Fuente y generación

- [x] 3.1 En `templates/fuente/fragmentos/handoff-odd.md`: aplicar D3 de `design.md` (reemplazar una viñeta por dos).
- [x] 3.2 Crear `templates/fuente/comandos-agente/odd-apply/` con `cuerpo.md` (D2, que incluye `<!-- incluir: handoff-odd -->`) y los encabezados `antigravity.md`, `cursor.md` y `copilot.md` (D1).
- [x] 3.3 En `scripts/generar-plantillas.ps1`: generar los tres archivos de D1 y compararlos en `-Comprobar`. Correr `pwsh scripts/generar-plantillas.ps1`. Verificación: S01 a S03 y S10 en verde y `-Comprobar` con código 0.

## 4. Instalación

- [x] 4.1 En `scripts/instalar.ps1`: aplicar D4 (item de la skill de Antigravity). Verificación: S05 y S06 en verde y `tests/instalar.Tests.ps1` en verde sin modificarlo.
- [x] 4.2 En `scripts/sincronizar-proyecto.ps1`: aplicar D4 (dos destinos). Verificación: S07 a S09 en verde y `tests/sincronizar-proyecto.Tests.ps1` en verde sin modificarlo.

## 5. Handoff y documentación

- [x] 5.1 En `skills/odd-change/SKILL.md`: aplicar D5 (línea de handoff y paso de "falta en el alcance"). Regenerar con `pwsh scripts/generar-plantillas.ps1`. Verificación: S12 en verde.
- [x] 5.2 En `templates/README.md`: columna "Comando ODD" en la matriz, con las fuentes de `## Context` del design. En `templates/copilot/README.md`: nota sobre `chat.promptFiles`. Verificación: S04 en verde.
- [x] 5.3 En `docs/workflow.md` y `docs/modo-de-uso.md`: el flujo ODD nombra `/odd-apply <nombre>`. En `docs/arquitectura/vision.md`, `## Hoja de ruta`: sumar "[baja] Antigravity puede mudar las skills a `~/.gemini/antigravity-cli/skills/` — origen: odd-apply — propuesta: cambiar la ruta de `instalar.ps1` cuando pase".
- [x] 5.4 En `.claude/CLAUDE.md`, "### Flujo ODD resumido", paso 2: nombrar `/odd-apply <nombre>` como comando del Agente. No tocar el bloque generado de reglas. Commitear solo este archivo con `docs: comando /odd-apply en el flujo ODD`, una línea de impacto y `Spec-ID: odd-apply`. Verificación: `-Comprobar` con código 0.

## 6. Cierre

- [x] 6.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S12).
- [x] 6.2 Revisión de seguridad del diff: búsqueda de `C:\Users` y de tokens en las líneas agregadas fuera de `openspec/`. Verificación: salida sin coincidencias, pegada.
- [x] 6.3 M01 (manual, LO CORRE EL USUARIO: no la simules ni la marques vos): verificar que el cambio aplica en un proyecto de prueba con los pasos de M01 del `## Test Plan`. Dejala `[ ]` y pedile al usuario la evidencia en el resumen.
  - Evidencia (13/11/2026, corrida por el usuario en Antigravity): `instalar.ps1` desde la rama dejó `.gemini/skills/odd-apply/SKILL.md` (`-Comprobar` sin diferencias). Corrida 1 en sdd-global-config, sin ODD abierto: los tres controles de arranque fallaron y el Agente frenó sin tocar archivos; informó el skill cargado desde `~/.gemini/skills/odd-apply/SKILL.md`. Corrida 2 en un repo descartable con el ODD `corregir-typo` abierto: commit `e113103 docs: corregir nombre de Claude en README` con trailer `Spec-ID: odd-corregir-typo`, diff limitado a `README.md` y al documento (respetó la exclusión de acentos), evidencia en `## Evidencia`, `estado: listo-para-verify` y sin nota `apply\` en el vault. `/odd:verify corregir-typo` aprobó sin CRITICAL (commit `3051d36`).

## 7. Ajustes después del PR (hechos por Claude a pedido del usuario)

- [x] 7.1 Sincronizar el repo con Copilot (`sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot`): el CI fallaba en `-Comprobar` porque faltaba `.github/prompts/odd-apply.prompt.md` y `.github/copilot-instructions.md` estaba atrasado. Evidencia: `-Comprobar` → "Todos los archivos están al día" (exit 0); `generar-plantillas.ps1 -Comprobar` → OK; `tests/ejecutar.ps1` → exit 0.
- [x] 7.2 README: `/odd-apply` en el flujo ODD, archivos del comando en "Qué contiene" y en "Plantillas del Agente" (`comandos-agente/`, `comandos/`, `handoff-odd.md`), cómo llega el comando a cada agente, skills `arquitectura` y `ficha`, y bloque de setup de Copilot. Evidencia: diff de `README.md`.
- [x] 7.3 Sacar de `templates/fuente/comandos-agente/odd-apply/cuerpo.md` la sección "Frenos durante la implementación", que repetía las dos viñetas del fragmento `handoff-odd`; queda una línea con lo que el fragmento no dice ("no commitees a medias", D2 punto 6). Regenerar y resincronizar el repo con Copilot. Evidencia: `generar-plantillas.ps1 -Comprobar` → OK; `sincronizar-proyecto.ps1 -Agentes copilot -Comprobar` → al día; `tests/ejecutar.ps1` → 93 OK, 0 fallas; la skill generada nombra "escalar a SDD" solo en el fragmento y en la línea nueva.
