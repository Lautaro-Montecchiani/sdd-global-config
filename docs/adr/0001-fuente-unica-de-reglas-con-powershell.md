# 0001. Fuente única de las reglas del Agente, generada con PowerShell 7

Estado: aceptada
Fecha: 2026-11-10
Change: sincronizar-reglas

## Contexto

Las reglas del Agente estaban copiadas a mano en cuatro plantillas (`AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc` y `GEMINI.md`) y en el `CLAUDE.md` global, y la instalación en cada máquina y en cada proyecto se hacía copiando archivos con los comandos del README. Las copias se desincronizaron sin que nada lo detectara: la `.github/copilot-instructions.md` de este repo había perdido las 8 reglas de ejecución. Cada change de reglas repetía la misma edición cuatro veces y tareas manuales de comparar hashes.

## Alternativas

- **Seguir copiando a mano con un checklist:** no detecta la desincronización; es lo que falló.
- **Un solo archivo de reglas y que cada agente lea ese archivo:** Cursor exige `.mdc` con frontmatter, Copilot busca `.github/copilot-instructions.md` y Antigravity `~/.gemini/GEMINI.md`; cada uno tiene además partes propias (comandos permitidos, reglas mínimas). No hay un formato que lean los cuatro.
- **Generar con Python, Node o una herramienta de plantillas:** suma un runtime o una dependencia que el workflow no necesita hoy. PowerShell 7 ya es el shell del workflow (perfil con `OBSIDIAN_VAULT` y `SDD_CONFIG_REPO`) y está en los runners de GitHub.
- **Generar también el `CLAUDE.md`:** es la fuente canónica de Claude y del espejo del vault, y sus reglas están en tercera persona. Se controla que tenga los mismos títulos de reglas, sin generarlo.

## Decisión

Las partes compartidas de las plantillas viven en `templates/fuente/fragmentos/` y cada plantilla tiene un esqueleto en `templates/fuente/esqueletos/` con marcas de inclusión. `scripts/generar-plantillas.ps1` (PowerShell 7, sin librerías externas) genera las cuatro plantillas, y con `-Comprobar` hace fallar el CI si alguna difiere o si los títulos de las reglas del `CLAUDE.md` no coinciden. La instalación por máquina (`scripts/instalar.ps1`) y por proyecto (`scripts/sincronizar-proyecto.ps1`) también son scripts de PowerShell 7, con chequeo de cambios locales y una sección `## Propio del proyecto` que se conserva.

## Consecuencias

- Positivas: una regla del Agente se edita una vez; la desincronización falla en el PR; instalar y sincronizar es un comando con el mismo control que antes se hacía a mano; los changes de reglas pierden las tareas de copiar y comparar.
- Negativas: las plantillas no se editan directamente (hay que editar la fuente y regenerar); los scripts son código que hay que mantener y testear; el workflow queda atado a PowerShell 7; la primera sincronización de un proyecto con contenido propio sin marcar requiere una fusión a mano.
