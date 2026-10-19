## Why

Las plantillas para el Agente están todas sueltas en `templates/` (`GEMINI.md`, `antigravity-settings.json`, `copilot-instructions.md`, `AGENTS.md`), sin indicar qué agente usa cada una ni qué soporta cada agente. Distintas personas del equipo usan agentes distintos: hoy se sigue usando Antigravity, y el change `agente-cursor` (de otra persona, todavía sin pushear) propone reemplazarlo por Cursor y retirar las plantillas de Antigravity. Además, la barra de estado de Antigravity se apagó sola en una máquina (el CLI escribió `"enabled": false`) y la plantilla no dice que tiene que estar prendida.

## What Changes

- `templates/` pasa a tener **una carpeta por agente**, cada una con sus reglas, su configuración (cuando el agente la soporta) y un README de instalación:
  - `templates/antigravity/`: `settings.json` (ex `antigravity-settings.json`, ahora con `"enabled": true` en `statusLine`) y `README.md` (instalación, placeholders, barra de estado).
  - `templates/gemini/`: `GEMINI.md` (las reglas del Agente, que también lee Antigravity) y `README.md` (instalación y carpetas de confianza).
  - `templates/copilot/`: `copilot-instructions.md` y `README.md`.
  - `templates/comun/`: `AGENTS.md` (estándar multi-agente, va en la raíz de cada proyecto; lo leen Codex, Cursor y otros) y `README.md`.
- `templates/README.md` pasa a ser un índice con la **matriz de soporte por agente** (reglas, permisos, barra de estado), con lo verificado y lo que no.
- La carpeta de Cursor no se crea en este change: queda reservada en la matriz para `agente-cursor`, que debería **agregar** `templates/cursor/` en vez de reemplazar a Antigravity.
- Se actualizan las rutas en `README.md`, `docs/modo-de-uso.md` (y su `.docx`), `docs/workflow.md`, el `CLAUDE.md` global (con su espejo en el vault y su copia en el repo) y las specs `agent-cli-permissions` y `test-driven-verification`.

Archivos globales que se modifican y por qué:
- `templates/**`: nueva estructura por agente.
- `.claude/CLAUDE.md` (copia de `~/.claude/CLAUDE.md`) y su espejo en el vault: nombran las rutas de las plantillas del Agente.
- `README.md`, `docs/modo-de-uso.md`, `docs/modo-de-uso.docx`, `docs/workflow.md`: comandos de instalación con las rutas nuevas.

## Capabilities

### New Capabilities
- `agent-templates`: estructura de plantillas por agente en `templates/`, contenido mínimo de cada carpeta y matriz de soporte por agente.

### Modified Capabilities
- `agent-cli-permissions`: la plantilla de Antigravity pasa a `templates/antigravity/settings.json` y su `statusLine` exige `"enabled": true`.
- `test-driven-verification`: el requirement "Regla para el Agente" nombra las rutas nuevas de las instrucciones del Agente.

## Non-goals

- No se agrega soporte de Cursor (lo trae `agente-cursor`), ni de Codex más allá de `AGENTS.md`.
- No se agregan permisos ni barra de estado para Gemini CLI: su documentación oficial no confirma una clave de barra de estado ni el nombre de las claves de permisos.
- No se cambian las 7 reglas de ejecución del Agente; solo se mueven los archivos que las llevan.
- No se toca la configuración instalada en cada máquina (`~/.gemini/…`): cada persona reinstala si quiere.

## Impact

- **Plantillas:** se mueven 4 archivos y se agregan 5 README; se borran las rutas viejas de `templates/`.
- **Reglas globales:** `CLAUDE.md` global + espejo del vault + copia en el repo (commit separado).
- **Docs:** `README.md`, `docs/modo-de-uso.md` (con el `.docx` regenerado), `docs/workflow.md`.
- **Otros proyectos:** los que ya copiaron `copilot-instructions.md` o `AGENTS.md` no cambian; solo cambia de dónde se copian a partir de ahora.
- **`agente-cursor`:** su proposal tiene que ajustarse a esta estructura antes del apply (agregar `templates/cursor/` sin retirar Antigravity).
