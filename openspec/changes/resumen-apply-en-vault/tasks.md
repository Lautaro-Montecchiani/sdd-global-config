# Tasks

## 1. Reglas y plantillas

- [x] 1.1 En `.claude/CLAUDE.md` ampliar la regla 7 de ejecución según design D1–D3 y D6 (copia en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault, con fecha, rama y commit, sin datos personales ni credenciales, sin commit ni push, además del resumen en el output); agregar `apply\` a la estructura del vault marcada como local y no versionada; en la tabla "Cuándo actuar" indicar que el Agente escribe `apply\` y `/opsx:verify` lo lee; ajustar la frase de `/opsx:verify`. Verificar con `grep -n "apply" .claude/CLAUDE.md` y pegar la salida.
- [x] 1.2 Ampliar la regla 7 con el mismo contenido en `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/comun/AGENTS.md`, con el formato de cada archivo. Verificar S01 y S02.

## 2. Comandos y skills

- [x] 2.1 En `.claude/commands/opsx/verify.md` y `skills/openspec-verify-change/SKILL.md` agregar, antes del reporte, el paso de leer `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` y contrastar cada `[x]` con su evidencia y con el diff, con los CRITICAL de design D4 (tarea sin evidencia, archivo ausente, salvo que el usuario entregue la evidencia) y la nota de vault inexistente; el reporte cita la ruta y no pega el contenido. Mantener idénticos comando y skill entre sí donde hoy lo son. Verificar con `grep -n "apply/" .claude/commands/opsx/verify.md skills/openspec-verify-change/SKILL.md`.
- [x] 2.2 En `.claude/commands/opsx/apply.md` y `skills/openspec-apply-change/SKILL.md` agregar la línea del anuncio de design D5 sin cambiar el comando de handoff. Verificar con `grep -rn "apply/" .claude/commands/opsx/apply.md skills/openspec-apply-change/SKILL.md`.
- [x] 2.3 En `.claude/commands/opsx/verify.md` y `skills/openspec-verify-change/SKILL.md` (design D4, escenario "Vault inexistente"): cuando el vault no existe en la máquina, reportar CRITICAL "no se pudo contrastar la evidencia" (en vez de solo anotarlo), sin dar la evidencia por verificada, de modo que el veredicto final no pueda ser "listo para archivar". Mantener idénticos comando y skill entre sí donde hoy lo son. Copiar ambos a `~/.claude` y verificar con hash (ignorando fin de línea) que coinciden con el repo. Verificar con `grep -n "no se pudo contrastar" .claude/commands/opsx/verify.md skills/openspec-verify-change/SKILL.md` y pegar la salida.

## 3. Guías

- [x] 3.1 En `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` documentar la carpeta `projects/<proyecto>/apply/` del vault, que `projects/*/apply/` está en el `.gitignore` del vault y que el verify solo se corre en la máquina del apply (D7); agregar que, al actualizar un proyecto, hay que volver a copiar las plantillas de reglas. Verificar S07.
- [x] 3.2 Regenerar `docs/modo-de-uso.docx` desde `docs/modo-de-uso.md` con pandoc, usando una copia temporal fuera del repo del `.docx` actual como `--reference-doc`; verificar que el docx menciona `apply/` y `.gitignore`.
- [x] 3.3 Chequeo de rutas: con un script en archivo (no en línea), verificar que `README.md`, `docs/*.md`, `templates/` y `.claude/CLAUDE.md` no contienen `C:\Users`.

## 4. Instalación y sincronización global

- [x] 4.1 Copiar `.claude/CLAUDE.md` a `~/.claude/CLAUDE.md`, `.claude/commands/opsx/*.md` a `~/.claude/commands/opsx/` y `skills/openspec-apply-change` y `skills/openspec-verify-change` a `~/.claude/skills/`; verificar con hash (ignorando fin de línea) que las copias instaladas coinciden con el repo.
- [x] 4.2 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md` y commitear en el vault (`chore: sdd-global-config — sync reglas resumen-apply-en-vault`); verificar que el espejo menciona `apply/`. Si el push del vault falla por la cuenta de GitHub, avisar sin forzar.
- [x] 4.3 Commitear el cambio de `.claude/CLAUDE.md` en un commit separado con la descripción del impacto (regla 7 ampliada y verify que contrasta evidencia) y trailer `Spec-ID: resumen-apply-en-vault`.

## 5. Verificación manual

- [x] 5.1 S01, S02, S08 — Buscar en las cuatro plantillas y en el `CLAUDE.md` global lo indicado en cada escenario y pegar el conteo y las líneas.
- [x] 5.2 S07 — Buscar `apply/` y `.gitignore` en las tres guías y pegar las líneas.

## 6. Verificación con Claude (no la ejecuta el Agente)

- [ ] 6.1 S03, S04, S05, S06 — En un repo de prueba con un change mínimo, correr `/opsx:verify` con el archivo presente y consistente, con una tarea sin evidencia, sin el archivo y con `OBSIDIAN_VAULT` inexistente (debe dar CRITICAL "no se pudo contrastar la evidencia"), y confirmar el reporte de cada caso.
- [ ] 6.2 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[resumen-apply-en-vault] El Agente deja el resumen del apply en el vault y el verify lo lee` desde `change/resumen-apply-en-vault`.
- `/opsx:verify resumen-apply-en-vault` en Claude antes del merge; `/opsx:archive resumen-apply-en-vault` después.
- Volver a copiar las plantillas de reglas en los proyectos que ya las tienen (`.cursor/rules/`, `.github/copilot-instructions.md`, `AGENTS.md`) y `GEMINI.md` en cada máquina.
