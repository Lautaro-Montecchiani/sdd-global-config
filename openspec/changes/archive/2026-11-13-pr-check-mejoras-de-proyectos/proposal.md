Issue: #61

## Why

Al sincronizar los proyectos el 13/11/2026, tres quedaron bloqueados porque su `.github/workflows/pr-check.yml` tiene mejoras propias que la plantilla no tiene: `permissions:` de solo lectura (los tres), excluir `.example`, `.sample` y `.template` del control de archivos sensibles (seguimiento-Suscripciones), `credentials.json` y `token.json` como sensibles (pdf_automation_research) y un job `validate-specs` (normalizacionRTF-python). Sincronizar con `-Forzar` perdería esas mejoras, y `pr-check.yml` no tiene sección `## Propio del proyecto`, así que el mensaje de bloqueo ("pasá el contenido debajo de `## Propio del proyecto`") no sirve para ese archivo. El problema de fondo es que las mejoras a los archivos generados se quedan en el proyecto y no vuelven al origen.

## What Changes

- **Plantilla `.github/workflows/pr-check.yml`:** suma `permissions:` de solo lectura (`contents: read`, `pull-requests: read`), excluye `.example`, `.sample` y `.template` del control de archivos sensibles, agrega `credentials.json` y `token.json` a los patrones sensibles y arranca con un comentario que dice dónde van las mejoras.
- **`scripts/sincronizar-proyecto.ps1`:** cuando `pr-check.yml` queda bloqueado, el mensaje (en `-Aviso` y en la sincronización normal) explica las dos salidas: un issue en `sdd-global-config` si la mejora sirve para todos, u otro workflow del proyecto y `-Forzar` si es propia.
- **Regla para devolver mejoras al origen** en `.claude/CLAUDE.md` (Capa de persistencia, junto al onboarding de proyectos) y en `README.md`.
- **`README.md`:** procedimiento para sincronizar varios proyectos (simular primero, solo los agentes que el proyecto ya usa, no pisar cambios sin commitear, no commitear desde el script).

Archivos globales que se modifican y por qué: `.github/workflows/pr-check.yml` es la plantilla que se copia a los proyectos; `scripts/sincronizar-proyecto.ps1` es el que la distribuye; `.claude/CLAUDE.md` tiene las reglas globales de Claude.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `rules-sync`: requirements nuevos sobre el contenido de la plantilla `pr-check.yml`, el mensaje de bloqueo de `pr-check.yml`, la regla de devolver mejoras al origen y el procedimiento para sincronizar varios proyectos.

## Non-goals

- La huella (versión y hash) en los archivos generados y el control en el CI de los proyectos: es el issue #58.
- Una sección `## Propio del proyecto` para archivos YAML: lo propio de `pr-check.yml` va en otro workflow.
- Poner al día los 3 proyectos bloqueados: es una tarea operativa después del merge (mover `validate-specs` de normalizacionRTF-python a su propio workflow y sincronizar los tres con `-Forzar`). Queda en los pendientes del vault.
- Que el Agente deje de agregar BOM: va en un issue aparte.

## Impact

- Los proyectos que tengan `pr-check.yml` lo van a ver atrasado hasta sincronizar. Con la versión nueva, sus PR corren con permisos de solo lectura.
- Retrocompatible: las versiones anteriores de la plantilla siguen reconociéndose como atrasadas en la historia de git.
- Las máquinas reciben el `CLAUDE.md` nuevo con `instalar.ps1`.
