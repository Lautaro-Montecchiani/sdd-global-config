## 1. Estructura fija y Requisitos Funcionales/No Funcionales

- [x] 1.1 Crear `skills/srs-generate/SKILL.md` con el frontmatter estándar (name, description, license, compatibility, metadata) y el esqueleto fijo de secciones de `docs/srs.md` (1 a 3.7, con la numeración del documento de referencia pero sin sus duplicados): Introducción, Información del Dominio del Problema, Necesidades de Negocio con sus subsecciones
- [x] 1.2 En `skills/srs-generate/SKILL.md`, implementar 3.5/3.6: leer `openspec/specs/**/spec.md` del proyecto destino, clasificar cada capability por heurística de palabras clave (performance, seguridad, escalabilidad, disponibilidad, usabilidad, mantenibilidad, compliance) en Funcional o No Funcional, dejando la clasificación visible en el documento
- [x] 1.3 En `skills/srs-generate/SKILL.md`, implementar el encabezado de identificación (título, proyecto, fecha de generación, estado borrador/completo) y la tabla de contenidos derivada de los headings; verificar que ningún número de sección se use dos veces (el documento de referencia duplica "3.4.1", no se reproduce)
- [x] 1.4 En `skills/srs-generate/SKILL.md`, implementar el formato de tabla para 3.1/3.2 (Objetivos de Negocio), 3.3 (Actores y Procesos de Negocio) y 3.6 (Requisitos No Funcionales), una tabla por ítem como en el documento de referencia
- [x] 1.5 En `skills/srs-generate/SKILL.md`, implementar los identificadores jerárquicos (`3.5.<n>.<m>` / `3.6.<n>.<m>`) con el mapeo persistido en `docs/srs.meta.yaml`: un ID asignado nunca se reasigna ni se renumera; los requirements nuevos toman el siguiente número libre
- [x] 1.6 En `skills/srs-generate/SKILL.md`, implementar los atributos Riesgo, Dependencia y Dificultad por requirement, con valores por defecto (Bajo / Ninguna identificada / Nominal) y lectura de las correcciones en `docs/srs.meta.yaml` indexadas por ID

## 2. Casos de Uso, diagramas y trazabilidad

- [x] 2.1 En `skills/srs-generate/SKILL.md`, implementar 3.4: convertir cada `#### Scenario:` de una spec en un Caso de Uso, con un diagrama UML de caso de uso en PlantUML (bloque ` ```plantuml `) derivado del `WHEN`
- [x] 2.2 En `skills/srs-generate/SKILL.md`, agregar diagramas Mermaid por Caso de Uso cuando corresponda: flowchart si el escenario tiene varios pasos de un solo actor, sequence diagram si hay interacción entre dos o más actores
- [x] 2.3 En `skills/srs-generate/SKILL.md`, hacer que el título de cada Caso de Uso cite el ID jerárquico del requirement del que proviene su escenario
- [x] 2.4 En `skills/srs-generate/SKILL.md`, implementar 3.7 (Matriz de Trazabilidad): tabla que cruza automáticamente los Casos de Uso de 3.4 con los Requisitos Funcionales de 3.5, usando los IDs jerárquicos
- [x] 2.5 En `skills/srs-generate/SKILL.md`, implementar el guard de escala: alcance opcional por capabilities, conteo de escenarios/requirements + estimación de tamaño antes de generar, umbral configurable (~40 casos de uso) que pide confirmación u ofrece acotar, y modo agrupado (un diagrama de casos de uso por capability, sin Mermaid por escenario) por encima del umbral

## 3. Entrevista guiada y persistencia

- [x] 3.1 En `skills/srs-generate/SKILL.md`, implementar la entrevista guiada para 2.2 (Glosario), 3.1/3.2 (Objetivos de Negocio) y 3.3 (Actores y Procesos de Negocio): se ofrece la primera vez que no existe `docs/srs.meta.yaml`, y persiste las respuestas ahí
- [x] 3.2 En `skills/srs-generate/SKILL.md`, implementar la prioridad de cada Requisito No Funcional (3.6) como parte de la misma entrevista, con las respuestas también en `docs/srs.meta.yaml`
- [x] 3.3 En `skills/srs-generate/SKILL.md`, sumar a la entrevista una única pregunta consolidada de excepciones de Riesgo/Dependencia/Dificultad (no una pregunta por requirement), persistida en `docs/srs.meta.yaml`
- [x] 3.4 En `skills/srs-generate/SKILL.md`, implementar la detección incremental de gaps: en cada regeneración, leer `docs/srs.meta.yaml` primero y preguntar solo por lo que sea nuevo (capability sin prioridad, actor o término nuevo en un escenario), sin repetir preguntas ya respondidas

## 4. Bootstrap, regeneración segura y seguridad

- [x] 4.1 En `skills/srs-generate/SKILL.md`, implementar el modo bootstrap: cuando `openspec/specs/` está vacío o no cubre partes evidentes del proyecto, ofrecerlo, leer código/README/config existentes para completar 3.5/3.6 y marcar cada sección resultante como "inferido del código, sin spec formal — revisar"; el bootstrap no reemplaza la entrevista guiada de las secciones de negocio (grupo 3) ni escribe en `openspec/specs/`
- [x] 4.2 En `skills/srs-generate/SKILL.md`, implementar la exclusión de secrets y rutas absolutas del modo bootstrap: no leer/citar archivos excluidos por el `.gitignore` del proyecto destino ni `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`; descartar strings con forma de credencial; reemplazar rutas absolutas con el usuario local por un placeholder
- [x] 4.3 En `skills/srs-generate/SKILL.md`, implementar la regeneración segura: si `docs/srs.md` ya existe, mostrar un resumen de las secciones que cambiarían antes de escribir y pedir confirmación explícita; no sobrescribir si el usuario no confirma
- [x] 4.4 En `skills/srs-generate/SKILL.md`, implementar la trazabilidad de origen: cada requirement de 3.5/3.6 cita su capability/spec, la marca de "inferido" (bootstrap) o la marca de "entrevista" (prioridad, glosario, actores, objetivos)
- [x] 4.5 En `skills/srs-generate/SKILL.md`, implementar el semáforo de cobertura: sección final de `docs/srs.md` con el desglose por origen (specs / inferido / entrevista / pendiente)

## 5. Enganche opcional en el archive

- [x] 5.1 Editar `skills/openspec-archive-change/SKILL.md`: agregar un paso al final (después del resumen de archive) que, solo si `docs/srs.md` ya existe en el proyecto, ofrezca regenerarlo invocando `srs-generate`; si `docs/srs.md` no existe, el paso no debe aparecer ni bloquear el archive

## 6. Documentación del setup

- [x] 6.1 Editar `README.md`: sumar `skills/srs-generate/` a la tabla "Qué contiene" y al paso 3 del setup por máquina
- [x] 6.2 Editar `docs/workflow.md`: sumar `srs-generate` a la lista de skills instaladas por el setup, con una descripción breve de su uso (invocación manual on-demand, estructura fija, entrevista la primera vez, oferta opcional al final de `/opsx:archive`)

## 7. Verificación

- [x] 7.1 Verificar que el cambio aplica en un proyecto de prueba: instalar `skills/srs-generate/` en un proyecto con `openspec/specs/` pobladas, correr la skill, responder la entrevista guiada y confirmar que `docs/srs.md` tiene encabezado + índice, las 7 secciones de la estructura fija sin números duplicados, las tablas en 3.1/3.2, 3.3 y 3.6, los IDs jerárquicos con sus atributos (Prioridad, Riesgo, Dependencia, Dificultad), los Casos de Uso citando el ID de su requirement con diagrama PlantUML (y Mermaid cuando corresponda), la Matriz de Trazabilidad por ID, y que `docs/srs.meta.yaml` guardó respuestas e IDs
- [x] 7.2 Correr la skill una segunda vez en el mismo proyecto y confirmar que no repite ninguna pregunta ya respondida y que ningún ID se renumeró; agregar una capability de prueba, regenerar y confirmar que toma el siguiente número libre sin mover los anteriores
- [x] 7.3 Probar el guard de escala en un proyecto grande real (Monitor-Mora, 419 escenarios): confirmar que la skill muestra el conteo, pide confirmación/ofrece acotar, y que en modo agrupado genera un diagrama por capability y un documento legible; probar además acotar el alcance a una sola capability y confirmar que ahí vuelven los diagramas por escenario y el semáforo de cobertura refleja el alcance
- [x] 7.4 Si el tiempo lo permite, simular un proyecto sin `openspec/specs/` y confirmar el modo bootstrap; confirmar que `/opsx:archive` solo ofrece regenerar el SRS cuando `docs/srs.md` ya existe

## 8. Correcciones del verify (2026-09-23)

- [x] 8.1 En `skills/srs-generate/SKILL.md`, agregar un bloque ` ```yaml ` de ejemplo (cerca de la sección 3.3, o al final del archivo) mostrando la forma completa de `docs/srs.meta.yaml`: mapeo de IDs jerárquicos (capability + requirement → ID), glosario, actores, objetivos de negocio, prioridad de cada Requisito No Funcional, y excepciones de Riesgo/Dependencia/Dificultad. Motivo: hoy cuatro secciones distintas (§3.3, §3.4, §5.1) leen/escriben ese archivo sin que se muestre nunca la forma combinada, lo que arriesga que dos regeneraciones estructuren el YAML de forma distinta y rompan la detección incremental de gaps (§5.2) o la lectura de IDs (§3.3)
- [x] 8.2 En `skills/srs-generate/SKILL.md`, frontmatter (líneas 5-8), cambiar el campo `compatibility` — hoy es una lista de sistemas operativos (`windows/linux/macos`) — por una descripción de texto de la dependencia de herramienta, igual que el resto de las skills del repo (ej. `compatibility: Requires openspec CLI.`, ver `skills/openspec-propose/SKILL.md:5` o `skills/openspec-archive-change/SKILL.md:5`). Si hace falta conservar la info de SO, moverla a `description` o a `metadata`, no a `compatibility`
- [ ] 8.3 En `skills/srs-generate/SKILL.md`, agregar un campo `processes:` al ejemplo de `docs/srs.meta.yaml` (líneas 177-218, mismo shape que `actors:`, ej. `{name, desc}`) y mencionarlo explícitamente en la lista de la entrevista guiada (línea 124, hoy solo dice "3.3" genérico). Motivo: la sección 3.3 se llama "Actores **y Procesos de Negocio**", pero el esquema y la entrevista solo cubren actores — los procesos de negocio no tienen dónde persistirse y en la práctica esa mitad de 3.3 nunca se completa
