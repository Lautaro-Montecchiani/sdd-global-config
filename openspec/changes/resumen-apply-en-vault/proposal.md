## Why

El resumen final del apply, con la evidencia de cada tarea marcada `[x]` (regla 7 de ejecución del Agente), hoy solo existe en el chat del Agente. Para que Claude lo use en `/opsx:verify` hay que pegarlo a mano en esta conversación, lo que llena la ventana de contexto con salidas de tests. Cuando no se pega, el verify no puede contrastar la evidencia: pasó en `srs-convenciones-ids`, donde la tarea 3.2 quedó como WARNING por no haber visto el resumen. Además, la regla global dice que el verify contrasta cada `[x]` con la evidencia del resumen, pero ni el comando `/opsx:verify` ni la skill `openspec-verify-change` lo hacen hoy.

## What Changes

- La regla 7 de ejecución del Agente pasa a pedir, además de pegar el resumen con evidencia en el output, una copia completa en el vault: `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`, con fecha, rama y commit de cada rama, tareas marcadas con su evidencia (salida en rojo y en verde) y tareas abiertas con su motivo. Sin datos personales ni credenciales (se reemplazan por `<DATO OMITIDO>`) y sin commit ni push de ese archivo.
- El vault ignora `projects/*/apply/` (ya está en el `.gitignore` del vault): las copias existen solo en la máquina donde se hizo el apply.
- `/opsx:verify` y la skill `openspec-verify-change` leen esa copia, contrastan cada `[x]` con su evidencia y con el diff, y reportan como CRITICAL la ausencia del archivo, salvo que el usuario entregue la evidencia por otra vía.
- `/opsx:apply` y su skill anuncian que el Agente deja la copia en el vault.
- El `CLAUDE.md` global (regla 7, estructura del vault y tabla "Cuándo actuar") y las cuatro plantillas de reglas (`gemini`, `copilot`, `cursor`, `comun/AGENTS.md`) llevan la regla 7 ampliada.
- Las guías documentan la carpeta `apply/` y que está ignorada por git en el vault.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `agent-templates`: la regla 7 de las cuatro plantillas incluye la copia del resumen en el vault.
- `test-driven-verification`: el verify lee el resumen del apply desde el vault y contrasta la evidencia.
- `project-onboarding`: las guías documentan la carpeta `apply/` del vault y su exclusión de git.

## Impact

- `.claude/CLAUDE.md` (y su copia en `~/.claude`, el espejo `_global/reglas-globales.md` del vault y la copia versionada).
- `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc`, `templates/comun/AGENTS.md`.
- `.claude/commands/opsx/{apply,verify}.md` y `skills/openspec-{apply-change,verify-change}/SKILL.md`.
- `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` (y su `.docx`).
- Fuera del repo: los proyectos que ya tienen copias de las plantillas (`.cursor/rules/`, `.github/copilot-instructions.md`, `AGENTS.md`) y cada `~/.gemini/GEMINI.md` quedan con la regla 7 anterior hasta que se vuelvan a copiar. Mientras tanto, el prompt del apply puede pedir la copia explícitamente.
- El verify solo puede correrse en la máquina donde se hizo el apply, porque las copias no se comparten por git.
- Cambia el criterio del verify: un change implementado sin la copia queda con un CRITICAL hasta que el usuario entregue la evidencia.
