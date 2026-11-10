## Why

Hoy Claude es el "arquitecto" del workflow en un sentido acotado: diseña cada change en su `design.md`, controla el proceso (verify, puerta de integración) y archiva. Trabaja change por change. No hay un lugar donde queden las decisiones de arquitectura que duran más que un change, los atributos de calidad del sistema no se declaran (solo la seguridad tiene su capa) y nadie mira el impacto de un change sobre el sistema completo ni lleva la deuda técnica. El usuario pidió que Claude sea su **arquitecto de software**, sumando esas responsabilidades al rol actual **sin cambiar ninguna regla vigente**. Issue: #33.

## What Changes

- **Rol de arquitecto de software** en el `CLAUDE.md` global: una sección nueva que define cuatro responsabilidades que se suman al rol actual. Las reglas vigentes no cambian: Claude sigue sin escribir código ni archivos del proyecto (los documentos de arquitectura del repo los escribe el Agente desde el `design.md`) y las decisiones las toma el usuario.
- **ADRs del proyecto:** cuando un change toma una decisión que dura más que él (tecnología del stack, nivel de arquitectura, integración externa, patrón transversal o un compromiso entre atributos de calidad), el `design.md` trae la sección `## ADR` con el texto completo y una tarea para que el Agente la guarde en `docs/adr/NNNN-<slug>.md` del proyecto.
- **Atributos de calidad:** la ficha suma `## Calidad` (rendimiento, disponibilidad, escalabilidad, costo y mantenibilidad, cada uno con un objetivo y una prioridad). `/ficha` la pregunta, el propose evalúa el change contra los de prioridad alta y el verify controla su verificación.
- **Visión y hoja de ruta:** documento vivo `docs/arquitectura/vision.md` en cada proyecto (propósito, contexto e integraciones, componentes, decisiones vigentes y hoja de ruta de deuda técnica priorizada). El propose lo crea si falta y lo actualiza cuando el change lo afecta, siempre como tarea del Agente.
- **Revisión de impacto:** todo `design.md` nuevo lleva `## Impacto en el sistema` (componentes afectados fuera del change, atributos de calidad, decisiones de arquitectura y deuda técnica que agrega, paga o descubre).
- **Resumen en el vault:** el archive reescribe `projects/<proyecto>/arquitectura.md` en el vault de Obsidian (nivel, atributos de calidad, ADRs vigentes y las 3 deudas de mayor prioridad). El inicio de sesión y `/opsx:explore` lo leen.
- **Verify:** suma una tabla "Arquitectura de software" con controles que dan WARNING o SUGGESTION. No se agrega ningún CRITICAL nuevo ni cambia la puerta de integración.

## Non-goals

- Cambiar, aflojar o reemplazar cualquier regla vigente del `CLAUDE.md` global: el rol se suma por encima. En particular, la regla 1 ("Claude NO edita archivos del proyecto") sigue igual.
- Que Claude decida solo: toda decisión de arquitectura se propone con alternativas y la aprueba el usuario al aprobar el change.
- Nuevas condiciones de merge o CRITICAL en el verify.
- Un comando nuevo de revisión periódica: la revisión se hace en cada propose y en `/arquitectura`, que no cambia.
- Diagramas obligatorios: la visión admite un diagrama, pero no lo exige.
- Modificar las plantillas del Agente: las tareas del change ya le dicen qué escribir y `docs/` es una carpeta permitida.
- Migrar los proyectos existentes de una vez: cada uno crea su visión en su próximo change.

## Capabilities

### New Capabilities
- `software-architect-role`: el rol de arquitecto de software de Claude, los ADRs del proyecto, la visión con hoja de ruta, la revisión de impacto en el `design.md`, el resumen de arquitectura en el vault y los controles del verify.

### Modified Capabilities
- `project-profile`: la ficha suma `## Calidad`; `/ficha` la revisa y la pregunta; el propose avisa si falta.

## Impact

- **Archivo global modificado:** `.claude/CLAUDE.md`: sección `## Rol de arquitecto de software`, fila en la tabla de roles, `## Calidad` en la ficha, lectura de `arquitectura.md` al iniciar sesión, tabla "Cuándo actuar" y estructura del vault. Se modifica porque es la fuente de las reglas que carga Claude en todos los proyectos.
- **Skills y comandos modificados:**
  - `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: `## Impacto en el sistema`, `## ADR`, visión y calidad en el `design.md`.
  - `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: tabla "Arquitectura de software".
  - `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: resumen `arquitectura.md` en el vault.
  - `skills/openspec-explore/SKILL.md` y `.claude/commands/opsx/explore.md`: leen el resumen y la visión.
  - `skills/ficha/SKILL.md`: sexta parte `## Calidad`.
- **Config:** `openspec/config.yaml`: glosario, actor Claude y OBJ-06.
- **Documentación:** `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/commands/opsx/` y el espejo `_global/reglas-globales.md` del vault.
- **Proyectos:** sin migración obligatoria. Desde la instalación, el próximo propose de cada proyecto agrega `## Impacto en el sistema` y la tarea de crear `docs/arquitectura/vision.md`.
- **Change en pausa:** `clasificacion-odd-sdd` (#32) también modifica `.claude/CLAUDE.md` y `openspec/config.yaml`; el que se mergee segundo resuelve los conflictos.
