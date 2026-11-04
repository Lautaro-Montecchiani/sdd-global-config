## Why

Las reglas del workflow no piden que un proyecto declare qué entra en su primera versión, qué datos maneja ni qué tecnologías usa. Varios proyectos ya lo escriben a mano y cada uno a su manera: `seguimiento-Suscripciones`, `normalizacionLeads-contactacion` y `PLANEAMIENTO` tienen un `## Stack` propio. `toyota-yacopini-web` recibe leads con datos personales y no lo declara en ningún lado. Sin esa información, Claude no puede advertir cuándo un change se sale del alcance, el Agente puede sumar librerías sin control y la seguridad de los datos personales (Ley 25.326) depende de que alguien se acuerde. Además, el change siguiente (`puerta-de-integracion`, issue #29) necesita saber qué datos vienen de afuera. Issue [#28](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/28).

## What Changes

- **Ficha del proyecto** en el `context:` de `openspec/config.yaml`, con tres subsecciones nuevas:
  - `## Alcance`: versión e ítems que incluye y que no incluye todavía;
  - `## Datos`: cada dato con su origen (externo o propio) y su tipo (personal, interno o público);
  - `## Stack`: lenguaje, framework, base de datos, integraciones y librerías clave.

  "¿Qué hace la aplicación?" se cubre con la descripción del `context:` y `## Objetivos de Negocio`, que ya existen.
- **Skill nueva `/ficha`:** entrevista que completa solo lo que falta (incluidos la descripción y los objetivos), respeta lo que el proyecto ya tiene escrito y nunca guarda datos reales, solo categorías.
- **`/opsx:propose`:** avisa en el resumen si falta la ficha (sin bloquear) y, si el change pide algo que figura como "no incluye", pregunta si se sigue y si se pasa al alcance.
- **Seguridad:** controles mínimos para datos personales, para cualquier tipo de proyecto, en la Capa de Seguridad del `CLAUDE.md` global. El design de un change que toca datos personales los incluye en su `## Security Layer`.
- **Regla 4 del Agente:** las librerías y servicios nuevos salen de `## Stack` o del `design.md`. Se actualiza en el `CLAUDE.md` global y en las 4 plantillas.
- Se instala todo en `~/.claude` y se sincroniza el espejo del vault.

## Non-goals

- Bloquear el propose por falta de ficha: solo se avisa.
- Guardar el historial de versiones del alcance: al pasar a V2 se reescribe la sección.
- Controlar en el verify los escenarios de dato inválido o la seguridad: es el change `puerta-de-integracion`.
- Completar la ficha de los proyectos existentes: cada uno la completa con `/ficha` cuando quiera.
- Normalizar los `## Stack` escritos a mano en otros proyectos.

## Capabilities

### New Capabilities
- `project-profile`: ficha del proyecto (alcance, datos y stack), skill `/ficha`, avisos del propose y uso del stack por el Agente.

### Modified Capabilities
- `project-context-schema`: `## Alcance`, `## Datos` y `## Stack` se suman a las subsecciones admitidas del `context:`.
- `security-layer-matrix`: controles mínimos para datos personales, para cualquier tipo de proyecto.

## Impact

- **Archivos globales modificados:**
  - `.claude/CLAUDE.md`: sección "Ficha del proyecto", controles de datos personales en la Capa de Seguridad y regla 4.
  - `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: aviso de ficha faltante, control de alcance y controles de datos personales en el design.
  - `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`: regla 4.
  - `README.md` y `docs/workflow.md`: una mención.
- **Archivo nuevo:** `skills/ficha/SKILL.md`.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/` (con la skill nueva), `~/.claude/commands/opsx/`, `~/.gemini/GEMINI.md` y el espejo `_global/reglas-globales.md` del vault.
- **Proyectos:** ninguno se rompe. Sin ficha, el propose solo agrega un aviso en el resumen.
