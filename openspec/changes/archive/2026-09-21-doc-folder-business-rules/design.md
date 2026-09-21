## Context

El proyecto `sdd-global-config` gestiona la configuración global del workflow SDD Híbrido. Actualmente, la documentación de reglas de negocio está fragmentada: `WORKFLOW.md` en la raíz, la guía de uso (`.docx` y `.md`) en `Modo de Uso/`, y el `README.md` sin referencias claras. Esto dificulta la navegación y contradice la naturaleza de repositorio de "tooling" del proyecto.

## Goals / Non-Goals

**Goals:**
- Crear `docs/` como carpeta canónica para toda la documentación de reglas de negocio
- Mover `WORKFLOW.md` y la guía de uso (`.docx` y `.md`) a `docs/`
- Actualizar `README.md` para que apunte a `docs/` como punto de entrada

**Non-Goals:**
- No modificar el contenido de los archivos movidos (solo reubicación)
- No tocar `openspec/`, `.claude/`, `skills/` ni ningún artefacto de spec o skill
- No crear documentación nueva más allá de lo que ya existe

## Decisions

### D1: Nombre de la carpeta → `docs/`

Alternativas consideradas:
- `docs/` — convencional en GitHub y corto, visible en la raíz
- `documentation/` — demasiado verboso para un repo de tooling
- `.docs/` — carpeta punto, como `.claude/` y `.github/`; descartada porque ese estilo se usa para soporte de herramientas, no para documentación pensada para leerse

**Decisión:** `docs/`, por ser la convención más difundida para documentación.

### D2: ¿Eliminar `Modo de Uso/` original?

**Decisión:** Sí. Una vez movido el contenido, la carpeta original se elimina para evitar duplicados. La carpeta contiene el `.docx` y su fuente `.md`; ambos se mueven, así que queda vacía.

### D3: ¿Qué va en `docs/`?

| Archivo origen | Destino en `docs/` |
|---|---|
| `WORKFLOW.md` | `docs/workflow.md` |
| `Modo de Uso/Modo de uso.docx` | `docs/modo-de-uso.docx` |
| `Modo de Uso/Modo de uso.md` | `docs/modo-de-uso.md` |

`README.md` no se mueve — se actualizan las 3 referencias existentes para que apunten a `docs/`.

## Security Layer

`project_type: tooling` — los artefactos gestionados son instrucciones para IA.

- Los archivos movidos (`WORKFLOW.md`, `modo-de-uso.md`, `modo-de-uso.docx`) no contienen secrets ni paths absolutos sensibles. Verificar antes del commit con `git diff --staged`.
- `README.md` solo agrega referencias relativas — sin rutas absolutas ni credenciales.

## Risks / Trade-offs

- **[Riesgo] Referencias externas rotas** → Los archivos se mueven de la raíz. Si algún repo externo linkea directamente a `WORKFLOW.md`, el link se rompe. Mitigación: es un repo de config privado; riesgo mínimo.
- **[Riesgo] Regeneración del docx** → El `.docx` se genera desde el `.md` de la guía de uso; tras el movimiento la fuente pasa a `docs/modo-de-uso.md`. Mitigación: regenerar siempre desde la nueva ubicación y mantener ambos archivos juntos en `docs/`.

## Migration Plan

1. Crear directorio `docs/`
2. Mover `WORKFLOW.md` a `docs/workflow.md`
3. Mover `Modo de Uso/Modo de uso.docx` a `docs/modo-de-uso.docx`
4. Mover `Modo de Uso/Modo de uso.md` a `docs/modo-de-uso.md`
5. Eliminar directorio `Modo de Uso/` (queda vacío)
6. Actualizar `README.md`: corregir las 3 referencias a los archivos para que apunten a `docs/`
7. Commit con `Spec-ID: doc-folder-business-rules`

Rollback: `git revert` del commit generado.

## Impacto en proyectos existentes

Ninguno. Este repositorio es standalone — no es dependencia de otros proyectos. Los archivos movidos son documentación de referencia, no código ejecutado ni importado por herramientas externas.

## Open Questions

Sin preguntas abiertas. El alcance está acotado a reorganización de archivos sin cambios de comportamiento.
