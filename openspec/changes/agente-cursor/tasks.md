# Tasks

## 1. Plantilla de reglas de Cursor

- [ ] 1.1 Crear `templates/cursor-rules.mdc` según design D1 (frontmatter con `description` y `alwaysApply: true`; lectura de `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con fallback `C:\TPA\_global\reglas-globales.md`; rol constructor; git; memoria del proyecto; sección "Comandos permitidos" que habilita solo `/opsx-apply` y deriva propose/verify/archive/explore/sync a Claude; aclaración de que las instrucciones dirigidas a Claude en `CLAUDE.md` no le aplican). Verificar los escenarios "Contenido de la regla" y "Cursor solo implementa" de la spec `project-onboarding` leyendo el archivo.
- [ ] 1.2 Eliminar `templates/GEMINI.md` y `templates/antigravity-settings.json`, y reescribir `templates/README.md` (tabla de plantillas con `cursor-rules.mdc` → `.cursor\rules\sdd-workflow.mdc` y `copilot-instructions.md`; sección de permisos de Cursor con la allowlist de D5 y la advertencia sobre `powershell`/`cmd.exe`; sin la baseline ni la barra de estado de Antigravity). Verificar con `ls templates` y los escenarios "Plantillas retiradas" y "Advertencia sobre shells".

## 2. Handoff de Claude

- [ ] 2.1 En `.claude/CLAUDE.md`, reemplazar `/openspec-apply-change {nombre}` por `/opsx-apply {nombre}` en la tabla de roles, la regla 8, el flujo OpenSpec y la tabla SDD Manual vs OpenSpec, y reescribir la línea "Onboarding de agentes no-Claude" para que indique copiar `templates\cursor-rules.mdc` → `.cursor\rules\sdd-workflow.mdc` por proyecto (sin `GEMINI.md`). Verificar con `grep -n "openspec-apply-change\|GEMINI" .claude/CLAUDE.md` sin resultados de handoff.
- [ ] 2.2 Reemplazar el comando de handoff por `/opsx-apply <name>` en `.claude/commands/opsx/apply.md`, `.claude/commands/opsx/propose.md`, `skills/openspec-apply-change/SKILL.md` y `skills/openspec-propose/SKILL.md`, manteniendo idénticos comando y skill entre sí donde hoy lo son. Verificar el escenario "El comando de handoff es el de Cursor" con `grep -rn "openspec-apply-change {\|/openspec-apply-change <" .claude/commands skills` (sin resultados).
- [ ] 2.3 Actualizar el `context:` de `openspec/config.yaml` de este repo: el Agente es Cursor y usa `.cursor/commands/` y `.cursor/rules/`. Verificar con `openspec validate agente-cursor`.

## 3. Guías

- [ ] 3.1 En `README.md`: quitar los pasos 4 y 5 del setup por máquina y agregar la configuración de auto-run de Cursor (D5); en "Sumar un proyecto al workflow" usar `openspec init --tools cursor` y copiar `templates\cursor-rules.mdc` a `.cursor\rules\sdd-workflow.mdc`; actualizar la tabla del repo y el flujo resumido con `/opsx-apply`. Verificar los escenarios "Comando de init sin claude", "Instalación de la regla", "Allowlist documentada" y "Setup sin pasos de Antigravity" sobre `README.md`.
- [ ] 3.2 En `docs/workflow.md`: init con `--tools cursor`, verificación de `.cursor\commands\opsx-apply.md` (en lugar de `.agent\skills\...`), instalación de la regla, handoff `/opsx-apply`, y nueva subsección de migración de Antigravity a Cursor (D6). Verificar los escenarios "Comando de init sin claude", "Instalación de la regla" y "Procedimiento de migración documentado" sobre ese archivo.
- [ ] 3.3 En `docs/modo-de-uso.md`: mismos cambios que 3.1 y 3.2 (setup por máquina sin Antigravity, permisos de Cursor, init, verificación, regla, handoff, migración). Verificar los mismos escenarios sobre ese archivo.
- [ ] 3.4 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` y verificar que el docx menciona `/opsx-apply` y no `antigravity-settings.json`.
- [ ] 3.5 En `CONTRIBUTING.md`, reemplazar el comando de handoff por `/opsx-apply`. Verificar con `grep -rn "openspec-apply-change" README.md CONTRIBUTING.md docs/*.md` (solo pueden quedar menciones a la skill de Claude, no como comando para el Agente).
- [ ] 3.6 Chequeo de rutas: con un script en archivo (no en línea), verificar que `templates/`, `README.md`, `docs/*.md`, `CONTRIBUTING.md` y `.claude/CLAUDE.md` no contienen `C:\Users`.

## 4. Instalación y sincronización global

- [ ] 4.1 Copiar `.claude/CLAUDE.md` a `~/.claude/CLAUDE.md`, `.claude/commands/opsx/*.md` a `~/.claude/commands/opsx/` y `skills/openspec-apply-change` y `skills/openspec-propose` a `~/.claude/skills/`; verificar con `diff` que las copias instaladas coinciden con el repo.
- [ ] 4.2 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md` y commitear en el vault (`chore: sdd-global-config — sync reglas agente-cursor`); verificar que el espejo menciona `/opsx-apply`.
- [ ] 4.3 Commitear el cambio de `.claude/CLAUDE.md` en un commit separado con la descripción del impacto (handoff a Cursor) y trailer `Spec-ID: agente-cursor`.

## 5. Prueba en proyecto

- [ ] 5.1 Verificar que el cambio aplica en un proyecto de prueba: en un directorio temporal, `openspec init --tools cursor` + `openspec update` + copiar la regla, y comprobar el escenario "Un proyecto iniciado solo con el Agente no tiene copias de Claude"; luego, en una sesión nueva de Claude en ese directorio, `/opsx:apply <change>` debe anunciar `/opsx-apply`, y en Cursor la regla debe aparecer activa y el Agente debe negarse a ejecutar `/opsx-propose`.

## Workflow follow-up

- Abrir PR `[agente-cursor] Cursor reemplaza a Antigravity como constructor` desde `change/agente-cursor`.
- `/opsx:verify agente-cursor` en Claude antes del merge; `/opsx:archive agente-cursor` después.
- Migrar Yacotrucks (D6): ya tiene `.cursor/commands/`; falta `.cursor/rules/sdd-workflow.mdc` y decidir si se borra `.agents/`.
