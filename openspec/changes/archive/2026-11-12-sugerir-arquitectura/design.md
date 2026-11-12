# Design

## Context

- `/arquitectura` (`skills/arquitectura/SKILL.md`) diagnostica un proyecto y escribe `## Arquitectura` solo con aprobación. Ninguna otra skill la menciona como próximo paso.
- **`/opsx:propose`** (`skills/openspec-propose/SKILL.md`):
  - si falta `## Arquitectura`, la pide;
  - si el change cruza una señal, agrega `## Recomendación de arquitectura`;
  - si hay `## Arquitectura` pero falta `nivel`, no dice nada.
- **`/opsx:verify`** (`skills/openspec-verify-change/SKILL.md`): si falta `## Arquitectura`, reporta SUGGESTION. Con `tamaño` declarado, reporta WARNING por cada archivo que supera la advertencia, pero no dice cómo seguir.
- **Fase del vault de `/opsx:archive`:** escribe `## Nivel` "sin evaluar" en `arquitectura.md` cuando falta `nivel`, sin sugerir nada.
- **Spec vigente:** el escenario "Proyecto sin nivel declarado" de `project-architecture` dice que ninguna skill bloquea ni reporta desvíos por falta de `nivel`. La sugerencia respeta eso: no es un desvío.
- **En este repo:** el 12/11/2026 se corrió `/arquitectura` y el usuario adoptó `nivel: 0` y `tamaño: 500, 1000`. La edición de `openspec/config.yaml` ya está hecha y entra en el commit de artefactos de este change.

## Goals / Non-Goals

**Goals:**
- Que Claude proponga `/arquitectura` en el momento en que el proyecto lo necesita, sin depender de que el usuario se acuerde.
- Que la sugerencia sea liviana: una línea, sin bloquear y sin repetirse en la misma operación.
- Registrar el nivel de este repo con su ADR y sacarlo de la hoja de ruta.

**Non-Goals:**
- Correr `/arquitectura` sola, o detectar en el verify señales de recetas además del tamaño.

## Decisions

### D1. Texto único de la sugerencia

Todas las operaciones usan la misma línea, con el motivo entre paréntesis: "Sugerencia: corré `/arquitectura` para evaluar la arquitectura del proyecto (<motivo>)". Los motivos son fijos:
- "`## Arquitectura` no declara `nivel`";
- "`nivel: <valor>` no corresponde a ninguna receta";
- "`<archivo>` tiene <n> líneas, sobre la advertencia de `tamaño`";
- "`arquitectura.md` quedó en sin evaluar".

Un solo texto se controla fácil en los tests y no confunde.

### D2. Dónde va en cada operación

- **Inicio de sesión** (`.claude/CLAUDE.md`, sección "Al iniciar cada sesión"): un paso nuevo después de leer el vault. Lee `## Arquitectura` de `openspec/config.yaml`. Si hay `## Arquitectura` sin `nivel` o con un valor que no es receta, avisa con D1. Si no hay `## Arquitectura`, no sugiere nada, porque el propose ya la pide.
- **`/opsx:propose`:** en el paso 0, donde ya lee `## Arquitectura`, guarda el resultado. En el resumen final suma la línea de D1, junto al aviso de ficha faltante. Si el propose escribió `nivel` en este mismo change (recomendación aplicada), no sugiere.
- **`/opsx:verify`:** al final del reporte, después de "Issues by Priority", va un bloque "Sugerencias de arquitectura" con una línea D1 por cada archivo que tuvo WARNING de tamaño. Si además falta `nivel`, va una línea D1 con ese motivo. No cambia severidades ni la evaluación final. Aplica en los dos métodos, con Test Plan y legacy.
- **Fase del vault de `/opsx:archive`:** después del paso e (`arquitectura.md`), si escribió "sin evaluar", el resumen suma la línea D1.

Se descartó sugerir en el apply (lo corre el Agente, no Claude) y en `/odd` (es un flujo liviano: el siguiente propose o inicio de sesión ya lo sugiere).

### D3. Una vez por operación

Cada operación junta los motivos y muestra cada línea D1 una sola vez. En el verify puede haber una línea por archivo, pero cada archivo aparece una sola vez.

### D4. Nivel de este repo

`openspec/config.yaml` suma `- nivel: 0` y `- tamaño: 500, 1000` al final de `## Arquitectura` (ya editado). El ADR 0003 registra la decisión. `docs/arquitectura/vision.md` cambia en tres lugares:
- en `## Decisiones vigentes` suma el link al ADR 0003;
- en `## Hoja de ruta` quita la línea "[baja] `## Arquitectura` no declara `nivel`";
- en `## Hoja de ruta` suma "[baja] `scripts/instalar.ps1` está en el umbral de aviso de `tamaño` (500 líneas) y mezcla la clasificación del espejo con lecturas de archivos y `git` — origen: ADR 0003 — propuesta: si pasa de 1000 líneas, evaluar `1-nucleo-funcional` y llevar la clasificación a funciones de `scripts/comun.ps1`".

## Impacto en proyectos existentes

- Retrocompatible: la sugerencia no bloquea ni cambia resultados del verify.
- Los proyectos sin `nivel` (la mayoría de los proyectos de la empresa) van a ver la línea al iniciar sesión y en cada propose hasta correr `/arquitectura`. Es el efecto buscado.
- Llega a cada máquina con `git pull` y `pwsh scripts/instalar.ps1`.

## Impacto en el sistema

**Componentes afectados:** el inicio de sesión de Claude en todos los proyectos (el `CLAUDE.md` global) y la nota `arquitectura.md` del vault, solo como disparador de la sugerencia.

**Atributos de calidad:**
- mantenibilidad (alta): sin efecto negativo. Los comandos se siguen generando desde las skills, y el texto de la sugerencia es uno solo (D1) y se controla en los tests — Verificación: S01–S06 y `pwsh scripts/generar-plantillas.ps1 -Comprobar` en el CI.

**Decisiones de arquitectura:** ADR nuevo: 0003.

**Deuda técnica:**
- paga: "`## Arquitectura` no declara `nivel`".
- agrega (registra): "`scripts/instalar.ps1` en el umbral de aviso de `tamaño`", de baja prioridad.

## ADR

```markdown
# 0003. Nivel 0 para sdd-global-config

Estado: aceptada
Fecha: 2026-11-12
Change: sugerir-arquitectura

## Contexto

`## Arquitectura` de `openspec/config.yaml` declaraba carpetas (`scripts/`, `skills/`, `templates/`, `tests/`) pero no `nivel`, así que el proyecto figuraba "sin evaluar". El 12/11/2026 se corrió `/arquitectura`. El código está solo en `scripts/` (4 archivos de PowerShell: `instalar.ps1` con 500 líneas, `generar-plantillas.ps1` con 311, `sincronizar-proyecto.ps1` con 238 y `comun.ps1` con 212). `skills/` y `templates/` son Markdown. La única señal fue `scripts/instalar.ps1`: está en el umbral de aviso y mezcla la clasificación del espejo del vault (6 casos) con lecturas de archivos y llamadas a `git`. Por eso sus tests necesitan carpetas y repos de prueba.

## Alternativas

- `1-nucleo-funcional` (llevar la clasificación a funciones puras en `scripts/comun.ps1` o `scripts/nucleo/`): descartada por ahora. La receta indica que en `tooling` normalmente no aplica, hay una sola señal en el límite del aviso, y los tests ya cubren los casos y corren en el CI.
- `2-tuberias`, `2-capas`, `3-hexagonal` y `3-modular`: descartadas. No hay ETL, capas de presentación, integraciones intercambiables ni varios dominios de negocio.
- No declarar nivel: descartada. Deja el proyecto "sin evaluar" y la deuda abierta.

## Decisión

`nivel: 0` y `tamaño: 500, 1000` en `## Arquitectura`, sin reglas `no importa:` ni carpetas nuevas. Las funciones auxiliares que se usen en más de un script van a `scripts/comun.ps1`.

## Consecuencias

- Positivas: el proyecto queda evaluado, el verify mide el tamaño de los scripts que crecen y la decisión sobre `instalar.ps1` tiene un umbral claro (1000 líneas).
- Negativas: la clasificación del espejo sigue mezclada con I/O, y sus tests siguen necesitando carpetas y repos de prueba.
```

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/sugerir-arquitectura.Tests.ps1` | `tests/` |
| `docs/adr/0003-nivel-0-para-sdd-global-config.md` | `docs/` (implícita) |

## Security Layer

Tipo de proyecto: `tooling`.

- Los artefactos modificados son instrucciones para IA y no exponen secrets ni rutas absolutas con usuario local — Verificación: revisión del diff: ninguna ruta `C:\Users\…` ni token en skills, comandos, `CLAUDE.md`, ADR ni visión.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/CLAUDE.md`, con línea de impacto.
- La sugerencia no ejecuta `/arquitectura` ni escribe `openspec/config.yaml` — Verificación: S01 (el texto exige "sin correrla" y no escribir).

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se corre la suite completa porque cambian `.claude/CLAUDE.md` y skills que leen otros tests.

Son tests de contrato de texto, como los de `srs-en-rama-del-change`: controlan que la skill o el `CLAUDE.md` y su comando generado tengan la instrucción de cada escenario y la línea D1. El comportamiento real se controla con M01. Cada test lleva `# test-plan: sugerir-arquitectura/<ID>` arriba del `Probar`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Claude sugiere la skill arquitectura / Inicio de sesión sin nivel | auto: `.claude/CLAUDE.md` tiene el paso de inicio de sesión con la línea D1, "sin correrla" y sin escribir `openspec/config.yaml` | `tests/sugerir-arquitectura.Tests.ps1` |
| S02 | Claude sugiere la skill arquitectura / Propose sin nivel | auto: `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md` suman D1 al resumen final y dicen que el propose no se bloquea | `tests/sugerir-arquitectura.Tests.ps1` |
| S03 | Claude sugiere la skill arquitectura / Verify con un archivo sobre la advertencia | auto: `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md` tienen el bloque "Sugerencias de arquitectura" en los dos métodos y aclaran que no cambia severidades | `tests/sugerir-arquitectura.Tests.ps1` |
| S04 | Claude sugiere la skill arquitectura / Archive con nivel sin evaluar | auto: `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md` suman D1 en la fase del vault cuando escriben "sin evaluar" | `tests/sugerir-arquitectura.Tests.ps1` |
| S05 | Claude sugiere la skill arquitectura / Proyecto con nivel declarado | auto: `openspec/config.yaml` declara `nivel: 0` y `tamaño: 500, 1000`, y las cuatro fuentes condicionan la sugerencia a la falta de nivel, a la advertencia de tamaño o a "sin evaluar" | `tests/sugerir-arquitectura.Tests.ps1` |
| S06 | Claude sugiere la skill arquitectura / Dato inválido: nivel desconocido | auto: `.claude/CLAUDE.md` y la skill de propose tienen el motivo "no corresponde a ninguna receta" y no corrigen el valor | `tests/sugerir-arquitectura.Tests.ps1` |
| S07 | ADR y visión | auto: existe `docs/adr/0003-nivel-0-para-sdd-global-config.md` con `Estado: aceptada`, `vision.md` lo enlaza, ya no tiene la deuda del nivel y tiene la de `instalar.ps1` | `tests/sugerir-arquitectura.Tests.ps1` |
| M01 | Sugerencia en un proyecto real sin nivel | manual: después de `pwsh scripts/instalar.ps1`, abrir una sesión nueva de Claude Code en un proyecto con `## Arquitectura` sin `nivel` y pegar la línea de sugerencia que muestra; no tiene que haber corrido `/arquitectura` ni modificado `openspec/config.yaml` | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `skills/openspec-verify-change/SKILL.md`, `skills/openspec-propose/SKILL.md`, `skills/openspec-archive-change/SKILL.md` (con `tests/generar-comandos.Tests.ps1` y `tests/srs-en-rama-del-change.Tests.ps1`) | Los comandos generados coinciden con su skill y los textos del archive en dos fases siguen presentes | Se suma la sugerencia (la cubren S02–S04). Los tests existentes no se modifican |
| C02 | `.claude/CLAUDE.md` (con `tests/instalar.Tests.ps1` y `tests/generar-plantillas.Tests.ps1`) | El bloque de reglas del Agente generado entre marcas y los textos de reglas globales | Se suma un paso al inicio de sesión fuera del bloque generado (lo cubre S01). Los tests existentes no se modifican |

## Risks / Trade-offs

- **[La línea se vuelve ruido en proyectos que no quieren evaluar todavía]** → Es una línea por operación y desaparece apenas se declara `nivel`, aunque sea `0`.
- **[El inicio de sesión lee `openspec/config.yaml` en proyectos sin OpenSpec]** → Si no hay archivo o no hay `## Arquitectura`, no sugiere nada.

## Migration Plan

1. Merge y `pwsh scripts/instalar.ps1` en cada máquina.
2. En los proyectos sin `nivel`, correr `/arquitectura` cuando aparezca la sugerencia.

## Open Questions

- Ninguna.
