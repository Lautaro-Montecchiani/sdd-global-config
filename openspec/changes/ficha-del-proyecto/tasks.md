# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply.

## 1. Skill ficha

- [x] 1.1 Crear `skills/ficha/SKILL.md` con frontmatter `name: ficha` y una `description` que diga que completa la ficha del proyecto (descripción, objetivos, alcance, datos y stack) en `openspec/config.yaml` sin reescribir lo que ya existe. Cuerpo con los pasos 1 a 6 de design D2, el formato de D1 y las restricciones de D2 y de la Security Layer (sin valores reales de datos, sin leer secretos, sin ejecutar código, sin changes, ramas, commits ni vault). Sin IDs del design (`D1`, `D2`…) en el texto. Evidencia: el frontmatter y la lista de pasos pegados en el resumen, y `Select-String -Path skills/ficha/SKILL.md -Pattern '\bD\d+\b'` sin resultados.
- [x] 1.2 Verificar con un script en archivo que `skills/ficha/` no contiene `C:\Users` ni rutas absolutas, y pegar la salida.

## 2. Propose (skill y comando)

- [x] 2.1 En `skills/openspec-propose/SKILL.md` **y** `.claude/commands/opsx/propose.md`, aplicar design D3:
  - paso 0: detectar si falta `## Alcance`, `## Datos` o `## Stack`, sin preguntar;
  - "Output": la línea de aviso "Falta la ficha del proyecto (`<lo que falta>`): corré `/ficha`";
  - creación del `proposal.md`: control de alcance contra `- no incluye:` con las tres opciones y lo que hace cada una;
  - "Artifact Creation Guidelines" de `design.md`: subsección "Datos personales" en la `## Security Layer` cuando el change toca un dato `personal`.

  Texto agregado idéntico en los dos archivos y sin IDs del design. Evidencia: `diff` de las líneas agregadas entre los dos archivos, sin diferencias, y `Select-String -Pattern '\bD\d+\b'` sin resultados en ambos.
- [x] 2.2 Commit aparte con `skills/ficha/`, `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: `feat: skill /ficha y avisos de ficha y alcance en el propose`, con un único bloque final de trailers que incluya `Spec-ID: ficha-del-proyecto`.

## 3. CLAUDE.md global

- [x] 3.1 En `.claude/CLAUDE.md`, agregar la sección `## Ficha del proyecto` después de `## Arquitectura del proyecto`, con el contenido de design D6 y el formato y ejemplos de D1. Evidencia: el bloque de la sección pegado en el resumen.
- [x] 3.2 En `.claude/CLAUDE.md`, en "Capa de Seguridad por Tipo de Proyecto", agregar `### Datos personales (cualquier tipo de proyecto)` después de `### tooling / config`, con los cinco controles y la línea final de design D4. Evidencia: `Select-String -Path .claude/CLAUDE.md -Pattern "### Datos personales" -Context 0,7`.
- [x] 3.3 En `.claude/CLAUDE.md`, agregar al final de la regla 4 la oración literal de design D5. Evidencia: `Select-String -Path .claude/CLAUDE.md -SimpleMatch -Pattern "si necesitás uno que no está en ninguno, frená y preguntá"`.
- [x] 3.4 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users` y que no cita IDs del design (`\bD\d+\b`), y pegar la salida.
- [x] 3.5 Commit aparte, solo con `.claude/CLAUDE.md`: `feat: ficha del proyecto y datos personales en CLAUDE.md`. El cuerpo describe el impacto: aplica a todos los proyectos, sin ficha solo hay un aviso en el propose, la Capa de Seguridad suma los datos personales y la regla 4 suma el stack. Un único bloque final de trailers con `Spec-ID: ficha-del-proyecto`.

## 4. Plantillas y documentación

- [x] 4.1 Agregar al final de la regla 4 la oración literal de design D5 en `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`. Evidencia: `Select-String -Path templates/*/* -SimpleMatch -Pattern "si necesitás uno que no está en ninguno, frená y preguntá"`, con 4 coincidencias.
- [x] 4.2 En `README.md` y `docs/workflow.md`, agregar una línea que explique la ficha del proyecto y la skill `/ficha`. Evidencia: el diff.
- [x] 4.3 Commit aparte: `docs: regla 4 con el stack y ficha del proyecto en las guías`, con un único bloque final de trailers que incluya `Spec-ID: ficha-del-proyecto`.

## 5. Instalación (para que aplique en otros repos)

- [x] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada `.claude/commands/opsx/*.md`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D7). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master" o "con cambios locales".
- [x] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` (incluida `skills/ficha/`) y **todos** los comandos de `.claude/commands/opsx/`. Copiar `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales, incluido `~/.claude/skills/ficha/SKILL.md`.
- [x] 5.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas ficha-del-proyecto`) y pushear. Verificar que el espejo contiene "Ficha del proyecto". Si el push falla por la cuenta de GitHub, avisar sin forzar.

## 6. Verificación con Claude (no la ejecuta el Agente)

- [x] 6.1 S01, S02, S12, S13, S16 y S17 por revisión de los archivos y con los `Select-String` del Test Plan.
- [x] 6.2 S03 a S08 y S18 en sesiones **nuevas** de Claude Code en los repos descartables G, H e I (design, Test Plan).
- [x] 6.3 S09 a S11, S14 y S15 en sesiones **nuevas** de Claude Code en copias limpias del repo descartable I.
- [x] 6.4 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[ficha-del-proyecto] Ficha del proyecto: alcance V1, datos y stack` desde `change/ficha-del-proyecto`, con `Closes #28`.
- `/opsx:verify ficha-del-proyecto` antes del merge y `/opsx:archive` después.
- Después del archive: proponer `puerta-de-integracion` (issue #29), que usa `## Datos`.
- Fuera de este repo: correr `/ficha` en `toyota-yacopini-web` (maneja leads con datos personales).
