## 1. Caracterización

- [x] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `.claude/statusline.sh`, `templates/antigravity/statusline_new.ps1` y `tests/statusline-instalable.Tests.ps1`. Verificación: salida pegada. Puede mostrar en rojo solo `statusline-instalable/S04` en Windows (es el #74, que arregla la 2.1); todo lo demás en verde.

## 2. Tests

- [x] 2.1 C02 (#74): en `tests/statusline-instalable.Tests.ps1`, S04, aplicar D3 de `design.md` (normalizar `\r\n` a `\n` de los dos lados en las dos comparaciones), sin cambiar nada más. Commit: `test: S04 de statusline-instalable sin depender de los saltos de línea`, con `Spec-ID: barra-de-estado-con-bloques`. Verificación: S04 en verde en esta máquina (Windows), salida pegada antes (rojo) y después (verde).
- [x] 2.2 Test primero, S01 a S04 en `tests/barra-de-estado-con-bloques.Tests.ps1` (archivo nuevo, UTF-8 sin BOM, con `. "$PSScriptRoot/apoyo.ps1"` y `# test-plan: barra-de-estado-con-bloques/<ID>` arriba de cada `Probar`), con los JSON inventados y la forma de correr cada script que dice el Test Plan de `design.md`. Si `powershell.exe` no existe, S02 y la parte de Antigravity de S04 se saltean con el motivo escrito (regla 3). Verificación: fallan con el código actual (salida en rojo pegada).
- [x] 2.3 C03: en `tests/statusline-instalable.Tests.ps1`, aplicar D4 de `design.md` a S14, S16 y S21, sin cambiar nada más. Commit: `test: S14, S16 y S21 de statusline-instalable con bloques y flecha`, con `Spec-ID: barra-de-estado-con-bloques`. Verificación: con `.claude/statusline.sh` y `statusline_new.ps1` sin D1 ni D2 (si el cambio de la 3.1 ya está hecho sin commitear, apartarlo con `git stash` para correrlo), S14, S16 y S21 fallan; salida en rojo pegada. Pasan a verde con la 3.1 y la 3.2.

## 3. Implementación

- [x] 3.1 En `.claude/statusline.sh`: aplicar D1 (dos barras con `█`/`░` y `↺` en el reinicio), sin tocar nada más. Commit: `feat: barra de statusline.sh con bloques y flecha de reinicio`, con `Spec-ID: barra-de-estado-con-bloques`. Verificación: S01 y la parte de `statusline.sh` de S04 en verde, `statusline-instalable/C02` en verde sin modificarlo, y `statusline-instalable/S14` y `S16` en verde.
- [x] 3.2 En `templates/antigravity/statusline_new.ps1`: aplicar D2 (`$lleno`, `$vacio`, `$flecha` con `[char]`, función `Barra` y los dos segmentos), dejando el archivo en ASCII puro y sin BOM. Commit: `feat: barra de Antigravity con bloques y flecha de reinicio`, con `Spec-ID: barra-de-estado-con-bloques`. Verificación: S02, S03, la parte de Antigravity de S04 y `statusline-instalable/S21` en verde.

## 4. Cierre

- [x] 4.1 M01 (lo hace el Agente, sin `instalar.ps1`): cadena real `.bat` → `powershell.exe` sobre una carpeta temporal, como dice el Test Plan. Verificación: salida pegada con los bloques y `↺` legibles, y la carpeta temporal borrada.
- [ ] 4.2 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada, incluido `statusline-instalable/S04`.
- [x] 4.3 Revisión de seguridad del diff: buscar rutas `C:\Users`, tokens, `Invoke-Expression`, `eval` y `exec` en las líneas agregadas fuera de `openspec/`, y confirmar que ningún archivo nuevo o modificado tiene BOM. Verificación: salida sin coincidencias, pegada.
