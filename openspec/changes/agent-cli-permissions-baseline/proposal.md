## Why

La carpeta `.gemini/` está versionada en el repo, pero es una foto vieja de la configuración personal del CLI del Agente (Antigravity): mezcla permisos, workspaces de confianza, el modelo elegido y rutas de una PC concreta. Nada la lee ni la instala, y en una PC o notebook nueva no hay forma documentada de replicar las reglas de permisos que hoy usa el Agente. Este change deja de versionar esa carpeta y define, en una spec y en plantillas sin datos de la máquina, la configuración que sí conviene replicar.

## What Changes

- Dejar de versionar `.gemini/` (`git rm --cached` y una línea en `.gitignore`). Los archivos siguen en el disco y la configuración real del CLI no se toca.
- Nueva spec `agent-cli-permissions` con la baseline de permisos del Agente: `toolPermission` y `artifactReviewPolicy` en `always-proceed`, `allowNonWorkspaceAccess` en `true`, una allowlist base de comandos y la barra de estado.
- Plantilla versionada `templates/antigravity-settings.json` para instalar esa baseline en una máquina nueva, sin rutas de usuario.
- La barra de estado no se versiona como scripts: se especifica por comportamiento en la spec (formato de salida, campos y escenarios) y el propio CLI del Agente la genera en cada máquina con un prompt documentado.
- Un paso de instalación por máquina en `README.md` y `docs/modo-de-uso.md` (con el `.docx` regenerado), y en `templates/README.md` la fila de la plantilla y el prompt para generar la barra de estado.

Este change no modifica ningún archivo global (`~/.claude/`, `~/.gemini/`): solo archivos del repositorio `sdd-global-config`.

## Non-goals

- No se modifica el `settings.json` real del CLI de ninguna máquina.
- No se versionan los workspaces de confianza, el modelo, el esquema de colores, comandos puntuales ni credenciales (por ejemplo `oauth_creds.json`).
- No se cambia el nivel de permisos: se replica el actual.
- No se reescribe la historia de git: los commits anteriores de `.gemini/` siguen en la historia.
- No se versionan los scripts de la barra de estado (`.bat` y `.ps1`): los genera el CLI del Agente a partir de la spec.
- No se crea un script instalador; si se quiere, se propone en otro change.
- No se toca `templates/GEMINI.md` ni el resto de las plantillas existentes.

## Capabilities

### New Capabilities

- `agent-cli-permissions`: baseline de permisos y barra de estado del CLI del Agente, con su instalación por máquina y sin datos personales versionados.

### Modified Capabilities

<!-- Sin cambios de requisitos en specs existentes -->

## Impact

- Archivo nuevo: `templates/antigravity-settings.json`.
- Archivos modificados: `.gitignore`, `README.md`, `templates/README.md`, `docs/modo-de-uso.md` y `docs/modo-de-uso.docx` (regenerado).
- `.gemini/` deja de estar en git (los archivos locales no se borran).
- Sin impacto en skills, comandos ni en el flujo OpenSpec activo.
