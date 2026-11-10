## MODIFIED Requirements

### Requirement: Criterios SDD
Claude SHALL clasificar como SDD todo pedido que cumpla al menos uno de estos criterios, y como ODD el que no cumpla ninguno:
- K1: agrega o quita un comportamiento descrito en una spec vigente, crea una capability nueva o modifica requirements de más de una capability (modificar requirements existentes de una sola capability no cumple K1: va por ODD con un cambio mínimo de spec);
- K2: cambia cómo se lee, valida, transforma, guarda, registra, expone o envía un dato declarado en `## Datos` como `(externo)` o `personal`, o agrega o quita campos de ese dato (usarlo igual que antes no cumple K2);
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

#### Scenario: Dato usado igual que antes
- **WHEN** `## Datos` declara el nombre del lead como `personal` y el usuario pide cambiar el saludo "Hola, {nombre}" a "Buenas, {nombre}"
- **THEN** K2 no se cumple, porque el nombre se usa igual que antes
- **AND** la clasificación es ODD con un cambio mínimo de spec

#### Scenario: Dato transformado
- **WHEN** `## Datos` declara el nombre del lead como `personal` y el usuario pide mostrarlo en mayúsculas en el saludo
- **THEN** la clasificación es SDD por K2, porque transforma el dato
- **AND** Claude no ofrece pasarlo a ODD
