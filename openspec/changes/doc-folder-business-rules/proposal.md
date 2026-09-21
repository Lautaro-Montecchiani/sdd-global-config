## Why

Las reglas de negocio del proyecto (workflow SDD híbrido, roles Claude/Agente, guías de uso) están dispersas en la raíz del repositorio (`WORKFLOW.md`, `README.md`) y en la carpeta `Modo de Uso/`. Centralizar todo en una carpeta `docs/` mejora la trazabilidad y mantiene la raíz limpia, alineado con el `project_type: tooling` declarado en `openspec/config.yaml`.

## What Changes

- Crear directorio `docs/` en la raíz del proyecto
- Mover `WORKFLOW.md` → `docs/workflow.md`
- Mover `Modo de Uso/Modo de uso.docx` → `docs/modo-de-uso.docx`
- Mover `Modo de Uso/Modo de uso.md` → `docs/modo-de-uso.md` (fuente de la que se genera el `.docx`)
- Actualizar `README.md`: sus 3 referencias existentes a `WORKFLOW.md` y `Modo de uso.md` pasan a apuntar a `docs/`
- Eliminar la carpeta `Modo de Uso/` una vez migrado su contenido

## Non-goals

- No se modifican artefactos de OpenSpec (`openspec/changes/`, `openspec/config.yaml`)
- No se modifican los directorios `.claude/` ni `skills/`
- No se modifica `~/.claude/CLAUDE.md` global
- No se cambia el comportamiento de ningún skill ni comando


## Capabilities

### New Capabilities

- `doc-folder-structure`: Carpeta `docs/` como repositorio centralizado de reglas de negocio y documentación del workflow SDD híbrido. Incluye workflow, guía de uso y referencia rápida.

### Modified Capabilities

<!-- Sin cambios de requisitos en specs existentes -->

## Impact

- Archivos movidos a `docs/`: `WORKFLOW.md`, `Modo de Uso/Modo de uso.docx`, `Modo de Uso/Modo de uso.md`
- Archivo actualizado: `README.md`
- Archivo eliminado: directorio `Modo de Uso/`
- Sin impacto en herramientas, skills, ni en el flujo OpenSpec activo
- `README.md` es el único archivo de raíz que cambia en contenido
