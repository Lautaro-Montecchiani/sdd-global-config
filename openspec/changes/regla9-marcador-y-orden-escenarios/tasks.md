# Tasks

## 1. CLAUDE.md global

- [ ] 1.1 En `.claude/CLAUDE.md`, regla 9: cambiar "los tests llevan marcador de ID" por "los tests llevan el marcador `test-plan: <nombre-change>/<ID>` (en el nombre, un comentario o el docstring)" según design D1, sin tocar el resto. Verificar S05 y S06 con `grep -n "test-plan" .claude/CLAUDE.md` y pegar la salida.
- [ ] 1.2 Copiar `.claude/CLAUDE.md` a `~/.claude/CLAUDE.md` y verificar con hash (ignorando fin de línea).
- [ ] 1.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas regla9-marcador-y-orden-escenarios`) y pushear; verificar que el espejo contiene `test-plan: <nombre-change>/<ID>`. Si el push falla por la cuenta de GitHub, avisar sin forzar.
- [ ] 1.4 Commitear `.claude/CLAUDE.md` en un commit aparte con la descripción del impacto y trailer `Spec-ID: regla9-marcador-y-orden-escenarios`.

## 2. Verificación manual

- [ ] 2.1 S01 — Pegar la fila de Codex de `templates/README.md`.

## 3. Verificación con Claude (no la ejecuta el Agente)

- [ ] 3.1 S02, S03, S04 — Tras el archive, confirmar el orden de los escenarios en `openspec/specs/agent-templates/spec.md` y, en el SRS regenerado, `CU-3.5.10.2.2` = Cursor, `.3` = Antigravity, `.4` = Sin Gemini CLI, sin otros CU renombrados.
- [ ] 3.2 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[regla9-marcador-y-orden-escenarios] Marcador test-plan en la regla 9 y orden de escenarios de la matriz` desde `change/regla9-marcador-y-orden-escenarios`.
- `/opsx:verify regla9-marcador-y-orden-escenarios` antes del merge; `/opsx:archive` después; regenerar el SRS y cerrar 3.1.
