## Context

El workflow SDD Híbrido ya tiene una fuente de verdad viva para requirements: `openspec/specs/<capability>/spec.md`, actualizada por deltas en cada `/opsx:archive` (vía `openspec-sync-specs`). Lo que falta es una vista consolidada, en el formato que suelen pedir stakeholders no técnicos (SRS con estructura ISO/IEC/IEEE 29148: Introduction/Scope, Stakeholder Requirements, System/Functional Requirements, Non-Functional Requirements). Hoy esa vista, si existe, se redacta a mano y se desincroniza.

Los `spec.md` actuales no tienen una convención de metadata (no hay frontmatter ni marca de "funcional" vs. "no funcional" por requirement) — solo `# <capability> Specification`, `## Purpose` y `## Requirements` con bloques `### Requirement:` / `#### Scenario:`. La skill nueva tiene que trabajar con ese formato tal cual está, sin pedir que se lo cambie retroactivamente.

El usuario aportó como referencia un documento con dos partes: la Parte 1 es un SRS concreto de un proyecto ajeno ("Echalo Fideo", un marketplace de chefs a domicilio), con esqueleto de secciones 1 a 3.7 (Introducción, Información del Dominio del Problema, Necesidades de Negocio → Objetivos de Negocio, Actores y Procesos de Negocio con tablas, Casos de Uso con diagramas UML, Requisitos Funcionales agrupados por módulo, Requisitos No Funcionales con prioridad, Matriz de Trazabilidad). La Parte 2 es la guía abstracta de ISO/IEC/IEEE 29148:2011 (describe StRS/SyRS/SRS como conceptos, no es una plantilla rellenable). El usuario pidió que la salida sea "una copia exacta del documento" — se interpreta como el esqueleto de secciones y numeración de la Parte 1 (no su contenido específico de Chef/Plato, ni la Parte 2), más diagramas de flujo y UML.

## Goals / Non-Goals

**Goals:**
- Un SRS por proyecto que se pueda regenerar en cualquier momento sin quedar desincronizado, porque se arma leyendo las specs vigentes en vez de escribirse a mano.
- Que sirva también para proyectos sin historial de OpenSpec (terminados o legacy), con una primera pasada de bootstrap.
- Que cada requirement del SRS trace a su spec de origen.

**Non-Goals:**
- No define un mecanismo de aprobación/firma del SRS.
- No agrega metadata nueva a los `spec.md` existentes (frontmatter, tags de funcional/no-funcional) — la clasificación la hace la skill al leer, no se le pide al workflow de propose/archive que cambie.
- No migra el SRS a otro formato de salida (PDF, Google Docs) — el artefacto es un `.md` en el repo del proyecto, como el resto de la documentación del workflow.

## Decisions

### D1: El SRS se ensambla por agregación, no se redacta

La skill lee `openspec/specs/**/spec.md` del proyecto destino y arma cada sección del SRS citando la capability de origen, en vez de que alguien complete la plantilla a mano. Esto es la decisión central del change (ver la conversación previa en el vault de este proyecto).

Alternativas consideradas:
- SRS mantenido a mano siguiendo la plantilla del documento de referencia — descartada: es exactamente el problema que motiva el change (desincronización, doble fuente de verdad).
- Generarlo una sola vez y no volver a tocarlo — descartada: un SRS que no se regenera con cada change vuelve a quedar desactualizado.

**Decisión:** agregación desde `openspec/specs/`, regenerable on-demand.

### D2: Clasificación Funcional / No-Funcional por heurística de palabras clave, con revisión humana

Como los `spec.md` no distinguen funcional de no-funcional, la skill clasifica cada capability por defecto en la sección "3.5 Requisitos Funcionales", salvo que su `## Purpose` o el texto de sus requirements contenga palabras clave típicas de no-funcional (performance, seguridad/security, escalabilidad/scalability, disponibilidad/availability, usabilidad/usability, mantenibilidad/maintainability, compliance), en cuyo caso va a "3.6 Requisitos No Funcionales". El SRS generado deja visible la clasificación aplicada a cada capability para que se pueda corregir a mano.

Alternativas consideradas:
- Pedir que cada `spec.md` declare su categoría en frontmatter — descartada por ahora: cambiaría el formato de specs existentes en todos los proyectos, fuera del alcance de este change (ver Non-Goals).
- Que la skill pregunte interactivamente la categoría de cada capability en cada corrida — descartada: vuelve la regeneración pesada y no escala con muchas capabilities; la heurística con corrección visible es más liviana.

**Decisión:** heurística por palabras clave + clasificación visible y corregible.

### D3: Modo bootstrap para proyectos sin specs (o con specs incompletas)

Si `openspec/specs/` está vacío o cubre menos del proyecto real, la skill ofrece una pasada de bootstrap: lee código, README y configuración del proyecto (excluyendo lo listado en `.gitignore` y cualquier archivo con patrón de secreto — ver Security Layer) para completar un primer borrador, marcando cada sección como "inferido del código, sin spec formal — revisar" en vez de mezclarlo sin aviso con lo que sí viene de una spec confirmada.

Alternativas consideradas:
- No ofrecer bootstrap y exigir que el proyecto tenga specs de OpenSpec primero — descartada: deja afuera justo a los proyectos terminados/legacy que motivaron la pregunta original del usuario.
- Que el bootstrap genere requirements formales en `openspec/specs/` automáticamente — descartada: eso es responsabilidad de `/opsx:propose` con intervención humana, no de un generador de reportes; el bootstrap solo alimenta el SRS, no crea specs.

**Decisión:** bootstrap opcional, con las secciones inferidas marcadas explícitamente y sin escribir en `openspec/specs/`.

### D4: Regeneración con confirmación, nunca sobrescritura silenciosa

Si `docs/srs.md` ya existe, la skill compara el contenido derivado nuevo contra el archivo actual, muestra un resumen de qué secciones cambiarían y pide confirmación antes de escribir. Esto cubre el caso de un SRS que alguien retocó a mano después de generarlo (por ejemplo, para darle prosa más natural).

Alternativas consideradas:
- Sobrescribir siempre sin preguntar — descartada: destruye cualquier pasada editorial manual sin aviso, justo lo que se buscaba evitar al pasar a un modelo de agregación.
- Versionar automáticamente el archivo anterior (`srs.md.bak`) — descartada por ahora: el control de versiones ya lo da git; alcanza con mostrar el diff antes de confirmar.

**Decisión:** diff + confirmación antes de sobrescribir.

### D5: Enganche opcional en `/opsx:archive`, nunca obligatorio

`skills/openspec-archive-change/SKILL.md` suma un paso al final (después del resumen de archive): si `docs/srs.md` ya existe en el proyecto, ofrece regenerarlo invocando `srs-generate`. Si no existe, no se ofrece nada — no se fuerza la adopción de SRS en proyectos que nunca la pidieron.

Alternativas consideradas:
- Regenerar el SRS automáticamente en cada archive, sin preguntar — descartada: en proyectos con muchos changes seguidos sería ruidoso, y el archive de sdd-global-config no debería asumir que todo proyecto quiere un SRS.
- No engancharlo a nada, solo comando manual — descartada parcialmente: el usuario pidió explícitamente poder engancharlo al archive; se deja como oferta opt-in en vez de obligar a acordarse de correrlo aparte.

**Decisión:** paso opcional al final del archive, condicionado a que el SRS ya exista.

### D6: Estructura fija = esqueleto exacto de la Parte 1 del documento de referencia

`docs/srs.md` sigue siempre las mismas secciones y numeración: `1. Introducción` (1.1 Alcance, 1.2 Objetivos), `2. Información del Dominio del Problema` (2.1 Introducción al dominio, 2.2 Glosario de Términos), `3. Necesidades de Negocio` (3.1 Objetivos de negocio de clientes/usuarios, 3.2 Objetivos de Negocio, 3.3 Actores y Procesos de Negocio, 3.4 Casos de Uso, 3.5 Requisitos Funcionales, 3.6 Requisitos No Funcionales, 3.7 Matriz de Trazabilidad). Esto es igual para cualquier proyecto — lo que cambia por proyecto es el contenido de cada subsección (por ejemplo, 3.5 se agrupa por las capabilities reales del proyecto, nunca por los módulos del documento de ejemplo).

Alternativas consideradas:
- Estructura libre tipo ISO 29148 genérica (la del diseño original de este change, antes de revisar el documento con el usuario) — descartada: el usuario no conoce bien el formato SRS y pidió explícitamente que la salida sea reconocible contra el documento que ya tiene como referencia.
- Copiar también el contenido de ejemplo (Chef, Plato, Reserva...) — descartada: es contenido de un proyecto ajeno, no tiene sentido en ningún otro proyecto (ver Non-Goals de la propuesta).

**Decisión:** esqueleto fijo de la Parte 1, contenido siempre del proyecto destino.

### D7: Diagramas — Mermaid para flujo/secuencia, PlantUML solo para casos de uso

Cada Caso de Uso (3.4) deriva de un `#### Scenario:` de una spec y lleva un diagrama UML de caso de uso en PlantUML (actor + óvalo, como las Figuras 1-4 del documento de referencia). Además, cuando el escenario tiene más de un paso o más de un actor en el `WHEN/THEN`, se agrega un diagrama Mermaid: flowchart si es una secuencia de pasos de un solo actor, sequence diagram si hay interacción entre dos o más actores.

Alternativas consideradas (decisión del usuario, ver conversación previa):
- Solo Mermaid — descartada: no tiene un tipo de diagrama de "caso de uso" nativo (actor + óvalo); se podría aproximar con un flowchart pero no es UML real.
- Solo PlantUML — descartada: no se renderiza solo en GitHub/GitLab, hace falta una extensión o servidor; para flujo/secuencia, que es lo más frecuente, conviene lo que se ve sin instalar nada.
- Los dos, cada uno donde mejor rinde — elegida.

**Decisión:** PlantUML únicamente para 3.4.1 (diagrama de caso de uso); Mermaid para flujo/secuencia dentro de cada caso de uso.

### D8: Entrevista guiada con persistencia incremental para secciones sin fuente formal

Glosario de Términos (2.2), Objetivos de Negocio (3.1/3.2), Actores y Procesos de Negocio (3.3) y la prioridad de cada Requisito No Funcional (3.6) no salen de ninguna spec ni, en general, del código — son información de negocio que nadie escribió todavía en el proyecto. La primera vez que se corre `srs-generate`, la skill hace una entrevista corta (4-5 preguntas: términos del glosario, objetivos de negocio, actores, procesos de negocio, prioridad por cada NFR sin clasificar) y persiste las respuestas en `docs/srs.meta.yaml`. En regeneraciones siguientes, la skill lee ese archivo primero y solo pregunta por lo que sea nuevo desde la última corrida (una capability agregada sin prioridad asignada, un actor que aparece en un escenario nuevo, etc.) — nunca repite una pregunta ya respondida.

Alternativas consideradas (decisión del usuario, ver conversación previa):
- Inferir todo del código/README (modo bootstrap extendido a estas secciones) — descartada como default: información de negocio (objetivos, actores) rara vez está escrita en el código; inferirla sin preguntar arriesga inventar contenido que se presenta como si fuera real.
- Dejar placeholders "TBD" sin preguntar nada — descartada como default: obliga a editar `docs/srs.md` a mano después, que es exactamente lo que D4 trata de evitar en las secciones que sí se pueden completar solas.
- Entrevista corta + persistencia incremental — elegida: junta lo mejor de las dos (no inventa, no repite trabajo).

**Decisión:** entrevista la primera vez, `docs/srs.meta.yaml` como estado persistido, solo se re-pregunta por los gaps nuevos en cada regeneración.

## Risks / Trade-offs

- **[Riesgo] La heurística de D2 clasifica mal una capability (por ejemplo, una que mezcla funcional y no-funcional)** → La clasificación queda visible en el SRS generado; corregirla es una edición de texto, no un cambio de código ni de spec.
- **[Riesgo] El bootstrap de D3 infiere mal un requirement a partir del código** → Toda sección inferida queda marcada como tal; el SRS no se presenta como spec formal aprobada hasta que alguien la revise.
- **[Riesgo] El bootstrap lee un archivo con datos sensibles que no está en `.gitignore`** → Ver Security Layer: además del `.gitignore` del proyecto, la skill excluye patrones de secreto conocidos (`*.key`, `*.pem`, `*.env`, `secrets/`) y no copia strings que parezcan credenciales.
- **[Trade-off] Un SRS agregado lee menos fluido que uno redactado a mano** → Aceptado a propósito (ver conversación previa): la prioridad es que nunca quede desincronizado: la prosa se puede pulir manualmente y D4 protege esa edición.
- **[Riesgo] La entrevista de D8 se responde una vez y queda desactualizada (un actor cambia de nombre, un objetivo de negocio ya no aplica)** → `docs/srs.meta.yaml` es un archivo de texto versionable: se edita a mano como cualquier otro archivo del proyecto; la skill solo agrega gaps nuevos, no sobrescribe lo ya respondido sin que alguien lo borre primero.
- **[Trade-off] Mezclar dos herramientas de diagramas (D7) agrega una dependencia extra** → Es la opción que el usuario eligió a propósito (cobertura de UML real en casos de uso) sobre usar una sola herramienta; PlantUML solo se usa en el único lugar donde Mermaid no alcanza (diagrama de caso de uso).
- **[Riesgo] PlantUML no se renderiza solo en GitHub** → El bloque PlantUML queda como texto (` ```plantuml `) dentro de `docs/srs.md`; se ve renderizado con la extensión de VS Code o un visor local, igual que cualquier `.puml`; no bloquea la lectura del resto del documento.

## Security Layer

`project_type: tooling` — la skill en sí es una instrucción para IA (`SKILL.md`) y el SRS que produce es documentación, no código de producción.

- El modo bootstrap (D3) NO debe leer ni citar el contenido de archivos excluidos por el `.gitignore` del proyecto destino, ni de `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/` aunque no estén en `.gitignore`.
- Antes de escribir cualquier valor literal encontrado en código/config al SRS, la skill descarta strings que matcheen patrones típicos de credenciales (tokens, API keys, connection strings) en vez de copiarlos.
- El SRS generado no debe incluir rutas absolutas con el nombre de usuario de la máquina (mismo criterio que el resto de los artefactos del workflow) — si una ruta del código las tiene, se reemplaza por un placeholder, igual que D7 de `align-project-claude-md-openspec`.
- `docs/srs.md` y `docs/srs.meta.yaml` son archivos versionables normales del proyecto destino; no requieren reglas de `.gitignore` adicionales.
- Las respuestas de la entrevista guiada (D8) son información de negocio, no secrets — igual, si alguna respuesta contiene un dato sensible (por ejemplo un nombre de cliente real en un objetivo de negocio), queda a criterio de quien responde; la skill no valida el contenido de las respuestas, solo el del código/config que lee en el modo bootstrap.

## Impacto en proyectos existentes

- **Sin impacto por defecto:** ningún proyecto existente tiene hoy `docs/srs.md` ni depende de esta skill; nada cambia hasta que alguien la invoque.
- **Proyectos con `openspec/specs/` pobladas:** pueden generar su SRS de inmediato en modo agregación pura.
- **Proyectos terminados o sin historial de OpenSpec:** usan el modo bootstrap (D3) para la primera versión; luego siguen igual que el resto.
- **`skills/openspec-archive-change/SKILL.md`:** el paso nuevo (D5) es aditivo y condicional — el comportamiento actual del archive no cambia para proyectos sin `docs/srs.md`.
- **Retrocompatibilidad:** no se modifica el formato de `openspec/specs/**/spec.md` ni el schema `spec-driven`; la skill nueva solo lee, no escribe ahí.

## Migration Plan

1. Crear `skills/srs-generate/SKILL.md` con: la plantilla fija (D6), la agregación de Requisitos Funcionales/No Funcionales (D1/D2), Casos de Uso con diagramas PlantUML/Mermaid (D7) y Matriz de Trazabilidad, la entrevista guiada con persistencia en `docs/srs.meta.yaml` (D8), el modo bootstrap (D3), la regeneración con diff+confirmación (D4) y la exclusión de secrets/rutas.
2. Sumar el paso opcional en `skills/openspec-archive-change/SKILL.md` (D5).
3. Sumar `srs-generate` a la lista de skills del setup de máquina en `README.md` y `docs/workflow.md`.
4. Probar en un proyecto de prueba real (ver tasks.md): uno con specs pobladas (modo agregación completo, incluida la entrevista) y, si hay tiempo, simular uno sin specs (modo bootstrap).

Rollback: eliminar `skills/srs-generate/`, revertir el paso agregado en `openspec-archive-change/SKILL.md` y las menciones en `README.md`/`docs/workflow.md`. Ningún proyecto destino pierde nada porque `docs/srs.md` y `docs/srs.meta.yaml` son archivos aparte que no reemplazan `openspec/specs/`.

## Open Questions

Sin preguntas abiertas.
