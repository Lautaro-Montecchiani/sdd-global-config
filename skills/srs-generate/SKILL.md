---
name: srs-generate
description: Genera y mantiene actualizado el SRS (Software Requirements Specification) de un proyecto por agregación de specs vigentes.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  version: 1.0.0
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
  - **"borrador"**: si existen secciones marcadas como pendientes o inferidas (bootstrap).
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

### 3.4 Atributos Adicionales por Requirement

Cada requirement de 3.5 y 3.6 debe mostrar los siguientes atributos con sus valores por defecto si no han sido modificados:
- **Riesgo:** Bajo
- **Dependencia:** Ninguna identificada
- **Dificultad:** Nominal

Las correcciones o excepciones a estos valores por defecto deben leerse de `docs/srs.meta.yaml` (indexadas por el ID jerárquico del requirement). En la entrevista guiada se hará una **única pregunta consolidada** para identificar si algún requirement se sale de lo normal, en lugar de preguntar uno por uno.

## 4. Casos de Uso, Diagramas y Trazabilidad

### 4.1 Generación de Casos de Uso (Sección 3.4)

Convierte cada `#### Scenario:` de una spec en un Caso de Uso dentro de la sección 3.4.
- Para cada Caso de Uso, genera un **diagrama UML de caso de uso en PlantUML** (usando un bloque de código ````plantuml `).
- Infiere el/los actor(es) y el caso de uso (como óvalo) a partir de la cláusula `WHEN` del escenario.

### 4.2 Diagramas Mermaid Adicionales

Cuando un escenario sea más complejo, debes agregar un diagrama de Mermaid junto al diagrama PlantUML de caso de uso:
- **Flujo de varios pasos (Flowchart):** Si el escenario (en el `WHEN`/`THEN`) tiene varios pasos secuenciales de un solo actor, agrega un `flowchart` en Mermaid detallando los pasos.
- **Interacción entre actores (Sequence Diagram):** Si el escenario involucra interacción entre dos o más actores, agrega un diagrama de secuencia (`sequenceDiagram`) en Mermaid.
- **Importante:** No uses PlantUML para diagramas de flujo/secuencia, ni Mermaid para diagramas de caso de uso.

### 4.3 Títulos de Casos de Uso

El título de cada Caso de Uso en 3.4 debe citar explícitamente el **ID jerárquico** (por ejemplo, `[3.5.1.2]`) del requirement del cual proviene el escenario.

### 4.4 Matriz de Trazabilidad (Sección 3.7)

Debes generar la sección "3.7 Matriz de Trazabilidad" cruzando automáticamente de forma tabular los Casos de Uso (de la sección 3.4) con los Requisitos Funcionales (de la sección 3.5).
- Usa los **IDs jerárquicos** generados para vincular ambos elementos en la tabla.

### 4.5 Guard de Escala y Alcance

Antes de generar el documento, debes verificar la escala del proyecto:
1. **Alcance Opcional:** Ofrece al usuario la opción de limitar el alcance a ciertas capabilities. Si no se especifica, el alcance es todas.
2. **Conteo y Umbral:** Cuenta los escenarios (casos de uso) y requirements en el alcance.
3. Si el número de casos de uso supera el umbral configurable (por defecto ~40), debes detenerte, mostrar la estimación de tamaño y pedir confirmación u ofrecer acotar el alcance.
4. **Modo Agrupado:** Si el usuario decide continuar superando el umbral, activa el **modo agrupado**. En este modo:
   - Genera un solo diagrama de casos de uso (PlantUML) por capability, agrupando todos sus casos de uso.
   - **No** generes los diagramas de Mermaid (flujo/secuencia) por escenario.
   - Si se acota el alcance y queda por debajo del umbral, vuelve a generar un diagrama por escenario y sus diagramas Mermaid correspondientes.

## 5. Entrevista Guiada y Persistencia

Para las secciones que no pueden inferirse formalmente de las specs (Glosario de Términos 2.2, Objetivos de Negocio 3.1/3.2, y Actores y Procesos de Negocio 3.3), debes realizar una entrevista guiada corta al usuario. Asegúrate de preguntar tanto por los actores (quién usa el sistema) como por los procesos de negocio (flujos de trabajo clave).

### 5.1 Ejecución de la Entrevista

- **Primera vez:** Si no existe el archivo `docs/srs.meta.yaml`, realiza la entrevista completa para completar las secciones 2.2, 3.1, 3.2 y 3.3 (Actores y Procesos).
- **Prioridad (3.6):** En la misma entrevista, debes preguntar la prioridad (Deseable, Alta, Crítica, Media) de cada capability clasificada como Requisito No Funcional.
- **Atributos excepcionales (3.4):** Suma a la entrevista una única pregunta consolidada: "¿Algún requirement se sale de lo normal en riesgo, dependencia o dificultad?".
- **Persistencia:** Guarda todas las respuestas en `docs/srs.meta.yaml`.

### 5.2 Detección Incremental de Gaps

En cada regeneración posterior, debes implementar una **detección incremental de gaps**:
1. Lee `docs/srs.meta.yaml` primero.
2. Compara su contenido con el estado actual del proyecto.
3. Pregunta al usuario **solamente** por lo que sea nuevo (ej. una capability nueva en 3.6 sin prioridad asignada, un actor o término nuevo aparecido en un escenario reciente).
4. **Nunca** repitas preguntas ya respondidas; reutiliza las respuestas persistidas.

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
- Antes de sobrescribirlo, muestra al usuario un **resumen de los cambios** (qué secciones nuevas se agregan o qué contenido cambia significativamente).
- Pide **confirmación explícita** para proceder.
- **No sobrescribas** el archivo si el usuario no confirma o cancela la acción.

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

# Respuestas de la Entrevista Guiada
interview_done: true

glossary:
  - term: "API"
    definition: "Application Programming Interface"

objectives:
  - id: "OBJ-1"
    desc: "Reducir el tiempo de carga en un 20%"

actors:
  - name: "Administrador"
    desc: "Usuario con permisos totales sobre el sistema"

processes:
  - name: "Proceso de Autenticación"
    desc: "Flujo completo de registro, login y recuperación de contraseña"
```
