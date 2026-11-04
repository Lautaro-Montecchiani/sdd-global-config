# architecture-advisor Specification

## Purpose
Define cómo Claude asesora sobre la arquitectura de un proyecto a medida que se desarrolla: la escalera de niveles y sus recetas, la recomendación con evidencia en el propose, el diagnóstico de proyectos existentes y la guía para estudiar.

## Requirements

### Requirement: Escalera de niveles
La arquitectura de un proyecto SHALL describirse con una escalera de cuatro niveles: 0 sin estilo, 1 núcleo funcional (cálculos separados de conexiones), 2 capas o tuberías y filtros, y 3 hexagonal o monolito modular. El nivel 0 SHALL ser válido. Claude SHALL recomendar subir de nivel solo cuando encuentre en el código una señal que la receta del nivel siguiente nombra, y NO SHALL recomendar un nivel por teoría o por tipo de proyecto solamente.

#### Scenario: Script chico sin señales
- **WHEN** un proyecto es un script de normalización de 80 líneas y ninguna señal de las recetas aparece en su código
- **THEN** Claude no recomienda subir de nivel
- **AND** el proyecto puede quedar en nivel 0

#### Scenario: Señal concreta
- **WHEN** una función del proyecto lee un Excel, normaliza los datos y los sube a un servicio externo, y por eso no se puede testear sin el Excel ni el servicio
- **THEN** Claude puede recomendar el nivel 1, citando el archivo y la función

### Requirement: Recetas por nivel
Cada nivel distinto de 0 SHALL tener al menos una receta, instalada con la skill `arquitectura`, con: las señales que la justifican, las carpetas tipo y su propósito, las reglas `no importa:` que genera, la cantidad mínima de reglas `no importa:` que exige, pautas para el Agente que el verify no puede controlar, cuándo no aplicarla y su adaptación por `project_type`.

#### Scenario: Contenido de una receta
- **WHEN** se lee la receta del nivel 1
- **THEN** tiene las siete partes del requirement
- **AND** su mínimo de reglas `no importa:` es al menos 1

#### Scenario: Variantes de un nivel
- **WHEN** se leen las recetas del nivel 2
- **THEN** hay una receta para capas y otra para tuberías y filtros, cada una con sus siete partes

#### Scenario: Criterio de desempate
- **WHEN** un proyecto con una sola fuente y un solo destino muestra señales de `1-nucleo-funcional` y de `2-tuberias`
- **THEN** la recomendación es `1-nucleo-funcional`, la de nivel más bajo que resuelve las señales

### Requirement: El propose recomienda un nivel con evidencia
Cuando un change cruza una señal de la receta del nivel siguiente al declarado, `/opsx:propose` SHALL agregar al `design.md` una sección `## Recomendación de arquitectura` con cinco partes: qué vio (archivos concretos), qué problema trae, qué propone (nivel, carpetas y reglas), cuánto cuesta y qué descartó. Si el change no cruza ninguna señal, el design NO SHALL incluir esa sección.

#### Scenario: Change que cruza una señal
- **WHEN** el change va a agrandar un archivo que ya mezcla lectura de archivos, cálculos y escritura en un servicio externo
- **THEN** el `design.md` incluye `## Recomendación de arquitectura` con las cinco partes

#### Scenario: Change sin señales
- **WHEN** el change no cruza ninguna señal de las recetas
- **THEN** el `design.md` no incluye `## Recomendación de arquitectura`

#### Scenario: Señal excluida por la receta
- **WHEN** el change toca un script de menos de 150 líneas con una transformación repetida, y la receta del nivel 1 dice que no se aplica a scripts de ese tamaño
- **THEN** el `design.md` no incluye `## Recomendación de arquitectura`

### Requirement: El usuario decide sobre la recomendación
Ante una recomendación, `/opsx:propose` SHALL preguntar al usuario una vez, con tres opciones: aplicarla en este change, aplicarla en un change aparte o no aplicarla todavía. Solo si elige aplicarla en este change, SHALL escribir en `## Arquitectura` el `nivel`, las carpetas y las reglas de la receta con edición quirúrgica, y `tasks.md` SHALL incluir las tareas para mover el código.

#### Scenario: Aplicar en este change
- **WHEN** el usuario elige aplicar la recomendación en este change
- **THEN** `## Arquitectura` queda con el `nivel` y las carpetas y reglas de la receta
- **AND** `tasks.md` incluye las tareas para mover el código a esas carpetas

#### Scenario: No aplicar todavía
- **WHEN** el usuario elige no aplicarla todavía
- **THEN** `## Arquitectura` no cambia
- **AND** la recomendación queda en el `design.md` como registro

#### Scenario: Change aparte
- **WHEN** el usuario elige aplicarla en un change aparte
- **THEN** `## Arquitectura` no cambia en este change
- **AND** el resumen final del propose sugiere crear el issue del change de refactor

### Requirement: Señal de tamaño en proyectos nuevos
Cuando `/opsx:propose` escribe `## Arquitectura` por primera vez en un proyecto sin archivos de código fuera de las carpetas implícitas, SHALL agregar `- tamaño: 500, 1000`. En un proyecto que ya tiene código, NO SHALL agregar `tamaño` salvo que el usuario apruebe una recomendación de nivel o lo pida.

#### Scenario: Proyecto nuevo
- **WHEN** se corre el primer propose en un repo que solo tiene `README.md`, `openspec/` y `.gitignore`
- **THEN** `## Arquitectura` queda con `- tamaño: 500, 1000`

#### Scenario: Proyecto existente
- **WHEN** se corre el propose en un repo con código que no declara `## Arquitectura`
- **THEN** la `## Arquitectura` que se escribe no incluye `tamaño`

### Requirement: Diagnóstico con la skill arquitectura
La skill `/arquitectura` SHALL diagnosticar el proyecto actual sin crear un change ni modificar archivos de código. El informe SHALL incluir el nivel actual con evidencia, las señales encontradas con archivos concretos, la recomendación con las cinco partes y un plan de migración en changes chicos, de a una responsabilidad por change. Sin señales, SHALL decir que el nivel actual alcanza.

#### Scenario: Proyecto con un archivo enorme
- **WHEN** se corre `/arquitectura` en un proyecto cuyo `app.py` tiene más de 1000 líneas y mezcla rutas, cálculos y acceso a la base de datos
- **THEN** el informe cita `app.py`, su tamaño y las responsabilidades que mezcla
- **AND** propone un plan con un change por responsabilidad

#### Scenario: Proyecto ordenado
- **WHEN** se corre `/arquitectura` en un proyecto sin señales de las recetas
- **THEN** el informe dice que el nivel actual alcanza y no recomienda cambios

### Requirement: La skill arquitectura escribe solo con aprobación
Después del informe, `/arquitectura` SHALL preguntar si se adopta la recomendación. Solo con aprobación SHALL escribir en `## Arquitectura` el `nivel`, las carpetas, las reglas y `tamaño`, con edición quirúrgica y el aviso de 40 KB, y sugerir crear el issue del primer change de refactor. Sin aprobación, NO SHALL escribir nada.

#### Scenario: Recomendación aprobada
- **WHEN** el usuario aprueba la recomendación
- **THEN** `## Arquitectura` queda con `nivel`, carpetas, reglas y `tamaño`
- **AND** el resto del `context:` no cambia

#### Scenario: Recomendación no aprobada
- **WHEN** el usuario no aprueba la recomendación
- **THEN** `openspec/config.yaml` queda sin cambios

### Requirement: Guía para estudiar
El repo SHALL incluir `docs/guia-arquitecturas.md`, escrita para alguien que no estudió arquitectura de software. SHALL explicar en simple la escalera de niveles, cada estilo y paradigma del catálogo (capas, hexagonal, clean, microservicios, EDA, monolito modular, SOA, serverless, tuberías y filtros, microkernel, cliente-servidor, P2P, DDD, MVC, patrones GoF y funcional) con un ejemplo de proyecto tipo Yacopini, y decir cuáles probablemente no se usen.

#### Scenario: Estilo de topología
- **WHEN** se busca microservicios en la guía
- **THEN** la explicación dice cuándo conviene y por qué probablemente no se use en los proyectos actuales

#### Scenario: Relación con la escalera
- **WHEN** se lee la explicación del paradigma funcional
- **THEN** la guía la relaciona con el nivel 1 de la escalera
