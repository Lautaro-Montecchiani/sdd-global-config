# Design

## Context

- **Cómo lee comandos cada agente** (explore del 2026-11-12):
  - **Antigravity:** skills globales en `~/.gemini/skills/<nombre>/SKILL.md`. En esta PC están las de OpenSpec (`openspec-apply-change`, etc.), que se invocan como `/openspec-apply-change`. Según la guía de migración, los comandos personalizados de Gemini CLI se unificaron con las skills ([DEV](https://dev.to/volodymyr_nehir/how-to-build-custom-commands-for-gemini-cli-and-antigravity-49mb), [codelab de migración](https://gerfalcon.github.io/antigravity-cli-migration-codelab/antigravity-cli-migration/)). Ese codelab menciona `~/.gemini/antigravity-cli/skills/` como ruta nueva, pero en esta PC esa carpeta no existe y las skills de OpenSpec funcionan desde `~/.gemini/skills/`.
  - **Cursor:** comandos de proyecto en `.cursor/commands/<comando>.md`, invocados con `/` ([changelog 1.6](https://cursor.com/changelog/1-6), [buenas prácticas](https://cursor.com/blog/agent-best-practices)).
  - **Copilot:** prompt files en `.github/prompts/<nombre>.prompt.md`, invocados como `/<nombre>` en VS Code ([GitHub Docs](https://docs.github.com/en/copilot/concepts/prompting-and-context/prompt-files)). OpenSpec ya instala ahí `opsx-*.prompt.md` en 5 proyectos.
- **Generación:** `scripts/generar-plantillas.ps1` arma las 4 plantillas de reglas desde `templates/fuente/esqueletos/` y los incluye con `<!-- incluir: <fragmento> -->`. También arma los comandos de Claude desde `skills/` con encabezados en `templates/fuente/comandos/`. `-Comprobar` controla las dos cosas.
- **Instalación:**
  - `scripts/instalar.ps1` instala `GEMINI.md` en `<Destino>/.gemini/` solo si esa carpeta existe, con manifiesto y control de cambios locales.
  - `scripts/sincronizar-proyecto.ps1` arma una lista `$destinos` con `RutaRelativa` y `FuentePath` por agente (comun, copilot, cursor, pr-check).
- **El problema de esta mañana:** el fragmento `handoff-odd.md` pone "tocar más archivos de los permitidos" como ejemplo de criterio SDD, y por eso el Agente pidió escalar el ODD `reglas-agente-evidencia-commits` cuando solo le faltaba un test en el alcance.

## Goals / Non-Goals

**Goals:**
- Un comando `/odd-apply <nombre>`, con el mismo nombre en los tres agentes, generado desde una sola fuente y controlado en el CI.
- Que el comando valide el arranque y termine el checklist completo.
- Distinguir "falta en el alcance" de "escalar a SDD".

**Non-Goals:**
- Comandos para Codex o `AGENTS.md`, ni para el verify o el close del ODD.

## Decisions

### D1. Fuente única del comando

**Archivos fuente:**
- `templates/fuente/comandos-agente/odd-apply/cuerpo.md`: el cuerpo común, que incluye el fragmento `handoff-odd` con `<!-- incluir: handoff-odd -->`.
- Un encabezado por agente:
  - `antigravity.md`: frontmatter con `name: odd-apply` y `description:`;
  - `cursor.md`: sin frontmatter, solo un título;
  - `copilot.md`: frontmatter con `description:` y `agent: 'agent'`.

**Generación:** `generar-plantillas.ps1` arma cada archivo como encabezado + aviso de archivo generado + cuerpo, y lo escribe en:
- `templates/antigravity/skills/odd-apply/SKILL.md`
- `templates/cursor/commands/odd-apply.md`
- `templates/copilot/prompts/odd-apply.prompt.md`

**Comprobación:** `-Comprobar` compara los tres archivos con lo que se generaría.

### D2. Cuerpo del comando

1. **Entrada:** el nombre del ODD. Si falta, lista los `docs/odd/*.md` en `estado: abierto` y pregunta cuál.
2. **Control de arranque:** frena y explica qué falta si:
   - no existe `docs/odd/<nombre>.md`;
   - la rama actual no es `odd/<nombre>`;
   - `estado:` no es `abierto`.
3. **Implementación:** aplica la sección de handoff (el fragmento incluido), tarea por tarea, con las 8 reglas de ejecución.
4. **Cierre obligatorio:**
   - con todas las tareas `[x]`, cada una con su evidencia, pega la evidencia por criterio de aceptación en `## Evidencia`;
   - commitea con `docs:` o el tipo que corresponda y `Spec-ID: odd-<nombre>`;
   - deja `estado: listo-para-verify` y anota la línea en `## Progreso`.
5. **Resumen final:** tareas marcadas, commits y el próximo paso ("Claude corre `/odd:verify <nombre>`").
6. **Frenos:** "escalar a SDD" si se cumple un criterio de K1 a K10. "Falta en el alcance" si hace falta tocar un archivo que no está en "Archivos permitidos" sin criterio SDD. En los dos casos, anota en `## Progreso` y no commitea a medias.

### D3. Cambio del fragmento handoff-odd

La viñeta "Si al implementar se cumple un criterio SDD (por ejemplo, necesitás una dependencia nueva o tocar más archivos de los permitidos)…" se reemplaza por dos:
- "Si al implementar se cumple un criterio SDD (por ejemplo, necesitás una dependencia nueva o cambiar una spec vigente), **frená**, anotalo en `## Progreso` y avisá "escalar a SDD"."
- "Si necesitás tocar un archivo que no está en "Archivos permitidos" y no se cumple ningún criterio SDD (por ejemplo, un test o un dato de prueba), **frená**, anotalo en `## Progreso` y avisá "falta en el alcance": Claude amplía el documento y seguís."

### D4. Instalación

- **`instalar.ps1`:** suma un item como el de `GEMINI.md`, con `RutaDestRel = .gemini/skills/odd-apply/SKILL.md`, solo si existe `<Destino>/.gemini`. Usa el mismo control de cambios locales, el manifiesto y `-Comprobar`.
- **`sincronizar-proyecto.ps1`:** suma dos destinos:
  - con `copilot`: `.github/prompts/odd-apply.prompt.md`;
  - con `cursor`: `.cursor/commands/odd-apply.md`.

  Crea las carpetas si faltan y no toca otros archivos de esas carpetas.

### D5. Handoff y documentación

- **`skills/odd-change/SKILL.md`, paso 7 de `/odd`:** "Ejecutá en el Agente: `/odd-apply <nombre>`". Suma también el paso de "falta en el alcance": ampliar "Archivos permitidos", anotar en `## Progreso` y pedir que siga.
- **Regeneración:** de los comandos `.claude/commands/odd.md` y `odd/start.md`.
- **`.claude/CLAUDE.md`, "Flujo ODD resumido":** el paso 2 nombra `/odd-apply <nombre>`.
- **`templates/README.md`:** la matriz suma la columna "Comando ODD", con las fuentes citadas.
- **`docs/workflow.md` y `docs/modo-de-uso.md`:** el flujo ODD nombra `/odd-apply`.

### Alternativas descartadas

- **TOML en `~/.gemini/commands/odd/apply.toml` (`/odd:apply`):** en esta PC los TOML de `opsx` existen, pero los comandos personalizados se unificaron con las skills y el handoff SDD ya usa la skill. Además daría dos nombres distintos para el mismo comando.
- **Skill también en Copilot (`.github/skills/`) y Cursor:** Copilot invoca los prompts con `/`, y las skills se activan por descripción. Para Cursor no hay documentación oficial de skills invocables con `/`.
- **No hacer comando y mejorar la frase del handoff:** no resuelve que el Agente frene a mitad de camino.

## Impacto en proyectos existentes

- Los proyectos con Copilot o Cursor reciben el comando al correr `sincronizar-proyecto.ps1`. Los `opsx-*` de OpenSpec no se tocan.
- Las máquinas con Antigravity lo reciben con `instalar.ps1`.
- Sin `.gemini`, sin Copilot y sin Cursor, no cambia nada.
- **Orden con el ODD en curso:** `reglas-agente-evidencia-commits` toca las mismas plantillas. Se mergea primero, y este change se rebasa sobre `master` y se regenera antes del verify.

## Impacto en el sistema

**Componentes afectados:** las carpetas globales de Antigravity (`~/.gemini/skills/`) y las carpetas de comandos de Copilot y Cursor en los proyectos.

**Atributos de calidad:**
- mantenibilidad (alta): el cuerpo del comando sale de una sola fuente y reusa el fragmento `handoff-odd`. `-Comprobar` controla los tres archivos — Verificación: S01, S03 y `pwsh scripts/generar-plantillas.ps1 -Comprobar` en el CI.

**Decisiones de arquitectura:** ninguna. No cambia el stack ni el nivel, no suma integraciones externas nuevas (Antigravity, Cursor y Copilot ya están en la matriz) y no adopta un patrón transversal nuevo.

**Deuda técnica:**
- descubre: los tests de migración con copias viejas (C01 de `generar-plantillas`, en retiro en el ODD en curso) se rompen con cada cambio intencional a las plantillas.
- agrega: Antigravity puede mudar las skills a `~/.gemini/antigravity-cli/skills/`. Si pasa, hay que cambiar la ruta de instalación. Va a la hoja de ruta como baja.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `templates/fuente/comandos-agente/odd-apply/cuerpo.md`, `antigravity.md`, `cursor.md`, `copilot.md` | `templates/` |
| `templates/antigravity/skills/odd-apply/SKILL.md` | `templates/` |
| `templates/cursor/commands/odd-apply.md` | `templates/` |
| `templates/copilot/prompts/odd-apply.prompt.md` | `templates/` |
| `tests/odd-apply.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- Las instrucciones nuevas no exponen secrets ni rutas absolutas con usuario local — Verificación: revisión del diff: ninguna ruta `C:\Users\…` ni token en `templates/`, `skills/`, `scripts/` ni `.claude/`.
- La instalación no pisa archivos editados a mano ni archivos ajenos a esas carpetas — Verificación: S05 a S09.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/CLAUDE.md`.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se corre la suite completa porque cambian scripts existentes. Cada test lleva `# test-plan: odd-apply/<ID>` arriba del `Probar`. Los tests de `instalar.ps1` y `sincronizar-proyecto.ps1` usan carpetas temporales, nunca `$HOME` ni el vault reales.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Comando odd-apply para el Agente / Tres archivos con el mismo cuerpo | auto | `tests/odd-apply.Tests.ps1` |
| S02 | Comando odd-apply para el Agente / Control de arranque en el comando | auto | `tests/odd-apply.Tests.ps1` |
| S03 | Comando odd-apply para el Agente / Comando editado a mano | auto | `tests/odd-apply.Tests.ps1` |
| S04 | Comando odd-apply para el Agente / Matriz con el comando ODD | auto | `tests/odd-apply.Tests.ps1` |
| S05 | Instalación del comando odd-apply / Máquina con Antigravity | auto | `tests/odd-apply.Tests.ps1` |
| S06 | Instalación del comando odd-apply / Máquina sin Antigravity | auto | `tests/odd-apply.Tests.ps1` |
| S07 | Instalación del comando odd-apply / Proyecto con Copilot y prompts de OpenSpec | auto | `tests/odd-apply.Tests.ps1` |
| S08 | Instalación del comando odd-apply / Proyecto con Cursor | auto | `tests/odd-apply.Tests.ps1` |
| S09 | Instalación del comando odd-apply / Comprobar con el comando atrasado | auto | `tests/odd-apply.Tests.ps1` |
| S10 | Handoff ODD en las plantillas de reglas / El Agente encuentra un criterio SDD y Archivo fuera del alcance sin criterio SDD | auto | `tests/odd-apply.Tests.ps1` |
| S11 | Handoff ODD en las plantillas de reglas / escenarios existentes (Sección presente, Excepción ODD, Sección generada) | auto: tests existentes de `tests/clasificacion-odd.Tests.ps1`, que suman el marcador | `tests/clasificacion-odd.Tests.ps1` |
| S12 | Handoff ODD con comando del Agente / Handoff con el comando y Falta en el alcance | auto: `skills/odd-change/SKILL.md` y `.claude/commands/odd.md` tienen la línea de handoff y el paso de "falta en el alcance" | `tests/odd-apply.Tests.ps1` |
| M01 | `/odd-apply` en un agente real | manual (lo corre el usuario): después de instalar, abrir Antigravity en un proyecto de prueba con un ODD abierto, correr `/odd-apply <nombre>` y pegar el resumen final; la tarea queda `[ ]` hasta que el usuario pegue la evidencia | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/generar-plantillas.ps1` (con `tests/generar-plantillas.Tests.ps1` y `tests/generar-comandos.Tests.ps1`) | Generación y comprobación de las plantillas y los comandos de Claude | Suma los tres archivos del comando (S01, S03). Los tests existentes no se modifican |
| C02 | `scripts/instalar.ps1` (con `tests/instalar.Tests.ps1`) | Instalación de `~/.claude`, `GEMINI.md`, espejo y manifiesto | Suma la skill de Antigravity (S05, S06). Los tests existentes no se modifican |
| C03 | `scripts/sincronizar-proyecto.ps1` (con `tests/sincronizar-proyecto.Tests.ps1`) | Destinos por agente y `-Comprobar` | Suma los dos destinos (S07 a S09). Los tests existentes no se modifican |

## Risks / Trade-offs

- **[Antigravity cambia la carpeta de skills]** → Se anota en la hoja de ruta. La ruta vive en un solo lugar de `instalar.ps1`.
- **[El prompt de Copilot depende de `chat.promptFiles` en VS Code]** → Se documenta en `templates/copilot/README.md`.
- **[Conflicto de merge con el ODD en curso]** → Mergear el ODD primero, rebasar y regenerar.

## Migration Plan

1. Merge del ODD `reglas-agente-evidencia-commits`. Después, rebase de esta rama sobre `master`.
2. Merge de este change y `pwsh scripts/instalar.ps1` en cada máquina.
3. `pwsh scripts/sincronizar-proyecto.ps1 -Proyecto <ruta>` en los proyectos con Copilot o Cursor.

## Open Questions

- Ninguna.
