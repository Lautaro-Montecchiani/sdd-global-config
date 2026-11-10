## MODIFIED Requirements

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

### Requirement: El propose avisa si falta la ficha
Si a `openspec/config.yaml` le falta `## Alcance`, `## Datos`, `## Stack` o `## Calidad`, `/opsx:propose` SHALL avisarlo en el resumen final, nombrando lo que falta y sugiriendo `/ficha`, y NO SHALL preguntarlo ni bloquear el propose.

#### Scenario: Proyecto sin ficha
- **WHEN** se corre `/opsx:propose` en un proyecto sin `## Datos` ni `## Stack`
- **THEN** el propose sigue sin preguntar por ellos
- **AND** el resumen final dice que faltan `## Datos` y `## Stack` y sugiere `/ficha`

#### Scenario: Proyecto sin calidad
- **WHEN** se corre `/opsx:propose` en un proyecto con la ficha completa salvo `## Calidad`
- **THEN** el resumen final dice que falta `## Calidad` y sugiere `/ficha`
