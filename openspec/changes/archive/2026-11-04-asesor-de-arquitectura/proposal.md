## Why

El change `arquitectura-de-carpetas` le dio a cada proyecto una forma de declarar sus carpetas y prohibiciones de importación, pero Claude todavía no tiene criterio para **recomendar** cómo ordenar el código ni para **detectar** cuándo hace falta. Los proyectos de Yacopini suelen arrancar sin arquitectura definida (se pide algo y se empieza a programar), y quien programa no necesariamente conoce los estilos de arquitectura. El resultado está a la vista: en un relevamiento del 04/11/2026 sobre 1.101 archivos de código propio, 63 superan las 500 líneas y 16 las 1000, entre ellos `PLANEAMIENTO/app.py`, con 8.684. Issue [#26](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/26).

## What Changes

- **Escalera de niveles 0 a 3** como modelo de arquitectura incremental: nivel 0 sin estilo, nivel 1 núcleo funcional (separar cálculos de conexiones), nivel 2 capas o tuberías y filtros, y nivel 3 hexagonal o monolito modular. Un proyecto sube de nivel solo cuando aparece una señal concreta en su código.
- **Recetas por nivel**, en una skill nueva `arquitectura`. Cada receta trae las señales que la justifican, las carpetas tipo, las reglas `no importa:` que genera, la cantidad mínima de reglas, pautas para el Agente que el verify no puede controlar, y cuándo no aplicarla.
- **`/opsx:propose` recomienda un nivel** cuando el change cruza una señal. La recomendación tiene cinco partes (qué vio, qué problema trae, qué propone, cuánto cuesta y qué descartó) y queda en una sección `## Recomendación de arquitectura` del `design.md`. El usuario decide si aplicarla en el change, en un change aparte o no aplicarla todavía. Si la aprueba, Claude escribe en `## Arquitectura` el nivel, las carpetas y las reglas de la receta.
- **Skill `/arquitectura`**: diagnostica un proyecto existente sin crear un change. Informa el nivel actual con evidencia, las señales encontradas, la recomendación y un plan de migración en changes chicos.
- **Claves nuevas en `## Arquitectura`**: `nivel`, `tamaño` y `tamaño-excluir`. Ausencia de `nivel` = proyecto sin evaluar, sin bloquear nada.
- **Señal de tamaño de archivo en `/opsx:verify`**: SUGGESTION a partir de 500 líneas y WARNING a partir de 1000, solo cuando el diff agranda el archivo. Nunca CRITICAL. Tiene exclusiones por defecto y umbrales configurables. Se activa con la clave `tamaño`, que el propose escribe en los proyectos nuevos y que en los existentes se escribe recién cuando se decide ordenarlos.
- **`/opsx:verify` controla la coherencia del nivel**: SUGGESTION si el nivel declarado tiene menos reglas `no importa:` que el mínimo de su receta.
- **Regla 8 del Agente**: suma que aplique las pautas de `## Recomendación de arquitectura` del design, aunque el verify no pueda controlarlas. Se actualiza en el `CLAUDE.md` global y en las 4 plantillas.
- **Guía para estudiar** (`docs/guia-arquitecturas.md`): la escalera, los estilos y paradigmas de la lista del usuario explicados en simple, con ejemplos tipo Yacopini, incluidos los que probablemente no se usen.
- Se instala todo en `~/.claude` y se sincroniza el espejo del vault.

## Non-goals

- Imponer un nivel a los proyectos existentes: solo se evalúan cuando el usuario lo pide.
- Reglas que prohíban librerías externas: el control sigue siendo entre carpetas del proyecto. El usuario lo descartó en el explore.
- Señal de funciones largas: queda para un change futuro, después de probar la señal de tamaño de archivo.
- Unificar el código duplicado entre los repos `scrapingExodo-*`: es un tema aparte.
- Refactorizar algún proyecto real, como `PLANEAMIENTO`: cada refactor es un change propio en su repo.
- Estilos de topología de sistema (microservicios, SOA, EDA, serverless, P2P) como recetas: solo aparecen en la guía para estudiar.
- Resolver la duplicación entre `skills/` y `.claude/commands/opsx/`: este change edita las dos copias.

## Capabilities

### New Capabilities
- `architecture-advisor`: escalera de niveles y recetas, recomendación de nivel en el propose, skill `/arquitectura` de diagnóstico y guía para estudiar.

### Modified Capabilities
- `project-architecture`: claves nuevas `nivel`, `tamaño` y `tamaño-excluir` en `## Arquitectura`; la regla 8 suma las pautas de la recomendación; el verify agrega la coherencia del nivel y la señal de tamaño de archivo.

## Impact

- **Archivos globales modificados:**
  - `.claude/CLAUDE.md`: escalera de niveles, claves nuevas de `## Arquitectura`, responsabilidades por actor y regla 8. Es la fuente de las reglas.
  - `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: detección de señales, recomendación y escritura de `nivel` y `tamaño`.
  - `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: coherencia del nivel y señal de tamaño.
  - `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`: regla 8.
  - `README.md` y `docs/workflow.md`: una mención.
- **Archivos nuevos:** `skills/arquitectura/SKILL.md`, `skills/arquitectura/references/recetas.md` y `docs/guia-arquitecturas.md`.
- **Configuración de este repo:** `openspec/config.yaml` ya declara `## Arquitectura` (`skills/`, `templates/`), escrita en este propose.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/` (incluida la skill nueva) y `~/.claude/commands/opsx/`, más el espejo `_global/reglas-globales.md` del vault y `~/.gemini/GEMINI.md`.
- **Proyectos:** ninguno se rompe. Sin `nivel` no se controla la coherencia, y sin `tamaño` no se mide el tamaño de los archivos.
