## Why

La carpeta `.gemini/` está versionada en el repo, pero es una foto vieja de la configuración personal del CLI del Agente (Antigravity): mezcla permisos, workspaces de confianza, el modelo elegido y rutas de una PC concreta. Nada la lee ni la instala, y en una PC o notebook nueva no hay forma documentada de replicar las reglas de permisos que hoy usa el Agente. Este change deja de versionar esa carpeta y define, en una spec y en plantillas sin datos de la máquina, la configuración que sí conviene replicar.

## What Changes

- Dejar de versionar `.gemini/` (`git rm --cached` y una línea en `.gitignore`). Los archivos siguen en el disco y la configuración real del CLI no se toca.
- Nueva spec `agent-cli-permissions` con la baseline de permisos del Agente: `toolPermission` y `artifactReviewPolicy` en `always-proceed`, `allowNonWorkspaceAccess` en `true`, una allowlist base de comandos y la barra de estado.
- Plantillas versionadas en `templates/` para instalar esa baseline en una máquina nueva: `antigravity-settings.json` y los scripts de la barra de estado (`antigravity-statusline.bat` y `antigravity-statusline.ps1`), sin rutas de usuario.
- Un paso de instalación por máquina en `README.md` y `docs/modo-de-uso.md` (con el `.docx` regenerado) y una fila por plantilla en `templates/README.md`.

Este change no modifica ningún archivo global (`~/.claude/`, `~/.gemini/`): solo archivos del repositorio `sdd-global-config`.

## Non-goals

- No se modifica el `settings.json` real del CLI de ninguna máquina.
- No se versionan los workspaces de confianza, el modelo, el esquema de colores, comandos puntuales ni credenciales (por ejemplo `oauth_creds.json`).
- No se cambia el nivel de permisos: se replica el actual.
- No se reescribe la historia de git: los commits anteriores de `.gemini/` siguen en la historia.
- No se crea un script instalador; si se quiere, se propone en otro change.
- No se toca `templates/GEMINI.md` ni el resto de las plantillas existentes.

## Capabilities

### New Capabilities

- `agent-cli-permissions`: baseline de permisos y barra de estado del CLI del Agente, con su instalación por máquina y sin datos personales versionados.

### Modified Capabilities

<!-- Sin cambios de requisitos en specs existentes -->

## Impact

- Archivos nuevos: `templates/antigravity-settings.json`, `templates/antigravity-statusline.bat`, `templates/antigravity-statusline.ps1`.
- Archivos modificados: `.gitignore`, `README.md`, `templates/README.md`, `docs/modo-de-uso.md` y `docs/modo-de-uso.docx` (regenerado).
- `.gemini/` deja de estar en git (los archivos locales no se borran).
- Sin impacto en skills, comandos ni en el flujo OpenSpec activo.
