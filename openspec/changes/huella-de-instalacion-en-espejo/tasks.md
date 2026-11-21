## 1. Caracterización

- [ ] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `scripts/instalar.ps1` y `scripts/comun.ps1`. Verificación: salida en verde pegada (incluye `tests/instalar.Tests.ps1` con `reglas-fuente-unica/S08` a `S15` y `tests/statusline-instalable.Tests.ps1`).

## 2. Tests primero

- [ ] 2.1 Test primero, S01 a S11 en `tests/huella-de-instalacion-en-espejo.Tests.ps1` (archivo nuevo, UTF-8 sin BOM), como dice el encabezado del Test Plan de `design.md`: `. "$PSScriptRoot/apoyo.ps1"`, `Con-CarpetaTemporal`, `Ejecutar-Pwsh` e `Inicializar-VaultGit` propias y `# test-plan: huella-de-instalacion-en-espejo/<ID>` arriba de cada `Probar`. Afirmar lo que dice la columna "Verificación". Ningún test escribe en el `$HOME` ni en el vault reales. Comando: `pwsh -NoProfile -File tests/huella-de-instalacion-en-espejo.Tests.ps1`. Verificación: fallan con el código actual (salida en rojo pegada).

## 3. Implementación

- [ ] 3.1 En `scripts/comun.ps1`: agregar `Obtener-HuellaInstalacion -RepoRoot` según D1 de `design.md`. Verificación: S11 en verde.
- [ ] 3.2 En `scripts/instalar.ps1`: aplicar D2 (línea `instalacion:` en `$espejoNuevo`, sin cambiar `Quitar-LineasDinamicasEspejo`), D3 (orden de la clasificación del espejo) y D4 (aviso de `-Comprobar` con `repo atrasado`), sin cambiar la lista de archivos, el manifiesto ni la clasificación del destino. Commit con `scripts/comun.ps1`, el test nuevo y este archivo: `feat: huella de skills y comandos en el espejo del vault`, con `Spec-ID: huella-de-instalacion-en-espejo`. Verificación: S01 a S08 en verde, `tests/instalar.Tests.ps1` en verde sin modificarlo y `(Get-Content scripts/instalar.ps1).Count` pegado (menos de 630 líneas).
- [ ] 3.3 En `.claude/CLAUDE.md`: aplicar D5 (viñeta "Comprobar las reglas:" de "## Al iniciar cada sesión" y agregado a "**Escritura del espejo:**"), sin tocar el bloque generado de reglas. Commit que solo toque ese archivo: `docs: aviso de skills y comandos nuevos en el inicio de sesión`, con una línea "Impacto: …" y `Spec-ID: huella-de-instalacion-en-espejo`. Verificación: S09 en verde, `reglas-fuente-unica/S16` de `tests/instalar.Tests.ps1` en verde y `pwsh scripts/generar-plantillas.ps1 -Comprobar` con código 0.
- [ ] 3.4 En `README.md` y `docs/modo-de-uso.md`: aplicar D6. Verificación: S10 en verde y `reglas-fuente-unica/S17` de `tests/instalar.Tests.ps1` en verde.

## 4. Documentos de arquitectura

- [ ] 4.1 Crear `docs/adr/0008-huella-de-skills-y-comandos-en-el-espejo.md` con el contenido del bloque de código de `## ADR` del design. Verificación: el archivo existe y su texto es igual al bloque (diff pegado).
- [ ] 4.2 En `docs/arquitectura/vision.md`: en `## Decisiones vigentes`, agregar `- [0008. Huella de skills y comandos en el espejo del vault](../adr/0008-huella-de-skills-y-comandos-en-el-espejo.md)` después de la línea del 0007; en `## Hoja de ruta`, quitar la línea `- [media] las reglas llegan a otra máquina con el pull del vault, pero las skills y los comandos solo con instalar.ps1; pueden quedar desparejos — origen: ADR 0002 — propuesta: evaluar distribuir skills y comandos por el mismo camino que las reglas — issue: #53`. Verificación: diff pegado.

## 5. Cierre

- [ ] 5.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S11, C01 y los controles del CI en `OK`).
- [ ] 5.2 Revisión de seguridad del diff: buscar `C:\Users`, el nombre de la carpeta del usuario, tokens e `Invoke-Expression`/`iex` en las líneas agregadas fuera de `openspec/`, y confirmar que ningún archivo nuevo o modificado empieza con `EF BB BF`. Verificación: salida sin coincidencias y los primeros 3 bytes de cada archivo tocado, pegados.
- [ ] 5.3 M01 (lo corre el usuario): verificar que el cambio aplica en un proyecto de prueba y entre dos máquinas, como dice M01 del Test Plan: en la otra PC, después del merge y sin `git pull` del repo, `git -C $vault pull --rebase` y abrir Claude Code en cualquier proyecto; el aviso de inicio de sesión muestra `repo atrasado` con la línea de D4. Después, `git pull` e `instalar.ps1`, y `instalar.ps1 -Comprobar` con código 0. Queda `[ ]` hasta que el usuario lo confirme en el verify.
