## Why

Google retiró Gemini CLI y lo reemplazó por Antigravity CLI (anuncio del 19/05/2026; desde el 18/06/2026 dejó de atender a usuarios gratuitos y de los planes Pro y Ultra). El repo todavía lo trata como un agente soportado: tiene la carpeta `templates/gemini/`, una fila de "Gemini CLI" en la matriz de soporte, una sección de carpetas de confianza de Gemini CLI y textos que dicen "Gemini/Antigravity". La plantilla de reglas `GEMINI.md` sigue siendo necesaria, pero la usa Antigravity, que lee sus reglas globales desde `~/.gemini/GEMINI.md`.

## What Changes

- Mover `templates/gemini/GEMINI.md` a `templates/antigravity/GEMINI.md` (con `git mv`, conservando el historial). El destino de instalación no cambia: `~/.gemini/GEMINI.md`.
- Eliminar `templates/gemini/` (su `README.md` documentaba Gemini CLI y sus carpetas de confianza); las instrucciones de instalación de `GEMINI.md` pasan a `templates/antigravity/README.md`.
- Quitar la fila de Gemini CLI de la matriz de `templates/README.md`, apuntar la fila de Antigravity a `antigravity/GEMINI.md` y reemplazar la fuente de Gemini CLI por una nota con el anuncio de su retiro.
- Actualizar las referencias a `templates/gemini/` y a "Gemini CLI" o "Gemini/Antigravity" en el `CLAUDE.md` global, `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` (y su `.docx`) y las plantillas de reglas.
- Specs: la estructura de `templates/`, la matriz, las plantillas de reglas, el setup por máquina y la regla del Agente pasan a la ruta nueva.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `agent-templates`: sin carpeta `gemini/`, sin fila de Gemini CLI y con `GEMINI.md` dentro de `antigravity/`.
- `project-onboarding`: el setup por máquina de Antigravity usa `templates/antigravity/GEMINI.md`.
- `test-driven-verification`: la regla para el Agente apunta a `templates/antigravity/GEMINI.md`.

## Impact

- Archivos del repo: `templates/` (mover y borrar), `templates/README.md`, `templates/antigravity/README.md`, `.claude/CLAUDE.md`, `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `docs/modo-de-uso.docx`, y las plantillas de reglas que nombren "Gemini".
- Fuera del repo: `~/.claude/CLAUDE.md` y el espejo `_global/reglas-globales.md` del vault. `~/.gemini/GEMINI.md` de cada máquina no cambia de lugar ni de contenido.
- Quien siga instrucciones viejas con `templates\gemini\GEMINI.md` va a encontrar la ruta rota; las guías nuevas indican la ruta nueva.
- Los changes archivados y el SRS no se editan a mano: el SRS se regenera después del archive.
