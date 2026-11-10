## Why

Las reglas del Agente están copiadas a mano en cinco lugares: `.claude/CLAUDE.md` y las cuatro plantillas de `templates/`. Cada change de reglas repite la misma edición cuatro veces, más tareas para controlar a mano que los textos queden "idénticos". La instalación también es manual: copiar `CLAUDE.md`, skills y comandos a `~/.claude`, sincronizar el espejo del vault, comparar hashes antes y después, y volver a copiar las plantillas en cada proyecto con los comandos del README.

Las copias ya se desincronizaron: la `.github/copilot-instructions.md` de este repo (las reglas que lee Copilot cuando trabaja acá) no tiene las 8 reglas de ejecución, mientras que `templates/copilot/copilot-instructions.md` sí. Ninguna herramienta lo detectó. El próximo change (`clasificacion-odd-sdd`, #32) suma otra sección más a las cuatro plantillas. Issue: #35.

## What Changes

- **Fuente única de las plantillas del Agente:** las partes que se repiten (las 8 reglas de ejecución, el rol de constructor, git, la memoria del proyecto y el aviso del vault) pasan a fragmentos en `templates/fuente/`. Cada plantilla tiene un esqueleto con su parte propia (encabezado, comandos de Cursor, reglas mínimas de Antigravity) y marcas de inclusión. Un script genera las cuatro plantillas.
- **Control de desincronización:** el mismo script con `-Comprobar` falla si una plantilla commiteada no coincide con la generada, o si los títulos de las 8 reglas del `CLAUDE.md` no coinciden con los de la fuente. Corre en el CI de los PR de este repo.
- **Script de instalación por máquina:** copia `CLAUDE.md`, skills y comandos a `~/.claude` (y `GEMINI.md` a `~/.gemini` si la máquina usa Antigravity), sincroniza el espejo `_global/reglas-globales.md` del vault con commit y push, muestra una tabla de hashes y frena si una copia instalada tiene cambios locales.
- **Script de sincronización por proyecto:** actualiza `AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/sdd-workflow.mdc` y `.github/workflows/pr-check.yml` de un proyecto, conservando una sección `## Propio del proyecto` y frenando antes de pisar contenido propio que no reconoce. No commitea en el proyecto.
- **Tests automáticos de los scripts** con PowerShell 7 sin dependencias nuevas: `## Tests` deja de ser `ninguno`.
- **Este repo se sincroniza a sí mismo:** se corrige su `.github/copilot-instructions.md` con el script.
- **Primer ADR y visión del repo:** `docs/adr/0001` registra la elección de PowerShell 7 y de la generación desde fuente única; `docs/arquitectura/vision.md` nace con la hoja de ruta.
- README, guías y `CLAUDE.md` reemplazan los pasos manuales de copia por los scripts.

## Non-goals

- Generar el `CLAUDE.md` desde la fuente: es la fuente canónica de Claude y del espejo del vault, y sus reglas del Agente están en tercera persona ("el Agente frena") mientras que las plantillas hablan en segunda ("frená"). Solo se controla que tengan las mismas 8 reglas con los mismos títulos.
- Generar los comandos de `.claude/commands/` desde las skills: sigue como deuda en la hoja de ruta.
- Commitear o abrir PR en los proyectos: el script de sincronización deja los cambios para que se commiteen en la rama del change que corresponda.
- Instalar `templates/antigravity/settings.json`: tiene placeholders por máquina y se sigue fusionando a mano.
- Cambiar el contenido de las reglas: las plantillas generadas tienen el mismo texto que hoy, más el aviso de archivo generado y la sección `## Propio del proyecto`.

## Capabilities

### New Capabilities
- `rules-sync`: fuente única de las plantillas del Agente, generación y control de desincronización, instalación por máquina y sincronización por proyecto.

### Modified Capabilities
- `agent-templates`: las plantillas de reglas se generan desde `templates/fuente/` y llevan el aviso de archivo generado y la sección `## Propio del proyecto`.
- `project-onboarding`: el setup por máquina y la incorporación de un proyecto usan los scripts en vez de copiar a mano.

## Impact

- **Archivos nuevos:**
  - `templates/fuente/`: fragmentos compartidos y un esqueleto por plantilla.
  - `scripts/generar-plantillas.ps1`, `scripts/instalar.ps1`, `scripts/sincronizar-proyecto.ps1` y `scripts/comun.ps1` (funciones compartidas).
  - `tests/ejecutar.ps1` y `tests/*.Tests.ps1`: tests de los scripts, sin librerías externas.
  - `docs/adr/0001-fuente-unica-de-reglas-con-powershell.md` y `docs/arquitectura/vision.md`.
- **Archivos modificados:**
  - Las cuatro plantillas de `templates/`, ahora generadas.
  - `.github/workflows/plantillas.yml` (nuevo, solo para este repo): corre los tests y el control de plantillas. `pr-check.yml` no cambia, porque es el que se copia a los proyectos.
  - `.github/copilot-instructions.md`: sincronizado con la plantilla.
  - `.claude/CLAUDE.md`: la sincronización del espejo, el onboarding de agentes y el orden ante un cambio de reglas nombran los scripts.
  - `openspec/config.yaml`: `## Tests` con el comando de los tests y `## Arquitectura` con `scripts/` y `tests/`.
  - `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md` y los `README.md` de `templates/`.
- **Dependencias:** PowerShell 7 (`pwsh`), que ya es requisito del workflow y está en los runners `ubuntu-latest` de GitHub. Sin librerías nuevas.
- **Proyectos:** la primera sincronización de un proyecto con copias viejas o con contenido propio frena y pide fusionar a mano una vez; desde ahí, el contenido propio vive en `## Propio del proyecto` y se conserva.
- **Changes siguientes:** las tareas de instalación pasan a ser "correr `scripts/instalar.ps1`", y los cambios a las reglas del Agente se editan una sola vez en `templates/fuente/`.
