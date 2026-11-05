---
name: ficha
description: Completa la ficha del proyecto (descripción, objetivos, alcance, datos y stack) en openspec/config.yaml sin reescribir lo que ya existe.
license: MIT
metadata:
  version: "1.0"
---

Completa la ficha del proyecto (descripción, objetivos, alcance, datos y stack) en `openspec/config.yaml` sin reescribir lo que ya existe.

**Restricciones de ejecución:**
- Esta skill no crea changes, ramas ni commits, y no escribe en el Obsidian vault.
- **Security Layer:**
  - Solo lee código, sin ejecutarlo.
  - No lee archivos ni directorios ignorados por `.gitignore`, ni archivos sensibles: `*.env`, `*.key`, `*.pem`, `*.p12`, ni la carpeta `secrets/`.
  - **Nunca escribe valores reales de datos**, solo categorías y nombres de campos (por ejemplo: `leads (nombre, teléfono, email)`). Si el usuario pega un ejemplo con datos de una persona real, la skill usa únicamente los nombres de los campos y le recuerda que no hace falta pegarlos (Ley 25.326 de Protección de los Datos Personales).
  - La única escritura permitida es en `openspec/config.yaml` al completar las partes faltantes de la ficha, siempre con edición quirúrgica y respetando el límite de 40 KB.

---

## Formato de la ficha en `context:`

La ficha del proyecto se organiza en subsecciones dentro del bloque `context:` de `openspec/config.yaml`. Solo se escriben las claves declaradas, sin valores de relleno:

- **Descripción**: primera línea de texto libre dentro de `context:`, antes del primer encabezado `##`. Responde qué hace la aplicación.
- **`## Objetivos de Negocio`**: lista con formato `- <id>: <descripción>`.
- **`## Alcance`**:
  ```yaml
  ## Alcance
  - versión: V1
  - incluye: alta de leads desde la web
  - no incluye: integración con Salesforce
  ```
  Lleva `- versión: <Vn>` (por defecto `V1`), una línea `- incluye: <ítem>` por cada funcionalidad de la versión y una línea `- no incluye: <ítem>` por cada ítem que queda para versiones posteriores.
- **`## Datos`**:
  ```yaml
  ## Datos
  - leads (nombre, teléfono, email): formulario web (externo) | personal
  ```
  Formato: `- <dato> (<campos>): <origen> (externo|propio) | <personal|interno|público>`.
  - **Origen**: `externo` si entra desde afuera del sistema (formularios, archivos Excel, APIs, webhooks, scraping); `propio` si el sistema lo genera internamente o reside en su base de datos.
  - **Tipo**: `personal` para cualquier dato de personas físicas identificables (sujeto a Ley 25.326); `interno` para datos operativos del negocio sin información de personas; `público` para información de acceso general ya publicada.
- **`## Stack`**:
  ```yaml
  ## Stack
  - lenguaje: Python 3.11
  - framework: FastAPI
  - base-de-datos: PostgreSQL 15
  - integraciones: Salesforce API
  - librerias: pydantic, httpx
  ```
  Claves admitidas: `lenguaje`, `framework`, `base-de-datos`, `integraciones` y `librerias`, en ese orden. Cada una con valores separados por coma y la versión mayor si se conoce. No se incluyen claves de tecnologías que el proyecto no use.

---

## Pasos

1. **Lectura de `openspec/config.yaml`**
   - Lee `openspec/config.yaml`.
   - Si el archivo no existe, o no tiene un bloque `context:` activo (o está comentado), o le falta `project_type`, completa los campos faltantes según las reglas del esquema de configuración (solicitando `project_type` una sola vez si no se puede inferir).

2. **Revisión de partes existentes**
   - Evalúa si están presentes las cinco partes de la ficha:
     1. Línea de descripción general (texto previo al primer `##` en `context:`).
     2. `## Objetivos de Negocio`.
     3. `## Alcance`.
     4. `## Datos`.
     5. `## Stack`.
   - **Regla de respeto a lo existente**: una parte se considera presente si su encabezado existe en el archivo, en cualquier formato (texto libre, viñetas, etc.). No se reescribe ni se normaliza nada que el proyecto ya tenga definido.

3. **Verificación de ficha completa**
   - Si ninguna de las cinco partes falta, informa al usuario: "La ficha del proyecto ya está completa" y termina la ejecución sin realizar escrituras.

4. **Entrevista guiada (para lo que falta)**
   - Formula una sola consulta interactiva (`AskUserQuestion`) con hasta cuatro preguntas para relevar únicamente lo que falte. (Si faltan las cinco partes, solicita primero la descripción y objetivos, y en una segunda tanda el alcance, datos y stack).
   - Donde sea posible, propone opciones concretas basadas en la inspección del repositorio:
     - **Stack**: infiere lenguaje, framework y librerías inspeccionando archivos de dependencias (`requirements.txt`, `pyproject.toml`, `package.json`, `*.csproj`, `go.mod`). Ofrece: "Usar el inferido", "Corregirlo" o "No sé (dejar el inferido con `# inferido — revisar`)".
     - **Datos**: sugiere categorías a partir de nombres de modelos, tablas, columnas o campos en formularios (sin leer contenidos ni valores reales de datos), consultando el origen (`externo` o `propio`) y tipo (`personal`, `interno` o `público`).
     - **Alcance**: consulta la versión (sugiriendo `V1`), funcionalidades que incluye y cuáles quedan explícitamente fuera (`no incluye`).

5. **Escritura quirúrgica en `openspec/config.yaml`**
   - Escribe las partes faltantes siempre al final del `context:`, después de todo el contenido existente, en este orden: `## Alcance`, `## Datos` y `## Stack`. Si alguna de las tres ya existe más arriba (por ejemplo, un `## Stack` escrito a mano), las que faltan igual van al final: no se intercalan para respetar el orden.
   - La descripción se ubica en la primera línea de texto de `context:`, y `## Objetivos de Negocio` antes de las subsecciones técnicas.
   - Aplica edición quirúrgica acotada, controlando no exceder los 40 KB en el bloque `context:`.

6. **Resumen final**
   - Presenta un resumen con:
     - Qué partes se agregaron.
     - Qué valores quedaron marcados como `# inferido — revisar` (si los hubo).
     - Recordatorio al usuario de revisar y commitear los cambios en `openspec/config.yaml`.
