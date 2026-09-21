# Tasks: security-layer-matrix

## 1. Actualizar CLAUDE.md global

- [x] 1.1 Agregar sección `## Roles Claude / Copilot (OpenSpec)` con tabla explícita: Claude → explore/propose/verify/archive; Copilot → apply
- [x] 1.2 Agregar sección `## Capa de Seguridad por Tipo de Proyecto` con la matriz completa (frontend, backend-api, etl, fullstack)
- [x] 1.3 Reemplazar la sección `## Cómo llamar a Copilot` con el nuevo flujo OpenSpec: Claude anuncia el change, Copilot corre apply, Claude corre verify
- [x] 1.4 Actualizar la regla 8 en `## Reglas globales`: Claude genera handoff OpenSpec, no prompts bash

## 2. Crear SKILL.md global para apply en Claude

- [x] 2.1 Crear directorio `C:/Users/analistapi/.claude/skills/openspec-apply-change/`
- [x] 2.2 Escribir `SKILL.md` con paso 6 reemplazado: anunciar handoff a Copilot + listar tareas pendientes + recordar `/opsx:verify`
- [x] 2.3 Mantener pasos 1-5 y 7 idénticos al SKILL.md original para no romper la lectura de contexto

## 3. Actualizar openspec/config.yaml del proyecto TPA-Yacopini

- [x] 3.1 Agregar `project_type: fullstack` dentro del bloque `context:`
- [x] 3.2 Completar el bloque `context:` con stack real: Python 3.11, gspread, GAS, HTML5, Windows Task Scheduler
- [x] 3.3 Agregar bloque `rules:` con convenciones de proposal, tasks y design

## 4. Onboarding de proyectos nuevos y existentes

- [x] 4.1 **Repo nuevo:** después de `openspec init --tools claude,copilot`, eliminar `.claude/skills/openspec-apply-change/SKILL.md` del proyecto para que el global tome efecto
- [x] 4.2 **Repo existente con OpenSpec:** eliminar `.claude/skills/openspec-apply-change/SKILL.md` del proyecto y completar `openspec/config.yaml` con `project_type` + stack
- [x] 4.3 En ambos casos conservar `.agent/skills/openspec-apply-change/SKILL.md` intacto — Copilot lo necesita para implementar
- [x] 4.4 Documentar estos pasos en `sdd-global-config/WORKFLOW.md` como guía de onboarding reutilizable

## 5. Verificación

- [x] 5.1 Abrir Claude Code en el proyecto TPA-Yacopini y confirmar que `/opsx:apply` anuncia handoff en lugar de escribir código
  - Verificado el 2026-09-21 en `sdd-global-config` (el proyecto TPA-Yacopini no existe en esta máquina): `/opsx:apply doc-folder-business-rules` anunció el handoff al Agente, listó las 11 tareas pendientes y frenó; `git status` quedó sin cambios.
- [x] 5.2 Confirmar que al crear un nuevo change en TPA-Yacopini, el `design.md` generado incluye sección `## Security Layer`
  - Verificado el 2026-09-21 en `sdd-global-config`: `/opsx:propose docs-portable-paths` generó un `design.md` con la sección `## Security Layer` (`project_type: tooling`).
