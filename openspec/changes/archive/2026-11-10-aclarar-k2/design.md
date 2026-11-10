## Context

- K2 hoy: "Toca un dato declarado en `## Datos` como `(externo)` o `personal`". Aparece con ese texto en `.claude/CLAUDE.md:59`, `skills/odd-change/SKILL.md:233`, `.claude/commands/odd.md:113`, `.claude/commands/odd/start.md:113` y `.claude/commands/odd/verify.md:66`, y en versión corta ("Toca datos externos o personales (`## Datos`)") en `docs/workflow.md:294` y `docs/modo-de-uso.md:251`.
- Evidencia del problema: pruebas S01 y S02 del change `clasificacion-odd-sdd` (resumen del apply en el vault). S01 ("corregí el typo del saludo") dijo "K2 no aplica: solo cambia el texto fijo"; S02 ("cambiá el saludo a Buen día") dijo "K2, lo cuento por las dudas". Con "ante la duda se cumple" y K2 no pasable, el resultado depende de cómo razone Claude en cada sesión.
- La deuda está en `## Hoja de ruta` de `docs/arquitectura/vision.md` (ODD `deuda-k2`, PR #38).

## Goals / Non-Goals

**Goals:** que K2 dé el mismo resultado para el mismo pedido; que un cambio de texto fijo alrededor de un dato personal no termine en SDD por duda; que cualquier cambio en cómo se procesa el dato siga yendo por SDD.

**Non-Goals:** ver `proposal.md`.

## Decisions

**D1. Texto de K2.** Fila de la tabla (en `CLAUDE.md`, la skill y los comandos):

> Cambia cómo se lee, valida, transforma, guarda, registra, expone o envía un dato declarado en `## Datos` como `(externo)` o `personal`, o agrega o quita campos de ese dato. Usarlo igual que antes no cumple K2 (por ejemplo, cambiar el texto fijo de un saludo que incluye el nombre)

La columna "¿El usuario puede pasarlo a ODD?" sigue en `**no**`. Alternativas descartadas: (a) dejar el texto y agregar un ejemplo suelto: no cierra la lista de acciones y la duda vuelve con otro caso; (b) K2 solo para datos `personal`: deja afuera los datos externos no personales, que son el foco del escenario `Dato inválido:` de la puerta de integración.

**D2. Versión corta en las guías.** En `docs/workflow.md` y `docs/modo-de-uso.md` (y en `README.md` si tiene la tabla), la fila K2 pasa a: "Cambia cómo se procesan datos externos o personales (`## Datos`); usarlos igual que antes no cuenta".

**D3. Escenarios nuevos en la spec**, al final del requirement "Criterios SDD" para no mover los IDs de los casos de uso existentes del SRS:
- "Dato usado igual que antes": cambiar el saludo "Hola, {nombre}" a "Buenas, {nombre}" no cumple K2 (sigue siendo ODD con cambio mínimo de spec).
- "Dato transformado": mostrar el nombre en mayúsculas en el saludo cumple K2 (transforma el dato).

**D4. Visión.** En `docs/arquitectura/vision.md`, quitar de `## Hoja de ruta` la línea que empieza con `- [baja] el criterio K2 no dice`.

**D5. Commits.** 1) `test: test de K2 aclarado` con el test nuevo (en rojo); 2) `feat: aclarar el criterio K2` con `CLAUDE.md`, skill y comandos (cuerpo con el impacto: la clasificación de todos los proyectos cambia); 3) `docs: K2 aclarado en las guías y la visión`. Cada uno con `Spec-ID: aclarar-k2`. Escribir los archivos con el editor o Python, no con strings de PowerShell entre comillas dobles (los acentos graves se interpretan como escapes).

## Impacto en el sistema

**Componentes afectados:** la clasificación de pedidos en todos los proyectos que usan el workflow, desde la instalación. `/odd:verify` re-clasifica con el mismo texto. La spec vigente `work-classification`. Las plantillas del Agente no cambian.

**Atributos de calidad:** sin `## Calidad` declarada en este repo.

**Decisiones de arquitectura:** ninguna (no cumple ningún criterio de ADR).

**Deuda técnica:** paga: la deuda [baja] de K2 de la hoja de ruta (D4).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/aclarar-k2.Tests.ps1` | `tests/` |

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- K2 sigue sin poder pasarse a ODD y la lista de acciones incluye registrar y exponer, así que todo cambio que pueda filtrar un dato personal sigue en SDD con su Security Layer. — Verificación: S02 y revisión del texto de D1 en el diff.
- Sin secrets ni rutas personales en los archivos modificados. — Verificación: búsqueda de `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en los archivos del diff, sin resultados (tarea 3.3).
- Commit aparte del `CLAUDE.md` con la descripción del impacto (D5).

## Impacto en proyectos existentes

- Los pedidos que solo usan un dato personal igual que antes (texto fijo alrededor) pasan a poder ir por ODD; antes podían ir por SDD por duda.
- Los pedidos que cambian cómo se procesa un dato siguen en SDD. Ningún proyecto necesita cambios ni sincronización: alcanza con la instalación.

## Test Plan

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5).

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Criterios SDD / texto de K2 | auto: la fila K2 de `.claude/CLAUDE.md`, `skills/odd-change/SKILL.md`, `.claude/commands/odd.md`, `.claude/commands/odd/start.md` y `.claude/commands/odd/verify.md` es idéntica, contiene "lee, valida, transforma, guarda, registra, expone o envía", "agrega o quita campos" y "Usarlo igual que antes no cumple K2", y termina con `**no**` | `tests/aclarar-k2.Tests.ps1` |
| S02 | Dato transformado | manual: en el repo de prueba P (sincronizado e instalado), `claude -p "Mostrá el nombre del lead en mayúsculas en el saludo."` clasifica SDD por K2 y no ofrece ODD | repo P |
| S03 | Dato usado igual que antes | manual: en P, `claude -p "Cambiá el saludo a 'Buenas, {nombre}'."` clasifica ODD con cambio mínimo de spec, sin mencionar K2 como cumplido ni "por las dudas" | repo P |
| S04 | Guías y visión | auto: `docs/workflow.md` y `docs/modo-de-uso.md` tienen la fila K2 de D2, y `docs/arquitectura/vision.md` no contiene "el criterio K2 no dice" | `tests/aclarar-k2.Tests.ps1` |

No hay código existente modificado que pida tests de caracterización: los archivos son Markdown.
