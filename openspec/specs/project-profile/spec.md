# project-profile Specification

## Purpose
Define la ficha del proyecto (alcance de la versión, datos que maneja y stack), cómo se completa con la skill `/ficha` y cómo la usan el propose y el Agente para cuidar el alcance, la seguridad de los datos y las dependencias.
## Requirements
### Requirement: Formato de la ficha
El `context:` de `openspec/config.yaml` SHALL admitir `## Alcance` (`- versión: <Vn>`, ítems `- incluye: <ítem>` y `- no incluye: <ítem>`), `## Datos` (`- <dato>: <origen> (externo|propio) | <personal|interno|público>`), `## Stack` (claves `lenguaje`, `framework`, `base-de-datos`, `integraciones`, `librerias`) y `## Calidad` (`- <atributo>: <objetivo> | <alta|media|baja>`, con atributo `rendimiento`, `disponibilidad`, `escalabilidad`, `costo` o `mantenibilidad`). Solo se escriben las claves declaradas, sin valores de relleno.

#### Scenario: Alcance con versión
- **WHEN** un proyecto declara `## Alcance` con `- versión: V1`, `- incluye: alta de leads desde la web` y `- no incluye: integración con Salesforce`
- **THEN** la V1 incluye el alta de leads y deja afuera la integración con Salesforce

#### Scenario: Dato personal de origen externo
- **WHEN** `## Datos` declara `- leads (nombre, teléfono, email): formulario web (externo) | personal`
- **THEN** el dato leads es personal y viene de afuera

#### Scenario: Stack sin claves de relleno
- **WHEN** el proyecto no usa base de datos
- **THEN** `## Stack` no incluye la clave `base-de-datos`

#### Scenario: Atributo de calidad con prioridad
- **WHEN** `## Calidad` declara `- rendimiento: respuesta de la API < 500 ms p95 | alta`
- **THEN** el rendimiento es un atributo de prioridad alta con ese objetivo

#### Scenario: Calidad sin atributos de relleno
- **WHEN** al proyecto no le importa la escalabilidad
- **THEN** `## Calidad` no incluye la línea `escalabilidad`

### Requirement: La skill ficha completa lo que falta
La skill `/ficha` SHALL revisar la descripción del `context:`, `## Objetivos de Negocio`, `## Alcance`, `## Datos`, `## Stack` y `## Calidad`, y preguntar solo por lo que falta, proponiendo el stack que se infiere del repo (archivos de dependencias). Para `## Calidad` SHALL preguntar qué atributos importan, con su objetivo y prioridad, y ofrecer "Ninguno por ahora", que no escribe la subsección. SHALL escribir con edición quirúrgica y el aviso de 40 KB, y NO SHALL reescribir ni normalizar una subsección que ya existe, aunque tenga otro formato.

#### Scenario: Proyecto sin ficha
- **WHEN** se corre `/ficha` en un proyecto Python con `requirements.txt` y sin `## Alcance`, `## Datos` ni `## Stack`
- **THEN** pregunta por las tres, proponiendo un `## Stack` inferido de `requirements.txt`
- **AND** las escribe al final del `context:` sin tocar el resto

#### Scenario: Stack escrito a mano
- **WHEN** el proyecto ya tiene un `## Stack` en texto libre
- **THEN** `/ficha` no pregunta por el stack ni modifica esa subsección

#### Scenario: Ficha completa
- **WHEN** el proyecto ya tiene descripción, objetivos, alcance, datos, stack y calidad
- **THEN** `/ficha` informa que la ficha está completa y no escribe nada

#### Scenario: Falta solo la calidad
- **WHEN** el proyecto tiene todas las partes menos `## Calidad` y el usuario declara rendimiento con prioridad alta
- **THEN** `/ficha` escribe `## Calidad` al final del `context:` con la línea de rendimiento y no toca el resto

### Requirement: La ficha no guarda datos reales
`/ficha` SHALL registrar en `## Datos` solo categorías de datos y sus campos (por ejemplo, "nombre, teléfono, email"), y NO SHALL escribir valores reales (nombres, números, documentos ni direcciones de personas), aunque aparezcan en el repo o en la respuesta del usuario.

#### Scenario: Usuario que pega un ejemplo real
- **WHEN** el usuario responde con un ejemplo que contiene un teléfono y un email reales
- **THEN** `## Datos` registra solo los campos teléfono y email, sin los valores
- **AND** la skill recuerda que no hace falta pegar datos reales (Ley 25.326)

### Requirement: El propose avisa si falta la ficha
Si a `openspec/config.yaml` le falta `## Alcance`, `## Datos`, `## Stack` o `## Calidad`, `/opsx:propose` SHALL avisarlo en el resumen final, nombrando lo que falta y sugiriendo `/ficha`, y NO SHALL preguntarlo ni bloquear el propose.

#### Scenario: Proyecto sin ficha
- **WHEN** se corre `/opsx:propose` en un proyecto sin `## Datos` ni `## Stack`
- **THEN** el propose sigue sin preguntar por ellos
- **AND** el resumen final dice que faltan `## Datos` y `## Stack` y sugiere `/ficha`

#### Scenario: Proyecto sin calidad
- **WHEN** se corre `/opsx:propose` en un proyecto con la ficha completa salvo `## Calidad`
- **THEN** el resumen final dice que falta `## Calidad` y sugiere `/ficha`

### Requirement: El propose cuida el alcance
Si el change pide algo que coincide con un ítem `no incluye` de `## Alcance`, `/opsx:propose` SHALL preguntarlo una vez con tres opciones: seguir y pasar el ítem a `incluye`, seguir sin tocar el alcance, o cancelar el propose. Solo con la primera SHALL editar `## Alcance`.

#### Scenario: Pasar el ítem al alcance
- **WHEN** el change pide la integración con Salesforce, que figura como `- no incluye: integración con Salesforce`, y el usuario elige pasarla al alcance
- **THEN** la línea queda como `- incluye: integración con Salesforce` y el propose sigue

#### Scenario: Seguir sin tocar el alcance
- **WHEN** el usuario elige seguir sin tocar el alcance
- **THEN** `## Alcance` no cambia y el `proposal.md` lo menciona

#### Scenario: Cancelar
- **WHEN** el usuario elige cancelar
- **THEN** el propose termina sin crear el change

### Requirement: El Agente respeta el stack
La regla 4 del Agente SHALL decir que las librerías y servicios nuevos salen de `## Stack` o del `design.md` del change, y que si hace falta uno que no está en ninguno, el Agente frena y pregunta. El texto SHALL ser el mismo en el `CLAUDE.md` global y en las cuatro plantillas de reglas.

#### Scenario: Librería no prevista
- **WHEN** durante el apply el Agente quiere agregar una librería que no figura en `## Stack` ni en el design
- **THEN** frena y pregunta en vez de agregarla

#### Scenario: Texto en todas las fuentes
- **WHEN** se busca la oración de la regla 4 sobre `## Stack` en el `CLAUDE.md` global y en las cuatro plantillas
- **THEN** aparece igual en las cinco

