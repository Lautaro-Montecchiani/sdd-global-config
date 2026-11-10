# Spec Delta

## Purpose
Define cómo Claude clasifica un pedido que cambia archivos del proyecto como ODD (flujo liviano) o SDD (ciclo OpenSpec completo): la lista cerrada de criterios, qué criterios puede pasar por alto el usuario y qué pasa ante la duda.

## ADDED Requirements

### Requirement: Clasificar antes de escribir artefactos
Ante todo pedido que implique cambiar archivos del proyecto, Claude SHALL clasificarlo como ODD o SDD antes de escribir cualquier artefacto, y SHALL anunciar en una línea la clasificación y los criterios que la justifican. Las preguntas y el `/opsx:explore` NO SHALL clasificarse.

#### Scenario: Pedido chico
- **WHEN** el usuario pide corregir un typo en un mensaje cuyo texto correcto ya está en una spec vigente
- **THEN** Claude anuncia "ODD" con el motivo en una línea antes de escribir el documento

#### Scenario: Pregunta
- **WHEN** el usuario pregunta qué hace un archivo
- **THEN** Claude responde sin clasificar

### Requirement: Criterios SDD
Claude SHALL clasificar como SDD todo pedido que cumpla al menos uno de estos criterios, y como ODD el que no cumpla ninguno:
- K1: agrega o quita un comportamiento descrito en una spec vigente, crea una capability nueva o modifica requirements de más de una capability (modificar requirements existentes de una sola capability no cumple K1: va por ODD con un cambio mínimo de spec);
- K2: toca un dato declarado en `## Datos` como `(externo)` o `personal`;
- K3: toca autenticación, permisos, manejo de secretos o un control de la Security Layer;
- K4: agrega, quita o actualiza dependencias;
- K5: cambia un contrato hacia afuera (endpoints, formato de archivos, flags de CLI o esquema de base de datos);
- K6: cambia el nivel de arquitectura o mueve código entre capas o módulos;
- K7: toca más de 5 archivos, sin contar tests ni documentación;
- K8: el "qué" no está claro y hay alternativas que el usuario tiene que elegir;
- K9: el usuario pide SDD;
- K10: cumple un criterio de ADR del rol de arquitecto (elige o cambia una tecnología de `## Stack`, cambia el `nivel` de `## Arquitectura`, suma o cambia una integración externa, adopta un patrón transversal o resuelve un compromiso entre dos atributos de calidad).

Ante la duda sobre un criterio, Claude SHALL considerarlo cumplido.

#### Scenario: Modificación de una spec
- **WHEN** una spec vigente dice que el mensaje de bienvenida es "Hola, {nombre}" y el usuario pide cambiarlo a "Buen día, {nombre}"
- **THEN** la clasificación es ODD con un cambio mínimo de spec, porque modifica un requirement existente de una sola capability

#### Scenario: Comportamiento nuevo
- **WHEN** el usuario pide agregar un mensaje de despedida que ninguna spec describe
- **THEN** la clasificación es SDD por K1

#### Scenario: Bug contra una spec vigente
- **WHEN** el código muestra "Hla, {nombre}" y la spec vigente dice "Hola, {nombre}"
- **THEN** la clasificación es ODD, porque corregirlo no cambia la spec

#### Scenario: Pedido ambiguo
- **WHEN** el usuario pide "mejorar los mensajes" sin decir cómo
- **THEN** la clasificación es SDD por K8

#### Scenario: Decisión de arquitectura
- **WHEN** el usuario pide agregar logging estructurado en todos los módulos
- **THEN** la clasificación es SDD por K10

### Requirement: Cambio de clasificación por el usuario
El usuario SHALL poder pasar cualquier pedido de ODD a SDD. SHALL poder pasar un pedido de SDD a ODD solo si ninguno de los criterios cumplidos es K1, K2, K3 o K10; en ese caso, el documento ODD SHALL anotar en `## Clasificación` qué criterio se pasó por alto y por pedido de quién. Si se cumple K1, K2, K3 o K10, Claude NO SHALL ofrecer ni aceptar ODD.

#### Scenario: Dato externo
- **WHEN** el usuario pide validar que el teléfono del formulario (declarado `(externo) | personal`) no venga vacío y después pide hacerlo por ODD
- **THEN** Claude responde que va por SDD por K2 y no crea el documento ODD

#### Scenario: Criterio que se puede pasar por alto
- **WHEN** un pedido cumple solo K7 y el usuario pide ODD
- **THEN** Claude crea el documento ODD
- **AND** `## Clasificación` dice que K7 se pasó por alto a pedido del usuario

#### Scenario: Comportamiento nuevo pedido por ODD
- **WHEN** un pedido agrega un comportamiento que ninguna spec describe y el usuario pide ODD
- **THEN** Claude responde que va por SDD por K1 y no crea el documento ODD

#### Scenario: Criterio de ADR
- **WHEN** un pedido cumple K10 y el usuario pide ODD
- **THEN** Claude responde que va por SDD por K10 y no crea el documento ODD

### Requirement: Escalado a SDD
Si durante un ODD se cumple un criterio SDD (porque el Agente lo detecta al implementar o porque el verify lo encuentra en el diff), el ODD SHALL quedar `escalado`, NO SHALL mergearse, y Claude SHALL ofrecer `/opsx:propose` usando el documento ODD como entrada.

#### Scenario: El Agente necesita una dependencia
- **WHEN** el Agente avisa "escalar a SDD" porque el ODD necesita una dependencia nueva
- **THEN** el documento queda con `estado: escalado` y el motivo en `## Progreso`
- **AND** Claude ofrece `/opsx:propose` con el documento como entrada
