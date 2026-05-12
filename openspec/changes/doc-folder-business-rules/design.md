## Context

El proyecto `sdd-global-config` gestiona la configuración global del workflow SDD Híbrido. Actualmente, la documentación de reglas de negocio está fragmentada: `WORKFLOW.md` en la raíz, el docx en `Modo de Uso/`, y el `README.md` sin referencias claras. Esto dificulta la navegación y contradice la naturaleza de repositorio de "tooling" del proyecto.

## Goals / Non-Goals

**Goals:**
- Crear `docs/` como carpeta canónica para toda la documentación de reglas de negocio
- Mover `WORKFLOW.md` y el docx de uso a `docs/`
- Actualizar `README.md` para que apunte a `docs/` como punto de entrada

**Non-Goals:**
- No modificar el contenido de los archivos movidos (solo reubicación)
- No tocar `openspec/`, `.claude/`, `skills/` ni ningún artefacto de spec o skill
- No crear documentación nueva más allá de lo que ya existe

## Decisions

### D1: Nombre de la carpeta → `docs/`

Alternativas consideradas:
- `docs/` — convencional en GitHub, pero más asociada a documentación técnica pública
- `documentation/` — demasiado verboso para un repo de tooling
- `docs/` — semánticamente claro, prefijo punto indica carpeta de soporte (como `.claude/`, `.github/`), consistente con el estilo del proyecto

**Decisión:** `docs/` por consistencia con las carpetas punto del proyecto y por la distinción semántica respecto a `docs/` pública.

### D2: ¿Eliminar `Modo de Uso/` original?

**Decisión:** Sí. Una vez movido el contenido, la carpeta original se elimina para evitar duplicados. El docx es el único archivo en esa carpeta.

### D3: ¿Qué va en `docs/`?

| Archivo origen | Destino en `docs/` |
|---|---|
| `WORKFLOW.md` | `docs/workflow.md` |
| `Modo de Uso/Modo de uso.docx` | `docs/modo-de-uso.docx` |

`README.md` no se mueve — se actualiza para referenciar `docs/`.

## Security Layer

`project_type: tooling` — los artefactos gestionados son instrucciones para IA.

- Los archivos movidos (`WORKFLOW.md`, `modo-de-uso.docx`) no contienen secrets ni paths absolutos sensibles. Verificar antes del commit con `git diff --staged`.
- `README.md` solo agrega referencias relativas — sin rutas absolutas ni credenciales.

## Risks / Trade-offs

- **[Riesgo] Referencias externas rotas** → Los archivos se mueven de la raíz. Si algún repo externo linkea directamente a `WORKFLOW.md`, el link se rompe. Mitigación: es un repo de config privado; riesgo mínimo.
- **[Trade-off] `docs/` vs `docs/`** → `docs/` es menos estándar en GitHub. Si el repo se hace público en el futuro, considerar renombrar a `docs/`.

## Migration Plan

1. Crear directorio `docs/`
2. Mover `WORKFLOW.md` a `docs/workflow.md`
3. Mover `Modo de Uso/Modo de uso.docx` a `docs/modo-de-uso.docx`
4. Eliminar directorio `Modo de Uso/` (queda vacío)
5. Actualizar `README.md`: agregar sección de referencias a `docs/`
6. Commit con `Spec-ID: doc-folder-business-rules`

Rollback: `git revert` del commit generado.

## Impacto en proyectos existentes

Ninguno. Este repositorio es standalone — no es dependencia de otros proyectos. Los archivos movidos son documentación de referencia, no código ejecutado ni importado por herramientas externas.

## Open Questions

Sin preguntas abiertas. El alcance está acotado a reorganización de archivos sin cambios de comportamiento.
