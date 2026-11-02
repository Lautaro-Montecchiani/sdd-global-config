---
name: srs-generate
description: Genera y mantiene actualizado el SRS (Software Requirements Specification) de un proyecto por agregación de specs vigentes.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  version: 1.1.0
  author: SDD
---

# SRS Generation Skill

Esta skill ensambla y regenera el archivo `docs/srs.md` de un proyecto a partir de sus especificaciones vigentes en `openspec/specs/`, entrevistas guiadas, y modo bootstrap para proyectos sin historial.

## 1. Introducción

El archivo `docs/srs.md` generado siempre sigue este esqueleto fijo de secciones:

- 1. Introducción
  - 1.1 Alcance
  - 1.2 Objetivos
- 2. Información del Dominio del Problema
  - 2.1 Introducción al dominio
  - 2.2 Glosario de Términos
- 3. Necesidades de Negocio
  - 3.1 Objetivos de negocio de clientes/usuarios
  - 3.2 Objetivos de Negocio
  - 3.3 Actores y Procesos de Negocio
  - 3.4 Casos de Uso
  - 3.5 Requisitos Funcionales
  - 3.6 Requisitos No Funcionales
  - 3.7 Matriz de Trazabilidad

**Nota:** Ningún número de sección se usa dos veces. Si alguna sección no tiene contenido disponible, se genera igual pero marcada como pendiente.

## 2. Instrucciones para generar Requisitos Funcionales y No Funcionales (3.5 y 3.6)

Para generar las secciones "3.5 Requisitos Funcionales" y "3.6 Requisitos No Funcionales", debes:

1. Leer todos los archivos `openspec/specs/**/spec.md` del proyecto destino (las capabilities vigentes).
2. Clasificar cada capability en "Funcional" o "No Funcional".
   - **Heurística de clasificación**: Si el archivo `spec.md` (su `## Purpose` o sus requirements) contiene de forma predominante palabras clave como `performance`, `seguridad`, `escalabilidad`, `disponibilidad`, `usabilidad`, `mantenibilidad`, `compliance`, clasifícalo como No Funcional (va en 3.6). De lo contrario, clasifícalo como Funcional (va en 3.5).
3. Dejar explícita la clasificación aplicada a cada capability en el documento generado (ej. agregando una nota "Clasificación: No Funcional" bajo la capability) para que el usuario pueda corregirla a mano si fuera necesario.
4. Las capabilities clasificadas en 3.6 (No Funcionales) deben llevar una prioridad (Deseable, Alta, Crítica, Media). Si no tienen prioridad asignada, deben quedar marcadas como "pendiente" hasta que se completen por entrevista o editando el archivo `docs/srs.meta.yaml`.

## 3. Instrucciones de Formato General

### 3.1 Encabezado de Identificación y Tabla de Contenidos

Al generar `docs/srs.md`, debes incluir un encabezado de identificación al principio del archivo que contenga:
- Título del documento (ej. "Software Requirements Specification")
- Nombre del proyecto
- Fecha de generación
- Estado del documento:
  - **"borrador"**: si existen secciones marcadas como pendientes o inferidas (bootstrap), o diagramas de caso de uso sin renderizar a SVG.
  - **"completo"**: si todas las secciones están completas y no hay nada pendiente o inferido.

Luego del encabezado, debes generar una tabla de contenidos (TOC) con enlaces a cada heading del documento.

**Regla estricta:** Asegúrate de que **ningún número de sección se use dos veces** en el documento.

### 3.2 Formato de Tabla para Secciones Específicas

Las secciones **3.1/3.2 (Objetivos de Negocio)**, **3.3 (Actores y Procesos de Negocio)** y **3.6 (Requisitos No Funcionales)** deben presentarse usando un formato de tabla individual por cada ítem. No utilices texto corrido ni listas simples.

Por ejemplo, cada Objetivo de Negocio debe ser una tabla con filas para "ID", "Descripción", etc. Cada Actor debe ser una tabla con "Nombre", "Descripción", etc. Cada Requisito No Funcional de 3.6 debe ser una tabla individual detallando su ID, descripción, prioridad, etc.

### 3.3 Identificadores Jerárquicos Estables

Cada requirement funcional (3.5) y no funcional (3.6) debe recibir un ID jerárquico del tipo `3.5.<n>.<m>` o `3.6.<n>.<m>`, donde `<n>` es el orden de la capability y `<m>` el orden del requirement dentro de ella.
- **Persistencia:** Debes guardar el mapeo (capability + requirement → ID) en el archivo `docs/srs.meta.yaml` del proyecto.
- **Estabilidad:** Un ID ya asignado **nunca se reasigna ni se renumera** en futuras regeneraciones. Si se agregan nuevos requirements o capabilities, estos deben tomar el **siguiente número libre** (el máximo actual + 1) para `<n>` o `<m>`.
- **Orden por ID:** Las capabilities deben presentarse en 3.5 y 3.6 ordenadas por su ID jerárquico y **no por nombre de carpeta**, de modo que una capability nueva con nombre alfabéticamente anterior reciba el siguiente número libre y quede al final, sin desplazar los IDs existentes.

### 3.4 Atributos Adicionales por Requirement

Cada requirement de 3.5 y 3.6 debe mostrar los siguientes atributos con sus valores por defecto si no han sido modificados:
- **Riesgo:** Bajo
- **Dependencia:** Ninguna identificada
- **Dificultad:** Nominal

Las correcciones o excepciones a estos valores por defecto deben leerse de `docs/srs.meta.yaml` (indexadas por el ID jerárquico del requirement). En la entrevista guiada se hará una **única pregunta consolidada** para identificar si algún requirement se sale de lo normal, en lugar de preguntar uno por uno.

## 4. Casos de Uso, Diagramas y Trazabilidad

### 4.1 Generación de Casos de Uso (Sección 3.4)

Convierte cada `#### Scenario:` de una spec en un Caso de Uso dentro de la sección 3.4.
- **Identificador de Caso de Uso:** Cada Caso de Uso debe tener el ID `CU-<ID del requirement>.<n>`, donde `<n>` es la posición del escenario dentro de su requirement (1, 2, …) y no un número correlativo global. De esta forma, agregar capabilities o requirements no cambia el ID de los casos de uso existentes.
- **Límite conocido:** Insertar un escenario en el medio de un requirement desplaza el índice `<n>` de los siguientes escenarios de ese requirement. Por lo tanto, nuevos escenarios deben agregarse al final del requirement para mantener la estabilidad de los IDs.
- **Nombres y ubicación (design D1):** Todo archivo de diagrama se guarda en `docs/diagramas/` del proyecto destino (relativo a la raíz del repo):
  - Por escenario: `docs/diagramas/CU-<ID del caso de uso sin el prefijo CU->.puml` y su correspondiente `.svg` (ej. `CU-3.5.1.2.1.puml` y `CU-3.5.1.2.1.svg`).
  - Patrón propio de la skill: nombres que comienzan con `CU-` o `CAP-`, seguidos de dígitos y puntos, terminados en `.puml` o `.svg`. Cualquier otro archivo de la carpeta es ajeno y no se toca.
- **Contenido de cada `.puml` (design D2):** UTF-8 sin BOM, con este orden:
  1. Línea `@startuml`
  2. Línea `!pragma layout smetana` (motor interno, sin Graphviz)
  3. Actor(es) inferido(s) del `WHEN` del escenario.
  4. Un `rectangle` con el nombre del sistema que contiene el/los `usecase` (en modo agrupado, todos los de la capability) y las asociaciones actor–caso de uso.
  5. Línea `@enduml`
  - Textos entre comillas dobles; una comilla doble dentro del texto del escenario se reemplaza por comilla simple.
  - La skill **NO** escribe `!include`, `!includeurl`, `!import` ni ninguna otra directiva `!` salvo el `!pragma layout smetana` de arriba.
- **Visualización en el SRS (`docs/srs.md`) (design D7):**
  - **Nunca se escribe un bloque `plantuml` inline en `docs/srs.md`.**
  - En su lugar, en cada Caso de Uso (o al inicio de cada capability en modo agrupado):
    - Con SVG: una línea de imagen Markdown `![Diagrama CU-3.5.1.2.1](diagramas/CU-3.5.1.2.1.svg)` y debajo `Fuente: [CU-3.5.1.2.1.puml](diagramas/CU-3.5.1.2.1.puml)`.
    - Sin SVG: solo `Diagrama sin renderizar — fuente: [CU-3.5.1.2.1.puml](diagramas/CU-3.5.1.2.1.puml)`.
  - Las rutas son relativas a `docs/`.

### 4.2 Diagramas Mermaid Adicionales

Cuando un escenario sea más complejo, debes agregar un diagrama de Mermaid junto al diagrama de caso de uso. El diagrama Mermaid sigue en bloque inline, ubicado inmediatamente después de la imagen (o de la línea de fallback) del caso de uso:
- **Flujo de varios pasos (Flowchart):** Si el escenario (en el `WHEN`/`THEN`) tiene varios pasos secuenciales de un solo actor, agrega un `flowchart` en Mermaid detallando los pasos.
- **Interacción entre actores (Sequence Diagram):** Si el escenario involucra interacción entre dos o más actores, agrega un diagrama de secuencia (`sequenceDiagram`) en Mermaid.
- **Importante:** No uses PlantUML para diagramas de flujo/secuencia, ni Mermaid para diagramas de caso de uso.

### 4.3 Títulos de Casos de Uso

El título de cada Caso de Uso en 3.4 debe citar tanto su ID de caso de uso (`CU-<ID del requirement>.<n>`) como explícitamente el **ID jerárquico** (por ejemplo, `[3.5.1.2]`) del requirement del cual proviene el escenario (ej. `CU-3.5.1.2.1: Nombre del escenario [3.5.1.2]`).

### 4.4 Matriz de Trazabilidad (Sección 3.7)

Debes generar la sección "3.7 Matriz de Trazabilidad" cruzando automáticamente de forma tabular los Casos de Uso (de la sección 3.4) con los Requisitos Funcionales (de la sección 3.5).
- Cada fila debe citar el ID del caso de uso (`CU-…`) y el ID jerárquico del requirement funcional del que proviene.

### 4.5 Guard de Escala y Alcance

Antes de generar el documento, debes verificar la escala del proyecto:
1. **Alcance Opcional:** Ofrece al usuario la opción de limitar el alcance a ciertas capabilities. Si no se especifica, el alcance es todas.
2. **Conteo y Umbral:** Cuenta los escenarios (casos de uso) y requirements en el alcance.
3. Si el número de casos de uso supera el umbral configurable (por defecto ~40), debes detenerte, mostrar la estimación de tamaño y pedir confirmación u ofrecer acotar el alcance.
4. **Modo Agrupado:** Si el usuario decide continuar superando el umbral, activa el **modo agrupado**. En este modo:
   - Genera un solo diagrama de casos de uso por capability en `docs/diagramas/CAP-<ID de la capability>.puml` con su `.svg` (ej. `CAP-3.5.1.puml` y `CAP-3.5.1.svg`), agrupando todos sus casos de uso (design D1).
   - **No** generes los diagramas de Mermaid (flujo/secuencia) por escenario.
   - Si se acota el alcance y queda por debajo del umbral, vuelve a generar un diagrama por escenario (`docs/diagramas/CU-<ID>.puml` y su `.svg`) y sus diagramas Mermaid correspondientes.

### 4.6 Renderizado a SVG

La generación de los archivos `.svg` a partir de los `.puml` se realiza de forma local utilizando Java y una versión fija de `plantuml.jar`.

#### Versión fija y caché (design D3)

| Parámetro | Valor |
|---|---|
| Versión | `1.2026.8` |
| Asset | `plantuml-1.2026.8.jar` |
| URL | `https://github.com/plantuml/plantuml/releases/download/v1.2026.8/plantuml-1.2026.8.jar` |
| SHA-256 | `5e1ecfa8ecd32c90b03bbf3b1eb6f020943f98ab0fcf4032be31a0002ee2c462` |
| Caché | `~/.claude/tools/plantuml/plantuml-1.2026.8.jar` |

- **Seguridad (Security Layer):** Prohibido usar servidores de render online (plantuml.com, kroki u otros), ya que enviarían el contenido de las especificaciones a terceros.
- **Rutas portables:** La caché reside en el home del usuario (`~/.claude/tools/plantuml/`). Nunca se escribe una ruta absoluta en el SRS, en los diagramas ni en los resúmenes. Para actualizar la versión de PlantUML se deben cambiar la versión, la URL y el hash juntos en un change nuevo.

#### Obtención y verificación del jar (design D4)

En cada generación:
1. Si el jar está en la caché (`~/.claude/tools/plantuml/plantuml-1.2026.8.jar`), calcular su SHA-256 (`Get-FileHash -Algorithm SHA256` en PowerShell, `sha256sum` en bash o `certutil -hashfile <archivo> SHA256` en Windows). Si coincide, usarlo. Si no coincide, borrarlo y seguir con el paso 2 (un solo reintento). La comparación no distingue mayúsculas.
2. Bajar desde la URL fija a `plantuml-1.2026.8.jar.part` en la misma carpeta, calcular el SHA-256 y, solo si coincide, renombrarlo a `plantuml-1.2026.8.jar`. Si no coincide o falla la descarga, borrar el `.part` y aplicar el fallback (D8).

#### Detección de Java (design D5)

- Se detecta con `java -version`: tiene que existir y ser la versión 11 o superior.
- Si `java` no está instalado en el PATH o es anterior a 11, se aplica el fallback (D8) sin intentar bajar el jar.

#### Render incremental, uno por archivo (design D6)

Antes de escribir un `.puml`, la skill lo compara con el que ya está en disco:
- Si el contenido es idéntico y el `.svg` existe, no se renderiza y se sigue usando ese SVG.
- Si es nuevo, cambió o le falta el `.svg`, se escribe y se renderiza con una invocación por archivo:
  ```bash
  java -Djava.awt.headless=true -DPLANTUML_SECURITY_PROFILE=SANDBOX -jar <jar> -tsvg -charset UTF-8 docs/diagramas/<archivo>.puml
  ```
  De esta forma el `.svg` queda al lado del `.puml`.
- Si el exit code es distinto de 0, el diagrama tiene un error: se borra el `.svg` que PlantUML haya dejado (PlantUML escribe una imagen del error) y ese diagrama pasa al fallback puntual (D8).

#### Fallback (design D8)

- **Por entorno** (sin Java, Java menor que 11, jar no obtenido o no verificado): se escriben igual todos los `.puml`. Los diagramas cuyo `.puml` no cambió y ya tienen `.svg` lo conservan (D6). Los demás se muestran como "sin renderizar" (D7).
- **Puntual** (error al renderizar un archivo puntual): solo ese diagrama queda "sin renderizar".
- En los dos casos, el resumen final indica cuántos diagramas quedaron sin SVG y por qué (sin Java, hash, descarga, o el nombre del archivo con error), y el encabezado del SRS queda en "borrador".

#### Limpieza de diagramas huérfanos (design D9)

Con la lista de diagramas vigentes (por escenario o agrupados, según el modo de esta corrida):
- Se borran de `docs/diagramas/` los `.puml` y `.svg` con patrón propio (`CU-*` o `CAP-*`) que no estén en la lista.
- Un cambio de modo deja huérfanos todos los del modo anterior.
- Cualquier otro archivo de la carpeta ajeno a estos patrones no se toca.

## 5. Entrevista Guiada y Persistencia

Para las secciones que no pueden inferirse formalmente de las specs (Glosario de Términos 2.2, Objetivos de Negocio 3.1/3.2, y Actores y Procesos de Negocio 3.3), debes realizar una entrevista guiada corta al usuario. Asegúrate de preguntar tanto por los actores (quién usa el sistema) como por los procesos de negocio (flujos de trabajo clave).

### 5.1 Ejecución de la Entrevista

- **Primera vez:** Si no existen las subsecciones en `openspec/config.yaml`, realiza la entrevista completa para completar las secciones 2.2, 3.1, 3.2 y 3.3 (Actores y Procesos).
- **Prioridad (3.6):** En la misma entrevista, debes preguntar la prioridad (Deseable, Alta, Crítica, Media) de cada capability clasificada como Requisito No Funcional.
- **Atributos excepcionales (3.4):** Suma a la entrevista una única pregunta consolidada: "¿Algún requirement se sale de lo normal en riesgo, dependencia o dificultad?".
- **Persistencia:** Guarda las respuestas de glosario, objetivos, actores y procesos en el `context:` de `openspec/config.yaml`. Guarda las prioridades (3.6) y atributos excepcionales (3.4) en `docs/srs.meta.yaml`.

### 5.2 Detección Incremental de Gaps

En cada regeneración posterior, debes implementar una **detección incremental de gaps**:
1. Lee primero `docs/srs.meta.yaml` (para prioridades y atributos) y el `context:` de `openspec/config.yaml` (para glosario, objetivos, actores y procesos).
2. Compara su contenido con el estado actual del proyecto.
3. Pregunta al usuario **solamente** por lo que sea nuevo (ej. una capability nueva en 3.6 sin prioridad asignada, un actor o término nuevo aparecido en un escenario reciente).
4. **Nunca** repitas preguntas ya respondidas; reutiliza las respuestas persistidas.

### 5.3 Persistencia en `openspec/config.yaml`

El conocimiento del negocio (Glosario, Objetivos, Actores y Procesos) no se guarda en `docs/srs.meta.yaml`, sino directamente en el campo `context:` de `openspec/config.yaml` del proyecto destino.

**Lectura:**
Para construir las secciones 2.2, 3.1, 3.2 y 3.3 del SRS, debes leer las subsecciones estructuradas dentro del campo `context:` de `openspec/config.yaml`:
- `## Glosario`
- `## Actores y Procesos de Negocio` (con sus sub-encabezados `### Actores` y `### Procesos`)
- `## Objetivos de Negocio`

**Formato de los ítems:**
Dentro de estas subsecciones, cada ítem debe escribirse como una lista simple:
- En Glosario: `- <término>: <definición>`
- En Actores (bajo `### Actores`): `- <nombre>: <descripción>`
- En Procesos (bajo `### Procesos`): `- <nombre>: <descripción>`
- En Objetivos de Negocio: `- <id>: <descripción>`

**Escritura y Actualización:**
Cuando debas guardar nuevas respuestas de la entrevista para estos puntos:
- Si la subsección (ej. `## Glosario`) no existe en `context:`, **appendéala al final** del texto de `context:`, separada por una línea en blanco.
- Si la subsección ya existe, **reemplaza solamente el bloque** de texto entre su encabezado y el siguiente `##` (o el final del texto), **sin tocar** el resto de `context:` (donde pueden vivir `project_type`, `Stack`, u otras reglas del proyecto).

**Advertencia de Tamaño:**
Dado que el CLI de OpenSpec descarta todo el campo `context` si supera los 50KB, debes:
1. Calcular el tamaño resultante del string `context:` en bytes antes de escribir los cambios.
2. Si el nuevo tamaño supera los **40KB**, muestra una advertencia al usuario antes de escribir, indicándole que se acerca al límite y dándole la oportunidad de acortar las descripciones, pero **no bloquees** la escritura automáticamente.

## 6. Bootstrap, Regeneración y Seguridad

### 6.1 Modo Bootstrap

Si la carpeta `openspec/specs/` no existe, está vacía, o detectas que el código contiene funcionalidades evidentes que no están documentadas en specs formales, ofrece el **modo bootstrap**:
- Lee código fuente, `README.md` y archivos de configuración para inferir las capabilities de las secciones 3.5 y 3.6.
- Marca cada capability y requirement inferido explícitamente con: **"inferido del código, sin spec formal — revisar"**.
- El bootstrap no reemplaza la entrevista guiada; las secciones de negocio (2.2 y grupo 3) siempre deben completarse mediante entrevista.
- **Importante:** La skill genera el SRS en `docs/srs.md` y `docs/srs.meta.yaml`, pero nunca escribe o modifica nada dentro de `openspec/specs/`.

### 6.2 Exclusión de Secretos (Seguridad)

Al leer código en modo bootstrap (o en cualquier otra fase), debes **omitir** lo siguiente:
1. Cualquier archivo excluido por el `.gitignore` del proyecto.
2. Cualquier archivo que coincida con: `*.env`, `*.key`, `*.pem`, `*.p12`, o esté en un directorio `secrets/`.
3. Cualquier string literal que se parezca a una credencial (tokens, contraseñas, claves API). Debes descartarlas y no incluirlas en el SRS.
4. **Rutas Absolutas:** Si encuentras una ruta absoluta que incluye el nombre del usuario local de la máquina, reemplaza esa parte con un placeholder (ej. `<USER_HOME>`) para no dejar información privada de la máquina en el documento.

### 6.3 Regeneración Segura

Si el archivo `docs/srs.md` **ya existe** en el proyecto:
- Antes de sobrescribirlo, muestra al usuario un **resumen de los cambios**:
  - Qué secciones nuevas se agregan o qué contenido cambia significativamente.
  - Conteo de archivos `.puml` que se crean, cambian y borran en `docs/diagramas/`, con los nombres de los que se borran (design D10).
- Pide **confirmación explícita** para proceder.
- **Sin confirmación no se toca `docs/diagramas/`** ni se sobrescribe `docs/srs.md`.
- El renderizado a SVG ocurre después de confirmar.

### 6.4 Trazabilidad de Origen

Cada requirement que generes en 3.5 y 3.6 debe indicar de dónde proviene. Usa las siguientes marcas según corresponda:
- **Spec:** Cita la capability y ruta del archivo `spec.md` (ej. "Origen: `openspec/specs/auth/spec.md`").
- **Inferido:** "Origen: Inferido del código (bootstrap)".
- **Entrevista:** "Origen: Entrevista guiada".

### 6.5 Semáforo de Cobertura

Agrega al final de `docs/srs.md` una sección de cobertura que muestre un desglose porcentual (o conteo) del origen de la información del documento:
- % Proveniente de **Specs formales**
- % **Inferido** del código (bootstrap)
- % Proveniente de la **Entrevista guiada**
- % **Pendiente** (secciones marcadas como TBD)

## 7. Estructura de `docs/srs.meta.yaml`

Para garantizar la estabilidad en la detección incremental de gaps y la persistencia de IDs, el archivo `docs/srs.meta.yaml` debe estructurarse siempre de la siguiente manera:

```yaml
# Mapeo de IDs Jerárquicos (capability + requirement -> ID)
ids:
  capability-nombre-1:
    cap_id: "3.5.1"
    reqs:
      "Título del Requirement A": "3.5.1.1"
      "Título del Requirement B": "3.5.1.2"
  capability-nombre-2:
    cap_id: "3.6.1"
    reqs:
      "Título del Requirement C": "3.6.1.1"

# Prioridades para Requisitos No Funcionales (indexadas por ID de capability o requirement)
priorities:
  "3.6.1": "Alta"

# Excepciones a atributos (Riesgo, Dependencia, Dificultad) por ID de requirement
exceptions:
  "3.5.1.2":
    riesgo: "Alto"
    dependencia: "API Externa"
```

## 8. Migración Automática

Si al leer `docs/srs.meta.yaml` encuentras campos de versiones anteriores como `glossary`, `objectives`, `actors` o `processes`:
1. **Mígralos** a sus respectivas subsecciones (`## Glosario`, `## Actores y Procesos de Negocio`, `## Objetivos de Negocio`) en el campo `context:` de `openspec/config.yaml`, siguiendo el formato descrito en la sección 5.3.
2. **Bórralos** de `docs/srs.meta.yaml`, dejando allí solamente los IDs y atributos.
3. No vuelvas a preguntar por esta información en la entrevista.
4. **Al finalizar**, agrega al resumen de la skill una línea clara indicando qué se migró (ej. "Migración automática: 3 actores y 5 términos movidos a `config.yaml`").
