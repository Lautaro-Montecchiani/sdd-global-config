# Proposal: Security Layer Matrix

## Intent

El workflow SDD híbrido (Claude + Copilot) no tiene una capa de seguridad de aplicación definida. Cuando se crean specs para un proyecto frontend, backend, o ETL, no hay una referencia que indique qué controles de seguridad son obligatorios según el tipo de proyecto. Esto genera specs inconsistentes donde la seguridad queda a criterio de cada sesión.

## Scope

- Agregar matriz de seguridad por tipo de proyecto al CLAUDE.md global
- Definir cómo se declara el `project_type` en `openspec/config.yaml` de cada proyecto
- Modificar el SKILL.md de `apply` en Claude para que genere handoff a Copilot en lugar de escribir código
- Actualizar la tabla de roles Claude/Copilot en el CLAUDE.md global
- Actualizar el `openspec/config.yaml` del proyecto TPA-Yacopini como proyecto piloto

## Non-goals

- No modifica el comportamiento del SKILL.md de Copilot (sigue implementando)
- No instala ninguna librería de seguridad — solo define los requisitos en specs
- No aplica retroactivamente a changes ya archivados

## Approach

Editar `~/.claude/CLAUDE.md` para agregar la sección de seguridad por tipo. Crear `~/.claude/skills/openspec-apply-change/SKILL.md` global con el comportamiento de handoff. Actualizar `openspec/config.yaml` del proyecto TPA con contexto real del stack.
