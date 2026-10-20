# Spec Delta

## MODIFIED Requirements

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
