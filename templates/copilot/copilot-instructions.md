<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->

# Workflow SDD Híbrido — Instrucciones para el Agente

## Reglas globales (fuente de verdad)

Antes de implementar, leé las reglas completas del workflow en el vault de Obsidian:

- `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (variable configurada una vez por máquina — ver `docs/modo-de-uso.md`)

Si el archivo no existe en esta máquina, avisá al usuario antes de continuar.

## Tu rol: CONSTRUCTOR

- Implementás leyendo los artefactos OpenSpec del change activo en `openspec/changes/{nombre}/`: `proposal.md`, `design.md`, `specs/**/*.md`, `tasks.md`.
- No planificás ni modificás specs — si un artefacto es ambiguo o contradictorio, escalá al usuario.
- Marcá cada tarea completada con `[x]` en `tasks.md`. No marques `[x]` una tarea de tests si su test no pasa. Cada test lleva el marcador `test-plan: <nombre-change>/<ID>`. Los tests de caracterización se corren en verde antes de modificar el código que fijan.

## Reglas de ejecución (obligatorias)

1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra. Esas tareas llevan la marca `(lo corre el usuario)` en `tasks.md`: aunque el usuario te pida correrla, queda `[ ]`; si corriste algo, lo pegás en el resumen como "evidencia para que confirme el usuario".
2. **Test primero = falla primero:** si la tarea dice "test primero", corré el test contra el código actual antes de tocar la implementación: tiene que fallar. Si pasa de entrada, el test está mal: frená y avisá.
3. **No debilitar tests:** no borres ni aflojes asserts, no conviertas fallas en `skip`, no captures `AssertionError`. Un `skip` solo vale por falta de entorno (`ImportError`, sin conexión), con el motivo escrito.
4. **No inventar:** selectores, rutas, endpoints, nombres de campos y APIs externas salen del `design.md` del change o de lo que confirme el usuario. Si falta algo, frená y preguntá; nunca escribas "resuelto" sin haberlo verificado. Las librerías y servicios nuevos salen de `## Stack` de `openspec/config.yaml` o del `design.md`; si necesitás uno que no está en ninguno, frená y preguntá.
5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
6. **Sin comentarios de razonamiento:** nada de monólogo en el código ("wait...", "I will...", dudas). Solo comentarios que expliquen el código.
7. **Resumen final con evidencia:** al terminar el apply, listá las tareas marcadas, cada una con su evidencia (salida del test en rojo y en verde, o salida de consola o captura para tareas manuales), y las que quedaron abiertas con el motivo. Además de incluir este resumen en el output del chat, guardá una copia completa en el vault: `$env:OBSIDIAN_VAULT\projects\<proyecto>\apply\AAAA-MM-DD-<change>.md`, con `<proyecto>` = nombre de la carpeta del repo. La copia lleva frontmatter con `project`, `change`, `date` y la rama con su commit (`git log --oneline -3`), sección `## Tareas marcadas` con cada ID y su evidencia, y sección `## Tareas abiertas` con el motivo. Salidas sensibles, credenciales o datos personales se reemplazan por `<DATO OMITIDO>`. Solo escribí el archivo: NO hagas commit ni push de él (la carpeta está en el `.gitignore` del vault). Si el apply se repite el mismo día, agregá una sección al final en vez de sobrescribirlo. Si el vault no existe en la máquina, anotalo en el resumen del chat y continuá. Claude contrasta cada `[x]` con el diff y con esta evidencia en `/opsx:verify`. En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault.
8. **Respetar la arquitectura:** los archivos nuevos van en la carpeta que indica el `design.md`, dentro de las declaradas en `## Arquitectura` de `openspec/config.yaml`. No crees carpetas fuera de las declaradas (sí subcarpetas de una declarada) ni agregues imports que una carpeta tiene prohibidos (`no importa:`). Si necesitás una carpeta que el design no prevé, frená y preguntá. Si generás desde una plantilla o un scaffolder, listá en el resumen del apply los archivos de ejemplo que trae y borrá los que el design no pide. Si el proyecto no declara `## Arquitectura`, seguí el design y avisalo en el resumen. Si el `design.md` trae `## Recomendación de arquitectura`, aplicá sus pautas para el Agente aunque el verify no pueda controlarlas.

## Handoff ODD

- Leé `docs/odd/<nombre>.md` y trabajá solo en el branch `odd/<nombre>` y en los archivos permitidos de "Alcance".
- No edites `openspec/` en un ODD: el cambio de spec, si lo hay, lo escribe y lo aplica Claude.
- Implementá tarea por tarea con las reglas de ejecución que ya tenés (evidencia antes de `[x]`, test primero = falla primero, no debilitar tests).
- Pegá la evidencia en `## Evidencia` del documento ODD: no escribas la nota `apply\` del vault, que es del flujo SDD.
- Si al implementar se cumple un criterio SDD (por ejemplo, necesitás una dependencia nueva o cambiar una spec vigente), **frená**, anotalo en `## Progreso` y avisá "escalar a SDD".
- Si necesitás tocar un archivo que no está en "Archivos permitidos" y no se cumple ningún criterio SDD (por ejemplo, un test o un dato de prueba), **frená**, anotalo en `## Progreso` y avisá "falta en el alcance": Claude amplía el documento y seguís.
- Commiteá con `{type}: {desc}` y el trailer `Spec-ID: odd-<nombre>`, y dejá `estado: listo-para-verify`.

## Git

- Commiteá siempre en la rama `change/{nombre-change}` — nunca en `main`/`master`.
- Formato de commit: `{type}: {descripción corta}` (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`).
- Trailer obligatorio en cada commit: `Spec-ID: {nombre-change}`.
- Antes de commitear: revisar `git diff --staged` — nunca commitear `.env`, `*.key`, `*.pem` ni credenciales.

## Memoria del proyecto

Contexto histórico en el vault: `$env:OBSIDIAN_VAULT\projects\{nombre-proyecto}\context.md` (+ `decisions\` y `archive\`). Leelo si necesitás contexto que no está en los artefactos del change.

## Propio del proyecto
<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->
