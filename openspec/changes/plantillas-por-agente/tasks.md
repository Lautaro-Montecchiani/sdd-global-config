## 1. Estructura de templates

- [ ] 1.1 Antes de tocar nada, guardar el hash de `~/.gemini/antigravity-cli/settings.json` (para S07)
- [ ] 1.2 Mover con `git mv`: `templates/antigravity-settings.json` → `templates/antigravity/settings.json`, `templates/GEMINI.md` → `templates/gemini/GEMINI.md`, `templates/copilot-instructions.md` → `templates/copilot/copilot-instructions.md`, `templates/AGENTS.md` → `templates/comun/AGENTS.md` (D1)
- [ ] 1.3 En `templates/antigravity/settings.json`, agregar `"enabled": true` a `statusLine` como dice D2, sin cambiar el resto del archivo
- [ ] 1.4 Crear `templates/antigravity/README.md` con el contenido de D2 (la sección "Barra de estado", los placeholders y la advertencia de baseline permisiva que hoy están en `templates/README.md`, más "Si la barra no aparece") y la parte de instalación de D4
- [ ] 1.5 Crear `templates/gemini/README.md`, `templates/copilot/README.md` y `templates/comun/README.md` según D4
- [ ] 1.6 Reescribir `templates/README.md` como índice con la matriz exacta de D3 y sus fuentes

## 2. Referencias

- [ ] 2.1 Actualizar las rutas en `README.md`, `docs/modo-de-uso.md` y `docs/workflow.md` (D5)
- [ ] 2.2 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc` (D5)
- [ ] 2.3 Actualizar las rutas en `~/.claude/CLAUDE.md` (secciones "Reglas de ejecución del Agente" y "Reglas globales en el vault"), copiarlo a `.claude/CLAUDE.md` del repo y re-sincronizar el espejo `$vault\_global\reglas-globales.md` con el comando del `CLAUDE.md` global; commit del `CLAUDE.md` aparte, con descripción del impacto (D5)

## 3. Verificación manual

- [ ] 3.1 S01 — Listar `templates/` recursivamente y pegar la salida
- [ ] 3.2 S02 — Revisar los 4 README de carpeta contra D4 y anotar el resultado
- [ ] 3.3 S03, S04 — Pegar las filas de Gemini CLI y de Cursor de la matriz de `templates/README.md` y compararlas con D3
- [ ] 3.4 S05, S16 — Buscar "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/comun/AGENTS.md`, `~/.claude/CLAUDE.md` y el espejo del vault; pegar el conteo
- [ ] 3.5 S06, S07 — Pegar la salida de `git ls-files .gemini`, la línea `.gemini/` de `.gitignore` y el hash de `~/.gemini/antigravity-cli/settings.json` comparado con el de 1.1
- [ ] 3.6 S08, S09, S13 — Validar `templates/antigravity/settings.json` como JSON y pegar `toolPermission`, `artifactReviewPolicy`, `allowNonWorkspaceAccess`, `permissions.allow` y `statusLine`
- [ ] 3.7 S10, S11, S12 — Pasarle al `statusline.bat` instalado los JSON de los tres escenarios de la barra (y una entrada no JSON) y pegar las líneas sin ANSI
- [ ] 3.8 S14, S15 — Buscar las rutas nuevas en `README.md` y `docs/modo-de-uso.md`, confirmar que no quedan rutas viejas fuera de `openspec/changes/archive/` y `docs/srs.md`, y confirmar el prompt y "Si la barra no aparece" en `templates/antigravity/README.md`

## 4. Cierre

- [ ] 4.1 Verificar que el cambio aplica en un proyecto de prueba
