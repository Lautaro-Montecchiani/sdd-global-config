# Spec Delta

## MODIFIED Requirements

### Requirement: Los proyectos se inician solo con el Agente
Las guías SHALL indicar `openspec init --tools cursor` para iniciar un proyecto y SHALL NOT incluir `claude` en `--tools`, para que Claude use los comandos y skills globales y no copias locales por defecto. Las guías SHALL NOT pedir "liberar el slot de apply".

#### Scenario: Comando de init sin claude
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** ningún comando `openspec init` incluye `claude` en `--tools`
- **AND** el comando indicado es `openspec init --tools cursor`
- **AND** ninguna guía contiene el paso de "liberar el slot de apply"

#### Scenario: Un proyecto iniciado solo con el Agente no tiene copias de Claude
- **WHEN** se ejecuta `openspec init --tools cursor` en un directorio nuevo y luego `openspec update`
- **THEN** existe el comando del Agente `.cursor/commands/opsx-apply.md`
- **AND** no existe la carpeta `.claude/` en el proyecto

## ADDED Requirements

### Requirement: Reglas del Agente por proyecto en Cursor
El repositorio SHALL versionar la plantilla `templates/cursor-rules.mdc`, y las guías SHALL indicar copiarla a `.cursor/rules/sdd-workflow.mdc` de cada proyecto que se suma al workflow. La plantilla SHALL aplicarse siempre (`alwaysApply: true`), remitir al espejo del vault `_global/reglas-globales.md` y no contener rutas con el usuario local.

#### Scenario: Instalación de la regla
- **WHEN** se lee la sección "Sumar un proyecto al workflow" de `README.md` y la equivalente de `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** indican copiar `$env:SDD_CONFIG_REPO\templates\cursor-rules.mdc` a `.cursor\rules\sdd-workflow.mdc` del proyecto

#### Scenario: Contenido de la regla
- **WHEN** se lee `templates/cursor-rules.mdc`
- **THEN** su frontmatter tiene `alwaysApply: true`
- **AND** indica leer `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback `C:\TPA\_global\reglas-globales.md`)
- **AND** define el rol de constructor con commits en `change/{nombre}`, formato `{type}: {desc}` y trailer `Spec-ID`

#### Scenario: Cursor solo implementa
- **WHEN** se lee `templates/cursor-rules.mdc`
- **THEN** indica que el Agente solo ejecuta `/opsx-apply`
- **AND** indica que `/opsx-propose`, `/opsx-verify`, `/opsx-archive`, `/opsx-explore` y `/opsx-sync` corresponden a Claude y no deben ejecutarse en Cursor

### Requirement: El setup por máquina no instala configuración de Antigravity
El setup por máquina de `README.md` y `docs/modo-de-uso.md` SHALL NOT incluir pasos que copien `GEMINI.md` ni `antigravity-settings.json`, y el repositorio SHALL NOT versionar esas plantillas.

#### Scenario: Plantillas retiradas
- **WHEN** se listan los archivos de `templates/`
- **THEN** no existen `GEMINI.md` ni `antigravity-settings.json`

#### Scenario: Setup sin pasos de Antigravity
- **WHEN** se busca `.gemini` y `antigravity` en `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y `templates/README.md`
- **THEN** solo aparecen en la sección de migración de proyectos existentes

### Requirement: Migración de proyectos existentes de Antigravity a Cursor
Las guías SHALL describir cómo pasar un proyecto que ya usa OpenSpec con Antigravity a Cursor: ejecutar `openspec init --tools cursor` en el proyecto, instalar `.cursor/rules/sdd-workflow.mdc` y, de forma opcional, eliminar `.agent/` y `.agents/` de Antigravity. Las guías SHALL indicar que la eliminación se commitea aparte y desde la rama principal.

#### Scenario: Procedimiento de migración documentado
- **WHEN** se lee la sección de proyecto existente con OpenSpec de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** describe los tres pasos anteriores
- **AND** indica commitear la eliminación de `.agent/`/`.agents/` aparte, desde la rama principal

#### Scenario: Proyecto migrado
- **WHEN** en un proyecto con Antigravity se ejecutan los pasos de migración
- **THEN** existen `.cursor/commands/opsx-apply.md` y `.cursor/rules/sdd-workflow.mdc`
- **AND** no existe la carpeta `.claude/` creada por el proceso
