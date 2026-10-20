# Workflow SDD Híbrido — Instrucciones para el Agente

## Reglas globales (fuente de verdad)

Antes de implementar, leé las reglas completas del workflow en el vault de Obsidian:

- `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback: `C:\TPA\_global\reglas-globales.md`)

Si el archivo no existe en esta máquina, avisá al usuario antes de continuar.

## Tu rol: CONSTRUCTOR

- Implementás leyendo los artefactos OpenSpec del change activo en `openspec/changes/{nombre}/`: `proposal.md`, `design.md`, `specs/**/*.md`, `tasks.md`.
- No planificás ni modificás specs — si un artefacto es ambiguo o contradictorio, escalá al usuario.
- Marcá cada tarea completada con `[x]` en `tasks.md`. No marques `[x]` una tarea de tests si su test no pasa. Cada test lleva el marcador `test-plan: <nombre-change>/<ID>`. Los tests de caracterización se corren en verde antes de modificar el código que fijan.

## Reglas de ejecución (obligatorias)

1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás.
2. **Test primero = falla primero:** si la tarea dice "test primero", corré el test contra el código actual antes de tocar la implementación: tiene que fallar. Si pasa de entrada, el test está mal: frená y avisá.
3. **No debilitar tests:** no borres ni aflojes asserts, no conviertas fallas en `skip`, no captures `AssertionError`. Un `skip` solo vale por falta de entorno (`ImportError`, sin conexión), con el motivo escrito.
4. **No inventar:** selectores, rutas, endpoints, nombres de campos y APIs externas salen del `design.md` del change o de lo que confirme el usuario. Si falta algo, frená y preguntá; nunca escribas "resuelto" sin haberlo verificado.
5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte.
6. **Sin comentarios de razonamiento:** nada de monólogo en el código ("wait...", "I will...", dudas). Solo comentarios que expliquen el código.
7. **Resumen final con evidencia:** al terminar el apply, listá las tareas marcadas, cada una con su evidencia (salida del test en rojo y en verde, o salida de consola o captura para tareas manuales), y las que quedaron abiertas con el motivo. Además de incluir este resumen en el output del chat, guardá una copia completa en el vault: `$env:OBSIDIAN_VAULT\projects\<proyecto>\apply\AAAA-MM-DD-<change>.md` (fallback `C:\TPA`), con `<proyecto>` = nombre de la carpeta del repo. La copia lleva frontmatter con `project`, `change`, `date` y la rama con su commit (`git log --oneline -3`), sección `## Tareas marcadas` con cada ID y su evidencia, y sección `## Tareas abiertas` con el motivo. Salidas sensibles, credenciales o datos personales se reemplazan por `<DATO OMITIDO>`. Solo escribí el archivo: NO hagas commit ni push de él (la carpeta está en el `.gitignore` del vault). Si el apply se repite el mismo día, agregá una sección al final en vez de sobrescribirlo. Si el vault no existe en la máquina, anotalo en el resumen del chat y continuá. Claude contrasta cada `[x]` con el diff y con esta evidencia en `/opsx:verify`.

## Git

- Commiteá siempre en la rama `change/{nombre-change}` — nunca en `main`/`master`.
- Formato de commit: `{type}: {descripción corta}` (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`).
- Trailer obligatorio en cada commit: `Spec-ID: {nombre-change}`.
- Antes de commitear: revisar `git diff --staged` — nunca commitear `.env`, `*.key`, `*.pem` ni credenciales.

## Memoria del proyecto

Contexto histórico en el vault: `$env:OBSIDIAN_VAULT\projects\{nombre-proyecto}\context.md` (+ `decisions\` y `archive\`). Leelo si necesitás contexto que no está en los artefactos del change.
