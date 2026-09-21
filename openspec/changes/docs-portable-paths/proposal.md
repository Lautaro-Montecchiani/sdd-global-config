## Why

El `/opsx:verify` de `doc-folder-business-rules` detectó que dos documentos movidos a `docs/` contienen rutas absolutas con el usuario local (`C:\Users\<usuario>\...`). Además de exponer el nombre de usuario de una máquina en documentación versionada, esas instrucciones solo funcionan en esa PC, y la regla de `tooling`/`config` pide no exponer paths absolutos sensibles. El `design.md` de ese change afirma lo contrario, así que conviene corregirlo en la raíz del problema.

## What Changes

- `docs/modo-de-uso.md` (línea 10): `cd "C:\Users\<usuario>\Desktop\Proyectos\{nombre-proyecto}"` pasa a `cd "{ruta-del-proyecto}"`, con el mismo estilo de placeholder que ya usa el documento.
- `docs/workflow.md` (líneas 32 y 63): `C:\Users\<usuario>\AppData\Roaming\openspec\config.json` pasa a `$env:APPDATA\openspec\config.json`.
- Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md`, porque el `.docx` es la versión derivada y contiene la misma ruta.
- Ningún otro cambio de contenido en los documentos.

Este change no modifica ningún archivo global (`~/.claude/`): solo los tres documentos del repositorio `sdd-global-config` listados arriba.

## Non-goals

- No se tocan `.gemini/`, `skills/`, `.claude/` ni el `CLAUDE.md` global.
- No se editan los artefactos de otros changes (incluido `doc-folder-business-rules`): su afirmación de Security Layer pasa a ser cierta una vez aplicado este change.
- `openspec/config.yaml` y `.gemini/settings.json` también contienen rutas con el usuario local; se evalúan por separado, no en este change.
- No se reescribe ni reorganiza ningún otro contenido de los documentos.

## Capabilities

### New Capabilities

- `docs-portable-paths`: la documentación de `docs/` no incluye rutas absolutas que revelen el usuario o la máquina local; usa placeholders o variables de entorno.

### Modified Capabilities

<!-- Sin cambios de requisitos en specs existentes -->

## Impact

- Archivos modificados: `docs/modo-de-uso.md`, `docs/workflow.md`, `docs/modo-de-uso.docx` (regenerado).
- Sin impacto en skills, comandos ni en el flujo OpenSpec activo.
- Los lectores pasan a reemplazar el placeholder `{ruta-del-proyecto}` por su propia ruta, en línea con el resto de la guía.
