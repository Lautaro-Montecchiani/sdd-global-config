# agent-templates Specification

## Purpose
Define la estructura de plantillas por agente en `templates/` (una carpeta por agente con sus reglas, su configuración cuando el agente la soporta y un README de instalación) y la matriz que indica qué soporta cada agente según su documentación oficial.

## Requirements

### Requirement: Una carpeta por agente en templates
`templates/` SHALL tener una carpeta por agente soportado (`antigravity/`, `copilot/`, `cursor/`) y una carpeta `comun/` para lo que lee más de un agente. Cada carpeta SHALL contener un `README.md` que diga para qué agente es, qué archivos trae y dónde se instala cada uno. NO SHALL quedar plantillas sueltas en la raíz de `templates/`, salvo `templates/README.md`, ni una carpeta `gemini/`.

#### Scenario: Estructura por agente
- **WHEN** se listan los archivos de `templates/`
- **THEN** existen `templates/antigravity/settings.json`, `templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/comun/AGENTS.md`
- **AND** cada carpeta tiene su `README.md`
- **AND** en la raíz de `templates/` solo está `README.md`
- **AND** no existe `templates/gemini/`

#### Scenario: README de instalación por agente
- **WHEN** se lee el `README.md` de la carpeta de un agente
- **THEN** indica para qué agente es y el destino de instalación de cada archivo

### Requirement: Matriz de soporte por agente
`templates/README.md` SHALL tener una tabla con una fila por agente soportado (Antigravity, Copilot, Codex, Cursor) y columnas para reglas, permisos y barra de estado, indicando en cada celda la plantilla o el documento que lo cubre o, si no hay, el motivo ("no soportado" o "no verificado"). Una capacidad SHALL figurar como cubierta solo si la documentación oficial del agente la confirma. La matriz NO SHALL incluir Gemini CLI, retirado por Google.

#### Scenario: Agente con soporte parcial
- **WHEN** se lee la fila de Codex en la matriz
- **THEN** la columna de reglas apunta a `templates/comun/AGENTS.md`
- **AND** las columnas de permisos y barra de estado dicen "no verificado"

#### Scenario: Cursor cubierto por su carpeta
- **WHEN** se lee la fila de Cursor en la matriz
- **THEN** la columna de reglas apunta a `templates/cursor/sdd-workflow.mdc`
- **AND** la columna de permisos remite a `templates/cursor/README.md`
- **AND** la columna de barra de estado dice "no verificado"

#### Scenario: Antigravity con sus reglas
- **WHEN** se lee la fila de Antigravity en la matriz
- **THEN** la columna de reglas apunta a `templates/antigravity/GEMINI.md` con destino `~/.gemini/GEMINI.md`

#### Scenario: Sin Gemini CLI
- **WHEN** se lee `templates/README.md`
- **THEN** no hay fila ni carpeta de Gemini CLI
- **AND** una nota indica que Google lo retiró, con enlace al anuncio

### Requirement: Mismas reglas de ejecución en todas las plantillas de reglas
Los archivos de reglas de las plantillas (`templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/comun/AGENTS.md`) SHALL incluir las mismas 7 reglas de ejecución del Agente del `CLAUDE.md` global. La regla 7 SHALL pedir además guardar una copia completa del resumen final en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault.

#### Scenario: Reglas presentes en cada plantilla
- **WHEN** se buscan "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en las cuatro plantillas de reglas
- **THEN** aparecen en las cuatro

#### Scenario: Copia del resumen en el vault
- **WHEN** se lee la regla 7 de cada una de las cuatro plantillas y la del `CLAUDE.md` global
- **THEN** indica guardar la copia en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`
- **AND** indica que lleva fecha, rama y commit, sin datos personales ni credenciales
- **AND** indica que el Agente no la commitea ni la pushea
