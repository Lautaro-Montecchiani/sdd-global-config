## Context

`doc-folder-business-rules` movió la documentación a `docs/` sin modificar su contenido (renombres al 100%). Su verify detectó que dos archivos movidos contienen rutas absolutas con el usuario local: `docs/modo-de-uso.md` (línea 10, el `cd` del Paso 1) y `docs/workflow.md` (línea 63, la ruta de `config.json` del perfil global de OpenSpec). El `.docx` es la versión derivada del `.md` de la guía de uso, así que contiene la misma ruta.

La guía está escrita para PowerShell y ya usa placeholders con llaves (`{nombre-proyecto}`) y variables de entorno (`$env:USERPROFILE`, `$env:SDD_CONFIG_REPO`).

## Goals / Non-Goals

**Goals:**
- Que `docs/` no revele el usuario ni la máquina local.
- Mantener el estilo de placeholders y variables que ya usa la documentación.
- Que el `.docx` quede consistente con el `.md`.

**Non-Goals:**
- No modificar `openspec/config.yaml`, `.gemini/`, skills, comandos ni el `CLAUDE.md` global.
- No editar artefactos de otros changes.
- No reescribir ni reorganizar otro contenido de los documentos.

## Decisions

### D1: `docs/modo-de-uso.md` línea 10 → `cd "{ruta-del-proyecto}"`

Alternativas consideradas:
- `$HOME\Desktop\Proyectos\{nombre-proyecto}` — asume una convención de carpetas que no todos los equipos tienen.
- `<ruta-del-proyecto>` — los corchetes angulares rompen al copiar y pegar en PowerShell (la propia guía ya aclara esto para `<agente>`).
- `{ruta-del-proyecto}` — mismo estilo que `{nombre-proyecto}`; cada lector lo reemplaza por su ruta.

**Decisión:** `{ruta-del-proyecto}`.

### D2: `docs/workflow.md` línea 63 → `$env:APPDATA\openspec\config.json`

Alternativas consideradas:
- `%APPDATA%\openspec\config.json` — sintaxis de `cmd`; la guía es de PowerShell.
- `$env:APPDATA\openspec\config.json` — resuelve a `C:\Users\<usuario>\AppData\Roaming` en cada equipo y sigue la convención `$env:` del resto de la guía.

**Decisión:** `$env:APPDATA\openspec\config.json`.

### D3: Regenerar el `.docx` desde el `.md`

Se regenera con el mismo procedimiento usado antes (`ConvertFrom-Markdown` + Word COM), primero a un archivo temporal para comparar cantidad de párrafos y tamaño con el actual antes de reemplazarlo. Editar el `.docx` a mano se descarta: es un artefacto derivado y se desincronizaría.

## Risks / Trade-offs

- **[Riesgo] Los placeholders son menos "copiar y pegar"** → Es el mismo criterio que el resto de la guía (`{nombre-proyecto}`); el Paso 1 ya pide reemplazar valores.
- **[Riesgo] Regenerar el `.docx` puede cambiar el formato** → Comparar con el actual (párrafos, tamaño) antes de reemplazar; si difiere de forma notable, revisar antes de commitear.
- **[Riesgo] Word no disponible en la máquina que implementa** → El `.docx` queda pendiente de regenerar y el change no se da por completo hasta hacerlo.
- **[Trade-off] Quedan rutas con usuario en `openspec/config.yaml` y `.gemini/settings.json`** → Fuera de alcance; se evalúan en otro change.

## Security Layer

`project_type: tooling` — los artefactos gestionados son instrucciones para IA y para usuarios.

- Este change elimina las dos rutas absolutas con el usuario local de la documentación versionada; es el control aplicable ("no exponer paths absolutos sensibles").
- Verificación: buscar `C:\Users` en `docs/*.md` y en el contenido del `.docx` sin resultados.
- Los artefactos de este change usan `<usuario>` en lugar del nombre real.
- Revisar `git diff --staged` antes de cada commit: sin secrets ni credenciales.

## Impacto en proyectos existentes

Ninguno. Los cambios son solo texto en documentación de referencia: no se ejecutan ni se importan desde otras herramientas, y no afectan skills, comandos ni el flujo OpenSpec. Retrocompatibilidad: quien siga la guía deberá reemplazar el placeholder `{ruta-del-proyecto}` por su propia ruta.

## Migration Plan

1. Editar la línea 10 de `docs/modo-de-uso.md`.
2. Editar la línea 63 de `docs/workflow.md`.
3. Regenerar `docs/modo-de-uso.docx` desde el `.md`.
4. Verificar que no queda `C:\Users` en los documentos.
5. Commit con `Spec-ID: docs-portable-paths`.

Rollback: `git revert` del commit generado.

## Open Questions

Sin preguntas abiertas.
