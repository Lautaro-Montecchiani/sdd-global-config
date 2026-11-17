## ADDED Requirements

### Requirement: Plantilla de pr-check con permisos mínimos
La plantilla `.github/workflows/pr-check.yml` SHALL declarar `permissions:` de solo lectura (`contents: read` y `pull-requests: read`), SHALL tratar como sensibles `.env`, `.key`, `.pem`, `.p12`, `secrets/`, `credentials.json` y `token.json`, y NO SHALL marcar como sensibles los archivos que terminan en `.example`, `.sample` o `.template`. SHALL empezar con un comentario que diga que no se edita en los proyectos y adónde van las mejoras.

#### Scenario: Permisos de solo lectura
- **WHEN** se lee `.github/workflows/pr-check.yml`
- **THEN** declara `permissions:` con `contents: read` y `pull-requests: read`

#### Scenario: Patrones sensibles y plantillas de ejemplo
- **WHEN** se lee el paso "Check no secrets in diff" de `.github/workflows/pr-check.yml`
- **THEN** los patrones sensibles incluyen `credentials.json` y `token.json`
- **AND** los archivos que terminan en `.example`, `.sample` o `.template` se excluyen antes de buscar patrones

#### Scenario: Comentario de origen
- **WHEN** se leen las primeras líneas de `.github/workflows/pr-check.yml`
- **THEN** dicen que el archivo se genera desde `sdd-global-config`, que las mejoras para todos van como issue en `sdd-global-config` y que lo propio del proyecto va en otro workflow

### Requirement: Mensaje de bloqueo de pr-check
Cuando `scripts/sincronizar-proyecto.ps1` deja bloqueado `.github/workflows/pr-check.yml`, en `-Aviso` y en la sincronización normal, SHALL explicar que, si la mejora sirve para todos, se abre un issue en `sdd-global-config` y que, si es propia, se pasa a otro workflow y se sincroniza con `-Forzar`. NO SHALL pedir pasar el contenido debajo de `## Propio del proyecto` para ese archivo. Los mensajes de los demás archivos bloqueados no cambian.

#### Scenario: Aviso con pr-check bloqueado
- **WHEN** se corre `-Aviso` sobre un proyecto cuyo `pr-check.yml` no coincide con ninguna versión de la plantilla
- **THEN** la línea nombra `.github/workflows/pr-check.yml` con la indicación del issue en `sdd-global-config` y del otro workflow con `-Forzar`
- **AND** no le pide pasar ese archivo debajo de `## Propio del proyecto`

#### Scenario: Aviso con pr-check y AGENTS.md bloqueados
- **WHEN** se corre `-Aviso` sobre un proyecto con `pr-check.yml` y `AGENTS.md` bloqueados
- **THEN** la línea tiene la indicación de `## Propio del proyecto` para `AGENTS.md` y la del issue u otro workflow para `pr-check.yml`

#### Scenario: Sincronización con pr-check bloqueado
- **WHEN** se corre la sincronización sin `-Forzar` sobre un proyecto con `pr-check.yml` bloqueado
- **THEN** termina con error y el mensaje explica las dos salidas para `pr-check.yml`
- **AND** no modifica el archivo

### Requirement: Mejoras de archivos generados vuelven al origen
`.claude/CLAUDE.md` y `README.md` SHALL decir que un archivo generado (`AGENTS.md`, las instrucciones de Copilot o Cursor, los comandos `/odd-apply` y `pr-check.yml`) no se mejora en el proyecto: si la mejora sirve para todos, se abre un issue en `sdd-global-config`; si es propia, va debajo de `## Propio del proyecto` en los `.md` o en otro workflow en el caso de `pr-check.yml`.

#### Scenario: Regla documentada
- **WHEN** se busca la regla en `.claude/CLAUDE.md` y en `README.md`
- **THEN** los dos dicen las dos salidas (issue en `sdd-global-config` o lugar propio del proyecto) y nombran `pr-check.yml` con su otro workflow

### Requirement: Sincronizar varios proyectos
`README.md` SHALL documentar cómo poner al día varios proyectos: detectar los atrasados con `-Aviso`, simular primero con `-Simular`, pasar en `-Agentes` solo los agentes que el proyecto ya usa, no sincronizar si los archivos a reemplazar tienen cambios sin commitear y no commitear desde el script.

#### Scenario: Procedimiento documentado
- **WHEN** se lee la sección "Sumar un proyecto al workflow" de `README.md`
- **THEN** tiene el procedimiento con `-Aviso`, `-Simular`, `-Agentes` con los agentes que el proyecto ya usa, el control de cambios sin commitear y que el script no commitea
