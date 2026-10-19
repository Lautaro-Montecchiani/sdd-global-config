# Tasks

## 1. Carpeta de Cursor en templates

- [ ] 1.1 Crear `templates/cursor/sdd-workflow.mdc` según design D1: frontmatter con `description` y `alwaysApply: true`; contenido de `templates/copilot/copilot-instructions.md` (lectura de `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con fallback `C:\TPA\_global\reglas-globales.md`, rol constructor, git con ramas `change/{nombre}`, formato `{type}: {desc}` y trailer `Spec-ID`, memoria del proyecto y las 7 reglas de ejecución del Agente); sección "Comandos permitidos" que habilita solo `/opsx-apply` y deriva `/opsx-propose`, `/opsx-verify`, `/opsx-archive`, `/opsx-explore` y `/opsx-sync` a Claude; aclaración de que las instrucciones dirigidas a Claude en `CLAUDE.md` no le aplican. Pegar en el resumen las líneas del frontmatter y de "Comandos permitidos" como evidencia.
- [ ] 1.2 Crear `templates/cursor/README.md` según design D1, D5 y D6: para qué agente es, archivo `sdd-workflow.mdc` → `.cursor\rules\sdd-workflow.mdc` del proyecto con su comando de copia, permisos de ejecución automática de Cursor (allowlist `git status`, `git diff`, `git branch`, `git restore`, `openspec`, advertencia sobre `powershell`/`cmd.exe`, sin rutas reales) y cómo agregar Cursor a un proyecto que ya usa Antigravity.
- [ ] 1.3 En `templates/README.md`: reemplazar la fila de Cursor de la matriz por la exacta de design D7, agregar `cursor/` a la lista de carpetas, y quitar el texto "lo agrega `agente-cursor`" y la advertencia de que falta `templates/cursor/`.

## 2. Handoff de Claude

- [ ] 2.1 En `.claude/CLAUDE.md`, reemplazar `/openspec-apply-change {nombre}` por `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor) en la tabla de roles, la regla 8, el flujo OpenSpec y la tabla SDD Manual vs OpenSpec, y en la línea "Onboarding de agentes no-Claude" sumar que para Cursor se copia `templates\cursor\sdd-workflow.mdc` → `.cursor\rules\sdd-workflow.mdc` por proyecto. No quitar las rutas de `GEMINI.md` ni de las otras plantillas. Verificar con `grep -n "opsx-apply" .claude/CLAUDE.md`.
- [ ] 2.2 Reemplazar el comando de handoff por el anuncio de los dos agentes de design D2 en `.claude/commands/opsx/apply.md`, `.claude/commands/opsx/propose.md`, `skills/openspec-apply-change/SKILL.md` y `skills/openspec-propose/SKILL.md`, manteniendo idénticos comando y skill entre sí donde hoy lo son. Verificar con `grep -rn "opsx-apply" .claude/commands skills`.
- [ ] 2.3 Actualizar el `context:` de `openspec/config.yaml` de este repo según design D8, sin tocar el resto del `context:` ni las subsecciones. Verificar con `openspec validate agente-cursor`.

## 3. Guías

- [ ] 3.1 En `README.md`: separar el setup por máquina en un bloque de Antigravity (los pasos actuales) y uno de Cursor (auto-run según design D5), con la indicación de seguir solo el del agente que se usa; en "Sumar un proyecto al workflow", `openspec init --tools antigravity` o `openspec init --tools cursor` y, para Cursor, copiar `templates\cursor\sdd-workflow.mdc` a `.cursor\rules\sdd-workflow.mdc`; actualizar la tabla del repo y el flujo resumido con el handoff por agente. Verificar los escenarios S05, S08, S10, S11 y S14.
- [ ] 3.2 En `docs/workflow.md`: init con `--tools antigravity` o `--tools cursor`, verificación por agente (`.agent\skills\openspec-apply-change\` o `.cursor\commands\opsx-apply.md`), instalación de la regla de Cursor, handoff por agente y nueva subsección "Agregar Cursor a un proyecto existente" (design D6). Verificar los escenarios S05, S08 y S12.
- [ ] 3.3 En `docs/modo-de-uso.md`: mismos cambios que 3.1 y 3.2. Verificar los mismos escenarios sobre ese archivo.
- [ ] 3.4 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc`; verificar que el docx menciona `/opsx-apply` y `cursor\sdd-workflow.mdc` y sigue mencionando `antigravity\settings.json`.
- [ ] 3.5 En `CONTRIBUTING.md`, reemplazar el comando de handoff por el anuncio de los dos agentes. Verificar con `grep -rn "openspec-apply-change" README.md CONTRIBUTING.md docs/*.md` que solo quedan menciones válidas (Antigravity y la skill de Claude).
- [ ] 3.6 Chequeo de rutas: con un script en archivo (no en línea), verificar que `templates/`, `README.md`, `docs/*.md`, `CONTRIBUTING.md` y `.claude/CLAUDE.md` no contienen `C:\Users`.

## 4. Instalación y sincronización global

- [ ] 4.1 Copiar `.claude/CLAUDE.md` a `~/.claude/CLAUDE.md`, `.claude/commands/opsx/*.md` a `~/.claude/commands/opsx/` y `skills/openspec-apply-change` y `skills/openspec-propose` a `~/.claude/skills/`; verificar con hash (ignorando fin de línea) que las copias instaladas coinciden con el repo.
- [ ] 4.2 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md` y commitear en el vault (`chore: sdd-global-config — sync reglas agente-cursor`); verificar que el espejo menciona `/opsx-apply`.
- [ ] 4.3 Commitear el cambio de `.claude/CLAUDE.md` en un commit separado con la descripción del impacto (handoff por agente) y trailer `Spec-ID: agente-cursor`.

## 5. Verificación manual

- [ ] 5.1 S01, S02 — Listar `templates/` recursivamente y pegar la salida; revisar `templates/cursor/README.md` contra design D1, D5 y D6.
- [ ] 5.2 S03 — Pegar la fila de Cursor de `templates/README.md`, compararla con design D7 y confirmar que no queda "lo agrega agente-cursor".
- [ ] 5.3 S04, S06 — Buscar "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en las cuatro plantillas de reglas y pegar el conteo; pegar de `templates/cursor/sdd-workflow.mdc` `alwaysApply: true`, la lectura del espejo del vault con su fallback y el rol de constructor.
- [ ] 5.4 S05, S08, S10, S11, S12 — Buscar en `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` las rutas de la regla de Cursor, los comandos `openspec init`, los bloques de setup por agente y la subsección de proyecto existente; confirmar que no hay `claude` en `--tools` ni "liberar el slot", y que existen `templates/gemini/GEMINI.md` y `templates/antigravity/settings.json`; pegar las líneas.
- [ ] 5.5 S14, S15, S16, S17 — Pegar la allowlist y la advertencia sobre shells de Cursor; confirmar con `openspec validate agente-cursor --strict` y que el change no tiene secciones REMOVED y los requirements de Antigravity siguen en `openspec/specs/agent-cli-permissions/spec.md`; buscar "Copilot", "Gemini", "Antigravity" y "Cursor" como rol en los `CLAUDE.md` de proyecto alineados y pegar el resultado.
- [ ] 5.6 S09, S13 — En directorios temporales fuera del repo: (a) `openspec init --tools cursor` + `openspec update`, confirmar `.cursor/commands/opsx-apply.md` y que no existe `.claude/`; (b) `openspec init --tools antigravity`, confirmar `.agent/skills/openspec-apply-change/`; (c) sobre (b), `openspec init --tools cursor` + copiar la regla, confirmar los archivos de Cursor, que siguen las skills de Antigravity y que no hay `.claude/`; pegar los listados y borrar los directorios.

## 6. Verificación con Claude y con el usuario (no la ejecuta el Agente)

- [ ] 6.1 S18 — En una sesión nueva de Claude con los comandos instalados, correr `/opsx:apply <change>` y el cierre de `/opsx:propose` en un repo de prueba y confirmar que anuncian `/openspec-apply-change` (Antigravity) y `/opsx-apply` (Cursor).
- [ ] 6.2 S07 — El usuario abre un proyecto de prueba con la regla instalada en Cursor, pide `/opsx-propose` y confirma que Cursor se niega y deriva a Claude; si Cursor no está disponible, se anota y se verifica solo el texto de "Comandos permitidos".
- [ ] 6.3 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[agente-cursor] Cursor se suma como agente soportado junto a Antigravity` desde `change/agente-cursor`.
- `/opsx:verify agente-cursor` en Claude antes del merge; `/opsx:archive agente-cursor` después.
- Agregar Cursor a Yacotrucks (D6): ya tiene `.cursor/commands/`; falta `.cursor/rules/sdd-workflow.mdc`.
