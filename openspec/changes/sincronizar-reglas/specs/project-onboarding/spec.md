# Spec Delta

## Purpose
El setup por máquina y la incorporación de un proyecto pasan de copiar archivos a mano a correr `scripts/instalar.ps1` y `scripts/sincronizar-proyecto.ps1`.

## MODIFIED Requirements

### Requirement: El setup por máquina instala skills y comandos globales de Claude
El setup por máquina SHALL instalar en `~/.claude/skills/` todas las skills de `skills/` y en `~/.claude/commands/` los comandos de `.claude/commands/`, porque los comandos son lo que ejecutan `/opsx:*` y las skills los complementan. Las guías SHALL indicar hacerlo con `pwsh scripts/instalar.ps1` desde la raíz del repo (con `-Simular` para ver antes qué cambia), que además instala el `CLAUDE.md` y sincroniza el espejo del vault, y NO SHALL indicar copiarlos a mano.

#### Scenario: Skills y comandos instalados
- **WHEN** se lee el setup por máquina del `README.md`, de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** indican correr `scripts/instalar.ps1`
- **AND** dicen que instala el `CLAUDE.md`, todas las skills de `skills/` y los comandos de `.claude/commands/` en `~/.claude/`
- **AND** no tienen comandos `cp` de `skills\` ni de `.claude\`

### Requirement: Reglas del Agente por proyecto en Cursor
El repositorio SHALL versionar la plantilla `templates/cursor/sdd-workflow.mdc`, y las guías SHALL indicar instalarla en `.cursor/rules/sdd-workflow.mdc` de cada proyecto que usa Cursor como Agente con `scripts/sincronizar-proyecto.ps1`, junto con `AGENTS.md` y `.github/copilot-instructions.md` según el agente. La plantilla SHALL aplicarse siempre (`alwaysApply: true`), remitir al espejo del vault `_global/reglas-globales.md` y no contener rutas con el usuario local.

#### Scenario: Instalación de la regla
- **WHEN** se lee la sección "Sumar un proyecto al workflow" de `README.md` y la equivalente de `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** indican correr `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .` (con `-Agentes` para elegir `comun`, `copilot` o `cursor`)
- **AND** no tienen comandos `cp` de plantillas de reglas

#### Scenario: Contenido de la regla
- **WHEN** se lee `templates/cursor/sdd-workflow.mdc`
- **THEN** su frontmatter tiene `alwaysApply: true`
- **AND** indica leer `$env:OBSIDIAN_VAULT\_global\reglas-globales.md`, sin ruta hardcodeada (la variable se configura una vez por máquina)
- **AND** define el rol de constructor con commits en `change/{nombre}`, formato `{type}: {desc}` y trailer `Spec-ID`

#### Scenario: Cursor solo implementa
- **WHEN** se lee `templates/cursor/sdd-workflow.mdc`
- **THEN** indica que el Agente solo ejecuta `/opsx-apply`
- **AND** indica que `/opsx-propose`, `/opsx-verify`, `/opsx-archive`, `/opsx-explore` y `/opsx-sync` corresponden a Claude y no deben ejecutarse en Cursor

### Requirement: El setup por máquina se hace por agente
El setup por máquina de `README.md` y `docs/modo-de-uso.md` SHALL tener pasos separados para cada agente (Antigravity: `GEMINI.md` y `settings.json`; Cursor: ejecución automática) e indicar que cada persona sigue solo los del agente que usa. El paso de Antigravity SHALL instalar `templates\antigravity\GEMINI.md` en `~/.gemini/GEMINI.md` con `scripts/instalar.ps1` (que lo instala cuando existe la carpeta `~/.gemini`) y seguir copiando `settings.json` solo si no existe. El repositorio SHALL seguir versionando las plantillas de Antigravity.

#### Scenario: Pasos separados por agente
- **WHEN** se lee el setup por máquina de `README.md` y de `docs/modo-de-uso.md`
- **THEN** hay un bloque de pasos para Antigravity y otro para Cursor
- **AND** se indica seguir solo el del agente que se usa

#### Scenario: Plantillas de Antigravity presentes
- **WHEN** se listan los archivos de `templates/`
- **THEN** existen `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json`

#### Scenario: Ruta nueva en el setup
- **WHEN** se busca el paso que instala `GEMINI.md` en `README.md` y `docs/modo-de-uso.md`
- **THEN** indica correr `scripts/instalar.ps1`, que instala `templates\antigravity\GEMINI.md` en `~/.gemini/GEMINI.md`
- **AND** ninguna guía menciona `templates\gemini\`
