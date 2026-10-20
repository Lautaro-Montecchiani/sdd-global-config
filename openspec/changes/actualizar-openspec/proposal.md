## Why

El repo y los proyectos del equipo se escribieron sobre OpenSpec 1.4.1; la última versión es la 1.14.3 (17/10/2026). Probé la 1.14.3 en carpetas temporales y hay cambios que hacen que nuestras guías y specs queden desactualizadas o fallen:

- Antigravity instala sus skills y workflows en `.agents/` (antes `.agent/`). `openspec update` crea `.agents/` y deja la carpeta vieja `.agent/` si tiene archivos distintos. Nuestras guías, la spec `project-onboarding` y el `context:` de `config.yaml` dicen `.agent/skills/openspec-apply-change/`.
- `openspec validate --strict` marca como warning los requirements de más de 500 caracteres (desde 1.14.1) y falla. En este repo, 18 de 61 requirements pasan ese límite.
- La telemetría anónima de OpenSpec está activa en esta máquina (la config global ya tiene `telemetry.anonymousId`); hay que decidir si se desactiva en máquinas de la empresa.
- Los comandos y skills híbridos de este repo (`/opsx:*` y `openspec-*`) son versiones propias que no se actualizan con `openspec update`. Las skills nuevas traen mejoras que conviene evaluar una por una (la propuesta lee el código antes de redactar, el apply no dice "listo para archivar" cuando solo terminaron las tareas, el verify revisa requirements eliminados).

## What Changes

- Actualizar OpenSpec a 1.14.3 en esta máquina (`npm install -g @fission-ai/openspec@1.14.3`) y verificar con `openspec --version`.
- Guías, specs y `config.yaml` pasan a `.agents/skills/openspec-apply-change/` para Antigravity, con una nota para proyectos que todavía tienen `.agent/`.
- Nueva sección "Actualizar OpenSpec en un proyecto existente" en `docs/workflow.md` y `docs/modo-de-uso.md`: `openspec update`, qué hacer con el `.agent/` que queda y cómo revisar los cambios antes de commitear.
- El flujo propio usa `openspec validate` sin `--strict`; los requirements nuevos se escriben de hasta 500 caracteres cuando sea posible. No se reescriben los 18 requirements existentes.
- Telemetría de OpenSpec desactivada por máquina (`openspec config set telemetry.enabled false`), documentada en el setup por máquina.
- Portar a nuestros comandos y skills tres mejoras de 1.14.x: propuesta que lee código y tests antes de redactar, mensaje de apply cuando todas las tareas están marcadas y verify de requirements REMOVED. Se decide una por una en el design (D5); el resto no se adopta.
- Sin cambios al handoff ni al flujo híbrido.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `project-onboarding`: `.agents/` en la comprobación de Antigravity y en la guía de proyectos existentes; nuevos requirements para actualizar OpenSpec en un proyecto y para desactivar la telemetría por máquina.

## Impact

- Archivos del repo: `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` (y su `.docx`), `templates/cursor/README.md`, `openspec/config.yaml`, `.claude/commands/opsx/{propose,apply,verify}.md` y `skills/openspec-{propose,apply-change,verify-change}/SKILL.md`.
- Fuera del repo: OpenSpec global de esta máquina (`npm`), configuración global de OpenSpec (`telemetry.enabled`) y copias instaladas en `~/.claude`.
- Los otros proyectos del equipo no se tocan en este change: siguen funcionando con los archivos ya generados; la guía nueva describe cómo actualizarlos de a uno.
- Hay una instalación global de software: es la misma herramienta ya en uso, pero si Sistemas controla las versiones de `npm` en los equipos, conviene avisarles antes de actualizar.
