# Recetas de arquitectura

| `nivel` | Receta | Mínimo de reglas |
|---|---|---|
| `0` | Sin estilo | 0 |
| `1-nucleo-funcional` | Núcleo funcional: cálculos separados de conexiones | 1 |
| `2-tuberias` | Tuberías y filtros (ETL) | 1 |
| `2-capas` | Capas: presentación, negocio y datos | 2 |
| `3-hexagonal` | Hexagonal / Clean: dominio aislado con puertos y adaptadores | 2 |
| `3-modular` | Monolito modular: un módulo por dominio de negocio | 2 |

Los nombres de carpeta son sugerencias: si el proyecto ya tiene carpetas con ese papel, se usan esas y se respeta la relación de la regla.

---

## 1-nucleo-funcional

**Señales**: una función o archivo mezcla I/O (leer o escribir archivos, red, base de datos, APIs, logs) con cálculos; un cálculo no se puede testear sin un archivo o servicio real; la misma transformación aparece copiada en varios lugares; un archivo supera la advertencia de tamaño mezclando I/O y cálculos.

**Carpetas tipo**: (base `src/<paquete>/` en Python, `src/` en TS/JS): `nucleo/` (cálculos: entran datos, salen datos), `conexiones/` (leer y escribir archivos, DB, APIs, logs) y el script o archivo de entrada, que orquesta.

**Reglas `no importa:`**: `nucleo/ | no importa: conexiones/`.

**Mínimo de reglas**: 1

**Pautas para el Agente**: las funciones del núcleo reciben datos y devuelven datos nuevos, sin modificar sus argumentos; no usan variables globales modificables; no leen configuración ni variables de entorno (la entrada se las pasa); sus tests no necesitan mocks de servicios.

**Cuándo no aplicarla**: scripts de menos de unas 150 líneas de uso único; código que es casi todo I/O sin cálculos (copiar o mover archivos).

**Adaptación por `project_type`**: natural en `etl`/`scripts`; en `backend-api`, `src/services/` hace de núcleo y `src/db/` de conexiones; en `frontend`, la lógica de formateo y validación sale de los componentes hacia `src/lib/nucleo/`; en `tooling`/`config` normalmente no aplica.

---

## 2-tuberias

**Señales**: los pasos de un ETL (extraer, transformar, cargar) están en un solo archivo o función; se quiere correr o repetir un paso solo; agregar una fuente o un destino obliga a tocar la transformación.

**Carpetas tipo**: `src/<paquete>/extract/`, `transform/`, `load/` y `scripts/` (entradas que encadenan los pasos).

**Reglas `no importa:`**: `transform/ | no importa: extract/, load/` y `extract/ | no importa: load/`.

**Mínimo de reglas**: 1

**Pautas para el Agente**: cada paso recibe y devuelve datos en un formato acordado y documentado en el design; `transform/` sigue las pautas del núcleo funcional; un paso no llama al siguiente, sino que lo encadena la entrada.

**Cuándo no aplicarla**: un único paso, o una transformación trivial.

**Adaptación por `project_type`**: `etl`/`scripts`; en otros tipos, solo para procesos batch internos.

---

## 2-capas

**Señales**: rutas, controladores o pantallas con SQL o llamadas a APIs adentro; la misma regla de negocio repetida en varias rutas; cambiar la base de datos obliga a tocar pantallas o rutas.

**Carpetas tipo**: `src/presentacion/` (rutas, controladores, vistas), `src/negocio/` (reglas y servicios) y `src/datos/` (acceso a DB y APIs).

**Reglas `no importa:`**: `presentacion/ | no importa: datos/`, `negocio/ | no importa: presentacion/` y `datos/ | no importa: presentacion/, negocio/`.

**Mínimo de reglas**: 2

**Pautas para el Agente**: la presentación valida formato y llama a negocio; negocio no conoce HTTP (ni request ni response); datos devuelve estructuras simples, no objetos de la librería de base de datos.

**Cuándo no aplicarla**: apps con dos o tres pantallas de alta, baja y modificación sin reglas; frameworks que ya imponen su estructura (por ejemplo, las colecciones de Payload): ahí se sigue el framework.

**Adaptación por `project_type`**: en `backend-api` usa la fila sugerida existente (`src/api/`, `src/services/`, `src/db/`); en `fullstack` (una app), `src/app/` y `src/frontend/` son presentación y `src/backend/` es negocio y datos, con la prohibición existente.

---

## 3-hexagonal

**Señales**: hay que poder cambiar una integración (Salesforce por otro CRM, Excel por una API) sin tocar las reglas; las mismas reglas se usan desde varias entradas (web, script, bot); los tests de negocio siguen siendo lentos porque dependen de integraciones, aun con capas.

**Carpetas tipo**: `src/dominio/` (entidades y reglas), `src/aplicacion/` (casos de uso), `src/puertos/` (interfaces que el dominio necesita) y `src/adaptadores/` (DB, APIs, web, CLI).

**Reglas `no importa:`**: `dominio/ | no importa: aplicacion/, adaptadores/`, `aplicacion/ | no importa: adaptadores/` y `puertos/ | no importa: adaptadores/`.

**Mínimo de reglas**: 2

**Pautas para el Agente**: el dominio no importa frameworks ni librerías de I/O; los adaptadores implementan los puertos; los casos de uso reciben los puertos por parámetro.

**Cuándo no aplicarla**: una sola integración que no va a cambiar; una app chica mantenida por una persona (alcanza con capas).

**Adaptación por `project_type`**: `backend-api` y `fullstack` con varias integraciones.

---

## 3-modular

**Señales**: varios dominios de negocio (ventas, posventa, repuestos) en el mismo código que se pisan; un cambio en un dominio rompe otro; archivos compartidos que tocan todos.

**Carpetas tipo**: `src/modulos/<dominio>/` (cada uno ordenado por dentro con el nivel 1 o 2) y `src/compartido/` (tipos y utilidades sin lógica de dominio).

**Reglas `no importa:`**: `src/compartido/ | no importa: src/modulos/` y, por cada módulo, `src/modulos/<a>/ | no importa: src/modulos/<b>/` para los que no deben conocerse.

**Mínimo de reglas**: 2

**Pautas para el Agente**: cada módulo expone un único archivo de entrada pública y los demás usan solo ese; no se comparten tablas entre módulos sin una decisión en el design.

**Cuándo no aplicarla**: un solo dominio de negocio.

**Adaptación por `project_type`**: `fullstack` y `backend-api` grandes.
