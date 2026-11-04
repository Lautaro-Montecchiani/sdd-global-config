# Spec Delta

## MODIFIED Requirements

### Requirement: Declaración de la arquitectura en el context
Un proyecto SHALL poder declarar su arquitectura en la subsección `## Arquitectura` del `context:` de `openspec/config.yaml`, con una línea por carpeta: `- <ruta>/: <qué va> | no importa: <ruta>/, <ruta>/`, donde el segmento `| no importa:` es opcional. Las claves sin `/` final son reservadas: `comando` y `timeout` (herramienta de imports opcional, `timeout` en minutos y obligatorio si hay `comando`), `estado` (solo `inferido — revisar`), `nivel` (`0`, `1-nucleo-funcional`, `2-capas`, `2-tuberias`, `3-hexagonal` o `3-modular`; si falta, el proyecto está sin evaluar), `tamaño` (`<aviso>, <advertencia>` en líneas) y `tamaño-excluir` (rutas separadas por coma). Los archivos sueltos en la raíz del repo y las carpetas `openspec/`, `docs/` y las que empiezan con `.` SHALL considerarse siempre permitidas sin declararse. Una subcarpeta nueva dentro de una carpeta declarada SHALL considerarse permitida.

#### Scenario: Carpetas declaradas
- **WHEN** un proyecto declara `## Arquitectura` con `- src/backend/: servidor, DB y secretos` y `- src/frontend/: componentes | no importa: src/backend/`
- **THEN** las carpetas permitidas son `src/backend/`, `src/frontend/` y sus subcarpetas, más las implícitas
- **AND** los archivos de `src/frontend/` no pueden importar archivos de `src/backend/`

#### Scenario: Herramienta de imports declarada
- **WHEN** `## Arquitectura` incluye `- comando: <comando>`
- **THEN** también incluye `- timeout: <minutos>`

#### Scenario: Archivos de configuración en la raíz
- **WHEN** un proyecto tiene `package.json`, `tsconfig.json` o `Dockerfile` en la raíz y no los declara
- **THEN** no se consideran fuera de la arquitectura

#### Scenario: Proyecto sin nivel declarado
- **WHEN** `## Arquitectura` no incluye la clave `nivel`
- **THEN** el proyecto se considera sin evaluar
- **AND** ninguna skill bloquea ni reporta desvíos por eso

#### Scenario: Señal de tamaño declarada
- **WHEN** `## Arquitectura` incluye `- tamaño: 500, 1000` y `- tamaño-excluir: src/legacy/`
- **THEN** el aviso es a partir de 500 líneas, la advertencia a partir de 1000, y los archivos de `src/legacy/` no se miden

### Requirement: Regla 8 del Agente
Las reglas de ejecución del Agente SHALL incluir una regla 8 "Respetar la arquitectura": los archivos nuevos van en la carpeta que indica el `design.md` dentro de las declaradas en `## Arquitectura`; el Agente NO SHALL crear carpetas fuera de las declaradas (sí subcarpetas de una declarada) ni agregar imports que una carpeta tiene prohibidos; si necesita una carpeta nueva que el design no prevé, SHALL frenar y preguntar. Al generar desde una plantilla o scaffolder, SHALL listar en el resumen del apply los archivos de ejemplo que trae y borrar los que el design no pide. Si el proyecto no declara `## Arquitectura`, SHALL seguir el design y avisarlo en el resumen. Si el design incluye `## Recomendación de arquitectura`, SHALL aplicar sus pautas para el Agente aunque el verify no pueda controlarlas.

#### Scenario: Regla presente en todas las fuentes
- **WHEN** se busca "Respetar la arquitectura" en el `CLAUDE.md` global y en las cuatro plantillas de reglas
- **THEN** aparece en las cinco como regla 8

#### Scenario: Carpeta no prevista
- **WHEN** durante el apply el Agente necesita una carpeta que no está declarada ni en el design
- **THEN** frena y pregunta en vez de crearla

#### Scenario: Restos de plantilla
- **WHEN** el Agente genera el proyecto desde una plantilla que trae rutas o archivos de ejemplo
- **THEN** el resumen del apply los lista y los que el design no pide quedan borrados

#### Scenario: Pautas de la recomendación
- **WHEN** el design incluye `## Recomendación de arquitectura` con la pauta "las funciones de cálculo no modifican los datos que reciben"
- **THEN** el Agente escribe las funciones de cálculo respetando esa pauta
- **AND** el texto de la regla 8 que lo pide es el mismo en el `CLAUDE.md` global y en las cuatro plantillas

## ADDED Requirements

### Requirement: El verify controla la coherencia del nivel
Si `## Arquitectura` declara un `nivel` distinto de `0`, `/opsx:verify` SHALL contar las líneas con `| no importa:` y, si son menos que el mínimo de la receta de ese nivel, SHALL reportar una SUGGESTION con el nivel, el mínimo y la cantidad encontrada. Un `nivel` que no corresponde a ninguna receta SHALL reportarse como SUGGESTION. Sin `nivel`, NO SHALL hacer este control.

#### Scenario: Nivel sin sus reglas
- **WHEN** `## Arquitectura` declara `- nivel: 1-nucleo-funcional` y ninguna línea con `| no importa:`
- **THEN** el verify reporta SUGGESTION "nivel 1-nucleo-funcional sin sus reglas: mínimo 1, hay 0"

#### Scenario: Nivel con sus reglas
- **WHEN** `## Arquitectura` declara `- nivel: 1-nucleo-funcional` y una línea con `| no importa:`
- **THEN** el verify no reporta nada por la coherencia del nivel

#### Scenario: Nivel desconocido
- **WHEN** `## Arquitectura` declara `- nivel: 4-microservicios`
- **THEN** el verify reporta SUGGESTION indicando que el nivel no corresponde a ninguna receta

### Requirement: El verify mide el tamaño de los archivos que crecen
Si `## Arquitectura` declara `tamaño`, `/opsx:verify` SHALL medir las líneas de cada archivo de código que el diff agrega o agranda (más líneas agregadas que borradas). Si supera el aviso, SHALL reportar SUGGESTION; si supera la advertencia, WARNING con las responsabilidades que mezcla y una propuesta de partición. NUNCA SHALL reportarlo como CRITICAL. Sin `tamaño`, NO SHALL medir.

#### Scenario: Archivo que crece por encima del aviso
- **WHEN** con `- tamaño: 500, 1000` el diff agrega 40 líneas a un `.py` que queda en 620
- **THEN** el verify reporta SUGGESTION con la ruta y las 620 líneas

#### Scenario: Archivo que crece por encima de la advertencia
- **WHEN** con `- tamaño: 500, 1000` el diff agranda un `.ts` que queda en 1.150 líneas
- **THEN** el verify reporta WARNING con la ruta, las líneas, las responsabilidades que mezcla y una propuesta de partición

#### Scenario: Archivo grande que no crece
- **WHEN** el diff modifica un archivo de 8.000 líneas sin agrandarlo
- **THEN** el verify no lo reporta por tamaño

#### Scenario: Proyecto sin tamaño declarado
- **WHEN** `## Arquitectura` no declara `tamaño`
- **THEN** el verify no mide el tamaño de ningún archivo

### Requirement: Exclusiones de la señal de tamaño
La señal de tamaño SHALL medir solo archivos de código (por extensión) y SHALL excluir siempre los tests, los archivos generados, los datos y fixtures, las migraciones, los lockfiles y los archivos minificados, además de las rutas de `tamaño-excluir`. Los archivos de Markdown, YAML y JSON NO SHALL medirse.

#### Scenario: Test largo
- **WHEN** el diff agranda `tests/test_motor.py` hasta 1.100 líneas
- **THEN** el verify no lo reporta por tamaño

#### Scenario: Ruta excluida por el proyecto
- **WHEN** `## Arquitectura` declara `- tamaño-excluir: src/legacy/` y el diff agranda `src/legacy/viejo.py` hasta 1.200 líneas
- **THEN** el verify no lo reporta por tamaño

#### Scenario: Documentación larga
- **WHEN** el diff agranda un `SKILL.md` hasta 1.300 líneas
- **THEN** el verify no lo reporta por tamaño
