# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 minutos). Cada tarea de tests pega en el resumen del apply la salida en rojo (antes) y en verde (después). Ningún test escribe en el `$HOME` real ni en el vault real (design D7).

## 1. Infraestructura de tests y caracterización

- [x] 1.1 Crear `tests/apoyo.ps1` (funciones `Probar` y `Afirmar`, y una función que crea y borra una carpeta temporal por test) y `tests/ejecutar.ps1` (corre cada `tests/*.Tests.ps1` en un `pwsh -NoProfile` aparte con `HOME` y `OBSIDIAN_VAULT` en carpetas temporales vacías, imprime `OK <nombre>` o `FALLA <nombre>: <mensaje>` y termina con código 1 si alguno falla), según design D7. Evidencia: salida de `pwsh -NoProfile -File tests/ejecutar.ps1` con un test de ejemplo que pasa y otro que falla a propósito (después borrar los dos).
- [x] 1.2 C01, en verde antes de tocar las plantillas: copiar las cuatro plantillas actuales (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc`, `templates/antigravity/GEMINI.md`) a `tests/datos/plantillas-antes/` sin cambios, y escribir en `tests/generar-plantillas.Tests.ps1` el test `C01 plantillas sin cambios de texto` (marcador `# test-plan: sincronizar-reglas/C01`) que compara cada plantilla, sin la línea de aviso de archivo generado con su línea en blanco y sin el bloque final de `## Propio del proyecto` si existen, con su copia. Correr el comando de tests: verde. Evidencia: la salida.
- [x] 1.3 Commit aparte con los archivos de 1.1 y 1.2: `test: caracterización de las plantillas actuales`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`.

## 2. Fuente única y generación

- [x] 2.1 Test primero: en `tests/generar-plantillas.Tests.ps1`, los tests S01, S02, S03, S04, S05 y S21 de los escenarios de `specs/rules-sync/spec.md` ("Plantillas generadas desde una fuente única" y "Control de desincronización") y de `specs/agent-templates/spec.md` ("Aviso de archivo generado y sección propia"). Cada test copia `templates/`, `scripts/` y `.claude/CLAUDE.md` a una carpeta temporal y corre el script de la copia, para no tocar el repo. Correr el comando de tests: los seis en rojo y C01 en verde. Evidencia: la salida.
- [x] 2.2 Crear `templates/fuente/fragmentos/` (`aviso-vault.md`, `rol-constructor.md`, `reglas-ejecucion.md`, `git.md`, `memoria-proyecto.md`) y `templates/fuente/esqueletos/` (`AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc`, `GEMINI.md`) según design D1, con el texto copiado de las plantillas actuales sin cambiar palabras. Evidencia: `Get-ChildItem -Recurse templates/fuente` y la lista de marcas `<!-- incluir: ... -->` de cada esqueleto.
- [x] 2.3 Crear `scripts/comun.ps1` (design D5 y D6) y `scripts/generar-plantillas.ps1` (design D2, con `-Comprobar`). Evidencia: el comando de tests con S01 a S05 y S21 en verde.
- [x] 2.4 Correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1` para regenerar las cuatro plantillas del repo y después `-Comprobar`. Correr el comando de tests: C01, S01 a S05 y S21 en verde. Evidencia: las dos salidas, más `git diff --stat templates/`, donde cada plantilla suma solo las líneas del aviso y de `## Propio del proyecto`.
- [x] 2.5 Commit aparte con `templates/fuente/`, `scripts/comun.ps1`, `scripts/generar-plantillas.ps1`, las cuatro plantillas y `tests/generar-plantillas.Tests.ps1`: `feat: fuente única y generación de las plantillas del Agente`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`.

## 3. Instalación y sincronización

- [x] 3.1 Test primero: en `tests/instalar.Tests.ps1`, S06 a S12 (escenarios de "Instalación por máquina" y "Espejo del vault al instalar"); en `tests/sincronizar-proyecto.Tests.ps1`, S13 a S18 (escenarios de "Sincronización por proyecto"). Los tests usan un `-Destino` temporal, un vault de prueba con remote bare (`git init --bare`) y repos de prueba con commits hechos con `-c user.name` y `-c user.email` de prueba. Para S15, la versión vieja se toma con `git show` de un commit anterior de la plantilla en este repo. Correr el comando de tests: S06 a S18 en rojo. Evidencia: la salida.
- [x] 3.2 Crear `scripts/instalar.ps1` según design D3. Evidencia: S06 a S12 en verde.
- [x] 3.3 Crear `scripts/sincronizar-proyecto.ps1` según design D4. Evidencia: S13 a S18 en verde.
- [x] 3.4 Correr el comando de tests completo: todos en verde. Evidencia: la salida.
- [x] 3.5 Commit aparte con `scripts/instalar.ps1`, `scripts/sincronizar-proyecto.ps1` y sus tests: `feat: scripts de instalación y sincronización`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`.

## 4. CI

- [x] 4.1 Crear `.github/workflows/plantillas.yml` según design D8 (en `pull_request`, `actions/checkout@v4` con `fetch-depth: 0` y los tres pasos con `pwsh -NoProfile -File`). No tocar `.github/workflows/pr-check.yml`. Evidencia: el archivo y `git diff --stat .github/workflows/pr-check.yml` vacío (S19, parte del archivo).
- [x] 4.2 Commit aparte: `ci: tests y control de plantillas`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`.

## 5. Reglas globales y config

- [x] 5.1 En `.claude/CLAUDE.md`, aplicar design D9 ("Distribución a agentes no-Claude", "Onboarding de agentes no-Claude", "Orden completo ante un cambio de reglas" y la línea en "Sincronizar reglas globales al vault"). Sin cambiar el sentido de ninguna regla. Evidencia: `git diff .claude/CLAUDE.md`.
- [x] 5.2 En `openspec/config.yaml`: reemplazar `- comando: ninguno` de `## Tests` por `- comando: pwsh -NoProfile -File tests/ejecutar.ps1` y agregar `- timeout: 5`; agregar a `## Arquitectura` las líneas `- scripts/: generación de plantillas, instalación y sincronización (PowerShell 7)` y `- tests/: tests de los scripts`. Evidencia: `git diff openspec/config.yaml`.
- [x] 5.3 Correr `scripts/generar-plantillas.ps1 -Comprobar` (los títulos del `CLAUDE.md` siguen coincidiendo) y un script en archivo que busca `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en `scripts/`, `tests/`, `templates/` y `.claude/CLAUDE.md` (S20). Evidencia: las dos salidas, la segunda sin resultados. Después, commit aparte con `.claude/CLAUDE.md` y `openspec/config.yaml`: `feat: instalación con scripts en las reglas globales`. El cuerpo describe el impacto: las plantillas del Agente se generan desde `templates/fuente/`, la instalación y la sincronización de proyectos se hacen con scripts que frenan ante cambios locales, y el repo pasa a tener tests. Un único bloque final de trailers con `Spec-ID: sincronizar-reglas`.

## 6. Documentación, ADR y visión

- [x] 6.1 En `README.md`, aplicar design D10: setup con `pwsh scripts/instalar.ps1` (y `-Simular`), Antigravity con el mismo script, "Sumar un proyecto al workflow" con `sincronizar-proyecto.ps1`, sección "Plantillas del Agente", filas nuevas en "Qué contiene" y el párrafo de actualización de proyectos. Evidencia: el diff.
- [x] 6.2 En `docs/workflow.md` y `docs/modo-de-uso.md`, los mismos cambios en sus secciones equivalentes. Evidencia: el diff y la salida de S22, S23 y S24 (`Select-String` de `scripts/instalar.ps1` y `sincronizar-proyecto.ps1` en las tres guías, y ningún `cp` de `skills\`, `.claude\` ni de plantillas de reglas en esas secciones).
- [x] 6.3 En `templates/README.md` y los `README.md` de `templates/comun/`, `templates/copilot/`, `templates/cursor/` y `templates/antigravity/`: el archivo de reglas se genera desde `templates/fuente/` y se instala con los scripts. Evidencia: el diff.
- [x] 6.4 Crear `docs/adr/0001-fuente-unica-de-reglas-con-powershell.md` con el contenido del bloque de código `markdown` de `## ADR` del design, sin cambios. Evidencia: un script en archivo que compara el archivo con el bloque, sin diferencias (S26).
- [x] 6.5 Crear `docs/arquitectura/vision.md` con el contenido del bloque de código `markdown` de `## Visión inicial` del design, sin cambios. Evidencia: el mismo script de 6.4 para este archivo, sin diferencias (S26).
- [x] 6.6 Commit aparte con los archivos de 6.1 a 6.5: `docs: scripts de instalación y sincronización en las guías, ADR y visión`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`.

## 7. Este repo, instalación y prueba

- [x] 7.1 Correr `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot` (design D11). Si da `bloqueado`, pegar `git diff --no-index templates/copilot/copilot-instructions.md .github/copilot-instructions.md` y confirmar que la copia del repo no tiene contenido que no esté en la plantilla; recién entonces correr con `-Forzar`. Después, `-Comprobar` con código 0 (S25). Commit aparte con `.github/copilot-instructions.md`: `chore: sincronizar copilot-instructions del repo`, con un único bloque final de trailers que incluya `Spec-ID: sincronizar-reglas`. Evidencia: las salidas y el commit.
- [x] 7.2 Instalar en la máquina: `pwsh -NoProfile -File scripts/instalar.ps1 -Simular` y, si no hay archivos `con cambios locales`, `pwsh -NoProfile -File scripts/instalar.ps1`. Si hay cambios locales, **frenar y preguntar** (no usar `-Forzar` sin confirmación del usuario). **No cambiar la cuenta activa de `gh`**: si el push del vault falla por la cuenta, avisar. Evidencia: las dos tablas y el commit del vault (`git -C $env:OBSIDIAN_VAULT log --oneline -1`).
- [x] 7.3 Verificar que el cambio aplica en un proyecto de prueba: en una carpeta temporal, crear un repo git con un `AGENTS.md` igual a una versión anterior de la plantilla y un `.github/copilot-instructions.md` con una línea propia agregada, y correr `sincronizar-proyecto.ps1 -Proyecto <carpeta>`: el primero queda `actualizado`, el segundo `bloqueado`, el código de salida es 1 y el repo de prueba no tiene commits nuevos. Mover la línea propia debajo de `## Propio del proyecto` del archivo generado (copiándolo desde la plantilla) y volver a correr: los dos `igual` o `actualizado`, la línea propia conservada y código 0. Borrar la carpeta temporal. Evidencia: las dos salidas.

## Workflow follow-up

- Issue #35.
- Abrir PR `[sincronizar-reglas] Fuente única de reglas del Agente y scripts de instalación y sincronización` desde `change/sincronizar-reglas`, con `Closes #35`. El check "plantillas" del PR tiene que pasar (S19).
- `/opsx:verify sincronizar-reglas` antes del merge, en una sesión interactiva, y `/opsx:archive` después.
- Al retomar `clasificacion-odd-sdd` (#32): rebasar sobre `master`, cambiar sus tareas de plantillas para que editen `templates/fuente/` y regeneren, reemplazar sus tareas de instalación por `scripts/instalar.ps1`, y cambiar su `## Visión inicial` por una actualización de `docs/arquitectura/vision.md`.
