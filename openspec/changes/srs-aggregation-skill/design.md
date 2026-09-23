## Context

El workflow SDD Híbrido ya tiene una fuente de verdad viva para requirements: `openspec/specs/<capability>/spec.md`, actualizada por deltas en cada `/opsx:archive` (vía `openspec-sync-specs`). Lo que falta es una vista consolidada, en el formato que suelen pedir stakeholders no técnicos (SRS con estructura ISO/IEC/IEEE 29148: Introduction/Scope, Stakeholder Requirements, System/Functional Requirements, Non-Functional Requirements). Hoy esa vista, si existe, se redacta a mano y se desincroniza.

Los `spec.md` actuales no tienen una convención de metadata (no hay frontmatter ni marca de "funcional" vs. "no funcional" por requirement) — solo `# <capability> Specification`, `## Purpose` y `## Requirements` con bloques `### Requirement:` / `#### Scenario:`. La skill nueva tiene que trabajar con ese formato tal cual está, sin pedir que se lo cambie retroactivamente.

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

Como los `spec.md` no distinguen funcional de no-funcional, la skill clasifica cada capability por defecto en "System Requirements → Functional Requirements", salvo que su `## Purpose` o el texto de sus requirements contenga palabras clave típicas de no-funcional (performance, seguridad/security, escalabilidad/scalability, disponibilidad/availability, usabilidad/usability, mantenibilidad/maintainability, compliance). El SRS generado deja visible la clasificación aplicada a cada capability para que se pueda corregir a mano.

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

## Risks / Trade-offs

- **[Riesgo] La heurística de D2 clasifica mal una capability (por ejemplo, una que mezcla funcional y no-funcional)** → La clasificación queda visible en el SRS generado; corregirla es una edición de texto, no un cambio de código ni de spec.
- **[Riesgo] El bootstrap de D3 infiere mal un requirement a partir del código** → Toda sección inferida queda marcada como tal; el SRS no se presenta como spec formal aprobada hasta que alguien la revise.
- **[Riesgo] El bootstrap lee un archivo con datos sensibles que no está en `.gitignore`** → Ver Security Layer: además del `.gitignore` del proyecto, la skill excluye patrones de secreto conocidos (`*.key`, `*.pem`, `*.env`, `secrets/`) y no copia strings que parezcan credenciales.
- **[Trade-off] Un SRS agregado lee menos fluido que uno redactado a mano** → Aceptado a propósito (ver conversación previa): la prioridad es que nunca quede desincronizado: la prosa se puede pulir manualmente y D4 protege esa edición.

## Security Layer

`project_type: tooling` — la skill en sí es una instrucción para IA (`SKILL.md`) y el SRS que produce es documentación, no código de producción.

- El modo bootstrap (D3) NO debe leer ni citar el contenido de archivos excluidos por el `.gitignore` del proyecto destino, ni de `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/` aunque no estén en `.gitignore`.
- Antes de escribir cualquier valor literal encontrado en código/config al SRS, la skill descarta strings que matcheen patrones típicos de credenciales (tokens, API keys, connection strings) en vez de copiarlos.
- El SRS generado no debe incluir rutas absolutas con el nombre de usuario de la máquina (mismo criterio que el resto de los artefactos del workflow) — si una ruta del código las tiene, se reemplaza por un placeholder, igual que D7 de `align-project-claude-md-openspec`.
- `docs/srs.md` es un archivo versionable normal del proyecto destino; no requiere reglas de `.gitignore` adicionales.

## Impacto en proyectos existentes

- **Sin impacto por defecto:** ningún proyecto existente tiene hoy `docs/srs.md` ni depende de esta skill; nada cambia hasta que alguien la invoque.
- **Proyectos con `openspec/specs/` pobladas:** pueden generar su SRS de inmediato en modo agregación pura.
- **Proyectos terminados o sin historial de OpenSpec:** usan el modo bootstrap (D3) para la primera versión; luego siguen igual que el resto.
- **`skills/openspec-archive-change/SKILL.md`:** el paso nuevo (D5) es aditivo y condicional — el comportamiento actual del archive no cambia para proyectos sin `docs/srs.md`.
- **Retrocompatibilidad:** no se modifica el formato de `openspec/specs/**/spec.md` ni el schema `spec-driven`; la skill nueva solo lee, no escribe ahí.

## Migration Plan

1. Crear `skills/srs-generate/SKILL.md` con el flujo de agregación, bootstrap, diff+confirmación y detección de `docs/srs.md` existente.
2. Sumar el paso opcional en `skills/openspec-archive-change/SKILL.md` (D5).
3. Sumar `srs-generate` a la lista de skills del setup de máquina en `README.md` y `docs/workflow.md`.
4. Probar en un proyecto de prueba real (ver tasks.md): uno con specs pobladas (modo agregación) y, si hay tiempo, simular uno sin specs (modo bootstrap).

Rollback: eliminar `skills/srs-generate/`, revertir el paso agregado en `openspec-archive-change/SKILL.md` y las menciones en `README.md`/`docs/workflow.md`. Ningún proyecto destino pierde nada porque `docs/srs.md` es un archivo aparte que no reemplaza `openspec/specs/`.

## Open Questions

Sin preguntas abiertas.
