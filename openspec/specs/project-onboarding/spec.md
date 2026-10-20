# project-onboarding Specification

## Purpose
Define cómo se prepara una máquina y cómo se inicia un proyecto en el workflow: el setup instala las skills y los comandos globales de Claude, los proyectos se inician solo con el Agente (`openspec init --tools <agente>`) y los que tienen copias locales de Claude se limpian para que no pisen a las globales.

## Requirements

### Requirement: El setup por máquina instala skills y comandos globales de Claude
El setup por máquina SHALL instalar en `~/.claude/skills/` todas las skills de `skills/` y en `~/.claude/commands/opsx/` los comandos de `.claude/commands/opsx/`, porque los comandos son lo que ejecutan `/opsx:*` y las skills los complementan.

#### Scenario: Skills y comandos instalados
- **WHEN** se lee el setup por máquina del `README.md` y de `docs/workflow.md`
- **THEN** describen copiar todas las skills de `skills/` a `~/.claude/skills/`
- **AND** describen copiar los comandos de `.claude/commands/opsx/` a `~/.claude/commands/opsx/`

### Requirement: Los proyectos se inician solo con el Agente
Las guías SHALL indicar `openspec init --tools <agente>` para iniciar un proyecto, con `<agente>` igual a `antigravity` o `cursor`, y SHALL NOT incluir `claude` en `--tools`, para que Claude use los comandos y skills globales. Las guías SHALL indicar cómo comprobar la instalación: `.agents/skills/openspec-apply-change/` para Antigravity o `.cursor/commands/opsx-apply.md` para Cursor. Las guías SHALL NOT pedir "liberar el slot de apply".

#### Scenario: Comando de init sin claude
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** ningún comando `openspec init` incluye `claude` en `--tools`
- **AND** los comandos indicados son `openspec init --tools antigravity` y `openspec init --tools cursor`
- **AND** ninguna guía contiene el paso de "liberar el slot de apply"

#### Scenario: Un proyecto iniciado solo con el Agente no tiene copias de Claude
- **WHEN** se ejecuta `openspec init --tools <agente>` en un directorio nuevo y luego `openspec update`
- **THEN** existen los comandos o skills del Agente (`.agents/skills/openspec-apply-change/` con Antigravity, `.cursor/commands/opsx-apply.md` con Cursor)
- **AND** no existe la carpeta `.claude/` en el proyecto

#### Scenario: Comprobación de Antigravity con la carpeta nueva
- **WHEN** se leen las guías en el paso de comprobar la instalación de Antigravity
- **THEN** indican `.agents/skills/openspec-apply-change/` y no `.agent/skills/openspec-apply-change/`

### Requirement: Los proyectos con copias locales de Claude se limpian
Las guías SHALL describir cómo eliminar de un proyecto existente las copias locales de Claude: los comandos de `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`. Las guías SHALL indicar que, si están versionadas, la eliminación se commitea aparte y desde la rama principal, y que `openspec update` no las vuelve a generar.

#### Scenario: Procedimiento de limpieza documentado
- **WHEN** se lee la sección de proyecto existente con OpenSpec de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** indica eliminar `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`
- **AND** indica commitear la eliminación aparte, desde la rama principal

#### Scenario: La limpieza es duradera
- **WHEN** se eliminan las copias locales de Claude de un proyecto y se ejecuta `openspec update`
- **THEN** las copias no se vuelven a generar

### Requirement: Reglas del Agente por proyecto en Cursor
El repositorio SHALL versionar la plantilla `templates/cursor/sdd-workflow.mdc`, y las guías SHALL indicar copiarla a `.cursor/rules/sdd-workflow.mdc` de cada proyecto que usa Cursor como Agente. La plantilla SHALL aplicarse siempre (`alwaysApply: true`), remitir al espejo del vault `_global/reglas-globales.md` y no contener rutas con el usuario local.

#### Scenario: Instalación de la regla
- **WHEN** se lee la sección "Sumar un proyecto al workflow" de `README.md` y la equivalente de `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** indican, para Cursor, copiar `$env:SDD_CONFIG_REPO\templates\cursor\sdd-workflow.mdc` a `.cursor\rules\sdd-workflow.mdc` del proyecto

#### Scenario: Contenido de la regla
- **WHEN** se lee `templates/cursor/sdd-workflow.mdc`
- **THEN** su frontmatter tiene `alwaysApply: true`
- **AND** indica leer `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback `C:\TPA\_global\reglas-globales.md`)
- **AND** define el rol de constructor con commits en `change/{nombre}`, formato `{type}: {desc}` y trailer `Spec-ID`

#### Scenario: Cursor solo implementa
- **WHEN** se lee `templates/cursor/sdd-workflow.mdc`
- **THEN** indica que el Agente solo ejecuta `/opsx-apply`
- **AND** indica que `/opsx-propose`, `/opsx-verify`, `/opsx-archive`, `/opsx-explore` y `/opsx-sync` corresponden a Claude y no deben ejecutarse en Cursor

### Requirement: El setup por máquina se hace por agente
El setup por máquina de `README.md` y `docs/modo-de-uso.md` SHALL tener pasos separados para cada agente (Antigravity: `GEMINI.md` y `settings.json`; Cursor: ejecución automática) e indicar que cada persona sigue solo los del agente que usa. El paso de Antigravity SHALL copiar `templates\antigravity\GEMINI.md` a `~/.gemini/GEMINI.md`. El repositorio SHALL seguir versionando las plantillas de Antigravity.

#### Scenario: Pasos separados por agente
- **WHEN** se lee el setup por máquina de `README.md` y de `docs/modo-de-uso.md`
- **THEN** hay un bloque de pasos para Antigravity y otro para Cursor
- **AND** se indica seguir solo el del agente que se usa

#### Scenario: Plantillas de Antigravity presentes
- **WHEN** se listan los archivos de `templates/`
- **THEN** existen `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json`

#### Scenario: Ruta nueva en el setup
- **WHEN** se busca el paso que instala `GEMINI.md` en `README.md` y `docs/modo-de-uso.md`
- **THEN** copia `templates\antigravity\GEMINI.md` a `~/.gemini/GEMINI.md`
- **AND** ninguna guía menciona `templates\gemini\`

### Requirement: Agregar Cursor a proyectos existentes
Las guías SHALL describir cómo sumar Cursor a un proyecto que ya usa OpenSpec con Antigravity: ejecutar `openspec init --tools cursor` (conserva la configuración y suma la herramienta) e instalar `.cursor/rules/sdd-workflow.mdc`. Las guías SHALL indicar que las carpetas de Antigravity (`.agents/` y la anterior `.agent/`) solo se eliminan si el proyecto deja de usar Antigravity, en un commit aparte y desde la rama principal.

#### Scenario: Procedimiento documentado
- **WHEN** se lee la sección de proyecto existente con OpenSpec de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** describe los dos pasos anteriores
- **AND** indica que borrar `.agents/` (y `.agent/`) es opcional, solo si se deja Antigravity, en un commit aparte desde la rama principal

#### Scenario: Proyecto con los dos agentes
- **WHEN** en un proyecto con Antigravity se ejecutan los pasos de la guía
- **THEN** existen `.cursor/commands/opsx-apply.md` y `.cursor/rules/sdd-workflow.mdc`
- **AND** siguen existiendo las skills de Antigravity
- **AND** no existe la carpeta `.claude/` creada por el proceso

### Requirement: El vault documenta la carpeta de resúmenes del apply
Las guías SHALL describir la carpeta `projects/<proyecto>/apply/` del vault (dónde el Agente deja la copia del resumen del apply) e indicar que `projects/*/apply/` está en el `.gitignore` del vault, por lo que no se sube a git y el verify solo se corre en la máquina del apply. El `CLAUDE.md` global SHALL incluir `apply/` en la estructura del vault.

#### Scenario: Carpeta documentada
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** mencionan `projects/<proyecto>/apply/` y su exclusión de git

#### Scenario: Estructura del vault en el CLAUDE.md
- **WHEN** se lee la estructura del vault del `CLAUDE.md` global
- **THEN** incluye `apply\` bajo cada proyecto, marcada como local y no versionada

### Requirement: Actualizar OpenSpec en un proyecto existente
Las guías SHALL describir cómo actualizar un proyecto que ya usa OpenSpec: ejecutar `openspec update`, revisar con `git status` y `git diff` lo que cambió y commitearlo aparte. Si el proyecto tenía `.agent/`, las guías SHALL indicar que `openspec update` crea `.agents/` y deja `.agent/` cuando sus archivos difieren, y que se compara y elimina `.agent/` en un commit aparte desde la rama principal.

#### Scenario: Procedimiento de actualización documentado
- **WHEN** se lee la sección "Actualizar OpenSpec en un proyecto existente" de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** indica `openspec update` y la revisión del diff antes de commitear
- **AND** explica qué hacer con la carpeta `.agent/` que puede quedar

#### Scenario: Un proyecto con .agent/ se migra sin perder archivos
- **WHEN** en un directorio con `.agent/` generada por OpenSpec 1.4.1 se ejecuta `openspec update` con OpenSpec 1.14.3
- **THEN** existe `.agents/skills/openspec-apply-change/`
- **AND** `.agent/` no se borra sola cuando sus archivos difieren

### Requirement: La telemetría de OpenSpec se desactiva por máquina
El setup por máquina de `README.md` y `docs/modo-de-uso.md` SHALL indicar `openspec config set telemetry.enabled false`, con la comprobación `openspec config get telemetry.enabled`, porque las máquinas de la empresa no deben enviar telemetría de uso a terceros.

#### Scenario: Paso de telemetría en el setup
- **WHEN** se lee el setup por máquina de `README.md` y de `docs/modo-de-uso.md`
- **THEN** incluye el comando para desactivar la telemetría y el de comprobación

#### Scenario: Telemetría apagada en esta máquina
- **WHEN** se ejecuta `openspec config get telemetry.enabled`
- **THEN** devuelve `false`
