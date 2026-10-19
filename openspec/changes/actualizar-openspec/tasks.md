# Tasks

## 1. Instalación de OpenSpec en esta máquina

- [x] 1.1 Instalar OpenSpec 1.14.3 con `npm install -g @fission-ai/openspec@1.14.3` y pegar la salida de `openspec --version` (debe decir 1.14.3). Si `npm` pide permisos de administrador o falla, frenar y avisar: no usar otro método ni cambiar permisos.
- [x] 1.2 Ejecutar `openspec config set telemetry.enabled false` y pegar la salida de `openspec config get telemetry.enabled` (S09).

## 2. Guías, specs y configuración

- [x] 2.1 En `README.md`: agregar al setup por máquina el paso de telemetría (`openspec config set telemetry.enabled false` y `openspec config get telemetry.enabled`), común a Antigravity y Cursor, y cambiar toda comprobación de Antigravity a `.agents\skills\openspec-apply-change\`. Verificar los escenarios S01, S03 y S08.
- [x] 2.2 En `docs/workflow.md`: cambiar `.agent\skills\openspec-apply-change\` a `.agents\skills\...` (comprobación y advertencia de "Nunca eliminar"), ajustar la sección "Agregar Cursor a un proyecto existente" a `.agents/` (y `.agent/` como carpeta anterior) y agregar la sección "Actualizar OpenSpec en un proyecto existente" según design D2 (`openspec update`, `git status` y `git diff`, commit aparte, qué hacer con `.agent/`, y que no se recomienda `--strict`, D3). Verificar S03, S04 y S06.
- [x] 2.3 En `docs/modo-de-uso.md`: los mismos cambios que 2.1 y 2.2. Verificar los mismos escenarios sobre ese archivo.
- [x] 2.4 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc`; verificar que el docx menciona `.agents\skills\openspec-apply-change`, `telemetry.enabled` y `openspec update`.
- [x] 2.5 En `templates/cursor/README.md`: ajustar la mención de `.agent/`/`.agents/` a `.agents/` (y `.agent/` como carpeta anterior). Verificar con `grep -n "\.agent" templates/cursor/README.md`.
- [x] 2.6 Actualizar el `context:` de `openspec/config.yaml` cambiando `.agent/skills/` por `.agents/skills/`, sin tocar el resto del `context:`. Verificar con `openspec validate actualizar-openspec`.
- [x] 2.7 Chequeo de rutas: con un script en archivo (no en línea), verificar que `README.md`, `docs/*.md`, `templates/` y `openspec/config.yaml` no contienen `C:\Users`.

## 3. Comandos y skills

- [x] 3.1 Generar las skills de 1.14.3 en un directorio temporal fuera del repo (`openspec init --tools claude`) y pegar el fragmento exacto de cada mejora que se porta (design D5): propuesta que lee código antes de redactar, mensaje del apply con todas las tareas marcadas, verify de requirements REMOVED. Si falta alguno en esa versión, frenar y avisar.
- [x] 3.2 Portar la mejora de propose a `.claude/commands/opsx/propose.md` y `skills/openspec-propose/SKILL.md`, la de apply a `.claude/commands/opsx/apply.md` y `skills/openspec-apply-change/SKILL.md`, y la de verify a `skills/openspec-verify-change/SKILL.md` y al comando de verify equivalente en `.claude/commands/opsx/`, manteniendo idénticos comando y skill entre sí donde hoy lo son y sin tocar el handoff. Verificar con `git diff` que solo cambian esas partes. Si el comando de verify no tiene la parte equivalente, portarla solo a la skill y anotarlo.
- [x] 3.3 Borrar el directorio temporal de 3.1.

## 4. Instalación global y sincronización

- [x] 4.1 Copiar `.claude/commands/opsx/*.md` a `~/.claude/commands/opsx/` y `skills/openspec-propose`, `skills/openspec-apply-change` y `skills/openspec-verify-change` a `~/.claude/skills/`; verificar con hash (ignorando fin de línea) que las copias instaladas coinciden con el repo.
- [x] 4.2 Commitear los cambios de comandos y skills en un commit aparte con la descripción del impacto y trailer `Spec-ID: actualizar-openspec`.

## 5. Verificación manual

- [x] 5.1 S01, S03, S04, S06, S08 — Buscar en las tres guías y en `config.yaml` lo indicado en cada escenario y pegar las líneas; confirmar que no queda `.agent\skills` ni `.agent/skills` como ruta de comprobación.
- [x] 5.2 S02, S05 — En directorios temporales fuera del repo con 1.14.3: (a) `openspec init --tools antigravity` y `openspec update`, confirmar `.agents/skills/openspec-apply-change/` y que no existe `.claude/`; (b) `openspec init --tools cursor` y `openspec update`, confirmar `.cursor/commands/opsx-apply.md` y que no existe `.claude/`; (c) sobre (a), `openspec init --tools cursor` e instalar la regla, confirmar los archivos de Cursor y las skills de Antigravity; pegar los listados y borrar los directorios.
- [x] 5.3 S07 — En un directorio temporal: `openspec init --tools antigravity` con OpenSpec 1.4.1 (`npx --yes @fission-ai/openspec@1.4.1 init --tools antigravity`), modificar un archivo de `.agent/`, correr `openspec update` con 1.14.3 y confirmar `.agents/skills/openspec-apply-change/` y que `.agent/` conserva el archivo modificado; pegar los listados y borrar el directorio.

## 6. Verificación con Claude y con el usuario (no la ejecuta el Agente)

- [ ] 6.1 En una sesión nueva de Claude con los comandos instalados, correr `/opsx:propose` sobre un repo de prueba y confirmar que el propose y el cierre siguen anunciando `/openspec-apply-change` (Antigravity) y `/opsx-apply` (Cursor) y que lee código antes de redactar.
- [ ] 6.2 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[actualizar-openspec] Actualizar OpenSpec a 1.14.3 y adaptar guías, specs y comandos` desde `change/actualizar-openspec`.
- `/opsx:verify actualizar-openspec` en Claude antes del merge; `/opsx:archive actualizar-openspec` después.
- Actualizar los otros proyectos del equipo de a uno con la guía nueva (Yacotrucks, CRM-Usados y el resto), avisando a `yacjuanma` antes de tocar sus proyectos.
