## ADDED Requirements

### Requirement: Detalle operativo fuera del CLAUDE.md global
`.claude/CLAUDE.md` SHALL conservar las reglas y las tablas del workflow y SHALL remitir, con una o dos líneas, al lugar donde está el detalle operativo:
- los pasos del flujo ODD y del escalado a SDD, a la skill `odd-change`;
- qué resuelve cada nivel de arquitectura y cuándo subir, a `skills/arquitectura/references/recetas.md`;
- los ejemplos de las subsecciones de la ficha, a la skill `ficha`;
- los comandos PowerShell del vault, a la sección "Comandos del vault" de `README.md`;
- cómo protege `instalar.ps1` el espejo (ediciones a mano, `-Forzar`, `commit:` y huella `instalacion:`), a la sección "Espejo del vault" de `README.md`.

El flujo OpenSpec SHALL describirse en una sola sección "Modo OpenSpec". Cada texto que sale del `CLAUDE.md` SHALL existir en su destino.

#### Scenario: Una sola sección de OpenSpec
- **WHEN** se lee `.claude/CLAUDE.md`
- **THEN** tiene una sola sección `## Modo OpenSpec (cuando `openspec` CLI está disponible)` y ninguna `## Flujo OpenSpec`
- **AND** esa sección pide correr `openspec status --change "{nombre}" --json` antes de crear archivos, crear los artefactos en `openspec/changes/{nombre}/`, implementar con `/opsx:apply` y no usar el `specs/` legacy para changes nuevos

#### Scenario: Comandos del vault en el README
- **WHEN** se leen `.claude/CLAUDE.md` y `README.md`
- **THEN** `.claude/CLAUDE.md` no tiene bloques de código `powershell` y nombra la sección "Comandos del vault" del README
- **AND** `README.md` tiene la sección `## Comandos del vault` con los comandos para leer el contexto, escribir las notas de decisions, archive y ODD, actualizar `context.md`, cambiar el estado de una nota, eliminar una nota y sincronizar las reglas

#### Scenario: Ejemplos de la ficha en la skill
- **WHEN** se lee `## Ficha del proyecto` en `.claude/CLAUDE.md`
- **THEN** no tiene bloques de código `yaml`, nombra las subsecciones `## Alcance`, `## Datos`, `## Stack` y `## Calidad` y remite a la skill `/ficha`
- **AND** `skills/ficha/SKILL.md` tiene un ejemplo de cada una de esas cuatro subsecciones

#### Scenario: Escalera en las recetas
- **WHEN** se lee `### Escalera de niveles` en `.claude/CLAUDE.md`
- **THEN** nombra los niveles `0`, `1-nucleo-funcional`, `2-tuberias`, `2-capas`, `3-hexagonal` y `3-modular`, remite a `recetas.md` y no tiene una tabla
- **AND** `skills/arquitectura/references/recetas.md` tiene una fila para cada uno de los seis niveles y una sección `## <nivel>` con sus **Señales** para cada nivel desde `1-nucleo-funcional`

#### Scenario: Flujo ODD en la skill
- **WHEN** se lee `## Clasificación ODD / SDD` en `.claude/CLAUDE.md`
- **THEN** no tiene las subsecciones `### Flujo ODD resumido` ni `### Escalado a SDD` y remite a la skill `odd-change`
- **AND** conserva que el ODD vive en la rama `odd/<nombre>`, que `/odd:close` se corre después del merge y que, si aparece un criterio SDD, el documento pasa a `estado: escalado`, la rama no se mergea y Claude ofrece `/opsx:propose <nombre>`
- **AND** `skills/odd-change/SKILL.md` tiene `estado: escalado`, "no se mergea", "ODD `<nombre>` escalado a SDD" y `/opsx:propose <nombre>`

#### Scenario: Espejo del vault en el README
- **WHEN** se leen `.claude/CLAUDE.md` y `README.md`
- **THEN** `.claude/CLAUDE.md` dice que solo `scripts/instalar.ps1` escribe el espejo y `~/.claude/CLAUDE.md` y remite a la sección "Espejo del vault" del README
- **AND** `README.md` tiene la sección `## Espejo del vault`, que explica `-Forzar`, la línea `commit:` y la huella `instalacion:`

### Requirement: El detalle operativo nuevo va en la skill o en el README
`.claude/CLAUDE.md`, en "Fuente de las reglas", SHALL decir que el detalle operativo de un flujo (pasos, comandos y ejemplos) va en la skill que lo usa o en `README.md`, y que el `CLAUDE.md` lleva las reglas y las tablas.

#### Scenario: Regla de dónde va el detalle
- **WHEN** se lee `### Fuente de las reglas: repo `sdd-global-config`` en `.claude/CLAUDE.md`
- **THEN** dice que el detalle operativo (pasos, comandos y ejemplos) va en la skill que lo usa o en el README, y que el `CLAUDE.md` lleva las reglas y las tablas
