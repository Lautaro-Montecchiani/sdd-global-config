# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1`. Cada test nuevo o reutilizado lleva `# test-plan: reglas-fuente-unica-y-carga-desde-vault/<ID>`. Los commits de código no incluyen `openspec/`. El cambio a `.claude/CLAUDE.md` va en un commit separado de los scripts, con la descripción del impacto.

## 1. Preparación

- [ ] 1.1 M01 (manual, antes de escribir código): probar el import `@` con los pasos de M01 del `## Test Plan` de `design.md`, usando la ruta real de `$env:OBSIDIAN_VAULT`. Verificación: respuesta de Claude Code con la frase única pegada en el resumen del apply, y los dos archivos de prueba borrados. Si Claude no ve la frase, frenar y avisar: no seguir con el grupo 3.
- [ ] 1.2 C01 a C04: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada. Verificación: salida en verde pegada en el resumen.

## 2. Parte 1: bloque de reglas generado (`scripts/generar-plantillas.ps1`)

- [ ] 2.1 Test primero, S01, S02 y S03 en `tests/generar-plantillas.Tests.ps1`: bloque generado desde el fragmento, resto del archivo sin cambios y marcas faltantes (ninguna plantilla, comando ni `CLAUDE.md` cambia). Usar `Copiar-EntornoTemporal`. Verificación: los tres fallan con el código actual (salida en rojo pegada).
- [ ] 2.2 Test primero, S21 y S31 en `tests/generar-plantillas.Tests.ps1`: S21 es un test nuevo que cambia una palabra del cuerpo de la regla 4 dentro del bloque y espera código distinto de 0 y `.claude/CLAUDE.md` en la salida. S31 ajusta el test `sincronizar-reglas/S04`: sigue cambiando el título y esperando código distinto de 0, y su afirmación sobre la salida pasa a exigir `.claude/CLAUDE.md` (cambio intencional de C01). Verificación: los dos fallan con el código actual (salida en rojo pegada).
- [ ] 2.3 En `.claude/CLAUDE.md`, sección `### Reglas de ejecución del Agente`: aplicar D10 a de `design.md` (línea de introducción, marcas `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->` alrededor de las 8 reglas y última oración del párrafo "Distribución a agentes no-Claude"). Verificación: las dos marcas aparecen una vez cada una.
- [ ] 2.4 En `scripts/generar-plantillas.ps1`: implementar D1, D2 y D3 (validar marcas en memoria, escribir el bloque, comparar el texto completo en `-Comprobar` y quitar la comparación de títulos). Verificación: S01, S02, S03, S21 y S31 en verde.
- [ ] 2.5 Correr `pwsh scripts/generar-plantillas.ps1` para que el bloque de `.claude/CLAUDE.md` quede igual a `templates/fuente/fragmentos/reglas-ejecucion.md`. Verificación: `pwsh scripts/generar-plantillas.ps1 -Comprobar` termina con código 0 y `git diff --stat` no muestra cambios en `templates/comun/`, `templates/copilot/`, `templates/cursor/` ni `templates/antigravity/`.
- [ ] 2.6 C03 en `tests/clasificacion-odd.Tests.ps1`, test `clasificacion-odd-sdd/S20`: la afirmación sobre la regla 7 de `.claude/CLAUDE.md` pasa a usar `$oracionAgente`. No tocar las demás afirmaciones. Verificación: el archivo de tests completo en verde.
- [ ] 2.7 Agregar el marcador de S18 y S22 a los tests existentes `sincronizar-reglas/S03` y `sincronizar-reglas/S05` de `tests/generar-plantillas.Tests.ps1`, y el de S19 y S20 a los tests "S07 comando editado a mano…" y "S08 skill editada sin regenerar…" de `tests/generar-comandos.Tests.ps1` (solo el comentario). Verificación: suite completa en verde.

## 3. Parte 2: carga desde el vault y protección del espejo (`scripts/instalar.ps1`)

- [ ] 3.1 Test primero, S04 a S07 en `tests/instalar.Tests.ps1`: archivo de carga con vault, copia completa con `-SinVault`, ruta del vault con espacios y copia completa anterior que pasa a archivo de carga (tomar una versión anterior de `.claude/CLAUDE.md` con `git log` y `git show`). Todos con `-Destino` y `-Vault` en carpetas temporales. Verificación: S04, S06 y S07 fallan con el código actual (salida en rojo pegada); S05 puede pasar de entrada porque fija lo que no cambia, y se anota.
- [ ] 3.2 Test primero, S08 a S12 en `tests/instalar.Tests.ps1`: espejo ya igual (sin commit nuevo), editado a mano (nada cambia en vault ni destino), `-Forzar` con respaldo, espejo atrasado y repo atrasado (encabezado con `commit: 0000000` y cuerpo distinto, con `-Forzar`). Verificación: fallan con el código actual (salida en rojo pegada).
- [ ] 3.3 Test primero, S13 a S15 en `tests/instalar.Tests.ps1`: `-Comprobar` con instalación al día, con espejo distinto y con destino vacío. Verificación: fallan con el código actual (salida en rojo pegada).
- [ ] 3.4 En `scripts/instalar.ps1`: implementar D4 a D9 de `design.md` (contenido esperado del `CLAUDE.md` según haya vault, espejo armado desde el repo con el encabezado nuevo, clasificación del espejo antes de escribir, orden de escritura, parámetro `-Comprobar` y resolución del vault). Reusar `Normalizar-Texto`, `Obtener-HashNormalizado`, `Test-EsVersionGitHistorica`, `Respaldar-Archivos` y `Escribir-ArchivoUtf8SinBom` de `scripts/comun.ps1`; si hace falta una función compartida nueva, va en `scripts/comun.ps1`. Actualizar la línea de uso del encabezado del script. Verificación: S04 a S15 en verde.
- [ ] 3.5 S29 y S30 en `tests/instalar.Tests.ps1`: ampliar `sincronizar-reglas/S11` (el espejo nombra al repo como fuente, tiene `commit:` y el commit del vault incluye solo `_global/reglas-globales.md`) y `sincronizar-reglas/S12` (el `CLAUDE.md` instalado es la copia completa). No aflojar las afirmaciones existentes. Verificación: ambos en verde.
- [ ] 3.6 Agregar el marcador de S24 a S28 a los tests existentes `sincronizar-reglas/S06` a `S10` de `tests/instalar.Tests.ps1`. Verificación: `tests/instalar.Tests.ps1` completo en verde.

## 4. Texto de las reglas y guías

- [ ] 4.1 Test primero, S16 y S17 en `tests/instalar.Tests.ps1`: leen `.claude/CLAUDE.md`, `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` y afirman lo que dicen los escenarios del requirement "El repo como fuente única de las reglas". Verificación: fallan con el texto actual (salida en rojo pegada).
- [ ] 4.2 En `.claude/CLAUDE.md`: aplicar D10 b, c, d, e, f y g de `design.md` con el texto exacto. No tocar el bloque entre marcas. Verificación: S16 en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [ ] 4.3 En `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`: aplicar D11 de `design.md`. Verificación: S17 en verde.

## 5. Arquitectura

- [ ] 5.1 Crear `docs/adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md` con el contenido del bloque de código de `## ADR` del `design.md`. Verificación: el archivo existe y empieza con `# 0002.`.
- [ ] 5.2 Cambiar `Estado:` de `docs/adr/0001-fuente-unica-de-reglas-con-powershell.md` a `reemplazada por 0002`. Verificación: `git diff` muestra solo esa línea.
- [ ] 5.3 Actualizar `docs/arquitectura/vision.md`. En `## Componentes`, la línea de `.claude/CLAUDE.md` pasa a: "`.claude/CLAUDE.md`: reglas globales y única fuente donde se editan. Su bloque de reglas de ejecución del Agente se genera desde `templates/fuente/`. Se espeja en el vault, de donde lo leen Claude y el Agente; en `~/.claude/CLAUDE.md` se instala un archivo de carga (o la copia completa si no hay vault)." En `## Decisiones vigentes`, reemplazar la línea del 0001 por `- [0002. Reglas en una sola fuente y carga de Claude desde el vault](../adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md)`. En `## Hoja de ruta`, quitar la línea "las reglas del Agente siguen escritas dos veces…" y agregar: `- [media] las reglas llegan a otra máquina con el pull del vault, pero las skills y los comandos solo con instalar.ps1; pueden quedar desparejos — origen: ADR 0002 — propuesta: evaluar distribuir skills y comandos por el mismo camino que las reglas` y `- [baja] en este repo .claude/CLAUDE.md se carga dos veces en Claude (global y de proyecto) — origen: reglas-fuente-unica-y-carga-desde-vault — propuesta: evaluar mover la copia versionada fuera de .claude/ del repo`. Verificación: `git diff docs/arquitectura/vision.md` muestra solo esas líneas.

## 6. Integración

- [ ] 6.1 Correr `pwsh -NoProfile -File tests/ejecutar.ps1`, `pwsh scripts/generar-plantillas.ps1 -Comprobar` y `pwsh scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`. Verificación: las tres salidas con código 0 pegadas en el resumen.
- [ ] 6.2 S23 (manual): confirmar con `git diff master -- .github/workflows/plantillas.yml` que el workflow no cambió. Verificación: salida vacía pegada.
- [ ] 6.3 Security Layer (manual): buscar `C:\Users`, `D:\`, `Invoke-Expression` e `iex` en `scripts/`, `tests/`, `templates/`, `.claude/CLAUDE.md` y `docs/adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md`. Verificación: sin resultados nuevos respecto de `master` (salida pegada).
- [ ] 6.4 En la máquina real: correr `pwsh scripts/instalar.ps1 -Simular`, revisar la tabla, y después `pwsh scripts/instalar.ps1` y `pwsh scripts/instalar.ps1 -Comprobar`. Verificación: `~/.claude/CLAUDE.md` es el archivo de carga, el espejo del vault tiene el encabezado nuevo y `-Comprobar` termina con código 0 (salidas pegadas, con la ruta del vault reemplazada por `<DATO OMITIDO>` si incluye un nombre de usuario).
- [ ] 6.5 Verificar que el cambio aplica en un proyecto de prueba (M02): abrir Claude Code en otro proyecto y pedirle que cite la regla 3 de ejecución del Agente y el título de la primera sección de las reglas. Verificación: respuesta pegada en el resumen; la regla 3 es la del fragmento.

## Workflow follow-up

- Abrir el PR con `/branch-pr` y correr `/opsx:verify reglas-fuente-unica-y-carga-desde-vault`.
- Después del merge: `/opsx:archive`, regenerar el SRS y correr `pwsh scripts/instalar.ps1` en cada máquina.
