# Workflow SDD Híbrido — Contexto global para el Agente

## Reglas globales (fuente de verdad)

Antes de trabajar en cualquier proyecto, leé las reglas completas del workflow SDD en el vault de Obsidian:

- `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` (fallback: `C:\TPA\_global\reglas-globales.md`)

Ese archivo define: roles (Claude arquitecto / Agente constructor), flujo OpenSpec (propose → apply → verify → archive), formato de commits (`{type}: {desc}` + trailer `Spec-ID: {nombre-change}`), branches `change/{nombre}`, reglas de seguridad universales y por tipo de proyecto, y la capa de persistencia del vault.

## Reglas de ejecución (obligatorias)

1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás.
2. **Test primero = falla primero:** si la tarea dice "test primero", corré el test contra el código actual antes de tocar la implementación: tiene que fallar. Si pasa de entrada, el test está mal: frená y avisá.
3. **No debilitar tests:** no borres ni aflojes asserts, no conviertas fallas en `skip`, no captures `AssertionError`. Un `skip` solo vale por falta de entorno (`ImportError`, sin conexión), con el motivo escrito.
4. **No inventar:** selectores, rutas, endpoints, nombres de campos y APIs externas salen del `design.md` del change o de lo que confirme el usuario. Si falta algo, frená y preguntá; nunca escribas "resuelto" sin haberlo verificado.
5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte.
6. **Sin comentarios de razonamiento:** nada de monólogo en el código ("wait...", "I will...", dudas). Solo comentarios que expliquen el código.
7. **Resumen final con evidencia:** al terminar el apply, listá las tareas marcadas, cada una con su evidencia (salida del test en rojo y en verde, o salida de consola o captura para tareas manuales), y las que quedaron abiertas con el motivo. Además de incluir este resumen en el output del chat, guardá una copia completa en el vault: `$env:OBSIDIAN_VAULT\projects\<proyecto>\apply\AAAA-MM-DD-<change>.md` (fallback `C:\TPA`), con `<proyecto>` = nombre de la carpeta del repo. La copia lleva frontmatter con `project`, `change`, `date` y la rama con su commit (`git log --oneline -3`), sección `## Tareas marcadas` con cada ID y su evidencia, y sección `## Tareas abiertas` con el motivo. Salidas sensibles, credenciales o datos personales se reemplazan por `<DATO OMITIDO>`. Solo escribí el archivo: NO hagas commit ni push de él (la carpeta está en el `.gitignore` del vault). Si el apply se repite el mismo día, agregá una sección al final en vez de sobrescribirlo. Si el vault no existe en la máquina, anotalo en el resumen del chat y continuá. Claude contrasta cada `[x]` con el diff y con esta evidencia en `/opsx:verify`.

## Memoria por proyecto

Cada proyecto tiene contexto histórico en el vault: `$env:OBSIDIAN_VAULT\projects\{nombre-proyecto}\` — `context.md` (estado actual), `decisions\` (decisiones por change) y `archive\` (changes completados). Leé `context.md` al empezar a trabajar en un proyecto.

## Reglas mínimas (si no podés leer el vault)

- Nunca commitear `.env`, `*.key`, `*.pem` ni credenciales; revisar `git diff --staged` antes de cada commit.
- Nunca hardcodear secrets — todo a `.env` excluido del repo.
- Nunca trabajar directo en `main`/`master` para changes con spec.
- No marcar `[x]` tareas de tests si fallan; marcador `test-plan: <change>/<ID>`; `Cxx` en verde antes de tocar código viejo.
