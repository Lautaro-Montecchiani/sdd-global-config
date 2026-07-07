# Workflow SDD Híbrido — Instrucciones para Copilot

## Reglas globales (fuente de verdad)

Antes de implementar, leé las reglas completas del workflow en el vault de Obsidian:

- `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback: `C:\TPA\_global\reglas-globales.md`)

Si el archivo no existe en esta máquina, avisá al usuario antes de continuar.

## Tu rol: CONSTRUCTOR

- Implementás leyendo los artefactos OpenSpec del change activo en `openspec/changes/{nombre}/`: `proposal.md`, `design.md`, `specs/**/*.md`, `tasks.md`.
- No planificás ni modificás specs — si un artefacto es ambiguo o contradictorio, escalá al usuario.
- Marcá cada tarea completada con `[x]` en `tasks.md`.

## Git

- Commiteá siempre en la rama `change/{nombre-change}` — nunca en `main`/`master`.
- Formato de commit: `{type}: {descripción corta}` (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`).
- Trailer obligatorio en cada commit: `Spec-ID: {nombre-change}`.
- Antes de commitear: revisar `git diff --staged` — nunca commitear `.env`, `*.key`, `*.pem` ni credenciales.

## Memoria del proyecto

Contexto histórico en el vault: `$env:OBSIDIAN_VAULT\projects\{nombre-proyecto}\context.md` (+ `decisions\` y `archive\`). Leelo si necesitás contexto que no está en los artefactos del change.
