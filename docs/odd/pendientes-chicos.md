---
tipo: odd
nombre: pendientes-chicos
creado: 2026-11-13
estado: abierto
branch: odd/pendientes-chicos
---

## Objetivo
Que el comando de `## Tests` corra los mismos controles que el CI, que no quede ningún test de migración con copias viejas y que la línea de sugerencia de `/arquitectura` se vea entera en el Markdown.

## Problema
- **Verify sin los controles del CI:** `tests/ejecutar.ps1`, el comando de `## Tests`, no corre `generar-plantillas.ps1 -Comprobar` ni `sincronizar-proyecto.ps1 -Agentes copilot -Comprobar`. Por eso el verify de `reglas-agente-evidencia-commits` y el de `odd-apply` no vieron el prompt de Copilot atrasado en el repo, y el CI falló recién en el PR #48.
- **Test de migración con copia vieja:** C02 de `tests/clasificacion-odd.Tests.ps1` compara `.github/workflows/pr-check.yml` con la copia guardada en `tests/datos/pr-check-antes.yml`. Se rompe con cualquier cambio intencional al workflow, igual que el C01 de `generar-plantillas` que ya se retiró.
- **Sugerencia cortada:** la línea `Sugerencia: corré /arquitectura …` se escribe entre comillas invertidas simples y tiene comillas invertidas adentro (`/arquitectura`, `## Arquitectura`, `nivel`). El Markdown cierra el código en la primera comilla interna y la línea se ve cortada.

## Alcance
- Incluye:
  - `tests/ejecutar.ps1` corre los dos `-Comprobar` después de los tests.
  - Retirar C02 y `tests/datos/pr-check-antes.yml`.
  - Envolver la línea de sugerencia con comillas invertidas dobles donde está en línea (no dentro de bloques de código).
- No incluye: cambiar el texto de la sugerencia, la spec `architecture-advisor`, el workflow del CI ni los tests que usan `git show` para probar la detección de versiones viejas (`instalar.Tests.ps1` S07 y S11, `sincronizar-proyecto.Tests.ps1` S15 y S17).
- Cambio de spec: ninguno.
- Archivos permitidos:
  - `tests/ejecutar.ps1`
  - `tests/clasificacion-odd.Tests.ps1`
  - `tests/datos/pr-check-antes.yml` (se borra, y la carpeta `tests/datos/` si queda vacía)
  - `.claude/CLAUDE.md`
  - `skills/openspec-propose/SKILL.md`, `skills/openspec-verify-change/SKILL.md`, `skills/openspec-archive-change/SKILL.md`
  - `.claude/commands/opsx/propose.md`, `.claude/commands/opsx/verify.md`, `.claude/commands/opsx/archive.md` (solo regenerados)

## Clasificación
ODD. K1 no (no cambia specs: la línea de sugerencia conserva el mismo texto, solo cambian las comillas que la envuelven); K2 y K3 no (no toca datos ni seguridad); K4 no (sin dependencias); K5 no (`tests/ejecutar.ps1` es un script interno de tests; no cambian flags de los scripts públicos); K6 no; K8 no (el qué está definido); K10 no (no hay decisión de arquitectura).
**K7 pasado por alto a pedido del usuario (13/11/2026):** sin contar tests ni documentación, toca 7 archivos (`.claude/CLAUDE.md`, 3 skills y sus 3 comandos generados), pero el cambio en cada uno son solo las comillas de una línea.

## Checklist
- [ ] 1. En `tests/ejecutar.ps1`, después del bucle de tests y antes de decidir el código de salida: correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1 -Comprobar` y `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto <raíz del repo> -Agentes copilot -Comprobar` (con la raíz del repo resuelta desde `$PSScriptRoot/..`), mostrar su salida y una línea `OK <control>` o `FALLA <control>` por cada uno, con el mismo formato que los tests, y marcar `$huboFalla` si alguno termina con código distinto de 0. Mantener el `HOME`, `USERPROFILE` y `OBSIDIAN_VAULT` temporales solo para los tests, como ahora.
- [ ] 2. En `tests/clasificacion-odd.Tests.ps1`: borrar el test C02 (marcador `test-plan: clasificacion-odd-sdd/C02`), la variable `$antesPrCheck` y la función `Quitar-PasoCheckBranch` si queda sin uso. Borrar `tests/datos/pr-check-antes.yml` y la carpeta `tests/datos/` si queda vacía.
- [ ] 3. Envolver con comillas invertidas dobles (con un espacio adentro de cada lado, por ejemplo `` `` Sugerencia: corré `/arquitectura` … `` ``) cada aparición en línea de la línea de sugerencia, sin cambiar su texto:
  - `.claude/CLAUDE.md`, sección "Al iniciar cada sesión", paso 4. Commit aparte que solo toque este archivo, con una línea de impacto.
  - `skills/openspec-propose/SKILL.md` (Architecture suggestion D1).
  - `skills/openspec-verify-change/SKILL.md` (las dos viñetas de "Sugerencias de arquitectura", en el método con Test Plan y en el legacy).
  - `skills/openspec-archive-change/SKILL.md`, paso e de la fase del vault. La línea del bloque de código de "Output On Success" no se toca.
  - Regenerar los comandos con `pwsh scripts/generar-plantillas.ps1`.
- [ ] 4. Correr `pwsh -NoProfile -File tests/ejecutar.ps1` completo.

## Criterios de aceptación
- CA1: `tests/ejecutar.ps1` corre los dos controles y termina en 0 con el repo al día — Evidencia esperada: final de la salida con las líneas `OK` de los dos controles y el código de salida 0.
- CA2: si un archivo generado está atrasado, `tests/ejecutar.ps1` falla — Evidencia esperada: salida con una línea `FALLA` y código de salida 1 después de agregar una palabra a mano en `templates/cursor/commands/odd-apply.md`; después, `git restore` de ese archivo (el cambio de prueba no se commitea).
- CA3: no queda C02 ni la copia vieja — Evidencia esperada: búsqueda de `pr-check-antes` y de `clasificacion-odd-sdd/C02` en `tests/` sin coincidencias.
- CA4: la línea de sugerencia ya no está envuelta en comillas invertidas simples — Evidencia esperada: búsqueda de `` `Sugerencia: corré ` `` (comilla simple de apertura pegada) en `.claude/CLAUDE.md` y `skills/` sin coincidencias en línea; `tests/sugerir-arquitectura.Tests.ps1` en verde y `generar-plantillas.ps1 -Comprobar` con código 0.
- CA5: el diff contra `master` solo toca los archivos permitidos y este documento — Evidencia esperada: `git diff --stat master...HEAD`.

## Evidencia

## Progreso
2026-11-13: documento redactado — Claude

## Próximo paso
Ejecutá en el Agente: `/odd-apply pendientes-chicos`.
