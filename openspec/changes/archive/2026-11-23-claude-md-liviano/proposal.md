Issue: #55

## Why

`.claude/CLAUDE.md` tiene 580 líneas y unas 7.300 palabras, y Claude lo carga entero al empezar cada sesión, en todos los proyectos. Una parte es detalle operativo que ya está en las skills o que solo usa una skill: los comandos PowerShell del vault, los pasos del flujo ODD, la tabla de la escalera de niveles, los ejemplos YAML de la ficha, el detalle de cómo se protege el espejo y dos secciones de OpenSpec que dicen casi lo mismo. Ese texto ocupa contexto en sesiones que no lo usan, y cada change lo hace crecer (deuda #55).

## What Changes

- El `CLAUDE.md` global conserva todas las reglas y tablas. Los bloques de detalle operativo se cambian por una o dos líneas que dicen dónde está el detalle, sin perder ninguna regla:
  - "Flujo ODD resumido" y "Escalado a SDD" pasan a una sola subsección corta que remite a la skill `odd-change`, donde ya están los pasos.
  - "Flujo OpenSpec" y "Modo OpenSpec" se juntan en una sola sección "Modo OpenSpec".
  - "Escalera de niveles" nombra los seis niveles y remite a `recetas.md` de `/arquitectura`, que ya tiene la tabla y las señales.
  - "Subsecciones" de la ficha pierde los ejemplos YAML, que ya están en la skill `/ficha`.
  - "Reglas globales en el vault" y "Fuente de las reglas" se acortan. El detalle de la protección del espejo (`-Forzar`, `commit:` y huella `instalacion:`) pasa a una sección nueva del README.
  - "Comandos PowerShell" pasa entero a una sección nueva del README, "Comandos del vault".
- Se agrega en "Fuente de las reglas" la regla de dónde va el detalle operativo: en la skill que lo usa o en el README, no en el `CLAUDE.md`. Así el archivo deja de crecer con cada change.
- `docs/arquitectura/vision.md` quita la deuda #55 de la hoja de ruta.

Archivos globales que se modifican: `.claude/CLAUDE.md` (lo cargan Claude en todos los proyectos y el espejo del vault) y `README.md`. Si un texto que se saca no está en su destino, se copia ahí tal cual (`skills/odd-change/SKILL.md`, `skills/ficha/SKILL.md` o `skills/arquitectura/references/recetas.md`) y se regeneran los comandos.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `rules-sync`: suma dos requirements. Uno dice qué detalle operativo vive fuera del `CLAUDE.md` global y dónde. El otro dice que el detalle nuevo va en la skill o en el README.

## Non-goals

- No se borra ni se cambia ninguna regla. Cambia el lugar del detalle, no lo que hacen Claude ni el Agente.
- No se toca el bloque generado de las 8 reglas del Agente ni las secciones que piden los tests y specs vigentes: Scrumban (con `### Métricas` y `### Cadencias`), "Estructura sugerida por tipo de proyecto", "Estructura del vault", "Cuándo actuar", "Formato de context.md", la puerta de integración, la seguridad y las reglas de Git.
- No se modifica ni se afloja ningún test existente.
- No se fija un tope de palabras con un test.

## Impact

- El `CLAUDE.md` global baja de unas 7.300 a unas 6.400 palabras. Es menos que las 4.500 que se estimaron al aprobar el issue: al revisar los tests y las specs vigentes, varias secciones tienen que quedarse con su texto.
- Comportamiento de Claude: igual. Las skills ya traen los pasos que se sacan del `CLAUDE.md`, y los comandos de referencia quedan en el README.
- Otras máquinas: el cambio llega con `git pull` y `instalar.ps1`, como cualquier cambio de reglas.
- Tests: un archivo nuevo, `tests/claude-md-liviano.Tests.ps1`. La suite actual queda sin cambios.
