## ADDED Requirements

### Requirement: Comandos de Claude generados desde las skills
Las skills de `skills/` SHALL ser la única fuente del texto de los comandos de `.claude/commands/`. Cada comando SHALL tener en `templates/fuente/comandos/` un encabezado con su frontmatter y una o más líneas `<!-- incluir-skill: <skill> -->` (el cuerpo completo de `skills/<skill>/SKILL.md`, sin su frontmatter) o `<!-- incluir-skill: <skill>#<título> -->` (solo la sección `## <título>` de esa skill, hasta el siguiente título `## ` que no esté dentro de un bloque de código). `scripts/generar-plantillas.ps1` SHALL generar `.claude/commands/opsx/apply.md`, `opsx/archive.md`, `opsx/explore.md`, `opsx/propose.md`, `opsx/verify.md`, `odd/start.md`, `odd/verify.md`, `odd/close.md` y `odd.md` reemplazando cada marca por el texto que nombra, con un aviso de archivo generado después del frontmatter, en UTF-8 sin BOM y con fin de línea LF. `odd.md` SHALL ser idéntico a `odd/start.md`. Si una marca nombra una skill o una sección que no existe, el script SHALL terminar con código distinto de 0, nombrar el encabezado y la marca, y no escribir ningún archivo (ni plantillas ni comandos).

#### Scenario: Comando con la skill completa
- **WHEN** se corre `generar-plantillas.ps1` con el encabezado `opsx/apply.md` que incluye `openspec-apply-change`
- **THEN** `.claude/commands/opsx/apply.md` tiene el frontmatter del encabezado, el aviso de archivo generado y el cuerpo de `skills/openspec-apply-change/SKILL.md` sin su frontmatter
- **AND** no contiene la línea `<!-- incluir-skill: openspec-apply-change -->`

#### Scenario: Comando con secciones de una skill
- **WHEN** se corre `generar-plantillas.ps1` con el encabezado `odd/verify.md` que incluye las secciones `Verify (`/odd:verify`)` y `Escalado` de `odd-change`
- **THEN** `.claude/commands/odd/verify.md` contiene esas dos secciones completas
- **AND** no contiene la sección `Inicio (`/odd`)`

#### Scenario: Título dentro de un bloque de código
- **WHEN** la sección incluida tiene un bloque de código con líneas `## Objetivo` o `## Evidencia`
- **THEN** esas líneas quedan dentro de la sección generada y la sección termina en el siguiente título `## ` fuera del bloque

#### Scenario: Mismo texto para /odd y /odd:start
- **WHEN** se corre `generar-plantillas.ps1`
- **THEN** `.claude/commands/odd.md` y `.claude/commands/odd/start.md` son idénticos

#### Scenario: Dato inválido: skill inexistente
- **WHEN** un encabezado tiene `<!-- incluir-skill: no-existe -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra el encabezado y la marca
- **AND** ninguna plantilla ni ningún comando cambia

#### Scenario: Dato inválido: sección inexistente
- **WHEN** un encabezado tiene `<!-- incluir-skill: odd-change#No existe -->` y se corre `generar-plantillas.ps1`
- **THEN** el script termina con código distinto de 0 y nombra el encabezado y la marca
- **AND** ninguna plantilla ni ningún comando cambia

## MODIFIED Requirements

### Requirement: Control de desincronización
`generar-plantillas.ps1 -Comprobar` NO SHALL escribir archivos. SHALL terminar con código distinto de 0 y listar los archivos si alguna plantilla commiteada o algún comando de `.claude/commands/` difiere del generado (comparando sin diferencias de fin de línea ni BOM), o si los títulos de las reglas numeradas de `### Reglas de ejecución del Agente` de `.claude/CLAUDE.md` no son iguales, en el mismo orden, a los de `templates/fuente/fragmentos/reglas-ejecucion.md`. El repositorio SHALL correr este control, los tests de los scripts y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` en un workflow de GitHub Actions en cada PR.

#### Scenario: Plantilla editada a mano
- **WHEN** se agrega una línea a `templates/cursor/sdd-workflow.mdc` sin tocar la fuente y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `templates/cursor/sdd-workflow.mdc`
- **AND** el archivo no cambia

#### Scenario: Comando editado a mano
- **WHEN** se agrega una línea a `.claude/commands/opsx/verify.md` sin tocar `skills/openspec-verify-change/SKILL.md` y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `.claude/commands/opsx/verify.md`
- **AND** el archivo no cambia

#### Scenario: Skill editada sin regenerar
- **WHEN** se cambia una línea de `skills/odd-change/SKILL.md` dentro de la sección `Escalado` sin regenerar y se corre `generar-plantillas.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `.claude/commands/odd/start.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd.md`

#### Scenario: Reglas del CLAUDE.md con otro título
- **WHEN** el `CLAUDE.md` tiene una regla "No inventar nada" y la fuente "No inventar"
- **THEN** `-Comprobar` termina con código distinto de 0 y muestra las dos listas de títulos

#### Scenario: Todo sincronizado
- **WHEN** las plantillas y los comandos son los generados y los títulos coinciden
- **THEN** `-Comprobar` termina con código 0

#### Scenario: Workflow de PR
- **WHEN** se lee `.github/workflows/plantillas.yml`
- **THEN** corre en `pull_request`, hace checkout con `fetch-depth: 0`
- **AND** corre con `pwsh` los tests, `generar-plantillas.ps1 -Comprobar` y `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`
