# Workflow SDD Híbrido — Contexto global para el Agente

## Reglas globales (fuente de verdad)

Antes de trabajar en cualquier proyecto, leé las reglas completas del workflow SDD en el vault de Obsidian:

- `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback: `C:\TPA\_global\reglas-globales.md`)

Ese archivo define: roles (Claude arquitecto / Agente constructor), flujo OpenSpec (propose → apply → verify → archive), formato de commits (`{type}: {desc}` + trailer `Spec-ID: {nombre-change}`), branches `change/{nombre}`, reglas de seguridad universales y por tipo de proyecto, y la capa de persistencia del vault.

## Memoria por proyecto

Cada proyecto tiene contexto histórico en el vault: `$env:OBSIDIAN_VAULT\projects\{nombre-proyecto}\` — `context.md` (estado actual), `decisions\` (decisiones por change) y `archive\` (changes completados). Leé `context.md` al empezar a trabajar en un proyecto.

## Reglas mínimas (si no podés leer el vault)

- Nunca commitear `.env`, `*.key`, `*.pem` ni credenciales; revisar `git diff --staged` antes de cada commit.
- Nunca hardcodear secrets — todo a `.env` excluido del repo.
- Nunca trabajar directo en `main`/`master` para changes con spec.
