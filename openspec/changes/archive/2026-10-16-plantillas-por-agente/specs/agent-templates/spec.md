## ADDED Requirements

### Requirement: Una carpeta por agente en templates
`templates/` SHALL tener una carpeta por agente soportado (`antigravity/`, `gemini/`, `copilot/`) y una carpeta `comun/` para lo que lee más de un agente. Cada carpeta SHALL contener un `README.md` que diga para qué agente es, qué archivos trae y dónde se instala cada uno. NO SHALL quedar plantillas sueltas en la raíz de `templates/`, salvo `templates/README.md`.

#### Scenario: Estructura por agente
- **WHEN** se listan los archivos de `templates/`
- **THEN** existen `templates/antigravity/settings.json`, `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md` y `templates/comun/AGENTS.md`
- **AND** cada carpeta tiene su `README.md`
- **AND** en la raíz de `templates/` solo está `README.md`

#### Scenario: README de instalación por agente
- **WHEN** se lee el `README.md` de la carpeta de un agente
- **THEN** indica para qué agente es y el destino de instalación de cada archivo

### Requirement: Matriz de soporte por agente
`templates/README.md` SHALL tener una tabla con una fila por agente (Antigravity, Gemini CLI, Copilot, Codex, Cursor) y columnas para reglas, permisos y barra de estado, indicando en cada celda la plantilla que lo cubre o, si no hay, el motivo ("no soportado", "no verificado" o "lo agrega `agente-cursor`"). Una capacidad SHALL figurar como cubierta solo si la documentación oficial del agente la confirma.

#### Scenario: Agente con soporte parcial
- **WHEN** se lee la fila de Gemini CLI en la matriz
- **THEN** la columna de reglas apunta a `templates/gemini/GEMINI.md`
- **AND** las columnas de permisos y barra de estado dicen "no verificado"

#### Scenario: Agente pendiente
- **WHEN** se lee la fila de Cursor en la matriz
- **THEN** dice que lo agrega el change `agente-cursor` en `templates/cursor/`

### Requirement: Mismas reglas de ejecución en todas las plantillas de reglas
Los archivos de reglas de las plantillas (`templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md` y `templates/comun/AGENTS.md`) SHALL incluir las mismas 7 reglas de ejecución del Agente del `CLAUDE.md` global, con el formato que pida cada agente.

#### Scenario: Reglas presentes en cada plantilla
- **WHEN** se buscan "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en las tres plantillas de reglas
- **THEN** aparecen en las tres
