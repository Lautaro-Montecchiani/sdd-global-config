## ADDED Requirements

### Requirement: Carga única de las reglas en este repo
El repo SHALL versionar `.claude/settings.json` con la clave `claudeMdExcludes` y el único patrón `**/sdd-global-config/.claude/CLAUDE.md`, para que Claude Code no cargue la copia del repo y use solo las reglas instaladas. El archivo NO SHALL declarar permisos ni otras claves, ni contener rutas absolutas.

#### Scenario: Patrón de exclusión versionado
- **WHEN** se lee `.claude/settings.json`
- **THEN** es un JSON válido cuya única clave es `claudeMdExcludes`
- **AND** `claudeMdExcludes` es una lista con un solo elemento, `**/sdd-global-config/.claude/CLAUDE.md`

#### Scenario: Excluye solo la copia del repo
- **WHEN** se compara el patrón con `C:/Users/ana/sdd-global-config/.claude/CLAUDE.md`, `/home/ana/sdd-global-config/.claude/CLAUDE.md`, `C:/Users/ana/.claude/CLAUDE.md` y `/home/ana/.claude/CLAUDE.md`
- **THEN** coincide con las dos rutas de la copia del repo
- **AND** no coincide con las dos rutas del `CLAUDE.md` global

#### Scenario: Sin rutas personales
- **WHEN** se buscan letras de unidad (`C:`), `/Users/`, `/home/` y el nombre de la carpeta del usuario en `.claude/settings.json`
- **THEN** no hay resultados

### Requirement: Documentación de la carga única de las reglas
`README.md` SHALL explicar en la sección de setup que en este repo Claude carga solo las reglas instaladas, que el clon tiene que estar en una carpeta `sdd-global-config` y que para probar reglas editadas en una rama se corre `instalar.ps1` desde esa rama.

#### Scenario: Documentación de la carga
- **WHEN** se lee la sección de setup de `README.md`
- **THEN** dice que en este repo Claude carga solo las reglas instaladas, que el clon va en una carpeta `sdd-global-config` y que para probar reglas de una rama se corre `instalar.ps1` desde esa rama
