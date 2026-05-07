# Tasks: security-layer-matrix

## 1. Actualizar CLAUDE.md global

- [ ] 1.1 Agregar sección `## Roles Claude / Copilot (OpenSpec)` con tabla explícita: Claude → explore/propose/verify/archive; Copilot → apply
- [ ] 1.2 Agregar sección `## Capa de Seguridad por Tipo de Proyecto` con la matriz completa (frontend, backend-api, etl, fullstack)
- [ ] 1.3 Reemplazar la sección `## Cómo llamar a Copilot` con el nuevo flujo OpenSpec: Claude anuncia el change, Copilot corre apply, Claude corre verify
- [ ] 1.4 Actualizar la regla 8 en `## Reglas globales`: Claude genera handoff OpenSpec, no prompts bash

## 2. Crear SKILL.md global para apply en Claude

- [ ] 2.1 Crear directorio `C:/Users/analistapi/.claude/skills/openspec-apply-change/`
- [ ] 2.2 Escribir `SKILL.md` con paso 6 reemplazado: anunciar handoff a Copilot + listar tareas pendientes + recordar `/opsx:verify`
- [ ] 2.3 Mantener pasos 1-5 y 7 idénticos al SKILL.md original para no romper la lectura de contexto

## 3. Actualizar openspec/config.yaml del proyecto TPA-Yacopini

- [ ] 3.1 Agregar `project_type: fullstack` dentro del bloque `context:`
- [ ] 3.2 Completar el bloque `context:` con stack real: Python 3.11, gspread, GAS, HTML5, Windows Task Scheduler
- [ ] 3.3 Agregar bloque `rules:` con convenciones de proposal, tasks y design

## 4. Verificación

- [ ] 4.1 Abrir Claude Code en el proyecto TPA-Yacopini y confirmar que `/opsx:apply` anuncia handoff en lugar de escribir código
- [ ] 4.2 Confirmar que al crear un nuevo change en TPA-Yacopini, el `design.md` generado incluye sección `## Security Layer`
