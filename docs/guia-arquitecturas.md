# Guía de arquitecturas para desarrolladores

Esta guía explica en lenguaje claro y accesible los conceptos fundamentales de arquitectura de software que usamos en el flujo SDD, pensada para entender el porqué de cada estructura sin necesidad de formación académica previa.

---

## 1. Para qué sirve esta guía y cómo usarla con /arquitectura

La arquitectura de software no es más que la forma en que organizamos las carpetas, archivos y responsabilidades de un proyecto para que siga siendo fácil de entender, testear y modificar a medida que crece.

En nuestro flujo de trabajo contamos con la skill `/arquitectura`. Cuando la ejecutás en una sesión con Claude en cualquier proyecto, Claude:
1. Releva el inventario de carpetas y archivos.
2. Identifica el nivel actual de la arquitectura.
3. Busca señales concretas en el código (por ejemplo, funciones que mezclan cálculos con llamadas a APIs externas o archivos enormes).
4. Si detecta señales, te propone subir un escalón en la escalera de arquitectura, explicando exactamente qué vio, qué problema trae y qué plan de migración conviene seguir.

Esta guía sirve como material de estudio y consulta para entender los conceptos detrás de ese diagnóstico, saber cuándo conviene cada estilo y evaluar con criterio las sugerencias de Claude.

---

## 2. La escalera de niveles de arquitectura

Para evitar la sobreingeniería (crear capas y abstracciones complejas antes de necesitarlas) y el desorden (código espagueti donde todo se mezcla), usamos una escalera de niveles progresivos. Cada nivel resuelve un problema concreto y solo se sube cuando el código muestra una **señal** evidente:

```
Nivel 3: Hexagonal / Clean / Monolito modular
  ▲      [Señal: múltiples integraciones externas cambiantes o varios dominios de negocio que se pisan]
  │
Nivel 2: Capas / Tuberías y filtros
  ▲      [Señal: consultas SQL o llamadas a APIs mezcladas en pantallas/rutas, o pasos de ETL acoplados]
  │
Nivel 1: Núcleo funcional
  ▲      [Señal: funciones que mezclan cálculos con I/O o son difíciles de testear sin servicios reales]
  │
Nivel 0: Sin estilo
         [Punto de partida: scripts chicos y prototipos sin señales de fricción]
```

Subir de escalón no es obligatorio ni un objetivo en sí mismo: un script simple que funciona bien y no tiene señales de conflicto puede quedarse para siempre en nivel 0 o nivel 1.

---

## 3. Paradigmas de programación y la escalera

Un paradigma es la forma o mentalidad con la que estructuramos el razonamiento del código:

- **Orientado a objetos (POO)**: Agrupa datos y las operaciones que actúan sobre ellos en "objetos" o clases. Es muy intuitivo para modelar entidades con identidad y ciclo de vida (como un Usuario o un Vehículo).
- **Funcional**: Trata a los programas como secuencias de funciones que reciben datos y devuelven datos nuevos, evitando mutar variables existentes o generar efectos secundarios imprevistos.
- **Mixto**: La mayoría de los lenguajes actuales (Python, TypeScript) combinan ambos: clases para representar estructuras o puertos, y funciones puras para calcular.

### Relación con la escalera

El paradigma funcional es la piedra angular del **Nivel 1 (Núcleo funcional)**. Cuando separamos las operaciones matemáticas o de negocio en funciones puras (que no leen archivos, ni hacen peticiones HTTP, ni consultan bases de datos), esas funciones se pueden testear al instante con datos de prueba simples, sin depender de mocks ni servicios levantados.

---

## 4. Catálogo de arquitecturas, estilos y patrones

A continuación se describen los estilos y patrones más conocidos de la industria, aterrizados a nuestro contexto.

### Capas

- **Qué es**: Organiza el código en niveles horizontales superpuestos: presentación (interfaz/rutas), negocio (reglas comerciales) y datos (base de datos y APIs externas). Cada capa solo conoce a la capa inferior.
- **Ejemplo tipo Yacopini**: Una API en FastAPI donde las rutas en `src/api/` reciben el request, llaman a `src/services/` para validar reglas comerciales y calculan descuentos, y este pide datos a `src/db/`.
- **¿Te va a tocar?**: Sí (nivel 2 de la escalera). Muy común en backends y aplicaciones web tradicionales.

### Hexagonal

- **Qué es**: Coloca la lógica del negocio en el centro, aislada del mundo exterior. Se comunica con el afuera mediante "puertos" (interfaces) y "adaptadores" (implementaciones concretas para base de datos, APIs de terceros, CLI o web).
- **Ejemplo tipo Yacopini**: El servicio de contactación de leads, donde la regla de negocio para calificar prospectos es independiente de si el mensaje se envía vía WhatsApp de Meta, Gupshup o un CRM externo.
- **¿Te va a tocar?**: A veces (nivel 3 de la escalera). Cuando un proyecto tiene múltiples integraciones externas que pueden cambiar de proveedor sin tocar las reglas.

### Clean

- **Qué es**: Variante de arquitectura concéntrica muy similar a la hexagonal, formalizada por Robert C. Martin. Las dependencias van estrictamente de afuera hacia adentro (frameworks → controladores → casos de uso → entidades).
- **Ejemplo tipo Yacopini**: Un sistema de cotización de vehículos usados donde los casos de uso (calcular valor de toma) son independientes del framework web y de la base de datos.
- **¿Te va a tocar?**: A veces (nivel 3 de la escalera). En la práctica comparte el mismo nivel y reglas `no importa:` que la arquitectura hexagonal.

### Microservicios

- **Qué es**: Divide una solución en decenas de pequeñas aplicaciones autónomas que corren en servidores o contenedores separados y se comunican exclusivamente por red (HTTP, gRPC, colas).
- **Ejemplo tipo Yacopini**: Tener un microservicio exclusivo para ventas de salón, otro para facturación, otro para repuestos y otro para turnos de taller, cada uno con base de datos propia.
- **¿Te va a tocar?**: Probablemente no. Para el tamaño de nuestro equipo y volumen actual, los microservicios introducen una sobrecarga de mantenimiento de redes, despliegues y transacciones distribuidas innecesaria. Es preferible un monolito modular. Cuándo sí convendrían: equipos separados que despliegan cada servicio por su cuenta, o partes del sistema que necesitan escalar de forma independiente.

### EDA (Arquitectura orientada a eventos)

- **Qué es**: Los componentes se desacoplan emitiendo y escuchando eventos asíncronos ("LeadIngresado", "VehiculoEntregado") a través de un intermediario o cola de mensajes.
- **Ejemplo tipo Yacopini**: Al entrar un nuevo lead desde una landing page, se emite un evento que en paralelo dispara la notificación al asesor, la creación en el CRM y la actualización del tablero de métricas.
- **¿Te va a tocar?**: A veces. Aparece naturalmente al conectar flujos de n8n, webhooks o tareas en segundo plano.

### Monolito modular

- **Qué es**: Un único repositorio y despliegue unificado, pero estructurado internamente en módulos de dominio bien delimitados con interfaces públicas estrictas que impiden dependencias cruzadas caóticas.
- **Ejemplo tipo Yacopini**: Un sistema de gestión donde `src/modulos/ventas/`, `src/modulos/posventa/` y `src/modulos/repuestos/` funcionan de forma autónoma y solo interactúan a través de fachadas públicas documentadas.
- **¿Te va a tocar?**: Sí (nivel 3 de la escalera). La opción predilecta cuando una aplicación centralizada crece y maneja múltiples áreas de negocio.

### SOA (Arquitectura orientada a servicios)

- **Qué es**: Enfoque empresarial clásico anterior a los microservicios donde sistemas corporativos grandes exponen contratos de servicio formales coordinados por un bus central (ESB), usualmente mediante SOAP/XML.
- **Ejemplo tipo Yacopini**: La integración formal requerida por terminales automotrices o entidades bancarias para la consulta de garantías o aprobación de créditos prendarios.
- **¿Te va a tocar?**: Probablemente no. En desarrollos propios usamos APIs REST ligeras; solo interactuamos con SOA cuando nos conectamos a servicios heredados de terceros.

### Serverless

- **Qué es**: Ejecución de funciones en la nube bajo demanda (ej. Cloud Functions o AWS Lambda) que se activan por eventos puntuales y no requieren administrar servidores permanentes.
- **Ejemplo tipo Yacopini**: Una función serverless que procesa el webhook de un formulario de contacto, valida los campos, sanitiza el teléfono y lo encola en n8n, pagando solo por los segundos de ejecución.
- **¿Te va a tocar?**: A veces. Ideal para tareas específicas, webhooks esporádicos o pequeños scripts utilitarios.

### Tuberías y filtros (Pipes & Filters)

- **Qué es**: Procesa un flujo de datos haciéndolo pasar por una cadena de componentes independientes (filtros), donde la salida de cada paso alimenta directamente al siguiente.
- **Ejemplo tipo Yacopini**: Los procesos ETL de patentamientos o leads: `extract` (descargar reporte o Excel), `transform` (normalizar nombres, documentos y teléfonos) y `load` (insertar en PostgreSQL o BigQuery).
- **¿Te va a tocar?**: Sí (nivel 2 de la escalera). Es la arquitectura natural para proyectos clasificados como `etl` o `scripts`.

### Microkernel (Arquitectura de plugins)

- **Qué es**: Un núcleo mínimo (core) que gestiona el flujo general del sistema y una serie de complementos o plugins intercambiables que agregan soporte para casos específicos sin tocar el núcleo.
- **Ejemplo tipo Yacopini**: Un bot de scraping donde el núcleo maneja la navegación, colas y almacenamiento, y existen plugins independientes para cada portal de clasificados automotores.
- **¿Te va a tocar?**: A veces. Muy útil cuando necesitamos sumar nuevos proveedores o fuentes de datos de forma regular.

### Cliente-servidor y P2P

- **Qué es**: En cliente-servidor, los clientes solicitan recursos o servicios a un servidor centralizado. En P2P (peer-to-peer), cada nodo actúa simultáneamente como cliente y servidor sin entidad central.
- **Ejemplo tipo Yacopini**: Toda aplicación web interna donde el navegador (cliente) se comunica con una API alojada en la nube (servidor). Las redes P2P no aplican al negocio de la concesionaria.
- **¿Te va a tocar?**: Cliente-servidor sí (estándar omnipresente); P2P probablemente no.

### DDD (Diseño guiado por el dominio)

- **Qué es**: Filosofía de diseño que modela el software reflejando con fidelidad el lenguaje y las reglas del negocio, utilizando patrones tácticos como Entidades, Objetos de Valor (Value Objects) y Agregados.
- **Ejemplo tipo Yacopini**: Modelar una "OperacionComercial" asegurando que ninguna unidad se entregue sin la seña correspondiente ni sin documentación firmada, usando la misma terminología que el equipo de salón y administración.
- **¿Te va a tocar?**: A veces. Es un complemento metodológico para niveles 2 y 3 cuando las reglas de negocio son complejas.

### MVC, MVP y MVVM

- **Qué es**: Familia de patrones de interfaz para separar los datos (Modelo) de la pantalla (Vista) y de la lógica de presentación (Controlador, Presentador o VistaModelo reactivo).
- **Ejemplo tipo Yacopini**: Un tablero de control de stock donde los componentes visuales de React reaccionan automáticamente a los cambios de estado manejados por un hook o store (MVVM).
- **¿Te va a tocar?**: Sí (nivel 2 para interfaces de usuario). Viene integrado por defecto en la mayoría de los frameworks frontend modernos.

### Patrones GoF (Gang of Four)

- **Qué es**: Catálogo clásico de 23 patrones de diseño orientado a objetos (como Factory, Strategy, Adapter, Observer o Singleton) que resuelven problemas recurrentes a nivel de clases y métodos.
- **Ejemplo tipo Yacopini**: Aplicar un patrón *Strategy* para calcular diferentes esquemas de bonificaciones según el plan de ahorro, o un *Adapter* para unificar formatos de respuesta de distintos bancos.
- **¿Te va a tocar?**: Sí. No estructuran la carpeta completa del repo, sino que son soluciones tácticas dentro de los archivos de cualquier nivel.

### Paradigma funcional

- **Qué es**: Enfoque de programación basado en componer funciones puras que transforman datos sin producir efectos colaterales (I/O, mutaciones de variables globales).
- **Ejemplo tipo Yacopini**: Un módulo de validación y limpieza de teléfonos que toma una lista de strings crudos y devuelve una lista de teléfonos en formato internacional, sin tocar bases de datos ni archivos.
- **¿Te va a tocar?**: Sí (base fundamental del nivel 1 de la escalera). Es la base para que cualquier cálculo sea confiable y fácilmente testeable.

---

## 5. Cómo leer una recomendación de Claude

Cuando ejecutás `/opsx:propose` en un change que toca archivos con señales o cuando corrés la skill `/arquitectura`, Claude presenta una recomendación estructurada con estas partes:

1. **Qué vi**: Cita con precisión quirúrgica los archivos existentes, número de líneas y nombres de funciones o responsabilidades acopladas.
2. **Qué problema trae**: Explica por qué esa situación actual dificulta los tests, incrementa el riesgo de regresiones o complica el mantenimiento futuro.
3. **Qué propongo**: Especifica el nivel sugerido de la escalera, las carpetas correspondientes y las reglas de importación prohibidas (`no importa:`).
4. **Cuánto cuesta**: Estima los archivos que requerirán reubicación y evalúa si la migración puede realizarse gradualmente.
5. **Qué descarté**: Menciona las alternativas descartadas (como saltar a un nivel superior innecesario o no hacer nada) y los motivos de la decisión.
6. **Pautas para el Agente**: Reglas de implementación que el agente constructor deberá respetar al escribir el código nuevo.

### ¿Qué preguntar si no se entiende?

Si la recomendación no te resulta intuitiva, podés repreguntarle a Claude antes de decidir:
- *"¿Por qué considerás que esta función mezcla responsabilidades?"*
- *"¿Podemos hacer esta refactorización en un change aparte para no demorar la entrega actual?"*
- *"¿Cómo quedaría el código del cálculo una vez separado de la base de datos?"*

La decisión final siempre es tuya: podés aplicar la recomendación en el change, planificarla para un change aparte o rechazarla por el momento.

---

## 6. Glosario corto

- **Efecto secundario (Side effect)**: Modificar variables externas a una función, escribir en disco, realizar llamadas de red o alterar el estado global durante la ejecución.
- **Función pura**: Función que, ante los mismos argumentos de entrada, siempre retorna el mismo resultado y no produce ningún efecto secundario.
- **I/O (Input/Output)**: Cualquier interacción con el exterior del proceso: leer o escribir archivos, bases de datos, APIs de red, consola o reloj del sistema.
- **Acoplamiento**: Grado de interdependencia entre dos módulos o componentes; un acoplamiento alto significa que cambiar uno obliga a cambiar el otro.
- **Cohesión**: Medida en que las funciones dentro de un módulo pertenecen a una única responsabilidad bien definida.
- **Inversión de dependencias**: Principio de diseño donde los módulos centrales de negocio no dependen de librerías externas o bases de datos, sino de contratos abstractos (puertos o interfaces).
