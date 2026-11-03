## Why

El workflow SDD no dice nada sobre la estructura de carpetas de los proyectos, y el Agente deja los archivos donde cae. En `toyota-yacopini-web` (Next.js + Payload, fullstack) el Agente generó el proyecto desde una plantilla, y en `src/` quedaron mezclados colecciones, lógica de servidor y rutas, más restos de la plantilla (`src/app/my-route`, `.yarnrc`). Además, un componente de cliente que importa código de servidor puede filtrar secretos al bundle del navegador. Issue [#24](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/24).

## What Changes

- Cada proyecto puede declarar su arquitectura en una subsección `## Arquitectura` del `context:` de `openspec/config.yaml`. Se escribe una línea por carpeta: qué va ahí y, opcionalmente, qué carpetas no puede importar. También puede declarar una herramienta de imports opcional.
- El `CLAUDE.md` global suma la sección "Arquitectura del proyecto", con una tabla compacta de estructura sugerida por `project_type`. Fullstack tiene dos variantes: una sola app (separación dentro de `src/`) o monorepo. Además, la Security Layer de `fullstack` recomienda `server-only` en Next.js.
- `/opsx:propose` pide `## Arquitectura` una sola vez y ofrece una propuesta inferida del repo y del tipo de proyecto. El `design.md` de cada change dice en qué carpeta va cada archivo nuevo.
- Regla 8 del Agente, en el `CLAUDE.md` global y en las 4 plantillas. El Agente respeta las carpetas declaradas y las prohibiciones de importación, frena y pregunta si necesita una carpeta nueva, y limpia los restos de plantillas o scaffolders. Las plantillas pasan de "7 reglas" a "8 reglas".
- `/opsx:verify` controla la arquitectura en el diff:
  - archivo nuevo fuera de las carpetas declaradas: WARNING;
  - import prohibido directo: CRITICAL;
  - proyecto sin `## Arquitectura`: SUGGESTION;
  - si el proyecto declara una herramienta, la corre literal.
- Se instala todo en `~/.claude` y se sincroniza el espejo del vault, así las reglas aplican en las sesiones de otros repos. La instalación incluye lo que había quedado sin instalar del commit `04803c9`.

## Non-goals

- Imponer carpetas fijas: la tabla es una sugerencia y cada proyecto declara las suyas.
- Reordenar proyectos existentes (por ejemplo `toyota-yacopini-web`). Es un change aparte en cada repo.
- Marcar de forma retroactiva el código que ya está mal ubicado: solo se controla lo nuevo del diff.
- Exigir una herramienta de análisis de imports (dependency-cruiser, import-linter): queda opcional.
- Resolver la duplicación entre `skills/` y `.claude/commands/opsx/`: este change edita las dos copias.

## Capabilities

### New Capabilities
- `project-architecture`: declaración de la arquitectura de carpetas por proyecto, estructura sugerida por tipo, cómo la usan el propose, el Agente y el verify, y la migración de los proyectos que no la tienen.

### Modified Capabilities
- `project-context-schema`: `## Arquitectura` se suma a las subsecciones admitidas del `context:` y se pregunta junto con `project_type` y `## Tests`.
- `agent-templates`: las plantillas llevan las mismas 8 reglas de ejecución (antes 7).

## Impact

- **Archivos globales modificados:**
  - `.claude/CLAUDE.md`: regla 8, sección de arquitectura y Security Layer de fullstack. Es la fuente de las reglas.
  - `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: pedir o inferir la arquitectura y la ubicación de archivos en el design.
  - `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: control de carpetas e imports.
  - `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`: regla 8.
  - `README.md` y `docs/workflow.md`: una mención.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/` y `~/.claude/commands/opsx/`, más el espejo `_global/reglas-globales.md` del vault y `~/.gemini/GEMINI.md`.
- **Proyectos:** ninguno se rompe. Los que no tienen `## Arquitectura` reciben una SUGGESTION en el verify y la pregunta en el próximo propose.
