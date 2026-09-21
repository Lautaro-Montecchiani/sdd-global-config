## 1. Dejar de versionar `.gemini/`

- [ ] 1.1 Ejecutar `git rm -r --cached .gemini` para dejar de versionar `.gemini\settings.json`, `.gemini\statusline.bat` y `.gemini\statusline_new.ps1` sin borrar los archivos del disco
- [ ] 1.2 Agregar `.gemini/` a `.gitignore`

## 2. Plantillas de la baseline

- [ ] 2.1 Crear `templates\antigravity-settings.json` con `toolPermission`, `artifactReviewPolicy` y `allowNonWorkspaceAccess`, la allowlist base de siete comandos, `statusLine` y un `trustedWorkspaces` de ejemplo con placeholder, sin `model`, `colorScheme`, workspaces reales ni comandos puntuales
- [ ] 2.2 Crear `templates\antigravity-statusline.ps1` copiando `.gemini\statusline_new.ps1` sin cambios
- [ ] 2.3 Crear `templates\antigravity-statusline.bat` a partir de `.gemini\statusline.bat`, reemplazando la ruta absoluta por `%USERPROFILE%`

## 3. Documentación de instalación por máquina

- [ ] 3.1 Actualizar `templates\README.md` con una fila por plantilla nueva, su destino en `~/.gemini/antigravity-cli/` y qué valores completar
- [ ] 3.2 Actualizar `README.md` (setup por máquina) con el paso de instalar la plantilla de permisos y de la barra de estado
- [ ] 3.3 Actualizar `docs\modo-de-uso.md` (setup por máquina) con el mismo paso
- [ ] 3.4 Regenerar `docs\modo-de-uso.docx` desde `docs\modo-de-uso.md`, generando primero a un archivo temporal y comparando con el actual

## 4. Verificación

- [ ] 4.1 Confirmar que `git ls-files .gemini` no devuelve archivos y que los archivos de `.gemini\` siguen en el disco
- [ ] 4.2 Confirmar con un script en archivo que `templates\antigravity-settings.json` es JSON válido, tiene los tres valores de permisos y los siete comandos, y no contiene el nombre de usuario, rutas de unidad reales ni workspaces reales
- [ ] 4.3 Confirmar que `templates\antigravity-statusline.bat` y `templates\antigravity-statusline.ps1` no contienen el nombre de usuario
- [ ] 4.4 Verificar que el cambio aplica en un proyecto de prueba: copiar la plantilla a una carpeta temporal, reemplazar los placeholders y comprobar que el JSON resultante conserva las claves de permisos
