# Tasks

## 1. Plantillas

- [x] 1.1 Mover la plantilla con `git mv templates/gemini/GEMINI.md templates/antigravity/GEMINI.md` (design D1) y, dentro de ella, cambiar "Gemini/Antigravity" por "Antigravity" si aparece. Pegar `git status` como evidencia.
- [x] 1.2 Integrar en `templates/antigravity/README.md` la instalación de `GEMINI.md` (destino `~/.gemini/GEMINI.md`, una vez por máquina, fusionar si ya existe con contenido propio) y quitar "compartidas con Gemini CLI" (design D2). Eliminar `templates/gemini/README.md` y la carpeta `templates/gemini/`. Verificar S01 y S02.
- [x] 1.3 En `templates/README.md`: quitar `gemini/` de la lista de carpetas, borrar la fila de Gemini CLI, apuntar la fila de Antigravity a `antigravity/GEMINI.md` → `~/.gemini/GEMINI.md` y reemplazar la fuente de Gemini CLI por la nota del retiro con el enlace de design D3. Verificar S03, S03b, S04 y S05.
- [x] 1.4 En `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/cursor/README.md`, cambiar "Gemini/Antigravity" por "Antigravity" donde aparezca. Verificar con `grep -rn "Gemini" templates/` y pegar la salida (solo deben quedar la nota del retiro y rutas `~/.gemini/`).

## 2. CLAUDE.md global

- [x] 2.1 En `.claude/CLAUDE.md`: "Gemini/Antigravity" → "Antigravity" en las reglas de ejecución, y `templates/gemini/GEMINI.md` / `templates\gemini\GEMINI.md` → `templates/antigravity/GEMINI.md` / `templates\antigravity\GEMINI.md` en "Distribución a agentes no-Claude" y "Onboarding de agentes no-Claude" (design D4). Verificar con `grep -n "gemini" .claude/CLAUDE.md` y pegar la salida.
- [x] 2.2 Copiar `.claude/CLAUDE.md` a `~/.claude/CLAUDE.md` y verificar con hash (ignorando fin de línea).
- [x] 2.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md` y commitear en el vault (`chore: sdd-global-config — sync reglas retirar-gemini-cli`); verificar que el espejo menciona `templates\antigravity\GEMINI.md`. Si el push del vault falla por la cuenta, avisar sin forzar.
- [x] 2.4 Commitear `.claude/CLAUDE.md` en un commit aparte con la descripción del impacto y trailer `Spec-ID: retirar-gemini-cli`.

## 3. Guías

- [x] 3.1 En `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`, cambiar `templates\gemini\GEMINI.md` por `templates\antigravity\GEMINI.md` y quitar las menciones a Gemini CLI como agente (design D4), conservando las rutas `~/.gemini/`. Verificar S08 y S10.
- [x] 3.2 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc`; verificar que el docx menciona `templates\antigravity\GEMINI.md` y no `templates\gemini`.
- [x] 3.3 Chequeo de rutas: con un script en archivo (no en línea), verificar que `README.md`, `docs/*.md`, `templates/` y `.claude/CLAUDE.md` no contienen `C:\Users`.

## 4. Verificación manual

- [x] 4.1 S01, S02, S09 — Listar `templates/` recursivamente y pegar la salida; revisar `templates/antigravity/README.md`.
- [x] 4.2 S03, S03b, S04, S05 — Pegar las filas de Antigravity, Codex y Cursor de la matriz y la nota del retiro de Gemini CLI.
- [x] 4.3 S06, S07, S11 — Buscar las tres frases de reglas, `apply\AAAA-MM-DD` y `test-plan:` en las plantillas y en `.claude/CLAUDE.md`; pegar los conteos.
- [x] 4.4 S08, S10 — Pegar los bloques de setup de Antigravity y Cursor y la búsqueda de `templates\gemini` / `templates/gemini` (excluyendo `docs/srs.md` y `openspec/changes/archive/`), que debe dar cero.

## 5. Verificación con Claude (no la ejecuta el Agente)

- [ ] 5.1 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[retirar-gemini-cli] Retirar Gemini CLI y mover GEMINI.md a la plantilla de Antigravity` desde `change/retirar-gemini-cli`.
- `/opsx:verify retirar-gemini-cli` en Claude antes del merge; `/opsx:archive retirar-gemini-cli` después; regenerar el SRS.
- Evaluar en otro change pasar de `~/.gemini/GEMINI.md` a `~/.gemini/AGENTS.md`, probándolo antes en Antigravity.
