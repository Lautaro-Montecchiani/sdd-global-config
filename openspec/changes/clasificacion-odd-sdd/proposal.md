## Why

Hoy todo cambio de código pasa por el ciclo SDD completo: `proposal + design + specs + tasks`, Test Plan, verify con todas sus secciones, archive y oferta de SRS. Para un cambio chico (un typo, un texto, un bug que hace que el código vuelva a cumplir una spec vigente, un ajuste de estilos) ese costo es el mismo que el de una funcionalidad nueva, y el workflow no ofrece ningún camino más corto.

La idea sale de Organic Driven Development (ODD), el protocolo por defecto de Gentle AI v3.0.0: antes de trabajar se **clasifica** el pedido, y SDD queda como una rama a la que se entra solo cuando hace falta. De ODD se toman dos cosas: el paso de clasificar y el documento único por cambio (`docs/odd/<nombre>.md`). No se toma su capa de memoria (Engram): la memoria sigue siendo el vault de Obsidian. Tampoco se toma su verify opcional: la puerta de integración se mantiene. Issue: #32.

## What Changes

- **Clasificación antes de cada cambio:** Claude clasifica todo pedido que implique cambiar archivos del proyecto como **ODD** o **SDD**, con una lista cerrada de criterios. Si se cumple alguno de los criterios SDD, va por SDD. Si no se cumple ninguno, va por ODD. Ante la duda, SDD. Claude anuncia la clasificación con los criterios que la justifican y el usuario puede cambiarla, salvo los criterios de datos y seguridad, que no se pueden saltear.
- **Flujo ODD liviano:**
  - `/odd <nombre>`: Claude escribe un único documento `docs/odd/<nombre>.md` (objetivo, problema, alcance, clasificación, checklist, criterios de aceptación, evidencia, progreso y próximo paso), lo hace aprobar por el usuario, crea el branch `odd/<nombre>` y anuncia el handoff al Agente;
  - el Agente implementa tarea por tarea y pega la evidencia en el propio documento;
  - `/odd:verify <nombre>`: verify liviano (checklist con evidencia, criterios de aceptación, alcance del diff, tests si el proyecto los tiene, re-chequeo de los criterios SDD sobre el diff real y puerta de integración);
  - `/odd:close <nombre>`, después del merge: **guarda el cambio en el vault de Obsidian** (nota en `archive\`, `context.md` y `_index.md`), commitea y pushea el vault. No crea commits en el repo del proyecto: el documento queda `verificado` y el cierre vive en el vault.
- **Escalado a SDD:** si durante el ODD aparece un criterio SDD (el Agente lo detecta al implementar o el verify lo encuentra en el diff), el ODD se frena, queda `escalado` y su documento sirve de entrada para `/opsx:propose`.
- **Reglas y CI:**
  - el `CLAUDE.md` global suma la sección de clasificación y el flujo ODD, y ajusta las reglas que hoy exigen los cuatro artefactos a todo cambio, la condición de merge, los resultados de la puerta de integración (`no aplica (ODD)`) y la regla 7 del Agente;
  - las plantillas del Agente suman cómo ejecutar un handoff ODD y la misma excepción en la regla 7;
  - `pr-check.yml` y `branch-pr` aceptan branches `odd/*`;
  - `openspec/config.yaml` ajusta OBJ-01 y el glosario.
- **Integración con el rol de arquitecto de software** (mergeado en #33): el documento ODD va en `docs/odd/<nombre>.md`, una carpeta permitida en todo proyecto; todo pedido que cumple un criterio de ADR va por SDD (K10, sin excepción); un ODD que paga deuda de la hoja de ruta actualiza `docs/arquitectura/vision.md` y su cierre reescribe `arquitectura.md` del vault. Este repo recibe su `docs/arquitectura/vision.md` inicial.
- Se instala todo en `~/.claude` y se sincroniza el espejo del vault.

## Non-goals

- Usar Engram ni otra capa de memoria nueva: todo lo que persiste entre sesiones va al vault de Obsidian, como hoy.
- Cambiar el flujo SDD: propose, apply, verify y archive siguen igual para lo que se clasifica como SDD.
- Aflojar la puerta de integración: el ODD también la pasa (seguridad y explicabilidad).
- Generar o actualizar el SRS desde un ODD: por definición un ODD no cambia specs, así que no cambia los requisitos.
- Instalar Gentle AI ni depender de su CLI: se adopta la idea, no la herramienta.
- Resolver la duplicación de reglas entre plantillas: queda para un change aparte. Este change suma la misma sección en las cuatro plantillas.

## Capabilities

### New Capabilities
- `work-classification`: criterios cerrados para clasificar un pedido como ODD o SDD, quién decide, qué se puede cambiar y cuándo se escala.
- `odd-workflow`: documento ODD, comandos `/odd`, `/odd:verify` y `/odd:close`, verify liviano y cierre en el vault de Obsidian.

### Modified Capabilities
- `agent-templates`: se agrega un requirement para que las plantillas de reglas expliquen el handoff ODD y la excepción ODD de la regla 7. Los requirements existentes no cambian.
- `integration-gate`: la condición de merge suma el caso ODD (`/odd:verify` sin CRITICAL y el dato inesperado en `no aplica (ODD)`).

## Impact

- **Archivos globales nuevos:**
  - `skills/odd-change/SKILL.md`: flujo completo (`/odd`, `/odd:verify`, `/odd:close`).
  - `.claude/commands/odd/start.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd/close.md`: los comandos, con el mismo comportamiento que la skill.
- **Archivos globales modificados:**
  - `.claude/CLAUDE.md`: sección "Clasificación ODD / SDD", reglas globales 4 y 9, regla 7 del Agente, `### Branches`, `### Pull Requests`, resultados de la puerta de integración, tabla "Cuándo actuar" y estructura del vault.
  - `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`: sección "Handoff ODD" y excepción ODD en la regla 7.
  - `.github/workflows/pr-check.yml`: acepta `odd/*`.
  - `skills/branch-pr/SKILL.md`: acepta `odd/*` y controla el documento ODD en vez de los artefactos OpenSpec.
  - `openspec/config.yaml`: OBJ-01 y glosario.
  - `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`: el flujo ODD y cuándo se usa.
- **Archivo nuevo del repo:** `docs/arquitectura/vision.md`, la visión inicial de este repositorio con su hoja de ruta.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/commands/` (carpetas `opsx/` y `odd/`), el espejo `_global/reglas-globales.md` del vault y `~/.gemini/GEMINI.md` en cada máquina que use Antigravity.
- **Proyectos:** hay que volver a copiar las plantillas del Agente (`AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/sdd-workflow.mdc`) y el `pr-check.yml` en cada proyecto para usar ODD. Sin eso, el SDD sigue funcionando igual.
