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
Los archivos de reglas de las plantillas (`templates/antigravity/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/comun/AGENTS.md`) SHALL incluir las mismas 8 reglas de ejecución del Agente del `CLAUDE.md` global. La regla 7 SHALL pedir además guardar una copia completa del resumen final en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` del vault. Los cuatro archivos SHALL generarse desde `templates/fuente/` con `scripts/generar-plantillas.ps1`, SHALL empezar (en `.mdc`, después del frontmatter) con un comentario que diga que el archivo se genera desde `templates/fuente/` y no se edita a mano, y SHALL terminar con el título `## Propio del proyecto` y un comentario que diga que lo que se agregue debajo se conserva al sincronizar.

#### Scenario: Reglas presentes en cada plantilla
- **WHEN** se buscan "Evidencia antes de `[x]`", "Test primero = falla primero" y "No debilitar tests" en las cuatro plantillas de reglas
- **THEN** aparecen en las cuatro

#### Scenario: Copia del resumen en el vault
- **WHEN** se lee la regla 7 de cada una de las cuatro plantillas y la del `CLAUDE.md` global
- **THEN** indica guardar la copia en `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`
- **AND** indica que lleva fecha, rama y commit, sin datos personales ni credenciales
- **AND** indica que el Agente no la commitea ni la pushea

#### Scenario: Regla 8 en cada plantilla
- **WHEN** se busca "Respetar la arquitectura" en las cuatro plantillas de reglas y en el `CLAUDE.md` global
- **THEN** aparece en las cinco
- **AND** el `CLAUDE.md` global dice que las plantillas llevan "estas mismas 8 reglas"

#### Scenario: Aviso de archivo generado y sección propia
- **WHEN** se generan las cuatro plantillas
- **THEN** cada una tiene el comentario de archivo generado como primera línea (en `sdd-workflow.mdc`, como primera línea después del frontmatter)
- **AND** cada una termina con `## Propio del proyecto` y el comentario de contenido que se conserva
- **AND** sin ese aviso y esa sección, el resto del texto es igual al de las plantillas anteriores al change

### Requirement: Handoff ODD en las plantillas de reglas
Las cuatro plantillas de reglas del Agente (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`) SHALL tener una sección `## Handoff ODD`, con texto idéntico, que diga que el Agente: lee `docs/odd/<nombre>.md`; trabaja solo en el branch `odd/<nombre>` y en los archivos permitidos; aplica las mismas reglas de ejecución que en SDD; pega la evidencia en `## Evidencia` del documento en vez de escribir la nota `apply\` del vault; frena y avisa "escalar a SDD" si al implementar se cumple un criterio SDD; y commitea con `Spec-ID: odd-<nombre>`. La sección SHALL salir de un único fragmento de la fuente, `templates/fuente/fragmentos/handoff-odd.md`, incluido en los cuatro esqueletos después de las reglas de ejecución, y las plantillas SHALL regenerarse con `scripts/generar-plantillas.ps1`. La regla 7 de cada plantilla y la del `CLAUDE.md` global SHALL terminar con la excepción ODD: en un handoff ODD, la evidencia va en `## Evidencia` del documento y no se escribe la nota `apply\` del vault.

#### Scenario: Sección presente en las cuatro
- **WHEN** se busca `## Handoff ODD` en las cuatro plantillas de reglas
- **THEN** aparece una vez en cada una
- **AND** el texto de la sección es idéntico en las cuatro

#### Scenario: Excepción ODD en la regla 7
- **WHEN** se lee la regla 7 de las cuatro plantillas de reglas y la del `CLAUDE.md` global
- **THEN** cada una termina diciendo que en un handoff ODD la evidencia va en `## Evidencia` del documento ODD y no se escribe la nota `apply\` del vault
- **AND** la oración es idéntica en las cuatro plantillas

#### Scenario: Sección generada desde la fuente
- **WHEN** se corre `scripts/generar-plantillas.ps1 -Comprobar` después del change
- **THEN** termina con código 0
- **AND** `templates/fuente/fragmentos/handoff-odd.md` existe y los cuatro esqueletos lo incluyen

#### Scenario: El Agente encuentra un criterio SDD
- **WHEN** el Agente, siguiendo la plantilla, necesita tocar más archivos de los permitidos
- **THEN** frena, lo escribe en `## Progreso` del documento y avisa "escalar a SDD"

