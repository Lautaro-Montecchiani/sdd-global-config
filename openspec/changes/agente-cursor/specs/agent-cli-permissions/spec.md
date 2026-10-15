# Spec Delta

## ADDED Requirements

### Requirement: Permisos de ejecución del Agente en Cursor documentados
El setup por máquina de `README.md`, `templates/README.md` y `docs/modo-de-uso.md` SHALL describir cómo configurar en Cursor la ejecución automática de comandos del Agente con una allowlist genérica: `git status`, `git diff`, `git branch`, `git restore` y `openspec`. La documentación SHALL advertir que agregar `powershell` o `cmd.exe` permite ejecutar cualquier comando sin confirmación y SHALL NOT incluir rutas reales ni el nombre de usuario.

#### Scenario: Allowlist documentada
- **WHEN** se lee la sección de setup por máquina de `README.md` y de `docs/modo-de-uso.md`
- **THEN** indica dónde se configura la ejecución automática en Cursor
- **AND** lista esos cinco comandos

#### Scenario: Advertencia sobre shells
- **WHEN** se lee `templates/README.md`
- **THEN** advierte que sumar `powershell` o `cmd.exe` a la allowlist equivale a permitir cualquier comando

## REMOVED Requirements

### Requirement: Baseline de permisos del Agente en una máquina nueva
**Reason**: Antigravity deja de ser el constructor; Cursor no usa `~/.gemini/antigravity-cli/settings.json`.
**Migration**: Configurar la ejecución automática en Cursor según el requisito "Permisos de ejecución del Agente en Cursor documentados". El `settings.json` existente en cada máquina no se borra.

### Requirement: Allowlist base de comandos
**Reason**: La plantilla `templates/antigravity-settings.json` se retira.
**Migration**: La allowlist equivalente se documenta para Cursor (requisito "Permisos de ejecución del Agente en Cursor documentados").

### Requirement: Workspaces de confianza declarados por máquina
**Reason**: Concepto propio del CLI de Antigravity; la plantilla se retira.
**Migration**: Ninguna; en Cursor cada proyecto se abre como workspace.

### Requirement: Barra de estado especificada por comportamiento
**Reason**: Cursor (IDE) no tiene barra de estado configurable por script; los scripts de Antigravity dejan de ser necesarios.
**Migration**: Ninguna. Los scripts existentes en `~/.gemini/antigravity-cli/scratch/` pueden quedar o borrarse a mano.

### Requirement: La instalación por máquina está documentada
**Reason**: Describía la instalación de la plantilla de Antigravity y el prompt de la barra de estado.
**Migration**: Reemplazado por "Permisos de ejecución del Agente en Cursor documentados" y por los requisitos de onboarding de `project-onboarding`.
