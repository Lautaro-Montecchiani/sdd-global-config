## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `.claude/statusline.sh`, `templates/antigravity/statusline_new.ps1`, `tests/barra-de-estado-con-bloques.Tests.ps1` y `tests/statusline-instalable.Tests.ps1`. Verificación: salida en verde pegada.

## 2. Tests

- [x] 2.1 C02 y C03, test primero: en `tests/barra-de-estado-con-bloques.Tests.ps1` (S01 a S04) y en `tests/statusline-instalable.Tests.ps1` (S14, S16, S21 y S23), aplicar D3 de `design.md`, sin cambiar nada más (marcadores, títulos y el resto de los asserts quedan igual). Correrlos contra el código actual: tienen que fallar todos, porque la salida de hoy todavía usa `░` (S16 incluido, ya que deja de permitirlo). Commit: `test: tests de las barras sin ░`, con `Spec-ID: barra-de-estado-un-solo-bloque`. Verificación: salida en rojo pegada; pasan a verde con la 3.1 y la 3.2.
- [x] 2.2 Test primero, S01 a S04 en `tests/barra-de-estado-un-solo-bloque.Tests.ps1` (archivo nuevo, UTF-8 sin BOM, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: barra-de-estado-un-solo-bloque/<ID>` arriba de cada `Probar`), con los JSON inventados, la salida **con** ANSI y la forma de correr cada script que dice el Test Plan de `design.md`. Si `powershell.exe` no existe, S02 y la parte de Antigravity de S04 se saltean con el motivo escrito (regla 3). Commit: `test: S01 a S04 de barra-de-estado-un-solo-bloque`, con `Spec-ID: barra-de-estado-un-solo-bloque`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Implementación

- [x] 3.1 En `.claude/statusline.sh`: aplicar D1 (bloque de colores arriba de `units = 12` con `C_GRAY`, parte vacía de las dos barras con `█` en gris y vuelta al color del segmento, `rl_color` antes de `rl_bar`), sin tocar nada más. Commit: `fix: barras de statusline.sh con la parte vacía en gris`, con `Spec-ID: barra-de-estado-un-solo-bloque`. Verificación: S01 y la parte de `statusline.sh` de S04 en verde, C02 de `statusline-instalable` en verde sin modificarlo, y `statusline-instalable/S14` y `S16` y `barra-de-estado-con-bloques/S01` en verde.
- [x] 3.2 En `templates/antigravity/statusline_new.ps1`: aplicar D2 (`$gris`, sin `$vacio`, `Barra` con el parámetro de color y los dos segmentos), dejando el archivo en ASCII puro y sin BOM. Commit: `fix: barra de Antigravity con la parte vacía en gris`, con `Spec-ID: barra-de-estado-un-solo-bloque`. Verificación: S02, S03, la parte de Antigravity de S04, `statusline-instalable/S21` y `S23` y `barra-de-estado-con-bloques/S02` a `S04` en verde.

## 4. Cierre

- [x] 4.1 M01 (lo hace el Agente, sin `instalar.ps1`): cadena real `.bat` → `powershell.exe` sobre una carpeta temporal, como dice el Test Plan. Verificación: salida pegada con las secuencias ANSI visibles (`ESC` reemplazado por `<ESC>`), con 6 `█`, `<ESC>[90m` y 6 `█` antes de `50%`, y la carpeta temporal borrada.
- [x] 4.2 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada.
- [x] 4.3 Revisión de seguridad del diff: buscar rutas `C:\Users`, tokens, `Invoke-Expression`, `eval` y `exec` en las líneas agregadas fuera de `openspec/`, buscar `░` y `0x2591` en `.claude/statusline.sh` y `templates/antigravity/statusline_new.ps1`, y confirmar que ningún archivo nuevo o modificado tiene BOM. Verificación: salida sin coincidencias, pegada.
- [ ] 4.4 M02 (lo corre el usuario) — Verificar que el cambio aplica en un proyecto de prueba: en la terminal donde se desbordaba, desde la rama del change y sin `instalar.ps1`, pasar el JSON de S02 a `powershell.exe -NoProfile -ExecutionPolicy Bypass -File templates/antigravity/statusline_new.ps1` y confirmar que las dos barras miden lo mismo y que la parte vacía se ve en gris. Queda `[ ]` hasta que el usuario lo confirme en el verify.
