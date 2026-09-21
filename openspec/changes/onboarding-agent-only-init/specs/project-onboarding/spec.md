## ADDED Requirements

### Requirement: El setup por máquina instala skills y comandos globales de Claude
El setup por máquina SHALL instalar en `~/.claude/skills/` todas las skills de `skills/` y en `~/.claude/commands/opsx/` los comandos de `.claude/commands/opsx/`, porque los comandos son lo que ejecutan `/opsx:*` y las skills los complementan.

#### Scenario: Skills y comandos instalados
- **WHEN** se lee el setup por máquina del `README.md` y de `docs/workflow.md`
- **THEN** describen copiar todas las skills de `skills/` a `~/.claude/skills/`
- **AND** describen copiar los comandos de `.claude/commands/opsx/` a `~/.claude/commands/opsx/`

### Requirement: Los proyectos se inician solo con el Agente
Las guías SHALL indicar `openspec init --tools <agente>` para iniciar un proyecto y SHALL NOT incluir `claude` en `--tools`, para que Claude use los comandos y skills globales y no copias locales por defecto. Las guías SHALL NOT pedir "liberar el slot de apply".

#### Scenario: Comando de init sin claude
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** ningún comando `openspec init` incluye `claude` en `--tools`
- **AND** ninguna guía contiene el paso de "liberar el slot de apply"

#### Scenario: Un proyecto iniciado solo con el Agente no tiene copias de Claude
- **WHEN** se ejecuta `openspec init --tools <agente>` en un directorio nuevo y luego `openspec update`
- **THEN** existen las skills del Agente (por ejemplo `.agent/skills/openspec-apply-change/`)
- **AND** no existe la carpeta `.claude/` en el proyecto

### Requirement: Los proyectos con copias locales de Claude se limpian
Las guías SHALL describir cómo eliminar de un proyecto existente las copias locales de Claude: los comandos de `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`. Las guías SHALL indicar que, si están versionadas, la eliminación se commitea aparte y desde la rama principal, y que `openspec update` no las vuelve a generar.

#### Scenario: Procedimiento de limpieza documentado
- **WHEN** se lee la sección de proyecto existente con OpenSpec de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** indica eliminar `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`
- **AND** indica commitear la eliminación aparte, desde la rama principal

#### Scenario: La limpieza es duradera
- **WHEN** se eliminan las copias locales de Claude de un proyecto y se ejecuta `openspec update`
- **THEN** las copias no se vuelven a generar
