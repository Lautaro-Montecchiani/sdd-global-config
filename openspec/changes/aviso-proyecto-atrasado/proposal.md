## Why

Los proyectos quedan con reglas y comandos del Agente viejos (`AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/sdd-workflow.mdc` y los comandos `/odd-apply`) sin que nadie lo note. Un relevamiento del 13/11/2026 con `sincronizar-proyecto.ps1 -Comprobar` dio que ninguno de los 7 repos de esta PC con reglas del Agente estaba al día: seis atrasados y uno bloqueado por contenido propio sin marcar. El vault registra 27 proyectos, varios en otras máquinas. El CI de cada proyecto no puede detectarlo porque no tiene acceso a `sdd-global-config` (repo privado), y solo 2 proyectos tienen `pr-check.yml`.

## What Changes

- `scripts/sincronizar-proyecto.ps1` suma el modo `-Aviso`: no escribe, controla solo los archivos del Agente que ya existen en el proyecto (no pide los que faltan) y resume el resultado en una línea con rutas relativas y el comando para arreglarlo. Termina con 0 si está todo al día y con 1 si hay algo atrasado o bloqueado.
- `.claude/CLAUDE.md`, sección "Al iniciar cada sesión": en un proyecto que tiene archivos del Agente, Claude corre `sincronizar-proyecto.ps1 -Proyecto . -Aviso` desde `$env:SDD_CONFIG_REPO` y muestra la línea. No corrige nada por su cuenta. No corre en `sdd-global-config` (lo controla su CI) ni en carpetas sin archivos del Agente. Sin `SDD_CONFIG_REPO`, avisa que no se pudo controlar.
- `README.md`, `docs/modo-de-uso.md` y `docs/workflow.md` documentan `-Aviso`.
- `docs/arquitectura/vision.md` suma a la hoja de ruta el control en el CI de los proyectos (huella en los archivos generados), que queda para un change aparte.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `rules-sync`: requirement nuevo sobre el modo `-Aviso` de `sincronizar-proyecto.ps1` y requirement nuevo sobre el aviso al iniciar sesión en un proyecto.

## Non-goals

- Controlar los proyectos desde su CI (`pr-check.yml`) o con un token: va en un change aparte (huella en los archivos generados).
- Actualizar los proyectos atrasados: es una tarea operativa con `sincronizar-proyecto.ps1`, fuera de este change.
- Avisar en las sesiones del Agente (Antigravity, Cursor, Copilot): el aviso es de Claude al iniciar sesión.
- Detectar que el clon local de `sdd-global-config` está atrasado respecto de GitHub: el aviso compara contra el clon local; la actualización del clon sigue siendo `git pull`.

## Impact

- **Archivo global que se modifica:** `.claude/CLAUDE.md` (sección "Al iniciar cada sesión"), porque el aviso es un paso nuevo del inicio de sesión de Claude en todos los proyectos. Llega a las máquinas con `instalar.ps1` y al espejo del vault.
- **Script:** `scripts/sincronizar-proyecto.ps1` suma un parámetro (`-Aviso`). Los modos existentes no cambian.
- **Tests:** `tests/aviso-proyecto-atrasado.Tests.ps1` nuevo; `tests/sincronizar-proyecto.Tests.ps1` sigue en verde sin cambios.
- **Proyectos:** ningún archivo de los proyectos cambia. Los que tengan reglas atrasadas van a mostrar el aviso en la próxima sesión de Claude.
