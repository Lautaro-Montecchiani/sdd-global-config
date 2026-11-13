# Proposal

## Why

Para un change SDD, el Agente tiene un comando (`/openspec-apply-change` en Antigravity, `/opsx-apply` en Cursor y Copilot) que instala OpenSpec. Para un ODD no tiene ninguno: el handoff es la frase "implementá el ODD `docs/odd/<nombre>.md`", y el Agente tiene que deducir qué hacer a partir de la sección `## Handoff ODD` de sus reglas. El 12/11/2026 eso dio dos problemas en `reglas-agente-evidencia-commits`: el Agente frenó a mitad de camino sin commitear, y después pidió "escalar a SDD" porque necesitaba tocar un test que no estaba en el alcance, aunque eso no es un criterio SDD.

## What Changes

- Comando `/odd-apply <nombre>` para el Agente, generado desde una sola fuente para los tres agentes que leen comandos:
  - **Antigravity:** skill `odd-apply`, en `templates/antigravity/skills/odd-apply/SKILL.md`. `scripts/instalar.ps1` la instala en `~/.gemini/skills/odd-apply/SKILL.md`, junto a las skills de OpenSpec.
  - **Cursor:** comando `templates/cursor/commands/odd-apply.md`. `scripts/sincronizar-proyecto.ps1` lo copia a `.cursor/commands/odd-apply.md` del proyecto.
  - **Copilot:** prompt `templates/copilot/prompts/odd-apply.prompt.md`. `scripts/sincronizar-proyecto.ps1` lo copia a `.github/prompts/odd-apply.prompt.md` del proyecto, sin tocar los `opsx-*.prompt.md` de OpenSpec.
- **Contenido del comando:**
  - Antes de empezar, controla que exista `docs/odd/<nombre>.md`, que la rama sea `odd/<nombre>` y que el estado sea `abierto`. Si alguna falla, frena.
  - Después aplica la sección `## Handoff ODD`, termina el checklist completo (evidencia, commit, `estado: listo-para-verify`) y cierra con un resumen.
- `generar-plantillas.ps1` genera los tres archivos y `-Comprobar` los controla en el CI.
- **Handoff de `/odd`:** pasa a decir "Ejecutá en el Agente: `/odd-apply <nombre>`".
- **Fragmento `handoff-odd.md`:** separa dos casos que hoy están mezclados.
  - Tocar un archivo que no está en "Archivos permitidos" se avisa como "falta en el alcance", para que Claude amplíe el documento.
  - Solo un criterio de K1 a K10 se avisa como "escalar a SDD".
- La matriz de `templates/README.md` suma la columna "Comando ODD".

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `agent-templates`: requirement nuevo con el comando `/odd-apply` generado para los tres agentes, y cambio en "Handoff ODD en las plantillas de reglas" para el caso "falta en el alcance".
- `project-onboarding`: requirement nuevo sobre la instalación del comando (global para Antigravity, por proyecto para Cursor y Copilot).
- `odd-workflow`: requirement nuevo sobre el handoff de `/odd` con `/odd-apply <nombre>`.

## Non-goals

- Un comando para Codex o para otros agentes que solo leen `AGENTS.md`: siguen con la sección `## Handoff ODD`.
- Cambiar el flujo SDD o los comandos de OpenSpec.
- Comandos para `/odd:verify` o `/odd:close` en el Agente: son de Claude.

## Impact

- Archivos globales modificados:
  - `templates/fuente/` (fragmento y fuente nueva del comando);
  - las plantillas generadas;
  - `scripts/generar-plantillas.ps1`, `scripts/instalar.ps1` y `scripts/sincronizar-proyecto.ps1`;
  - la skill `odd-change` con sus comandos generados;
  - `templates/README.md`;
  - `.claude/CLAUDE.md` (flujo ODD).
- Llega a cada máquina con `pwsh scripts/instalar.ps1`, y a cada proyecto con `pwsh scripts/sincronizar-proyecto.ps1 -Proyecto <ruta>`.
- Orden de merge: se mergea después del ODD `reglas-agente-evidencia-commits`, que toca las mismas plantillas, y se regenera antes del verify.
- Sin dependencias nuevas.
