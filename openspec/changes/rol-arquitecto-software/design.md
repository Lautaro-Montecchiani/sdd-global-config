## Context

- Motivación en `proposal.md`. El 09/11/2026 el usuario pidió que Claude sea su arquitecto de software y eligió sumar cuatro responsabilidades (ADRs, atributos de calidad, visión con hoja de ruta y revisión de impacto), guardar la fuente en el repo del proyecto con un resumen en el vault, y mantener todas las reglas vigentes.
- Hoy el `CLAUDE.md` global define a Claude como arquitecto del workflow (propose, verify, archive) y la regla 1 le prohíbe editar archivos del proyecto, salvo artefactos OpenSpec y configuración global. La única excepción en la práctica es `srs-generate`, que escribe `docs/srs.md`.
- Lo que ya existe de arquitectura: `## Arquitectura` en `openspec/config.yaml` (carpetas, `no importa:`, `nivel`, `tamaño`), la escalera de niveles con recetas, `## Recomendación de arquitectura` y `## Ubicación de archivos` en el `design.md`, `/arquitectura` para diagnosticar, y la tabla de arquitectura del verify.
- La ficha (`/ficha`) declara alcance, datos y stack. No hay atributos de calidad: la seguridad tiene su propia capa.
- El vault guarda `context.md`, `decisions\`, `archive\` y `apply\` por proyecto. En `D:\Proyectos\sdd-vault` todavía no hay carpeta para `sdd-global-config`.
- El change `clasificacion-odd-sdd` (#32) está en pausa y toca `.claude/CLAUDE.md` y `openspec/config.yaml`.

## Goals / Non-Goals

**Goals:**
- Que cada proyecto tenga sus decisiones de arquitectura duraderas registradas (ADRs), su visión y su deuda técnica priorizada, en el repo y resumidas en el vault.
- Que todo propose mire el impacto del change sobre el sistema completo y sobre los atributos de calidad que importan.
- Que el rol se sume sin cambiar ninguna regla vigente: Claude sigue sin escribir archivos del proyecto y el merge sigue con las mismas condiciones.

**Non-Goals:**
- Un comando nuevo de revisión de arquitectura: alcanza con el propose y `/arquitectura`.
- CRITICAL nuevos o cambios en la puerta de integración.
- Migrar los proyectos existentes: cada uno crea su visión en su próximo change.
- Cambiar las plantillas del Agente.

## Decisions

**D1. El rol se suma, no reemplaza.** Sección nueva `## Rol de arquitecto de software` en el `CLAUDE.md` global, justo después de `## Roles Claude / Agente (OpenSpec)`. En la tabla de roles, la fila "Crear artefactos del change" pasa a "Crear artefactos del change y revisar la arquitectura del sistema". La sección dice: las cuatro responsabilidades (D2 a D5); que el rol se suma a las reglas vigentes sin cambiarlas; que Claude no escribe código ni archivos del proyecto, así que los documentos de arquitectura del repo los escribe el Agente desde el `design.md`; y que toda decisión se propone con alternativas y la aprueba el usuario al aprobar el change.
- Alternativa descartada: que Claude escriba `docs/adr/` y `docs/arquitectura/` directamente, como hace `srs-generate` con `docs/srs.md`. Eso agregaría una excepción a la regla 1, y el usuario pidió no cambiar las reglas. Además, que lo escriba el Agente deja los documentos en el mismo PR que el código y el verify los controla.

**D2. Revisión de impacto.** Todo `design.md` nuevo lleva `## Impacto en el sistema` antes de `## Ubicación de archivos` (y antes de `## Recomendación de arquitectura` si existe), con cuatro partes en negrita:
- **Componentes afectados:** módulos, integraciones, datos u otros proyectos fuera de los archivos del change. Si no hay, "ninguno fuera del change".
- **Atributos de calidad:** ver D4.
- **Decisiones de arquitectura:** "ADR nuevo: NNNN", "Reemplaza a: NNNN" o "ninguna".
- **Deuda técnica:** "agrega: …", "paga: …", "descubre: …" o "ninguna".
Claude la completa leyendo el código que toca el change y sus usos, `docs/arquitectura/vision.md` si existe y el resumen del vault.

**D3. ADRs.** Se escribe un ADR cuando el change toma una decisión que dura más que él. Los criterios son una lista cerrada: elige o cambia una tecnología de `## Stack`; cambia el `nivel` de `## Arquitectura` (incluido "Aplicar en este change" de una recomendación); suma o cambia una integración externa; adopta un patrón transversal (manejo de errores, logging, autenticación, acceso a datos); o resuelve un compromiso entre dos atributos de calidad. Si ninguno se cumple, no hay ADR.
- Formato (sección `## ADR` del `design.md`, con el texto completo):
  - `# NNNN. <título>`
  - `Estado: aceptada` · `Fecha: AAAA-MM-DD` · `Change: <nombre>` · `Reemplaza a: NNNN` (solo si corresponde)
  - `## Contexto`, `## Alternativas` (cada una con por qué se descartó), `## Decisión`, `## Consecuencias` (positivas y negativas)
- Número: el siguiente al mayor de `docs/adr/` del proyecto, o `0001`. Slug en kebab-case del título.
- Estado `aceptada` desde el propose: el usuario aprueba el ADR al aprobar el change. Si el change se abandona, el archivo nunca llega a `master`.
- Tarea para el Agente: "Crear `docs/adr/NNNN-<slug>.md` con el texto de `## ADR` del design". Si reemplaza a otro: "Cambiar `Estado:` de `docs/adr/<anterior>` a `reemplazada por NNNN`".
- Alternativa descartada: ADRs en el vault. El vault no viaja con el repo ni con el PR, y un dev sin vault no los vería.

**D4. Atributos de calidad.** La ficha suma `## Calidad`, después de `## Stack`:
- Formato: `- <atributo>: <objetivo> | <alta|media|baja>`. Atributos admitidos: `rendimiento`, `disponibilidad`, `escalabilidad`, `costo` y `mantenibilidad`. Solo se escriben los que importan. La seguridad no va acá porque tiene su capa.
- `/ficha` la trata como sexta parte: pregunta qué atributos importan, con objetivo y prioridad, y ofrece "Ninguno por ahora", que no escribe nada. Las mismas reglas de siempre: no reescribe lo que existe y escribe al final del `context:`.
- En el propose, **Atributos de calidad** de D2 tiene una línea por cada atributo de prioridad `alta`: "sin efecto", o el efecto con `— Verificación: <cómo>` (mismo formato que la Security Layer). Los de prioridad `media` o `baja` se mencionan solo si el change los afecta. Sin `## Calidad`: "sin `## Calidad` declarada" y aviso en el resumen final, junto al de la ficha.

**D5. Visión y hoja de ruta.** Documento vivo `docs/arquitectura/vision.md` en el repo de cada proyecto:
- `## Propósito`: una o dos líneas y la referencia a la descripción y a los objetivos de `openspec/config.yaml` (no los copia).
- `## Contexto e integraciones`: actores y sistemas externos con los que habla el proyecto. Admite un diagrama Mermaid, pero no lo exige.
- `## Componentes`: cada carpeta de `## Arquitectura` con su responsabilidad, en más detalle que el `config.yaml`.
- `## Decisiones vigentes`: `- [NNNN. <título>](../adr/NNNN-<slug>.md)` por cada ADR aceptado.
- `## Hoja de ruta`: `- [alta|media|baja] <deuda> — origen: <change o ADR> — propuesta: <cómo pagarla>`, ordenada por prioridad.
- Si no existe, el propose pone su contenido inicial en una sección `## Visión inicial` del `design.md` (inferido del repo, de la ficha y de `docs/adr/`) y agrega la tarea de crearlo.
- Si D2 nombra un ADR nuevo, componentes nuevos o deuda que se agrega o se paga, el propose agrega la tarea de actualizarlo, diciendo qué líneas cambian.
- Alternativa descartada: guardar la visión en `openspec/config.yaml`. Tiene un límite de 40 KB, y se inyecta en cada instrucción de OpenSpec.

**D6. Resumen en el vault.** En el paso 5.5 del archive, después de `_index.md`, Claude reescribe `$vault\projects\$p\arquitectura.md`:
- frontmatter `project`, `updated`;
- `## Nivel` (`nivel` de `## Arquitectura` o "sin evaluar"), `## Atributos de calidad` (los de `## Calidad` o "sin declarar"), `## Decisiones vigentes` (número y título de los ADRs con `Estado: aceptada` en `docs/adr/`) y `## Deuda prioritaria` (hasta 3 ítems de `## Hoja de ruta`, primero los de `alta`), y `Documento completo: docs/arquitectura/vision.md en el repo`.
- Va en el mismo commit del vault del archive. Sin código ni valores sensibles. Si el proyecto todavía no tiene `vision.md` ni ADRs, igual se escribe con lo que hay.
- Lectura: el paso 3 de "Al iniciar cada sesión" del `CLAUDE.md` y el inicio de `/opsx:explore` lo leen si existe. `/opsx:propose` también, en su paso 0.
- La tabla "Cuándo actuar" y la "Estructura del vault" suman `arquitectura.md`.

**D7. Controles del verify.** Tabla nueva "Arquitectura de software" en el reporte, después de la de arquitectura:

| Control | Resultado | Severidad |
|---|---|---|
| Impacto en el sistema | presente / falta | SUGGESTION si falta |
| Atributos de calidad | aplica cada `— Verificación:` | WARNING por cada una que no se cumple; WARNING "atributo sin verificación declarada" |
| ADR | archivo en `docs/adr/` con el título y la `## Decisión` del design | WARNING si falta o no coincide |
| Visión | `docs/arquitectura/vision.md` creado o actualizado si el design lo pide | WARNING si el diff no lo toca |

Ninguno da CRITICAL ni entra en la puerta de integración. Si la tarea del Agente quedó `[x]` sin respaldo en el diff, ya da CRITICAL por la regla vigente de evidencia: este control no lo duplica.

**D8. Skills y comandos.** Los cambios de D2 a D7 se escriben en la skill y en su comando con el mismo texto, como en los changes anteriores:
- `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: paso 0 lee `arquitectura.md` del vault y `docs/arquitectura/vision.md`; guías del `design.md` para `## Impacto en el sistema`, `## ADR` y `## Visión inicial`; aviso de `## Calidad` en el resumen.
- `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: D7, con sus líneas en "Issues by Priority".
- `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`: D6.
- `skills/openspec-explore/SKILL.md` y `.claude/commands/opsx/explore.md`: leer `arquitectura.md` y `docs/arquitectura/vision.md` si existen.
- `skills/ficha/SKILL.md`: D4.

**D9. `openspec/config.yaml` de este repo.**
- Glosario: "ADR: registro de una decisión de arquitectura que dura más que un change, en `docs/adr/NNNN-<slug>.md` del proyecto"; "Atributo de calidad: objetivo de rendimiento, disponibilidad, escalabilidad, costo o mantenibilidad, con prioridad, en `## Calidad`"; "Visión: documento vivo `docs/arquitectura/vision.md` con componentes, decisiones vigentes y hoja de ruta"; "Revisión de impacto: sección `## Impacto en el sistema` del `design.md`".
- Actores: "Claude (arquitecto): explora, propone…" pasa a "Claude (arquitecto de software): explora, propone, verifica y archiva changes, y lleva los ADRs, la visión y la revisión de impacto; no escribe código de producción".
- Objetivo nuevo: "OBJ-06: decisiones de arquitectura, atributos de calidad y deuda técnica registrados y revisados en cada change".

**D10. Instalación.** Igual que en los changes anteriores: comparar cada archivo instalado con `git show master:<ruta>` ignorando el fin de línea y frenar ante cambios locales; copiar a `~/.claude` el `CLAUDE.md`, todas las carpetas de `skills/` y todos los comandos de `.claude/commands/opsx/`; sincronizar el espejo `_global/reglas-globales.md`; verificar con hashes.

**D11. Commits.** Cuatro commits de código, separados de `openspec/` salvo el `config.yaml`, cada uno con un único bloque final de trailers con `Spec-ID: rol-arquitecto-software`:
1. `.claude/CLAUDE.md` y `openspec/config.yaml`, con la descripción del impacto;
2. propose, verify, archive y explore (skills y comandos);
3. `skills/ficha/SKILL.md`;
4. `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`.

## Impacto en el sistema

**Componentes afectados:** todos los proyectos que usan el workflow, desde su próximo propose (sección nueva en el `design.md`, posibles tareas de ADR y visión). El vault suma un archivo por proyecto. Las plantillas del Agente no cambian.

**Atributos de calidad:** sin `## Calidad` declarada en este repo. Mantenibilidad del workflow: suma texto a cuatro skills y al `CLAUDE.md`, que ya son largos (verify unas 5.200 palabras, `CLAUDE.md` unas 4.200).

**Decisiones de arquitectura:** ninguna con ADR en este repo: todavía no tiene `docs/adr/`. La decisión de que el Agente escriba los documentos de arquitectura queda en D1 y en el `CLAUDE.md`.

**Deuda técnica:** agrega más texto duplicado entre skills y comandos (la misma deuda que ya señala el change pendiente de fuente única de plantillas).

## Ubicación de archivos

No hay archivos nuevos en este repo: todos los cambios son a archivos existentes.

| Archivo nuevo | Carpeta declarada |
|---|---|
| (ninguno en este repo) | — |

En cada proyecto, los archivos nuevos que crea el Agente (`docs/adr/NNNN-<slug>.md` y `docs/arquitectura/vision.md`) van en `docs/`, que está permitida sin declararla. Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo, con un vault falso.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, las skills ni los comandos. — Verificación: revisión del diff y un script en archivo que busca `C:\Users` en los archivos modificados, sin resultados.
- Los ADRs, la visión y el resumen del vault no copian código, credenciales ni datos personales: las skills lo dicen explícitamente. — Verificación: revisión del diff: la oración está en propose (ADR y visión) y en archive (resumen); y S21.
- Claude no escribe archivos del proyecto: ADR y visión quedan como tareas del Agente. — Verificación: revisión del diff: las skills dicen "tarea para el Agente" y no "escribir"; y S05.
- Commit aparte del `CLAUDE.md` con la descripción del impacto, e instalación con chequeo previo de cambios locales (D10). — Verificación: tareas 1.4 y 6.1.

## Impacto en proyectos existentes

- **Sin migración obligatoria:** los changes en curso no cambian. El verify de un change con `design.md` anterior solo da una SUGGESTION por la falta de `## Impacto en el sistema`.
- **Próximo propose de cada proyecto:** suma `## Impacto en el sistema` y, si no hay `docs/arquitectura/vision.md`, la `## Visión inicial` con su tarea. Es un archivo más en ese PR.
- **Ficha:** `/ficha` va a preguntar por `## Calidad` en proyectos que ya tenían la ficha completa. Se puede responder "Ninguno por ahora".
- **Vault:** suma `projects/<proyecto>/arquitectura.md`, que escribe el archive.
- **Plantillas del Agente:** no hace falta volver a copiarlas.

## Risks / Trade-offs

- [Más ceremonia en cada propose, justo lo que el change `clasificacion-odd-sdd` intenta bajar] → Las cuatro partes de `## Impacto en el sistema` aceptan "ninguno" en una línea, y ADR y visión solo aparecen cuando hay algo que decir.
- [La visión se desactualiza si un change no la toca] → El propose agrega la tarea cada vez que D2 nombra algo que la afecta, y el verify da WARNING si no se hizo.
- [Criterios de ADR interpretables] → Lista cerrada de cinco criterios. Ante la duda, Claude pregunta al usuario en el propose.
- [Conflicto con el change en pausa #32] → Los dos tocan `.claude/CLAUDE.md` y `openspec/config.yaml` en secciones distintas. El segundo en mergearse resuelve el conflicto y vuelve a correr la instalación.
- [Skills más largas] → Se suma la menor cantidad de texto posible y la deuda queda anotada en D2 de este design.

## Migration Plan

Primero se edita y se instala (D10). Los proyectos se adaptan solos en su próximo propose. Rollback: revertir el PR, reinstalar desde `master` y volver a sincronizar el espejo. Los `docs/adr/` y `vision.md` que ya hayan creado los proyectos quedan como documentación, sin efecto en el workflow.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude. Todo el plan es manual. No hay tests de caracterización porque no hay código. Un test automático futuro llevaría el marcador `test-plan: rol-arquitecto-software/<ID>`.

Las pruebas usan sesiones nuevas de `claude -p --permission-mode acceptEdits --allowedTools` acotados (lectura, edición, `git` y `openspec`), de a 3 como máximo, con un vault falso. Las que necesitan respuestas humanas las hace el usuario en una sesión interactiva.

Fixtures:
- **Repo A** (`$env:TEMP\arq-prueba-a`): `project_type: backend-api`; `## Stack` con `base-de-datos: SQLite`; `## Calidad` con `- rendimiento: respuesta de la API < 500 ms p95 | alta`; `## Arquitectura` con `src/api/`, `src/services/` y `src/db/`; `src/services/clima.py` que llama a una API externa y lo usan `src/api/pronostico.py` y `src/api/alertas.py`; `docs/adr/0001-*.md` y `docs/adr/0002-*.md`; sin `docs/arquitectura/vision.md`.
- **Repo B** (`$env:TEMP\arq-prueba-b`): `project_type: scripts`, sin `## Calidad` y con `## Alcance`, `## Datos` y `## Stack`.
- **Vault falso V** (`$env:TEMP\arq-prueba-vault`): repo git con `projects/arq-prueba-a/context.md` y `_index.md`, y un remote local bare.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Rol / Sección presente | manual: `Select-String` de "## Rol de arquitecto de software" en `.claude/CLAUDE.md` y lectura de las cuatro responsabilidades y de las dos oraciones de reglas | `.claude/CLAUDE.md` |
| S02 | Rol / Reglas vigentes intactas | manual: `git diff master -- .claude/CLAUDE.md` sin líneas borradas ni modificadas en reglas globales, reglas de ejecución y puerta de integración (solo líneas agregadas o la fila de la tabla de roles) | `.claude/CLAUDE.md` |
| S03 | Impacto / Change que toca una integración | manual: en A, propose de "agregar caché a `src/services/clima.py`"; **Componentes afectados** nombra `pronostico` y `alertas` | repo A |
| S04 | Impacto / Change chico sin impacto | manual: en B, propose de "corregir el texto de ayuda del script"; las cuatro partes dicen "ninguno" o "ninguna" | repo B |
| S05 | ADR / Cambio de base de datos | manual: en A, propose de "pasar de SQLite a PostgreSQL"; `## ADR` con `# 0003.` y las cuatro secciones, y tarea del Agente para `docs/adr/0003-<slug>.md`; Claude no creó el archivo | repo A |
| S06 | ADR / Recomendación aplicada | manual (usuario): en A, propose que dispare una recomendación de nivel y elegir "Aplicar en este change"; el design también tiene `## ADR` | repo A |
| S07 | ADR / Decisión local | manual: en B, el design de S04 no tiene `## ADR` | repo B |
| S08 | Calidad / Atributo de prioridad alta afectado | manual: el design de S03 tiene una línea de rendimiento con `— Verificación:` | repo A |
| S09 | Calidad / Proyecto sin calidad declarada | manual: el design de S04 dice "sin `## Calidad` declarada" y el resumen sugiere `/ficha` | repo B |
| S10 | Visión / Proyecto sin visión | manual: el design de S03 tiene `## Visión inicial` y una tarea para crear `docs/arquitectura/vision.md` | repo A |
| S11 | Visión / Change que paga deuda | manual: en A con una `vision.md` que tiene una deuda "sin timeout en clima", propose de "agregar timeout a clima"; tarea para quitarla de `## Hoja de ruta` | repo A |
| S12 | Vault / Archive con ADR nuevo | manual: en A, con un change de prueba que agregó `docs/adr/0003-postgresql.md`, mergeado, `/opsx:archive`; `arquitectura.md` de V lista `0003` y el commit del vault lo incluye | vault V |
| S13 | Vault / Inicio de sesión | manual: sesión nueva en A lee `context.md` y `arquitectura.md` de V | repo A |
| S14 | Verify / ADR que no llegó al repo | manual: en A, rama con un design con `## ADR` y un diff sin `docs/adr/`; `/opsx:verify` da WARNING de ADR y ningún CRITICAL por ese control | repo A |
| S15 | Verify / Atributo de calidad que no se cumple | manual: en A, rama cuya verificación de rendimiento (revisión del diff) no se cumple; WARNING de rendimiento | repo A |
| S16 | Verify / Design anterior al change | manual: en A, rama con un design sin `## Impacto en el sistema`; solo una SUGGESTION por eso | repo A |
| S17 | Ficha / Formato: Alcance con versión | manual: regresión, el formato de `## Alcance` en `.claude/CLAUDE.md` y `skills/ficha/SKILL.md` no cambió | `skills/ficha/SKILL.md` |
| S18 | Ficha / Formato: Dato personal, Stack sin relleno, Atributo con prioridad y Calidad sin relleno | manual: `skills/ficha/SKILL.md` y `.claude/CLAUDE.md` documentan `## Calidad` con su formato, los cinco atributos y "solo se escriben los que importan"; `## Datos` y `## Stack` sin cambios | `skills/ficha/SKILL.md`, `.claude/CLAUDE.md` |
| S19 | Ficha / Proyecto sin ficha, Stack escrito a mano y Ficha completa | manual: regresión en B y en una copia de A con las seis partes: `/ficha` informa ficha completa sin escribir | repo A, repo B |
| S20 | Ficha / Falta solo la calidad | manual (usuario): `/ficha` en B, declarar rendimiento con prioridad alta; escribe `## Calidad` al final del `context:` | repo B |
| S21 | Propose avisa si falta la ficha / Proyecto sin ficha y sin calidad | manual: resumen de S04 dice que falta `## Calidad` y sugiere `/ficha`; regresión del aviso de `## Datos` y `## Stack` en una copia de B sin ellos; los documentos generados en S03 a S12 no tienen código ni valores sensibles | repo B |

## Open Questions

Ninguna. Decisiones del usuario del 09/11/2026: las cuatro responsabilidades, fuente en el repo con resumen en el vault, y ninguna regla vigente cambia. Decisión de diseño a confirmar al revisar este change: que el Agente escriba los ADRs y la visión (D1).
