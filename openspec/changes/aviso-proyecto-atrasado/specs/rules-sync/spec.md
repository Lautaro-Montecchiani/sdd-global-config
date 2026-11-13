## ADDED Requirements

### Requirement: Aviso de proyecto atrasado
`scripts/sincronizar-proyecto.ps1 -Proyecto <ruta> -Aviso` NO SHALL escribir en el proyecto. SHALL controlar solo los archivos del Agente que ya existen en el proyecto, con el mismo criterio que la sincronización para distinguir al día, atrasado y bloqueado. SHALL terminar con código 0 si todo está al día o no hay archivos del Agente, y con código distinto de 0 si algún archivo está atrasado o bloqueado. NO SHALL combinarse con otros modos ni con `-Agentes` o `-PrCheck`.

#### Scenario: Proyecto al día
- **WHEN** se corre `-Aviso` sobre un proyecto cuyo `AGENTS.md` y `.github/copilot-instructions.md` son iguales a sus plantillas
- **THEN** el código de salida es 0

#### Scenario: Archivo atrasado
- **WHEN** se corre `-Aviso` sobre un proyecto cuyo `.github/copilot-instructions.md` es igual a una versión anterior de la plantilla en la historia de git
- **THEN** el código de salida es distinto de 0
- **AND** ningún archivo del proyecto cambia

#### Scenario: Contenido propio sin marcar
- **WHEN** se corre `-Aviso` sobre un proyecto cuyo `AGENTS.md` no tiene `## Propio del proyecto` y no coincide con ninguna versión de la plantilla
- **THEN** el código de salida es distinto de 0

#### Scenario: Solo archivos existentes
- **WHEN** se corre `-Aviso` sobre un proyecto que tiene solo `.github/copilot-instructions.md`, igual a su plantilla, y no tiene `AGENTS.md` ni `.cursor/`
- **THEN** el código de salida es 0
- **AND** la salida no menciona `AGENTS.md`

#### Scenario: Proyecto sin archivos del Agente
- **WHEN** se corre `-Aviso` sobre una carpeta sin `AGENTS.md`, `.github/copilot-instructions.md`, `.github/prompts/odd-apply.prompt.md`, `.cursor/rules/sdd-workflow.mdc`, `.cursor/commands/odd-apply.md` ni `.github/workflows/pr-check.yml`
- **THEN** el código de salida es 0

#### Scenario: Parámetros incompatibles
- **WHEN** se corre `sincronizar-proyecto.ps1 -Proyecto <ruta> -Aviso -Comprobar`
- **THEN** termina con código distinto de 0 y un mensaje que dice que `-Aviso` no se combina con otros modos
- **AND** no escribe ningún archivo

#### Scenario: Dato inválido: archivo del Agente vacío
- **WHEN** se corre `-Aviso` sobre un proyecto cuyo `AGENTS.md` existe pero está vacío
- **THEN** lo trata como bloqueado, sin error de ejecución
- **AND** el código de salida es distinto de 0

### Requirement: Salida del aviso de proyecto
La salida de `-Aviso` SHALL ser una sola línea, con rutas relativas al proyecto y sin rutas absolutas. SHALL decir si las reglas del Agente están al día o si el proyecto no tiene archivos del Agente; si hay atrasados, SHALL listarlos con el comando para actualizarlos; si hay bloqueados, SHALL listarlos con la indicación de pasar el contenido propio debajo de `## Propio del proyecto`.

#### Scenario: Línea al día
- **WHEN** se corre `-Aviso` sobre un proyecto al día
- **THEN** la salida es una línea que dice que las reglas del Agente están al día

#### Scenario: Línea con atrasados
- **WHEN** se corre `-Aviso` sobre un proyecto con `.github/copilot-instructions.md` atrasado
- **THEN** la línea nombra `.github/copilot-instructions.md` e incluye `sincronizar-proyecto.ps1 -Proyecto .`

#### Scenario: Línea con bloqueados
- **WHEN** se corre `-Aviso` sobre un proyecto con `AGENTS.md` bloqueado
- **THEN** la línea nombra `AGENTS.md` y menciona `## Propio del proyecto`

#### Scenario: Línea sin archivos del Agente
- **WHEN** se corre `-Aviso` sobre una carpeta sin archivos del Agente
- **THEN** la salida es una línea que dice que el proyecto no tiene archivos del Agente

#### Scenario: Sin rutas absolutas en la salida
- **WHEN** se corre `-Aviso` sobre un proyecto con un archivo atrasado y otro bloqueado
- **THEN** la salida no contiene la ruta absoluta del proyecto ni la del repo

### Requirement: Aviso al iniciar sesión en un proyecto
`.claude/CLAUDE.md`, en "Al iniciar cada sesión", SHALL indicar que Claude corre `sincronizar-proyecto.ps1 -Proyecto . -Aviso` desde `$env:SDD_CONFIG_REPO` en todo proyecto con archivos del Agente, salvo en `sdd-global-config`, y que muestra la línea si el código de salida es distinto de 0. Claude NO SHALL sincronizar ni editar esos archivos por su cuenta.

#### Scenario: Paso en el inicio de sesión
- **WHEN** se lee "Al iniciar cada sesión" en `.claude/CLAUDE.md`
- **THEN** incluye el comando con `-Aviso` y las condiciones: no correrlo en `sdd-global-config` ni en carpetas sin archivos del Agente
- **AND** dice que Claude no sincroniza ni edita los archivos por su cuenta

#### Scenario: Sin variable del repo
- **WHEN** se lee "Al iniciar cada sesión" en `.claude/CLAUDE.md`
- **THEN** dice que, sin `$env:SDD_CONFIG_REPO`, Claude avisa que no se pudo controlar el proyecto y continúa

#### Scenario: Documentación del modo aviso
- **WHEN** se busca `-Aviso` en `README.md` y en `docs/modo-de-uso.md`
- **THEN** los dos explican qué controla, que no escribe y que Claude lo corre al iniciar sesión
