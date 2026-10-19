## Context

La regla 7 de ejecución del Agente pide un resumen final con evidencia, pero solo en el chat. `.claude/CLAUDE.md` dice que el verify contrasta cada `[x]` con esa evidencia; el comando `.claude/commands/opsx/verify.md` y `skills/openspec-verify-change/SKILL.md` no lo hacen hoy (no mencionan el resumen ni la evidencia). La skill de apply que corre el Agente es la que genera `openspec init` en cada proyecto, que este repo no controla; lo que sí llega al Agente son las reglas de las cuatro plantillas. Por eso la instrucción vive en la regla 7 y no en una skill.

El vault ya ignora `projects/*/apply/` (commit `chore: vault — ignorar projects/*/apply/`).

## Goals / Non-Goals

**Goals:**
- Que el Agente deje una copia completa del resumen en un lugar fijo y legible por Claude.
- Que el verify la lea y contraste la evidencia, sin pegarla en el chat.
- Que la copia no salga de la máquina.

**Non-Goals:**
- Reemplazar el resumen en el output del Agente (se mantiene).
- Compartir las copias entre máquinas.
- Cambiar las skills genéricas que genera `openspec init`.
- Actualizar las copias de plantillas ya instaladas en otros proyectos (queda en el follow-up).

## Decisions

**D1. Ruta fija:** `$env:OBSIDIAN_VAULT\projects\<proyecto>\apply\AAAA-MM-DD-<change>.md` (fallback `C:\TPA`), con `<proyecto>` = nombre de la carpeta del repo. Un archivo por change; si el apply se repite el mismo día, el Agente agrega una sección al final en vez de pisar el archivo.

**D2. Contenido mínimo:** frontmatter con `project`, `change`, `date` y la rama con su commit (`git log --oneline -3`); sección `## Tareas marcadas` con cada ID y su evidencia (salida en rojo y en verde, o salida de consola o captura para tareas manuales); sección `## Tareas abiertas` con el motivo. Salidas sensibles se reemplazan por `<DATO OMITIDO>`.

**D3. El Agente solo escribe el archivo:** no hace commit ni push de él. El `.gitignore` del vault lo cubre como segunda barrera. Si el vault no existe en la máquina, lo anota en el resumen del output y sigue.

**D4. El verify lee y contrasta.** Pasos nuevos en `/opsx:verify` y en la skill: leer el archivo del change; por cada `[x]`, buscar su evidencia en el archivo y su respaldo en el diff. Un `[x]` sin evidencia o sin respaldo en el diff es CRITICAL; la ausencia del archivo es CRITICAL "sin resumen del apply". Si el usuario entrega la evidencia por otra vía, se anota y se acepta. El reporte cita la ruta y no pega el contenido. Se aplica a todos los changes con tareas `[x]`, tengan Test Plan o no.

**D5. Anuncio del handoff:** `/opsx:apply` y su skill agregan una línea: "El Agente deja una copia del resumen en `projects/<proyecto>/apply/` del vault; `/opsx:verify` la lee desde ahí". No cambia el comando de handoff.

**D6. Reglas y estructura:** la regla 7 del `CLAUDE.md` global y de las cuatro plantillas se amplía igual; la estructura del vault suma `apply\` (local, no versionada); la tabla "Cuándo actuar" indica que el Agente escribe `apply\` y `/opsx:verify` la lee. Orden ante un cambio de reglas: editar `.claude/CLAUDE.md`, instalar en `~/.claude`, sincronizar el espejo del vault y commitear en el repo.

**D7. Límite:** como las copias no están en git, el verify solo funciona en la máquina del apply. Se documenta en las guías.

## Security Layer

Proyecto `tooling`: los artefactos modificados son instrucciones para IA.
- La copia puede contener salidas de tests con datos reales: el Agente reemplaza datos personales y credenciales por `<DATO OMITIDO>`, no pega tokens ni contraseñas, y el vault la ignora en git.
- Ningún artefacto del change incluye rutas con el usuario local; las verificaciones usan un script en archivo.
- Los cambios al `CLAUDE.md` global, comandos y skills se commitean aparte, con la descripción del impacto, y se verifican con hash las copias instaladas.
- El reporte del verify cita la ruta de la copia y no pega su contenido.

## Risks / Trade-offs

- Un Agente que no cumpla la regla no deja el archivo: el verify lo marca CRITICAL y se pide la copia o la evidencia.
- El archivo lo escribe quien marca los `[x]`: por eso el verify también contrasta con el diff y, cuando puede, vuelve a correr los tests.
- Las plantillas ya instaladas en otros proyectos siguen con la regla 7 anterior hasta volver a copiarlas: hasta entonces hay que pedir la copia en el prompt.
- Sin copia en git, no hay verify desde otra máquina.

## Migration Plan

1. Actualizar el `CLAUDE.md` global, plantillas, comandos, skills y guías en este repo.
2. Instalar en `~/.claude` y sincronizar el espejo del vault.
3. Volver a copiar las plantillas por proyecto y `GEMINI.md` en cada máquina cuando se actualice cada proyecto.
4. Si algo falla, revertir el PR y borrar `projects/*/apply/` del vault.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Mismas reglas de ejecución / Reglas presentes en cada plantilla | manual: sin tests automáticos. Pasos: buscar "Evidencia antes de", "Test primero = falla primero" y "No debilitar tests" en las cuatro plantillas y pegar el conteo | plantillas |
| S02 | Mismas reglas de ejecución / Copia del resumen en el vault | manual: revisión de contenido. Pasos: buscar `apply/AAAA-MM-DD` en la regla 7 de las cuatro plantillas y del `CLAUDE.md` global; confirmar fecha, rama y commit, sin datos sensibles y sin commit ni push | plantillas, `.claude/CLAUDE.md` |
| S03 | El verify lee el resumen del apply / Resumen presente y consistente | manual: requiere un repo de prueba. Pasos: crear un change mínimo con una tarea `[x]`, dejar el archivo en `apply/` con su evidencia y correr `/opsx:verify`; confirmar que contrasta y cita la ruta | `.claude/commands/opsx/verify.md`, `skills/openspec-verify-change/SKILL.md` |
| S04 | El verify lee el resumen del apply / Tarea marcada sin evidencia | manual: mismo repo. Pasos: quitar del archivo la evidencia de una tarea y correr el verify; confirmar CRITICAL con el ID | ídem |
| S05 | El verify lee el resumen del apply / Resumen ausente | manual: mismo repo. Pasos: borrar el archivo y correr el verify; confirmar CRITICAL "sin resumen del apply" y la recomendación | ídem |
| S06 | El verify lee el resumen del apply / Vault inexistente | manual: mismo repo. Pasos: apuntar `OBSIDIAN_VAULT` a una carpeta que no existe y correr el verify; confirmar que lo anota y no inventa evidencia (si el fallback `C:\TPA` interviene, anotarlo) | ídem |
| S07 | El vault documenta la carpeta de resúmenes del apply / Carpeta documentada | manual: revisión de contenido. Pasos: buscar `apply/` y `.gitignore` en las tres guías | guías |
| S08 | El vault documenta la carpeta de resúmenes del apply / Estructura del vault en el CLAUDE.md | manual: revisión de contenido. Pasos: leer la estructura del vault del `CLAUDE.md` global y confirmar `apply\` | `.claude/CLAUDE.md` |

## Open Questions

Sin preguntas abiertas.
