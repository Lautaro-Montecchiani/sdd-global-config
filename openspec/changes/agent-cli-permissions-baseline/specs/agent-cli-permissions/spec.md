## ADDED Requirements

### Requirement: La configuración personal del CLI del Agente no se versiona
El repositorio SHALL NOT versionar la carpeta `.gemini/` con archivos de configuración personal del CLI del Agente, porque contienen rutas de la máquina, workspaces de confianza y permisos. El repositorio SHALL versionar en su lugar plantillas sin datos de la máquina en `templates/`.

#### Scenario: `.gemini/` fuera de git
- **WHEN** se ejecuta `git ls-files .gemini`
- **THEN** no devuelve ningún archivo
- **AND** `.gitignore` contiene `.gemini/`

#### Scenario: Los archivos locales se conservan
- **WHEN** se deja de versionar `.gemini/`
- **THEN** los archivos de `.gemini/` siguen existiendo en el disco
- **AND** la configuración real del CLI en `~/.gemini/antigravity-cli/` no se modifica

### Requirement: Baseline de permisos del Agente en una máquina nueva
Una máquina que use esta configuración SHALL tener en `~/.gemini/antigravity-cli/settings.json` los valores `toolPermission` en `always-proceed`, `artifactReviewPolicy` en `always-proceed` y `allowNonWorkspaceAccess` en `true`.

#### Scenario: Permisos replicados desde la plantilla
- **WHEN** se instala `templates/antigravity-settings.json` en una máquina nueva
- **THEN** el `settings.json` resultante contiene los tres valores de permisos anteriores

### Requirement: Allowlist base de comandos
La plantilla SHALL incluir en `permissions.allow` únicamente los comandos genéricos `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec` y `powershell`. La plantilla SHALL NOT incluir comandos puntuales, como un `git commit` con archivos de un proyecto o scripts de una sesión identificados por un id.

#### Scenario: Allowlist genérica
- **WHEN** se lee `permissions.allow` de `templates/antigravity-settings.json`
- **THEN** contiene esos siete comandos
- **AND** no contiene rutas de sesión ni comandos específicos de un proyecto

### Requirement: Workspaces de confianza declarados por máquina
La plantilla SHALL incluir `trustedWorkspaces` con un valor de ejemplo con placeholder, y cada máquina SHALL declarar sus propios workspaces de confianza. Los workspaces reales SHALL NOT versionarse.

#### Scenario: Cada máquina declara los suyos
- **WHEN** se instala la plantilla en una máquina nueva
- **THEN** la persona reemplaza el placeholder por las carpetas de sus propios proyectos
- **AND** la plantilla versionada no contiene rutas reales ni el nombre de usuario

### Requirement: Barra de estado portable
La plantilla SHALL configurar `statusLine` con un comando que apunte a `statusline.bat` dentro de `~/.gemini/antigravity-cli/scratch/`. El repositorio SHALL proveer `templates/antigravity-statusline.bat` y `templates/antigravity-statusline.ps1` sin rutas de usuario, resolviendo el directorio con `%USERPROFILE%`.

#### Scenario: Scripts de la barra de estado sin usuario
- **WHEN** se leen `templates/antigravity-statusline.bat` y `templates/antigravity-statusline.ps1`
- **THEN** ninguno contiene una ruta absoluta con nombre de usuario
- **AND** el `.bat` invoca al `.ps1` usando `%USERPROFILE%`

### Requirement: La instalación por máquina está documentada
El `README.md` y la guía de uso (`docs/modo-de-uso.md`) SHALL incluir un paso de instalación por máquina de la plantilla de permisos y de la barra de estado, que indique el destino y los valores que hay que completar.

#### Scenario: Paso de instalación visible
- **WHEN** se lee la sección de setup por máquina del `README.md` y de `docs/modo-de-uso.md`
- **THEN** describen dónde copiar cada plantilla de `templates/`
- **AND** indican reemplazar los placeholders de `trustedWorkspaces` y de `statusLine`
