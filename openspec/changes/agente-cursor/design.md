# Design

## Context

Ver `proposal.md` — Why. Estado actual relevante (actualizado el 19/10/2026 sobre `master` con `plantillas-por-agente` ya archivado):

- `templates/` tiene una carpeta por agente: `antigravity/` (`settings.json` con permisos y barra de estado), `gemini/` (`GEMINI.md`, que también lee Antigravity), `copilot/` y `comun/` (`AGENTS.md`), más un `templates/README.md` con la matriz de soporte por agente. En esa matriz, Cursor figura "lo agrega `agente-cursor`".
- Antigravity sigue en uso en el equipo: contexto global en `~/.gemini/GEMINI.md`, permisos en `~/.gemini/antigravity-cli/settings.json` (spec `agent-cli-permissions`), skills del Agente en `.agent/skills/` o `.agents/` del proyecto, handoff `/openspec-apply-change {nombre}`.
- `openspec init --tools cursor` genera `.cursor/commands/opsx-{apply,archive,explore,propose,verify}.md` y `.cursor/skills/` (comprobado con OpenSpec 1.4.1; la 1.14 suma `opsx-sync`). Son comandos `/opsx-*` con la lógica estándar de OpenSpec, sin la capa híbrida ni el vault. Varios proyectos (p. ej. Yacotrucks) y este repo ya tienen `.cursor/commands/` sin versionar.
- Cursor carga reglas de proyecto desde `.cursor/rules/*.mdc` (frontmatter `description`, `globs`, `alwaysApply`) ([docs](https://docs.cursor.com/context/rules)). Las "User Rules" globales se cargan desde la configuración del IDE, no desde un archivo, así que no hay equivalente versionable a `~/.gemini/GEMINI.md`.
- El handoff `/openspec-apply-change {nombre}` está en `.claude/CLAUDE.md`, `.claude/commands/opsx/{apply,propose}.md`, `skills/openspec-{apply-change,propose}/SKILL.md`, `README.md`, `CONTRIBUTING.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y la spec `security-layer-matrix`.

## Goals / Non-Goals

**Goals:**
- Que Cursor reciba las reglas del workflow en cada sesión de un proyecto sin pasos manuales por sesión.
- Que el handoff de Claude nombre un comando que exista en el agente que use cada persona.
- Que Antigravity y Cursor convivan: cada persona sigue solo los pasos de su agente.

**Non-Goals:**
- Reescribir los comandos `/opsx-*` que genera OpenSpec para Cursor (se usan tal cual; la restricción de rol va en la regla).
- Soportar `cursor-agent` (CLI) ni definir su `cli-config.json`.
- Retirar o modificar nada de Antigravity.

## Decisions

### D1. Reglas por proyecto en `.cursor/rules/sdd-workflow.mdc` con `alwaysApply: true`
Única forma versionable de que Cursor cargue instrucciones siempre. La plantilla vive en `templates/cursor/sdd-workflow.mdc` (dentro de la estructura por agente) y se copia a cada proyecto, igual que `copilot-instructions.md`. Contenido: el de `templates/copilot/copilot-instructions.md` (rol constructor, git, memoria del proyecto, lectura del espejo del vault y las 7 reglas de ejecución del Agente) más una sección "Comandos permitidos" que restringe a `/opsx-apply`.
*Alternativas*: `AGENTS.md` en la raíz (`templates/comun/AGENTS.md`) — lo leen varias herramientas (incluido Claude en algunos casos) y podría confundir roles; User Rules del IDE — no versionables ni replicables por script.

### D2. Handoff con el comando de cada agente
El anuncio de Claude pasa a: "Ejecutá en el Agente: `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor)". Se reemplaza el texto en todos los archivos listados en Context y en el `CLAUDE.md` global (regla 8, tabla de roles, flujo OpenSpec, "Reglas en Modo OpenSpec"). El nombre de la skill del lado de Claude (`openspec-apply-change`, que solo anuncia el handoff) no cambia.
*Alternativas*: dejar solo `/opsx-apply` — rompería a quien siga con Antigravity; crear `.cursor/commands/openspec-apply-change.md` para conservar el nombre — duplica el comando generado y `openspec update` no lo mantiene.

### D3. Los comandos de arquitecto en Cursor se desactivan por regla, no borrándolos
`openspec update` regenera todos los `/opsx-*` de la herramienta configurada; borrarlos no es duradero. La regla D1 instruye no ejecutarlos y derivar al usuario a Claude.

### D4. Antigravity se conserva
No se retiran `templates/gemini/` ni `templates/antigravity/` ni los requirements de `agent-cli-permissions`. El setup por máquina de `README.md` y `docs/modo-de-uso.md` se separa en dos bloques (Antigravity y Cursor) y aclara que cada persona sigue solo el suyo.
*Alternativa descartada*: retirar Antigravity (propuesta original del 15/10/2026): dejaba sin plantilla ni barra de estado a quien sigue con Antigravity.

### D5. Permisos de Cursor documentados, no versionados
La configuración de auto-run de Cursor vive en el IDE. Se documenta en `templates/cursor/README.md` (y se resume en `README.md` y `docs/modo-de-uso.md`) la allowlist (`git status`, `git diff`, `git branch`, `git restore`, `openspec`) sin `powershell`/`cmd.exe`, con la advertencia de que sumarlos permite ejecutar cualquier comando. No se cubre `~/.cursor/cli-config.json` (CLI `cursor-agent`).

### D6. Agregar Cursor a proyectos existentes
`openspec init --tools cursor` en el proyecto (conserva la configuración existente y suma la herramienta), copiar la regla y, solo si el proyecto deja Antigravity, eliminar `.agent/`/`.agents/` en un commit aparte desde la rama principal — mismo criterio que la limpieza de copias locales de Claude.

### D7. Matriz y carpeta de Cursor
Se crea `templates/cursor/` con `sdd-workflow.mdc` y `README.md` (instalación de la regla, permisos D5 y procedimiento D6). La fila de Cursor de la matriz de `templates/README.md` queda exacta así: `| Cursor | cursor/sdd-workflow.mdc → .cursor/rules/sdd-workflow.mdc del proyecto (Cursor también lee comun/AGENTS.md) | documentado en cursor/README.md (auto-run del IDE, no versionable) | no verificado |`. Se quita la fila pendiente y el texto "lo agrega agente-cursor" de `templates/README.md`.

### D8. Contexto de este repo
En `openspec/config.yaml`, el `context:` pasa de "El Agente usa skills en .agent/skills/ y .github/skills/" a una línea que diga que el Agente puede ser Antigravity (`.agent/skills/`, `~/.gemini/`) o Cursor (`.cursor/commands/`, `.cursor/rules/`), con `.github/skills/` para Copilot, sin tocar el resto del `context:` ni las subsecciones.

## Impacto en proyectos existentes

- Proyectos con Antigravity: no cambia nada. Su handoff sigue siendo `/openspec-apply-change`, que el anuncio de Claude sigue mostrando junto al de Cursor.
- Proyectos que pasen a Cursor: necesitan `.cursor/commands/` (vía `openspec init --tools cursor`) y la regla D1; hasta entonces pueden seguir con Antigravity.
- Changes en curso (p. ej. `lavadero-tablero-unificado` en Yacotrucks): no requieren cambios en sus artefactos; solo cambia el comando con que se lanza el apply según el agente.
- Ningún proyecto queda con copias locales de Claude: `--tools cursor` no crea `.claude/`.
- Quien tenga `~/.gemini/GEMINI.md` lo conserva y sigue siendo parte del workflow para Antigravity.

## Security Layer

`project_type: tooling` — los artefactos modificados son instrucciones para IA:
- La plantilla `sdd-workflow.mdc`, el `CLAUDE.md` y las guías no contienen secrets ni rutas con el usuario local (solo `$env:OBSIDIAN_VAULT`, `$env:SDD_CONFIG_REPO` y el fallback convencional `C:\TPA`). El chequeo de "no contiene `C:\Users`" se hace con un script en archivo (las barras invertidas se pierden en comandos en línea).
- La regla de Cursor mantiene las prohibiciones de commitear `.env`, `*.key`, `*.pem` y credenciales y de revisar `git diff --staged`.
- La allowlist documentada excluye shells genéricos (D5), reduciendo lo que el Agente ejecuta sin confirmación. La baseline permisiva de Antigravity se conserva con su advertencia.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto, y se re-sincronizan el espejo del vault y la copia instalada en `~/.claude/`.

## Risks / Trade-offs

- [Cursor podría leer también `CLAUDE.md` del proyecto, que habla en primera persona de Claude como arquitecto] → la regla D1 aclara explícitamente que Cursor es el Agente y que las reglas de Claude no le aplican; se valida en el proyecto de prueba.
- [Los `/opsx-*` de Cursor no usan el vault ni la lógica híbrida] → Cursor solo ejecuta `/opsx-apply`, que no la necesita; el contexto del vault lo trae la regla.
- [El anuncio con dos comandos puede confundir al usuario] → cada comando lleva el nombre del agente entre paréntesis.
- [Una regla que el usuario puede desactivar en el IDE] → se acepta; es el mismo nivel de garantía que `copilot-instructions.md`.
- [La documentación de Cursor cambia] → la matriz marca "no verificado" lo que no está confirmado y los permisos van documentados, no versionados.

## Migration Plan

1. Mergear el change en `master`.
2. En cada máquina: reinstalar `CLAUDE.md`, comandos y skills en `~/.claude` (paso 2 y 3 del setup). Quien use Cursor, además, configura el auto-run.
3. En cada proyecto que vaya a usar Cursor: aplicar D6 cuando se vaya a trabajar en él.
4. Rollback: revertir el merge y reinstalar en `~/.claude`; los archivos de `~/.gemini/` no se tocan.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y una regla `.mdc`, sin tests automáticos. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Una carpeta por agente / Estructura por agente | manual: sin tests automáticos. Pasos: listar `templates/` recursivamente y pegar la salida; confirmar `cursor/sdd-workflow.mdc` y `cursor/README.md` junto a las demás carpetas y nada suelto en la raíz salvo `README.md` | `templates/**` |
| S02 | Una carpeta por agente / README de instalación por agente | manual: revisión de contenido. Pasos: leer `templates/cursor/README.md` y confirmar agente, archivos y destino (D1, D5, D6) | `templates/cursor/README.md` |
| S03 | Matriz de soporte / Cursor cubierto por su carpeta | manual: revisión de contenido. Pasos: pegar la fila de Cursor de `templates/README.md` y compararla con D7; confirmar que no queda "lo agrega agente-cursor" | `templates/README.md` |
| S04 | Mismas reglas de ejecución / Reglas presentes en cada plantilla | manual: sin tests automáticos. Pasos: buscar las tres frases en las cuatro plantillas de reglas y pegar el conteo | plantillas de reglas |
| S05 | Reglas del Agente por proyecto en Cursor / Instalación de la regla | manual: revisión de contenido. Pasos: buscar `templates\cursor\sdd-workflow.mdc` y `.cursor\rules\sdd-workflow.mdc` en `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` | guías |
| S06 | Reglas del Agente por proyecto en Cursor / Contenido de la regla | manual: revisión de contenido. Pasos: verificar en `templates/cursor/sdd-workflow.mdc` `alwaysApply: true`, la lectura del espejo del vault con su fallback, el rol de constructor con ramas, formato de commit y `Spec-ID` | `templates/cursor/sdd-workflow.mdc` |
| S07 | Reglas del Agente por proyecto en Cursor / Cursor solo implementa | manual: requiere abrir Cursor. Pasos: en un proyecto de prueba con la regla instalada, pedirle `/opsx-propose` en Cursor y confirmar que se niega y deriva a Claude; si Cursor no está disponible, verificar el texto de la sección "Comandos permitidos" y anotarlo | `templates/cursor/sdd-workflow.mdc` |
| S08 | Los proyectos se inician solo con el Agente / Comando de init sin claude | manual: revisión de contenido. Pasos: buscar `openspec init` en `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`; confirmar `--tools antigravity` y `--tools cursor`, sin `claude` ni "liberar el slot" | guías |
| S09 | Los proyectos se inician solo con el Agente / Un proyecto iniciado solo con el Agente no tiene copias de Claude | manual: requiere un directorio temporal. Pasos: `openspec init --tools cursor` y `openspec update`; confirmar `.cursor/commands/opsx-apply.md` y que no existe `.claude/`; repetir con `--tools antigravity` y confirmar `.agent/skills/openspec-apply-change/`; borrar el directorio | — |
| S10 | El setup por máquina se hace por agente / Pasos separados por agente | manual: revisión de contenido. Pasos: leer el setup por máquina de `README.md` y `docs/modo-de-uso.md` y confirmar un bloque por agente con la indicación de seguir solo el propio | `README.md`, `docs/modo-de-uso.md` |
| S11 | El setup por máquina se hace por agente / Plantillas de Antigravity presentes | manual: sin tests automáticos. Pasos: confirmar que existen `templates/gemini/GEMINI.md` y `templates/antigravity/settings.json` | `templates/` |
| S12 | Agregar Cursor a proyectos existentes / Procedimiento documentado | manual: revisión de contenido. Pasos: leer la sección de proyecto existente de `docs/workflow.md` y `docs/modo-de-uso.md` y confirmar los dos pasos y el borrado opcional de `.agent/` en commit aparte | `docs/workflow.md`, `docs/modo-de-uso.md` |
| S13 | Agregar Cursor a proyectos existentes / Proyecto con los dos agentes | manual: requiere un directorio temporal. Pasos: partir de un proyecto con `--tools antigravity`, correr `openspec init --tools cursor` e instalar la regla; confirmar los archivos de Cursor, que siguen las skills de Antigravity y que no hay `.claude/`; borrar el directorio | — |
| S14 | Permisos de ejecución en Cursor / Allowlist documentada | manual: revisión de contenido. Pasos: pegar de `README.md` y `docs/modo-de-uso.md` dónde se configura el auto-run y los cinco comandos | guías |
| S15 | Permisos de ejecución en Cursor / Advertencia sobre shells | manual: revisión de contenido. Pasos: pegar la advertencia de `templates/cursor/README.md` | `templates/cursor/README.md` |
| S16 | Permisos de ejecución en Cursor / Antigravity conserva su configuración | manual: sin tests automáticos. Pasos: confirmar con `openspec validate agente-cursor --strict` que el change no tiene secciones REMOVED y que los requirements de Antigravity siguen en `openspec/specs/agent-cli-permissions/spec.md` | `openspec/specs/agent-cli-permissions/spec.md` |
| S17 | Constructor sin herramienta concreta | manual: revisión de contenido. Pasos: buscar "Copilot", "Gemini", "Antigravity" y "Cursor" como rol en los `CLAUDE.md` de proyecto alineados de este repo | `.claude/CLAUDE.md` |
| S18 | Rol de Claude en apply / El handoff nombra el comando de cada agente | manual: requiere correr el apply. Pasos: en una sesión nueva de Claude con los comandos instalados, `/opsx:apply <change>` y confirmar que anuncia `/openspec-apply-change` (Antigravity) y `/opsx-apply` (Cursor); revisar también el cierre de `/opsx:propose` | `.claude/commands/opsx/apply.md`, `.claude/commands/opsx/propose.md` |

## Open Questions

Sin preguntas abiertas.
