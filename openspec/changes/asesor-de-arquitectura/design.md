## Context

- Motivación en `proposal.md` (Why). Las decisiones de fondo salieron del `/opsx:explore` del 04/11/2026: escalera de niveles, recomendación con evidencia, migración gradual y tamaño de archivo como señal.
- Base existente (capability `project-architecture`): `## Arquitectura` en el `context:` con una línea por carpeta y `| no importa:`; claves reservadas `comando`, `timeout` y `estado`; el propose la pide o infiere; regla 8 del Agente; el verify controla carpetas e imports solo sobre el diff.
- La lógica del propose y del verify está duplicada en `skills/openspec-propose/SKILL.md` / `.claude/commands/opsx/propose.md` y en `skills/openspec-verify-change/SKILL.md` / `.claude/commands/opsx/verify.md`. Se editan las dos copias con el mismo texto.
- Al proponer (04/11/2026), lo instalado en `~/.claude` (`CLAUDE.md`, las 8 skills y los 5 comandos) es igual al repo, comparando los hashes sin el fin de línea. No existe `~/.claude/skills/arquitectura/`.
- Relevamiento de tamaños (04/11/2026, código propio sin n8n, librerías ni perfiles de navegador): 1.101 archivos; 116 superan las 300 líneas, 63 las 500 y 16 las 1000. Los mayores: `PLANEAMIENTO/app.py` (8.684), `normalizacionLeads-contactacion/.../pdf_extraction_service.py` (1.600) y `sync_sheets.py` / `menu.py` repetidos en los tres `scrapingExodo-*` (unas 1.250 a 1.350 líneas cada uno).

## Goals / Non-Goals

**Goals:**
- Que las recomendaciones de arquitectura sean consistentes entre sesiones y modelos: salen de recetas escritas, no de lo que el modelo recuerde.
- Que cada recomendación se pueda entender sin saber arquitectura: cita archivos del propio repo y explica el problema concreto.
- Que nada nuevo bloquee: las severidades máximas son WARNING (tamaño) y SUGGESTION (coherencia del nivel).

**Non-Goals:**
- Detectar responsabilidades con un analizador automático: la detección de señales es lectura y criterio de Claude, guiado por las señales de cada receta.
- Generar las carpetas en disco: Claude escribe la declaración y las tareas, y el Agente mueve el código.

## Decisions

**D1. Escalera y recetas.** Seis valores de `nivel`, cada uno con su receta (salvo el 0) y su mínimo de reglas `no importa:`:

| `nivel` | Receta | Mínimo de reglas |
|---|---|---|
| `0` | Sin estilo | 0 |
| `1-nucleo-funcional` | Núcleo funcional: cálculos separados de conexiones | 1 |
| `2-tuberias` | Tuberías y filtros (ETL) | 1 |
| `2-capas` | Capas: presentación, negocio y datos | 2 |
| `3-hexagonal` | Hexagonal / Clean: dominio aislado con puertos y adaptadores | 2 |
| `3-modular` | Monolito modular: un módulo por dominio de negocio | 2 |

Hexagonal y Clean van juntas porque con `no importa:` se controlan igual (el dominio no depende de nada externo). Los niveles 2 y 3 incluyen el 1 por dentro: la parte de negocio, transformación o dominio sigue las pautas del núcleo funcional. Alternativa descartada: un campo `estilo` libre más un campo `paradigma`. Mezclaba niveles distintos (hexagonal con microservicios) y no se podía controlar.

**D2. Contenido de las recetas** (`skills/arquitectura/references/recetas.md`). Cada receta tiene siete partes, en este orden: **Señales**, **Carpetas tipo**, **Reglas `no importa:`**, **Mínimo de reglas**, **Pautas para el Agente**, **Cuándo no aplicarla** y **Adaptación por `project_type`**. Los nombres de carpeta son sugerencias: si el proyecto ya tiene carpetas con ese papel, se usan esas y se respeta la relación de la regla. Contenido de cada receta:

- **`1-nucleo-funcional`**
  - Señales: una función o archivo mezcla I/O (leer o escribir archivos, red, base de datos, APIs, logs) con cálculos; un cálculo no se puede testear sin un archivo o servicio real; la misma transformación aparece copiada en varios lugares; un archivo supera la advertencia de tamaño mezclando I/O y cálculos.
  - Carpetas tipo (base `src/<paquete>/` en Python, `src/` en TS/JS): `nucleo/` (cálculos: entran datos, salen datos), `conexiones/` (leer y escribir archivos, DB, APIs, logs) y el script o archivo de entrada, que orquesta.
  - Reglas: `nucleo/ | no importa: conexiones/`.
  - Pautas: las funciones del núcleo reciben datos y devuelven datos nuevos, sin modificar sus argumentos; no usan variables globales modificables; no leen configuración ni variables de entorno (la entrada se las pasa); sus tests no necesitan mocks de servicios.
  - Cuándo no: scripts de menos de unas 150 líneas de uso único; código que es casi todo I/O sin cálculos (copiar o mover archivos).
  - Por tipo: natural en `etl`/`scripts`; en `backend-api`, `src/services/` hace de núcleo y `src/db/` de conexiones; en `frontend`, la lógica de formateo y validación sale de los componentes hacia `src/lib/nucleo/`; en `tooling`/`config` normalmente no aplica.
- **`2-tuberias`**
  - Señales: los pasos de un ETL (extraer, transformar, cargar) están en un solo archivo o función; se quiere correr o repetir un paso solo; agregar una fuente o un destino obliga a tocar la transformación.
  - Carpetas tipo: `src/<paquete>/extract/`, `transform/`, `load/` y `scripts/` (entradas que encadenan los pasos).
  - Reglas: `transform/ | no importa: extract/, load/` y `extract/ | no importa: load/`.
  - Pautas: cada paso recibe y devuelve datos en un formato acordado y documentado en el design; `transform/` sigue las pautas del núcleo funcional; un paso no llama al siguiente, sino que lo encadena la entrada.
  - Cuándo no: un único paso, o una transformación trivial.
  - Por tipo: `etl`/`scripts`; en otros tipos, solo para procesos batch internos.
- **`2-capas`**
  - Señales: rutas, controladores o pantallas con SQL o llamadas a APIs adentro; la misma regla de negocio repetida en varias rutas; cambiar la base de datos obliga a tocar pantallas o rutas.
  - Carpetas tipo: `src/presentacion/` (rutas, controladores, vistas), `src/negocio/` (reglas y servicios) y `src/datos/` (acceso a DB y APIs).
  - Reglas: `presentacion/ | no importa: datos/`, `negocio/ | no importa: presentacion/` y `datos/ | no importa: presentacion/, negocio/`.
  - Pautas: la presentación valida formato y llama a negocio; negocio no conoce HTTP (ni request ni response); datos devuelve estructuras simples, no objetos de la librería de base de datos.
  - Cuándo no: apps con dos o tres pantallas de alta, baja y modificación sin reglas; frameworks que ya imponen su estructura (por ejemplo, las colecciones de Payload): ahí se sigue el framework.
  - Por tipo: en `backend-api` usa la fila sugerida existente (`src/api/`, `src/services/`, `src/db/`); en `fullstack` (una app), `src/app/` y `src/frontend/` son presentación y `src/backend/` es negocio y datos, con la prohibición existente.
- **`3-hexagonal`**
  - Señales: hay que poder cambiar una integración (Salesforce por otro CRM, Excel por una API) sin tocar las reglas; las mismas reglas se usan desde varias entradas (web, script, bot); los tests de negocio siguen siendo lentos porque dependen de integraciones, aun con capas.
  - Carpetas tipo: `src/dominio/` (entidades y reglas), `src/aplicacion/` (casos de uso), `src/puertos/` (interfaces que el dominio necesita) y `src/adaptadores/` (DB, APIs, web, CLI).
  - Reglas: `dominio/ | no importa: aplicacion/, adaptadores/`, `aplicacion/ | no importa: adaptadores/` y `puertos/ | no importa: adaptadores/`.
  - Pautas: el dominio no importa frameworks ni librerías de I/O; los adaptadores implementan los puertos; los casos de uso reciben los puertos por parámetro.
  - Cuándo no: una sola integración que no va a cambiar; una app chica mantenida por una persona (alcanza con capas).
  - Por tipo: `backend-api` y `fullstack` con varias integraciones.
- **`3-modular`**
  - Señales: varios dominios de negocio (ventas, posventa, repuestos) en el mismo código que se pisan; un cambio en un dominio rompe otro; archivos compartidos que tocan todos.
  - Carpetas tipo: `src/modulos/<dominio>/` (cada uno ordenado por dentro con el nivel 1 o 2) y `src/compartido/` (tipos y utilidades sin lógica de dominio).
  - Reglas: `src/compartido/ | no importa: src/modulos/` y, por cada módulo, `src/modulos/<a>/ | no importa: src/modulos/<b>/` para los que no deben conocerse.
  - Pautas: cada módulo expone un único archivo de entrada pública y los demás usan solo ese; no se comparten tablas entre módulos sin una decisión en el design.
  - Cuándo no: un solo dominio de negocio.
  - Por tipo: `fullstack` y `backend-api` grandes.

El archivo de recetas empieza con la tabla de D1 y una línea que explica que los nombres de carpeta son sugerencias. Debajo va el criterio de desempate (agregado tras el verify del 04/11/2026, en el que una sesión recomendó `2-tuberias` y cuatro `1-nucleo-funcional` para el mismo repo): "Si aparecen señales de más de una receta, se recomienda la de nivel más bajo que resuelve las señales encontradas. `2-tuberias` se prefiere a `1-nucleo-funcional` solo si hay más de una fuente o destino, o si se necesita correr un paso solo."

**D3. Claves nuevas en `## Arquitectura`.** `nivel` (uno de los seis valores de D1; si falta, sin evaluar), `tamaño` (`<aviso>, <advertencia>`, en líneas) y `tamaño-excluir` (rutas con `/` final, separadas por coma). No se escribe `nivel: sin evaluar`: la ausencia ya lo dice, igual que con las claves opcionales de `## Tests`. Alternativa descartada: `tamaño: activo` con umbrales fijos. Los umbrales tienen que poder ajustarse por proyecto.

**D4. Propose (skill y comando).**
1. **Paso 0:** cuando escribe `## Arquitectura` por primera vez, si el repo no tiene archivos de código (extensiones de D6) fuera de las carpetas implícitas, agrega `- tamaño: 500, 1000`.
2. **Señales:** al crear el `design.md`, como parte de la inspección del proyecto, Claude lee `~/.claude/skills/arquitectura/references/recetas.md` y revisa los archivos de código existentes que el change va a modificar o agrandar, buscando las **Señales** de la receta del nivel siguiente al declarado (sin `nivel`, las del nivel 1 y las de las recetas del nivel 2 que correspondan al `project_type`). Para la señal de tamaño usa los umbrales de `tamaño`, o 500 y 1000 si no está declarado: es solo para recomendar, el verify no mide sin `tamaño`. Antes de contar una señal, revisa **Cuándo no aplicarla** de esa receta: si aplica (por ejemplo, un script de menos de unas 150 líneas), la señal se descarta y no genera recomendación; puede mencionarse como observación en el resumen final, no en el design. Si las recetas no están instaladas, saltea este paso y lo avisa en el resumen.
3. **Recomendación:** si hay al menos una señal, agrega al `design.md`, antes de `## Ubicación de archivos`, la sección `## Recomendación de arquitectura` con estas subsecciones en negrita: **Qué vi** (archivos, líneas y funciones concretas), **Qué problema trae**, **Qué propongo** (nivel, carpetas y reglas de la receta adaptadas al repo), **Cuánto cuesta** (archivos que se mueven y si se puede hacer por partes), **Qué descarté** (otra receta o no hacer nada, con el motivo), **Pautas para el Agente** (las de la receta) y **Decisión**. Sin señales, la sección no aparece.
4. **Pregunta:** una sola `AskUserQuestion` con tres opciones: "Aplicar en este change", "Aplicar en un change aparte" y "No aplicar todavía". La respuesta se escribe en **Decisión**.
   - "Aplicar en este change": Claude escribe en `## Arquitectura` el `nivel`, las carpetas y las reglas (y `tamaño: 500, 1000` si no estaba), con edición quirúrgica y el aviso de 40 KB. `tasks.md` lleva las tareas para mover el código, con tests de caracterización (`Cxx`) antes de mover.
   - "Aplicar en un change aparte": no toca `## Arquitectura` y el resumen final sugiere `/issue-creation` para el refactor.
   - "No aplicar todavía": no toca `## Arquitectura`.
5. **Commit:** el commit de artefactos del paso 7 incluye `openspec/config.yaml` cuando el propose lo modificó.

**D5. Skill `arquitectura`** (`skills/arquitectura/SKILL.md`; se invoca `/arquitectura`). Solo lectura salvo el paso 6:
1. Lee `openspec/config.yaml` (`project_type`, `## Arquitectura`) y las recetas. Sin `openspec/config.yaml`, diagnostica igual y avisa que para guardar el resultado hace falta `openspec init`.
2. Inventario: carpetas de primer nivel y de `src/`, y archivos de código con su cantidad de líneas (extensiones y exclusiones de D6, más lo ignorado por `.gitignore`, `*.env`, `*.key`, `*.pem`, `*.p12` y `secrets/`, que no se leen).
3. Nivel actual: el declarado, controlando su coherencia como en D6; si no hay, el inferido, con la evidencia.
4. Señales: las de las recetas que aparecen, cada una con archivo, líneas y funciones o responsabilidades que mezcla. Lee los archivos más grandes y los que concentran I/O, sin pegar su contenido en el informe.
5. Informe en el chat: nivel actual, señales, recomendación con las cinco partes de D4 (sin **Decisión**) y plan de migración como lista ordenada de changes, una responsabilidad por change, cada uno con sus `Cxx`. Sin señales: "el nivel actual alcanza" y termina.
6. `AskUserQuestion` "Adoptar la recomendación" / "No por ahora". Si se adopta, escribe en `## Arquitectura` (creándola si falta) el `nivel`, las carpetas, las reglas y `tamaño: 500, 1000`, con edición quirúrgica y el aviso de 40 KB, y sugiere `/issue-creation` para el primer change del plan. Si no, no escribe nada.

No crea changes, ramas ni commits, y no escribe en el vault (como el explore).

**D6. Verify (skill y comando).** Dentro de "Architecture Verification", en los dos flujos (con Test Plan y legacy), después de "Tool":
- **Nivel:** si hay `nivel` distinto de `0`, cuenta las líneas de `## Arquitectura` con `| no importa:`. Si son menos que el mínimo de D1, SUGGESTION "nivel <valor> sin sus reglas: mínimo <m>, hay <n>". Si el valor no está en D1, SUGGESTION "nivel <valor> no corresponde a ninguna receta".
- **Tamaño:** solo si hay `tamaño`. Toma `git diff --numstat <rama principal>...HEAD` y se queda con los archivos que tienen más líneas agregadas que borradas (los nuevos incluidos), con extensión de código, y que no están excluidos. Mide sus líneas en `HEAD`. Por encima del aviso, SUGGESTION con ruta y líneas. Por encima de la advertencia, WARNING con ruta, líneas, hasta cinco responsabilidades que mezcla (leyendo el archivo) y una propuesta de partición según la receta que corresponda. Nunca CRITICAL.
  - Extensiones de código: `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.vue`, `.svelte`, `.ps1`, `.psm1`, `.cs`, `.java`, `.go`, `.rb`, `.php` y `.sql`.
  - Exclusiones fijas: rutas con un segmento `test/`, `tests/`, `__tests__/`, `spec/`, `migrations/`, `fixtures/` o `data/`; nombres `test_*`, `*_test.*`, `*.test.*`, `*.spec.*`, `*.generated.*`, `*.min.*` y `*.lock`; archivos cuyas primeras 5 líneas contienen "generated" o "do not edit" (sin distinguir mayúsculas). Se suman las rutas de `tamaño-excluir`.
- El reporte suma dos filas a la tabla `Arquitectura | Resultado`: "Coherencia del nivel" (`ok`, `sin nivel` o el aviso) y "Archivos que crecen sobre el umbral" (`no medido`, `0` o la lista con severidad). "Issues by Priority" suma la WARNING de tamaño y las dos SUGGESTION.

**D7. `CLAUDE.md` global.** En `## Arquitectura del proyecto`:
- El párrafo de claves reservadas suma `nivel`, `tamaño` y `tamaño-excluir` con su formato (D3).
- Subsección nueva `### Escalera de niveles`, antes de "Responsabilidades por actor", con la tabla de D1 sin la columna de mínimo y una columna "Cuándo subir", con la primera señal de cada receta. Debajo, dos líneas: las recetas completas están en `~/.claude/skills/arquitectura/references/recetas.md` y la guía para estudiar en `docs/guia-arquitecturas.md` del repo `sdd-global-config`.
- "Responsabilidades por actor": el propose suma "recomienda un nivel con evidencia cuando el change cruza una señal y escribe `tamaño` en proyectos nuevos"; línea nueva para `/arquitectura`, "diagnostica un proyecto existente y escribe `## Arquitectura` solo con aprobación"; el verify suma "coherencia del nivel (SUGGESTION) y tamaño de los archivos que crecen (SUGGESTION/WARNING, solo con `tamaño`)".
- Regla 8: se agrega al final, literal: "Si el `design.md` trae `## Recomendación de arquitectura`, aplicá sus pautas para el Agente aunque el verify no pueda controlarlas."

**D8. Plantillas.** La misma oración de D7 se agrega al final de la regla 8 en `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`. Siguen siendo 8 reglas.

**D9. Guía para estudiar** (`docs/guia-arquitecturas.md`), en español rioplatense y sin jerga sin explicar:
1. Para qué sirve y cómo se usa junto con `/arquitectura`.
2. La escalera: un diagrama ASCII de los niveles, con la señal típica de cada uno.
3. Paradigmas: orientado a objetos, funcional y mixto, en simple, y su relación con la escalera (el funcional es la base del nivel 1).
4. Catálogo, con una subsección por cada ítem: capas, hexagonal, clean, microservicios, EDA, monolito modular, SOA, serverless, tuberías y filtros, microkernel, cliente-servidor y P2P, DDD, MVC/MVP/MVVM, patrones GoF y funcional. Cada una con **Qué es** (dos o tres líneas), **Ejemplo tipo Yacopini** (un proyecto como el script de leads, un ETL de patentamientos, un tablero de métricas, la web con Payload o un sistema con ventas, posventa y repuestos) y **¿Te va a tocar?** (sí / a veces / probablemente no, con el nivel de la escalera si corresponde).
5. Cómo leer una recomendación de Claude: las cinco partes y qué preguntar si no se entiende.
6. Glosario corto.

Sin datos reales de clientes ni de empleados en los ejemplos. En Microservicios, **¿Te va a tocar?** dice también cuándo sí convendrían: equipos separados que despliegan cada servicio por su cuenta, o partes del sistema que necesitan escalar de forma independiente.

**D12. Sin referencias al design en lo que se instala.** Las skills, los comandos, el `CLAUDE.md`, las plantillas y las recetas no citan IDs de este design (`D1`, `D4`…), porque fuera del change no se resuelven. Remiten a la fuente instalada: el mínimo de reglas por nivel, a la tabla de `~/.claude/skills/arquitectura/references/recetas.md`; las extensiones, exclusiones y partes de la recomendación se escriben literalmente. Es el mismo criterio del commit `06d2dee` del change anterior.

**D10. Instalación.** Igual que en `arquitectura-de-carpetas`: antes de copiar, se compara cada archivo instalado con `git show master:<ruta>` sin el fin de línea, y si alguno tiene contenido local que no está en `master`, se frena y se pregunta. Después se copian a `~/.claude` el `CLAUDE.md`, todas las carpetas de `skills/` (incluida `arquitectura/` con `references/`) y todos los comandos de `.claude/commands/opsx/`; se copia `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`, y se sincroniza el espejo `_global/reglas-globales.md` del vault. Se verifica con hashes.

**D11. Commits.** Tres commits de código, separados de los artefactos y con `Spec-ID: asesor-de-arquitectura` en un único bloque final de trailers:
1. `.claude/CLAUDE.md`, con la descripción del impacto;
2. `skills/` (propose, verify y la skill nueva) y `.claude/commands/opsx/`;
3. plantillas, `README.md`, `docs/workflow.md` y `docs/guia-arquitecturas.md`.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `skills/arquitectura/SKILL.md` | `skills/` (subcarpeta) |
| `skills/arquitectura/references/recetas.md` | `skills/` (subcarpeta) |
| `docs/guia-arquitecturas.md` | `docs/` (implícita) |

Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, las skills, los comandos, las plantillas ni la guía. Las rutas se escriben con `~/.claude/`. Se verifica con un script en archivo, porque las barras invertidas se pierden en línea.
- `/arquitectura` y la detección de señales del propose solo leen código. No lo ejecutan ni leen lo ignorado por `.gitignore`, `*.env`, `*.key`, `*.pem`, `*.p12` ni `secrets/`. Los informes citan rutas, cantidad de líneas y nombres de funciones, sin pegar contenido.
- La única escritura nueva es `## Arquitectura` en `openspec/config.yaml`, con aprobación explícita y edición quirúrgica.
- La señal de tamaño del verify cuenta líneas y lee archivos del diff. No ejecuta nada.
- Commit aparte del `CLAUDE.md` con el impacto (regla `tooling`/`config`). La instalación tiene el chequeo previo de cambios locales (D10).

## Impacto en proyectos existentes

- **Sin `nivel` ni `tamaño`** (todos hoy): el verify no reporta nada nuevo. El propose puede sumar una `## Recomendación de arquitectura` solo cuando el change toca un archivo con una señal, y siempre ofrece "No aplicar todavía".
- **Proyectos con archivos grandes** (por ejemplo `PLANEAMIENTO`): no reciben avisos de tamaño hasta que se adopte una recomendación o se declare `tamaño` a mano.
- **Agentes:** la oración nueva de la regla 8 llega por las plantillas. Los proyectos que ya copiaron `AGENTS.md`, `.cursor/rules/sdd-workflow.mdc` o `.github/copilot-instructions.md` tienen que volver a copiarlos. Mientras tanto, el Agente igual ve las pautas porque están en el `design.md`.
- **Este repo:** declara `## Arquitectura` (`skills/`, `templates/`) desde este propose, sin `nivel` ni `tamaño`. No tiene archivos de código, así que la señal de tamaño no aplicaría.
- **Otras máquinas:** repetir el paso de instalación del README para tener la skill nueva.

## Risks / Trade-offs

- [La detección de señales es criterio de Claude, no un analizador] → Las recetas nombran señales concretas y la recomendación cita archivos y funciones, así se puede revisar. El usuario siempre decide.
- [El propose podría repetir la misma recomendación en cada change que toque el mismo archivo] → Solo aparece cuando el change toca ese archivo y cuesta una sola pregunta. Si molesta, adoptar "no aplicar todavía" como recuerdo persistente es un change futuro.
- [Contar `| no importa:` no prueba que las reglas sean las de la receta] → Se acepta: el aviso detecta el caso que importa (nivel declarado sin reglas). Comparar regla por regla obligaría a fijar nombres de carpeta.
- [Exclusiones por nombre con falsos negativos o positivos] → `tamaño-excluir` por proyecto, y la severidad máxima es WARNING.
- [Duplicación skill/comando] → La tarea de evidencia compara que el texto agregado sea idéntico en las dos copias.

## Migration Plan

Primero se edita y se instala (D10). Los proyectos adoptan los niveles cuando un propose cruza una señal o cuando se corre `/arquitectura`. Rollback: revertir el PR, reinstalar desde `master`, borrar `~/.claude/skills/arquitectura/` y volver a sincronizar el espejo. Las claves `nivel` y `tamaño` que ya se hayan escrito en algún proyecto no hacen daño: sin las skills nuevas, se ignoran.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude o el Agente. Todo el plan es manual. No hay tests de caracterización porque no hay código. Los cambios intencionales de comportamiento (propose, verify, regla 8) los cubren S05–S11, S23–S36. Un test automático futuro llevaría `test-plan: asesor-de-arquitectura/<ID>`.

Fixtures, que se crean en el verify:
- **Repo C** (`$env:TEMP\asesor-prueba-c`): `project_type: etl`, `## Tests` con `comando: ninguno`, sin `## Arquitectura`. `src/leads/procesar.py` de unas 1.100 líneas donde una misma función abre un Excel con `openpyxl`, normaliza teléfonos y hace un `requests.post` a una URL ficticia (no se ejecuta). Un change de prueba: "agregar validación de email en procesar.py".
- **Repo D** (`$env:TEMP\asesor-prueba-d`): solo `README.md`, `.gitignore` y `openspec/` con `config.yaml` sin `## Arquitectura`.
- **Repo E** (`$env:TEMP\asesor-prueba-e`): un script `normalizar.py` de 80 líneas, solo con cálculos sobre una lista, sin I/O.
- **Repo F** (`$env:TEMP\asesor-prueba-f`), con `## Arquitectura`: `src/`, `tests/`, `skills/`, `- tamaño: 500, 1000` y `- tamaño-excluir: src/legacy/`. En `master`: `src/grande.py` (8.000 líneas), `src/medio.py` (580), `src/app.ts` (1.000), `src/legacy/viejo.py` (1.100), `tests/test_motor.py` (1.000) y `skills/x/SKILL.md` (1.200). En la rama de prueba: `src/medio.py` +40 líneas (620); `src/app.ts` +150 (1.150); `src/grande.py` con 20 líneas reemplazadas sin agregar; `tests/test_motor.py` +100 (1.100); `src/legacy/viejo.py` +100 (1.200); `skills/x/SKILL.md` +100 (1.300). Para la coherencia del nivel se corre el verify con tres variantes de `## Arquitectura` en la rama: `nivel: 1-nucleo-funcional` sin reglas, con una regla `src/nucleo/ | no importa: src/conexiones/`, y `nivel: 4-microservicios`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Escalera / Script chico sin señales | manual: `/arquitectura` en el repo E dice que el nivel actual alcanza y no recomienda subir | repo E |
| S02 | Escalera / Señal concreta | manual: en el repo C, la recomendación cita `procesar.py` y la función que mezcla Excel, cálculo y POST | repo C |
| S03 | Recetas / Contenido de una receta | manual: la receta `1-nucleo-funcional` de `recetas.md` tiene las siete partes de D2 y mínimo 1 | `skills/arquitectura/references/recetas.md` |
| S04 | Recetas / Variantes de un nivel | manual: `recetas.md` tiene `2-capas` y `2-tuberias`, cada una con las siete partes | ídem |
| S05 | Propose recomienda / Change que cruza una señal | manual: el `design.md` del change de prueba del repo C tiene `## Recomendación de arquitectura` con las cinco partes, más **Pautas para el Agente** y **Decisión** | repo C `openspec/changes/*/design.md` |
| S06 | Propose recomienda / Change sin señales | manual: en el repo E, un change "agregar un caso a normalizar.py" no genera la sección | repo E |
| S07 | Usuario decide / Aplicar en este change | manual: en el repo C, elegir "Aplicar en este change"; `## Arquitectura` queda con `nivel`, carpetas, reglas y `tamaño`, y `tasks.md` tiene las tareas de mover el código con `Cxx` antes | repo C |
| S08 | Usuario decide / No aplicar todavía | manual: con el repo C restaurado, elegir "No aplicar todavía"; `config.yaml` sin `nivel` y **Decisión** registrada | repo C |
| S09 | Usuario decide / Change aparte | manual: con el repo C restaurado, elegir "Aplicar en un change aparte"; `config.yaml` sin `nivel` y el resumen sugiere `/issue-creation` | repo C |
| S10 | Tamaño en proyectos nuevos / Proyecto nuevo | manual: el primer propose en el repo D escribe `- tamaño: 500, 1000` | repo D `openspec/config.yaml` |
| S11 | Tamaño en proyectos nuevos / Proyecto existente | manual: en S08, la `## Arquitectura` escrita en el paso 0 del repo C no tiene `tamaño` | repo C `openspec/config.yaml` |
| S12 | Diagnóstico / Proyecto con un archivo enorme | manual: `/arquitectura` en el repo C cita `procesar.py`, sus líneas y las responsabilidades, y da un plan con un change por responsabilidad | repo C |
| S13 | Diagnóstico / Proyecto ordenado | manual: igual que S01 | repo E |
| S14 | Escribe con aprobación / Aprobada | manual: en `/arquitectura` del repo C restaurado, elegir "Adoptar"; `## Arquitectura` queda con `nivel`, carpetas, reglas y `tamaño`, y el diff de `config.yaml` solo toca esa subsección | repo C |
| S15 | Escribe con aprobación / No aprobada | manual: elegir "No por ahora"; `git status` sin cambios en `config.yaml` | repo C |
| S16 | Guía / Estilo de topología | manual: la subsección de microservicios de la guía dice cuándo conviene y por qué probablemente no se use | `docs/guia-arquitecturas.md` |
| S17 | Guía / Relación con la escalera | manual: la subsección del paradigma funcional menciona el nivel 1 | ídem |
| S18–S20 | Declaración / escenarios existentes (carpetas declaradas, herramienta, archivos de la raíz) | manual: el texto de D2 del change anterior sigue en el `CLAUDE.md` y en las skills sin cambios de comportamiento (diff) | `.claude/CLAUDE.md`, skills de propose y verify |
| S21 | Declaración / Proyecto sin nivel declarado | manual: verify en el repo F sin `nivel` no reporta coherencia (fila "sin nivel") | repo F |
| S22 | Declaración / Señal de tamaño declarada | manual: en el verify del repo F, aviso a 500, advertencia a 1000 y `src/legacy/` sin medir (S30, S31, S35) | repo F |
| S23–S25 | Regla 8 / escenarios existentes | manual: `grep -l "Respetar la arquitectura"` sobre el `CLAUDE.md`, las 4 plantillas, `~/.claude/CLAUDE.md` y el espejo del vault da 7 archivos | ídem |
| S26 | Regla 8 / Pautas de la recomendación | manual: la oración de D7 aparece idéntica en el `CLAUDE.md` y en las 4 plantillas (`Select-String` con el texto literal, 5 coincidencias) | `.claude/CLAUDE.md`, `templates/*` |
| S27 | Coherencia / Nivel sin sus reglas | manual: verify en el repo F con la variante sin reglas reporta la SUGGESTION con mínimo 1 y hay 0 | repo F |
| S28 | Coherencia / Nivel con sus reglas | manual: variante con una regla, fila "ok" | repo F |
| S29 | Coherencia / Nivel desconocido | manual: variante `4-microservicios`, SUGGESTION "no corresponde a ninguna receta" | repo F |
| S30 | Tamaño / Crece sobre el aviso | manual: SUGGESTION en `src/medio.py` (620) | repo F |
| S31 | Tamaño / Crece sobre la advertencia | manual: WARNING en `src/app.ts` (1.150) con responsabilidades y propuesta de partición | repo F |
| S32 | Tamaño / Archivo grande que no crece | manual: `src/grande.py` no aparece | repo F |
| S33 | Tamaño / Sin tamaño declarado | manual: en el repo F sin la clave `tamaño`, la fila dice "no medido" | repo F |
| S34 | Exclusiones / Test largo | manual: `tests/test_motor.py` no aparece | repo F |
| S35 | Exclusiones / Ruta excluida | manual: `src/legacy/viejo.py` no aparece | repo F |
| S36 | Exclusiones / Documentación larga | manual: `skills/x/SKILL.md` no aparece | repo F |
| S37 | Propose recomienda / Señal excluida por la receta | manual: igual que S06, en una sesión nueva en el repo E tras el grupo 7: sin `## Recomendación de arquitectura`, y la duplicación de `paso_0..8` como mucho como observación del resumen | repo E |
| S38 | Recetas / Criterio de desempate | manual: `recetas.md` tiene el criterio de D2, y una sesión nueva de `/arquitectura` en una copia limpia del repo C recomienda `1-nucleo-funcional` | `skills/arquitectura/references/recetas.md`, repo C |

S01, S02, S05–S15 se hacen en sesiones **nuevas** de Claude Code abiertas en cada repo descartable, para comprobar que lo instalado en `~/.claude` aplica en otro repo. S21, S22 y S27–S36 se hacen con `/opsx:verify` en sesiones nuevas en el repo F.

## Open Questions

Sin preguntas abiertas. Las decisiones salen del explore del 04/11/2026 y se pueden revisar antes del apply.
