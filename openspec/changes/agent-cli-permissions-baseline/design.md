## Context

El CLI del Agente (Antigravity) guarda su configuración real en `~/.gemini/antigravity-cli/settings.json` y su barra de estado en `~/.gemini/antigravity-cli/scratch/`. El repo tiene una copia versionada en `.gemini/` que quedó de un commit del 19 de junio: `settings.json` ya difiere del real (otro modelo y muchos menos workspaces) y los scripts de la barra de estado coinciden con los vivos. Ninguna guía ni plantilla usa esa carpeta.

La configuración real mezcla tres tipos de cosas: reglas de permisos que se quieren replicar en cualquier máquina, datos propios de cada máquina o persona (workspaces de confianza, modelo, colores) y restos puntuales de una sesión (un `git commit` de un proyecto, scripts identificados por un id de sesión).

## Goals / Non-Goals

**Goals:**
- Que una PC o notebook nueva pueda replicar las reglas de permisos actuales del Agente.
- Que el repo no contenga datos personales ni de la máquina.
- Que la instalación por máquina esté documentada junto al resto del setup.

**Non-Goals:**
- No modificar la configuración real de ninguna máquina.
- No versionar workspaces, modelo, colores ni credenciales.
- No reescribir la historia de git ni crear un script instalador.

## Decisions

### D1: Qué es baseline y qué es de cada máquina

| Elemento | Tratamiento |
|---|---|
| `toolPermission`, `artifactReviewPolicy` (`always-proceed`), `allowNonWorkspaceAccess` (`true`) | Baseline: va en la plantilla |
| `permissions.allow`: `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec`, `powershell` | Baseline: va en la plantilla |
| `statusLine` y scripts de la barra de estado | Baseline: van en la plantilla, con `%USERPROFILE%` |
| `trustedWorkspaces` | Por máquina: la plantilla trae un ejemplo con placeholder |
| `model`, `colorScheme` | Preferencia personal: no van en la plantilla |
| Comandos puntuales y scripts de sesión en `permissions.allow` | No se replican |

### D2: Plantilla con placeholders dentro de valores JSON

La plantilla es un JSON válido cuyos valores de máquina son cadenas con placeholders entre llaves (por ejemplo `{RUTA-A-TUS-PROYECTOS}\\{proyecto}`), en el mismo estilo que el resto de las guías.

Alternativas consideradas:
- Un script instalador que arme el `settings.json` — descartada: es código y queda fuera de alcance; si se quiere, se propone en otro change.
- Un merge automático con el `settings.json` existente — descartada por el mismo motivo; se documenta fusionar a mano si ya existe.

**Decisión:** plantilla estática con placeholders y pasos manuales de instalación.

### D3: Scripts de la barra de estado en `templates/`

Se copian los scripts vigentes a `templates/antigravity-statusline.bat` y `templates/antigravity-statusline.ps1`. El `.ps1` no tiene datos de usuario; el `.bat` reemplaza la ruta absoluta por `%USERPROFILE%`.

### D4: No reescribir la historia

Dejar de versionar `.gemini/` no borra sus versiones anteriores de la historia de git. Reescribirla es destructivo y queda fuera de alcance.

## Risks / Trade-offs

- **[Riesgo] La baseline es muy permisiva** → `always-proceed`, `allowNonWorkspaceAccess` y los comandos `powershell` y `cmd.exe` en la allowlist permiten que el Agente ejecute cualquier comando en cualquier carpeta sin pedir confirmación, así que la allowlist es en la práctica irrestricta. Se replica porque es la configuración vigente y una decisión explícita de la persona. Mitigación: cada máquina declara sus propios `trustedWorkspaces`, no se versionan credenciales, y la spec deja anotado que en equipos compartidos conviene evaluar quitar `powershell`, `cmd.exe` o `allowNonWorkspaceAccess`.
- **[Riesgo] La plantilla puede quedar desactualizada respecto de la config real** → Revisarla cuando cambien los permisos del Agente.
- **[Riesgo] Placeholders sin reemplazar** → La barra de estado no funcionaría y los workspaces no serían de confianza; los permisos generales sí se aplican. La guía indica qué completar.
- **[Trade-off] Los datos ya versionados siguen en la historia** → Aceptado para no reescribir la historia; el repo es privado.

## Security Layer

`project_type: tooling` — los artefactos gestionados son instrucciones y configuración para IA.

- No se versionan secrets ni credenciales: `oauth_creds.json`, tokens y archivos similares quedan fuera de las plantillas.
- No se versionan paths absolutos sensibles: usuario, workspaces reales ni rutas de recursos compartidos de la organización; las plantillas usan placeholders o `%USERPROFILE%`.
- Verificación: buscar el nombre de usuario y rutas de unidad en `templates/` sin resultados, y revisar `git diff --staged` antes de cada commit.
- Riesgo de permisos: ver el primer punto de Risks / Trade-offs.

## Impacto en proyectos existentes

Ninguno. Las máquinas que ya tienen su configuración no se ven afectadas: el change no toca `~/.gemini/`. La plantilla solo se usa al preparar una máquina nueva, y `.gemini/` sigue en el disco de quien la tenga. Retrocompatibilidad: nadie leía la copia versionada.

## Migration Plan

1. Dejar de versionar `.gemini/` y agregarlo a `.gitignore`.
2. Crear las tres plantillas en `templates/`.
3. Actualizar `templates/README.md`, `README.md` y `docs/modo-de-uso.md`, y regenerar el `.docx`.
4. Verificar que `git ls-files .gemini` no devuelve nada y que las plantillas son JSON válido sin datos de la máquina.
5. Commit con `Spec-ID: agent-cli-permissions-baseline`.

Rollback: `git revert` del commit generado.

## Open Questions

Sin preguntas abiertas.
