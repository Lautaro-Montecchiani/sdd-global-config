## 1. Estructura de templates

- [x] 1.1 Antes de tocar nada, guardar el hash de `~/.gemini/antigravity-cli/settings.json` (para S07)
  - Evidencia: `CFFE3A6B9EAA0CD7556E5F6B7C4298E149903FD4D6E43EF3A5A0E0B02628B9E4` (SHA-256).
- [x] 1.2 Mover con `git mv`: `templates/antigravity-settings.json` → `templates/antigravity/settings.json`, `templates/GEMINI.md` → `templates/gemini/GEMINI.md`, `templates/copilot-instructions.md` → `templates/copilot/copilot-instructions.md`, `templates/AGENTS.md` → `templates/comun/AGENTS.md` (D1)
- [x] 1.3 En `templates/antigravity/settings.json`, agregar `"enabled": true` a `statusLine` como dice D2, sin cambiar el resto del archivo
- [x] 1.4 Crear `templates/antigravity/README.md` con el contenido de D2 (la sección "Barra de estado", los placeholders y la advertencia de baseline permisiva que hoy están en `templates/README.md`, más "Si la barra no aparece") y la parte de instalación de D4
- [x] 1.5 Crear `templates/gemini/README.md`, `templates/copilot/README.md` y `templates/comun/README.md` según D4
- [x] 1.6 Reescribir `templates/README.md` como índice con la matriz exacta de D3 y sus fuentes

## 2. Referencias

- [x] 2.1 Actualizar las rutas en `README.md`, `docs/modo-de-uso.md` y `docs/workflow.md` (D5)
- [x] 2.2 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc` (D5)
- [x] 2.3 Actualizar las rutas en `~/.claude/CLAUDE.md` (secciones "Reglas de ejecución del Agente" y "Reglas globales en el vault"), copiarlo a `.claude/CLAUDE.md` del repo y re-sincronizar el espejo `$vault\_global\reglas-globales.md` con el comando del `CLAUDE.md` global; commit del `CLAUDE.md` aparte, con descripción del impacto (D5)

## 3. Verificación manual

- [x] 3.1 S01 — Listar `templates/` recursivamente y pegar la salida
  - Evidencia:
    - `templates\antigravity`, `templates\comun`, `templates\copilot`, `templates\gemini`, `templates\README.md`, `templates\antigravity\README.md`, `templates\antigravity\settings.json`, `templates\comun\AGENTS.md`, `templates\comun\README.md`, `templates\copilot\copilot-instructions.md`, `templates\copilot\README.md`, `templates\gemini\GEMINI.md`, `templates\gemini\README.md`.
- [x] 3.2 S02 — Revisar los 4 README de carpeta contra D4 y anotar el resultado
  - Evidencia:
    - `templates/antigravity/README.md`: agente Antigravity CLI (`agy`), archivo `settings.json` → `~/.gemini/antigravity-cli/settings.json` (remite a `templates/gemini/GEMINI.md` para reglas), comandos de instalación, baseline, prompt de barra de estado y sección "Si la barra no aparece".
    - `templates/gemini/README.md`: agente Gemini CLI (y reglas globales de Antigravity), archivo `GEMINI.md` → `~/.gemini/GEMINI.md`, comando de instalación y activación de carpetas de confianza (`security.folderTrust.enabled` en `~/.gemini/settings.json` y `~/.gemini/trustedFolders.json`) con enlaces oficiales.
    - `templates/copilot/README.md`: agente GitHub Copilot, archivo `copilot-instructions.md` → `{proyecto}\.github\copilot-instructions.md` y comando de instalación.
    - `templates/comun/README.md`: agentes que leen el estándar `AGENTS.md` (Codex, Cursor y otros), archivo `AGENTS.md` → `{proyecto}\AGENTS.md` y comando de instalación.
- [x] 3.3 S03, S04 — Pegar las filas de Gemini CLI y de Cursor de la matriz de `templates/README.md` y compararlas con D3
  - Evidencia:
    - `GeminiRow: | Gemini CLI | gemini/GEMINI.md → ~/.gemini/GEMINI.md | no verificado (la documentación oficial solo confirma las carpetas de confianza) | no verificado |` (`Match D3 Gemini: True`)
    - `CursorRow: | Cursor | lo agrega agente-cursor en templates/cursor/ (Cursor también lee comun/AGENTS.md) | lo agrega agente-cursor (~/.cursor/cli-config.json) | no verificado |` (`Match D3 Cursor: True`)
- [x] 3.4 S05, S16 — Buscar "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/comun/AGENTS.md`, `~/.claude/CLAUDE.md` y el espejo del vault; pegar el conteo
  - Evidencia:
    - `templates/gemini/GEMINI.md : Evidencia antes de [x]=1, Test primero = falla primero=1, No debilitar tests=1`
    - `templates/copilot/copilot-instructions.md : Evidencia antes de [x]=1, Test primero = falla primero=1, No debilitar tests=1`
    - `templates/comun/AGENTS.md : Evidencia antes de [x]=1, Test primero = falla primero=1, No debilitar tests=1`
    - `~/.claude/CLAUDE.md : Evidencia antes de [x]=1, Test primero = falla primero=1, No debilitar tests=1`
    - `$vault\_global\reglas-globales.md : Evidencia antes de [x]=1, Test primero = falla primero=1, No debilitar tests=1`
- [x] 3.5 S06, S07 — Pegar la salida de `git ls-files .gemini`, la línea `.gemini/` de `.gitignore` y el hash de `~/.gemini/antigravity-cli/settings.json` comparado con el de 1.1
  - Evidencia:
    - `git ls-files .gemini: []`
    - `.gitignore line: 13:.gemini/`
    - `Hash 1.1: CFFE3A6B9EAA0CD7556E5F6B7C4298E149903FD4D6E43EF3A5A0E0B02628B9E4` | `Hash S07: CFFE3A6B9EAA0CD7556E5F6B7C4298E149903FD4D6E43EF3A5A0E0B02628B9E4` (`Hash equal: True`)
- [x] 3.6 S08, S09, S13 — Validar `templates/antigravity/settings.json` como JSON y pegar `toolPermission`, `artifactReviewPolicy`, `allowNonWorkspaceAccess`, `permissions.allow` y `statusLine`
  - Evidencia:
    - `JSON valid: True`
    - `toolPermission: always-proceed`, `artifactReviewPolicy: always-proceed`, `allowNonWorkspaceAccess: True`
    - `permissions.allow (7): command(cmd\.exe), command(git status), command(git diff), command(git branch), command(git restore), command(openspec), command(powershell)`
    - `statusLine: {"type":"command","command":"{RUTA-DE-TU-USUARIO}/.gemini/antigravity-cli/scratch/statusline.bat","enabled":true}`
- [x] 3.7 S10, S11, S12 — Pasarle al `statusline.bat` instalado los JSON de los tres escenarios de la barra (y una entrada no JSON) y pegar las líneas sin ANSI
  - Evidencia:
    - `S10: mi-proyecto   42%   25% 1h30m  (change/plantillas-por-agente)  Modelo Ejemplo`
    - `S11: mi-proyecto   10%   25% 1h30m  (change/plantillas-por-agente)  Modelo Ejemplo`
    - `S12: sdd-global-config   0%   0%  (change/plantillas-por-agente)`
- [x] 3.8 S14, S15 — Buscar las rutas nuevas en `README.md` y `docs/modo-de-uso.md`, confirmar que no quedan rutas viejas fuera de `openspec/changes/archive/` y `docs/srs.md`, y confirmar el prompt y "Si la barra no aparece" en `templates/antigravity/README.md`
  - Evidencia:
    - Rutas nuevas en `README.md` (líneas 10, 43, 53, 77, 80) y `docs/modo-de-uso.md` (líneas 36, 37, 72, 77) y texto XML de `docs/modo-de-uso.docx` (`antigravity\settings.json: True`, `gemini\GEMINI.md: True`, `copilot\copilot-instructions.md: True`, `comun\AGENTS.md: True`, `old antigravity-settings.json: False`).
    - Sin rutas viejas fuera de `openspec/` (donde las specs vigentes se actualizan al correr `openspec archive`) y `docs/srs.md`.
    - `templates/antigravity/README.md`: `Has prompt statusline.bat + statusline_new.ps1: True`, `Has Si la barra no aparece + statusLine.enabled: True`.

## 4. Cierre

- [x] 4.1 Verificar que el cambio aplica en un proyecto de prueba
  - Evidencia: En `%TEMP%\prueba-plantillas-agente`, se ejecutaron los comandos de copia por máquina (`templates\gemini\GEMINI.md` y `templates\antigravity\settings.json` con `statusLine.enabled: True`) y por proyecto (`templates\copilot\copilot-instructions.md` → `.github\copilot-instructions.md` y `templates\comun\AGENTS.md` → `AGENTS.md`), confirmando los 4 archivos creados y eliminando la carpeta temporal al finalizar (`Carpeta temporal eliminada: True`).
