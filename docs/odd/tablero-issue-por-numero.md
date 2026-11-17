---
tipo: odd
nombre: tablero-issue-por-numero
creado: 2026-11-17
estado: listo-para-verify
branch: odd/tablero-issue-por-numero
---

## Objetivo
`scripts/tablero.ps1 -Issue` acepta el número del issue además de la URL: con `-Issue 75` mueve la tarjeta del issue #75 del repo de la carpeta actual, igual que con la URL completa.

## Problema
Hoy `tablero.ps1` solo reconoce el issue si recibe la URL completa, porque saca el número con `/issues/(\d+)` (línea 300). Con `-Issue 75` no encuentra la tarjeta aunque ya esté en el Project, y le pasa `75` tal cual a `gh project item-add --url 75`, que falla. Las skills no lo sufren porque le pasan la URL (`gh issue view <NN> --json url`), pero a mano es lo primero que uno escribe: pasó el 17/11/2026 al agregar #75 y #74 al tablero.

## Alcance
- Incluye: si `-Issue` es solo un número (por ejemplo `75`), `tablero.ps1` arma la URL `https://github.com/<owner>/<repo>/issues/75` con el remoto `origin` de la carpeta actual (`git remote get-url origin`), aceptando la forma HTTPS (`https://github.com/<owner>/<repo>.git`, con o sin `.git`) y la forma SSH (`git@github.com:<owner>/<repo>.git`), y sigue igual que con una URL. Si `-Issue` no es una URL de issue de GitHub ni un número, o es un número en una carpeta sin remoto `origin` de GitHub, avisa en una línea y termina con 1 sin llamar a `gh`.
- No incluye: consultar el issue a GitHub (`gh issue view`) para validar que existe; cambiar cómo las skills llaman al script (siguen pasando la URL); cambiar `-Wip`, `-Comprobar`, `-Columna` ni el formato de `tablero.md`.
- Cambio de spec: `scrumban-board` — «Mover la tarjeta de un issue» (`-Issue <url o número>`, más dos escenarios).
- Archivos permitidos: `scripts/tablero.ps1`, `tests/tablero-scrumban.Tests.ps1`, `docs/odd/tablero-issue-por-numero.md`.

## Clasificación
ODD con cambio mínimo de spec: modifica un requirement existente de una sola capability (`scrumban-board`), así que no cumple K1. No cumple K2: la URL se arma con el remoto local, sin leer datos nuevos de GitHub (los issues están declarados como dato externo). No toca autenticación, permisos ni secretos (K3), no suma dependencias (K4), no mueve código entre capas (K6), toca un solo archivo de código más su test (K7) y no hay decisión de arquitectura (K10). El "qué" está claro (K8).
K5 (contrato de CLI) quedó en duda, porque `-Issue` pasa a aceptar un valor nuevo: ante la duda cuenta como cumplido. Se pasa por alto a pedido del usuario (17/11/2026, "sin issue, arrancá el odd"). El cambio es compatible hacia atrás: una URL sigue funcionando igual.

## Checklist
- [x] 1. Test primero en `tests/tablero-scrumban.Tests.ps1`: sumar al final dos `Probar` con su marcador `# test-plan: odd-tablero-issue-por-numero/<ID>`, usando una carpeta temporal con `git init` y `git remote add origin <url inventada>` como carpeta actual al correr `tablero.ps1` (con `-Config` y `-Entrada` como S04):
  - S22 «Mover la tarjeta de un issue / Issue por número»: con `origin` `https://github.com/org/repo.git`, `-Issue 10 -Columna backlog` termina con 0, imprime `item-add` con `https://github.com/org/repo/issues/10` y `#10 → Backlog`; con `origin` `git@github.com:org/repo.git` imprime la misma URL.
  - S23 «Mover la tarjeta de un issue / Dato inválido: issue que no es URL ni número»: `-Issue abc` termina con 1, imprime una línea que nombra `-Issue` y no imprime `item-add`; `-Issue 10` en una carpeta sin remoto `origin` termina con 1 y no imprime `item-add`.
  Correrlos contra el código actual: tienen que fallar. Commit: `test: S22 y S23 de tablero-scrumban con el issue por número`, con `Spec-ID: odd-tablero-issue-por-numero`.
- [x] 2. En `scripts/tablero.ps1`: antes de buscar la tarjeta, si `$Issue` es solo dígitos, armar la URL con el remoto `origin` (HTTPS o SSH de `github.com`); si no es una URL de issue de GitHub ni un número, o no hay remoto de GitHub, avisar en una línea sin rutas absolutas y terminar con 1, sin llamar a `gh`. El resto del script no cambia. Commit: `fix: tablero.ps1 acepta el número del issue`, con `Spec-ID: odd-tablero-issue-por-numero`.
- [x] 3. Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`, con S04 a S08 de `tablero-scrumban` en verde sin modificarlos.
- [x] 4. Revisión del diff: sin rutas `C:\Users`, sin `Invoke-Expression`, `eval` ni `exec` en las líneas agregadas, y primeros 3 bytes de cada archivo tocado sin `EF BB BF`.

## Criterios de aceptación
- CA1: `-Issue 10` en una carpeta con `origin` de GitHub (HTTPS o SSH) mueve la tarjeta igual que con la URL — Evidencia esperada: salida de S22 en rojo (antes del cambio) y en verde (después).
- CA2: un `-Issue` que no es URL ni número, o un número sin remoto de GitHub, termina con 1 sin llamar a `gh` — Evidencia esperada: salida de S23 en rojo y en verde.
- CA3: con URL sigue funcionando igual — Evidencia esperada: S04 a S08 en verde sin modificarlos, en la suite completa.
- CA4: el diff no agrega rutas de la máquina, `Invoke-Expression`, `eval`, `exec` ni BOM — Evidencia esperada: salida de consola de la revisión del diff.

## Evidencia

### Tarea 1 / CA1 y CA2: Test primero en `tests/tablero-scrumban.Tests.ps1`
Salida en rojo antes de la implementación:
```
FALLA S22 Mover la tarjeta de un issue / Issue por número: Debe imprimir item-add con la URL armada https://github.com/org/repo/issues/10
FALLA S23 Mover la tarjeta de un issue / Dato inválido: issue que no es URL ni número: Issue 'abc' debe salir con código 1
```

Salida en verde después de la implementación:
```
OK S22 Mover la tarjeta de un issue / Issue por número
OK S23 Mover la tarjeta de un issue / Dato inválido: issue que no es URL ni número
```
Commit: `5e49806 test: S22 y S23 de tablero-scrumban con el issue por número` (Spec-ID: odd-tablero-issue-por-numero).

### Tarea 2 / CA1 y CA2: Soporte de número de issue en `scripts/tablero.ps1`
Se agregó la resolución y validación de `$Issue` con el remoto `origin` antes de llamar a `gh`:
Commit: `75a8f76 fix: tablero.ps1 acepta el número del issue` (Spec-ID: odd-tablero-issue-por-numero).

### Tarea 3 / CA3: Suite completa `pwsh -NoProfile -File tests/ejecutar.ps1`
Ejecución de la suite completa con código de salida 0. Escenarios S04 a S08 de `tablero-scrumban` y nuevos S22/S23 en verde:
```
OK S04 Mover la tarjeta de un issue / Issue nuevo en el tablero
OK S05 Mover la tarjeta de un issue / Issue que cambia de columna
OK S06 Mover la tarjeta de un issue / Columna desconocida
OK S07 Mover la tarjeta de un issue / Sin permiso o sin gh
OK S08 Mover la tarjeta de un issue / Dato inválido: Project sin la opción de la columna
...
OK S22 Mover la tarjeta de un issue / Issue por número
OK S23 Mover la tarjeta de un issue / Dato inválido: issue que no es URL ni número
...
OK scripts/generar-plantillas.ps1 -Comprobar
OK scripts/sincronizar-proyecto.ps1 -Proyecto C:\Users\analistapi\Desktop\Proyectos\sdd-global-config -Agentes copilot -Comprobar
```

### Tarea 4 / CA4: Revisión del diff
- Búsqueda de `C:\Users` en líneas agregadas del diff: 0 ocurrencias.
- Búsqueda de `Invoke-Expression`, `eval`, `exec` en líneas agregadas del diff: 0 ocurrencias.
- Comprobación de primeros 3 bytes (sin BOM `EF BB BF`):
  - `scripts/tablero.ps1`: `23 20 73`
  - `tests/tablero-scrumban.Tests.ps1`: `23 20 74`
  - `docs/odd/tablero-issue-por-numero.md`: `2D 2D 2D`

## Progreso
2026-11-17: documento redactado, sin issue (pedido del usuario) — Claude
2026-11-17: implementación completada con TDD (S22 y S23 en rojo antes del cambio, luego en verde), suite completa en verde y diff validado — Agente

## Próximo paso
Claude corre `/odd:verify tablero-issue-por-numero`.
