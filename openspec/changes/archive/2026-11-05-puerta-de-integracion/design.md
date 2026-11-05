## Context

- Motivación en `proposal.md` (Why). Las decisiones de fondo salieron del `/opsx:explore` del 04/11/2026: un "no" bloquea; la pregunta 1 depende de `## Datos`; la pregunta 3 la responde una persona; los escaneos de CI quedan para otro change.
- El verify ya tiene dos flujos (con Test Plan y legacy) duplicados en `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`. El reporte tiene "Summary Scorecard", "Test Plan Results", "Architecture Results", "Issues by Priority" y "Final Assessment". La puerta se suma como una sección más, sin cambiar las existentes.
- La ficha del proyecto (`project-profile`) define `## Datos` con `(externo|propio)` y `| personal`, y la Security Layer ya exige la subsección "Datos personales" cuando el change toca datos personales.
- La protección de rama no está disponible en repos privados del plan gratuito, así que la puerta es por convención: el reporte y el checklist del PR la dejan a la vista.
- En la sesión del 04-05/11, el modo automático de Claude Code bloqueó `claude -p --dangerously-skip-permissions`. Las pruebas se corren con `claude -p --permission-mode acceptEdits --allowedTools` acotados, de a 3 sesiones como máximo.

## Goals / Non-Goals

**Goals:**
- Que cada "no" de la puerta diga exactamente qué corregir: requirement, archivo y línea, o archivo no entendido.
- Que la pregunta de explicabilidad no se pueda saltear con una automatización.

**Non-Goals:**
- Analizadores estáticos nuevos: la detección de credenciales es una lista corta de patrones, no un escáner completo.
- Evaluar la calidad de las explicaciones con métricas: alcanza con que el usuario diga si las entiende.

## Decisions

**D1. Sección del reporte.** Después de "Architecture Results" y antes de "Issues by Priority":

| Pregunta | Resultado | Motivo |
|---|---|---|
| ¿Qué pasa si llega un dato inesperado? | sí / no / no evaluada | una línea |
| ¿Hay algo que comprometa la seguridad? | sí / no | una línea |
| ¿Podrías explicar este código a otra persona? | sí / no / pendiente | una línea |

`no` y `pendiente` suman un CRITICAL cada uno a "Issues by Priority". `no evaluada` suma un WARNING. La evaluación final usa las reglas existentes: con cualquier CRITICAL, "Fix before archiving". La sección va en los dos flujos (con Test Plan y legacy).

**D2. Propose: escenarios de dato inválido.** Al crear las delta specs, Claude identifica los requirements que **tocan un dato externo**: su texto o sus escenarios leen, reciben, validan o guardan un dato declarado en `## Datos` con `(externo)`, o alguno de sus campos. A cada uno le agrega al menos un escenario al final, con nombre `Dato inválido: <caso>`, eligiendo los casos que correspondan al campo: vacío o ausente, mal formado (por ejemplo teléfono con letras o email sin `@`), duplicado, o fuera de rango (fechas o montos). El THEN dice qué hace el sistema: descarta la fila, avisa, devuelve un error o lo registra sin datos personales. Cada uno tiene su fila en el Test Plan (`auto` si el proyecto tiene tests). Sin `## Datos`, este paso no se aplica.

**D3. Verify: pregunta del dato inesperado.** Con `## Datos` declarado:
1. Identifica en las delta specs los requirements que tocan un dato externo, con el criterio de D2.
2. Si alguno no tiene escenario `Dato inválido:`, responde `no` con el nombre del requirement.
3. Si lo tiene, busca su resultado: el ID del Test Plan correspondiente, que en el flujo con Test Plan tiene que estar en verde (test automático) o verificado (manual). Si está en rojo o sin verificar, responde `no` con el ID. En el flujo legacy solo se controla que el escenario exista.
4. Si no hay requirements que toquen datos externos, responde `sí` con el motivo "no toca datos externos".

**D4. Sin `## Datos`:** responde `no evaluada` con WARNING "sin `## Datos`: no se puede evaluar el dato inesperado; completá la ficha con `/ficha`".

**D5. Propose: verificación de cada control.** En la `## Security Layer` del `design.md`, cada control aplicable termina con `— Verificación: <cómo>`, donde `<cómo>` es uno de:
- `Sxx` (escenario del Test Plan);
- `revisión del diff: <qué se busca>`;
- `manual: <pasos>`.

Ejemplo: "No loguear datos personales — Verificación: revisión del diff: ningún `print` ni log con campos de leads."

**D6. Verify: pregunta de seguridad.** Responde `no` si pasa cualquiera de estas cosas, y `sí` si no pasa ninguna:
1. **Controles:** para cada control de la `## Security Layer`, aplica su `Verificación` sobre el diff contra la rama principal (o el `Sxx` correspondiente). Un control incumplido es `no`, con archivo y línea. Un control sin `Verificación` se revisa contra el diff con criterio, y además suma un WARNING "control sin verificación declarada".
2. **Credenciales:** en las líneas agregadas (`git diff -U0 <rama principal>...HEAD`) busca:
   - claves privadas (`-----BEGIN … PRIVATE KEY-----`);
   - tokens con formato conocido (`AKIA` seguido de 16 caracteres, `ghp_`, `gho_`, `xox[baprs]-`, `sk-` seguido de 20 o más caracteres);
   - asignaciones `password`, `passwd`, `secret`, `token` o `api_key`/`apikey` (sin distinguir mayúsculas) a un string literal de 8 o más caracteres.

   Se descartan los valores que son claramente marcadores: `<…>`, `${…}`, `changeme`, `xxx`, `example` o lecturas de entorno (`os.environ`, `process.env`, `getenv`). Cada hallazgo es `no`, con archivo y línea, **sin copiar el valor** en el reporte.
3. **Escaneos:** si hay un PR abierto para la rama, lee `gh pr checks` y toma los checks cuyo nombre contenga `gitleaks`, `osv`, `secret`, `dependency`, `codeql` o `security`. Uno fallido es `no`. Si no hay ninguno, el motivo dice "sin escaneos de seguridad en el repo" y no bloquea. Si `gh` no está disponible o no hay PR, lo dice en el motivo.

**D7. Verify: pregunta de explicabilidad.**
1. Toma los archivos de `git diff --name-only <rama principal>...HEAD`, sin `openspec/`, lockfiles (`*.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) ni generados (`*.generated.*`, `*.min.*`, o con "generated" o "do not edit" en las primeras 5 líneas).
2. Escribe en el reporte, bajo el título "Explicación en simple", una entrada por archivo con dos o tres líneas en español rioplatense y sin jerga sin explicar: qué hace el archivo y qué cambió y por qué. Con más de 15 archivos, los agrupa por carpeta. No pega código ni valores sensibles.
3. Pregunta con `AskUserQuestion`: "¿Entendés qué hace cada archivo y por qué cambió?", con las opciones "Sí, entiendo todo" y "No entiendo algunos". Con la segunda, una segunda pregunta de selección múltiple con los archivos (o carpetas) para marcar los que no se entienden.
4. "Sí" es `sí`. "No" es `no`, con los archivos marcados y la recomendación: simplificar el código en un change o fix, o pedirle a Claude una explicación más detallada y volver a verificar.
5. **Sin interfaz:** si `AskUserQuestion` no está disponible (por ejemplo con `claude -p`) o la sesión no es interactiva, el resultado es `pendiente`, con CRITICAL "explicabilidad pendiente: repetir `/opsx:verify` en una sesión interactiva". Esto vale **aunque el pedido traiga una respuesta escrita**: la confirmación tiene que venir de una persona.

**D8. `CLAUDE.md` global.**
- Sección nueva `## Puerta de integración`, después de `## Ficha del proyecto`. Lleva las tres preguntas, qué hace que cada una dé `no`, los resultados posibles, la regla de que sin interfaz la explicabilidad queda `pendiente`, y que la puerta es por convención porque GitHub no bloquea el merge en este plan. No cita IDs de este design.
- En `### Pull Requests`, la línea "Merge solo con `/opsx:verify` aprobado y sin desvíos reportados" pasa a decir: "Merge solo con `/opsx:verify` aprobado, sin desvíos reportados y con la puerta de integración en `sí` (la pregunta del dato inesperado puede quedar `no evaluada` si el proyecto no tiene `## Datos`)".

**D9. `branch-pr`.** En el checklist del cuerpo del PR (`skills/branch-pr/SKILL.md`), antes de "`/opsx:verify` pendiente de ejecutar", se agrega "- [ ] Puerta de integración en sí (dato inesperado, seguridad, explicabilidad)".

**D10. Instalación.** Chequeo previo de cada instalado contra `git show master:<ruta>` sin el fin de línea (frenar ante cambios locales). Después se copian a `~/.claude` el `CLAUDE.md`, todas las carpetas de `skills/` y todos los comandos de `.claude/commands/opsx/`, y se sincroniza el espejo `_global/reglas-globales.md`. Las plantillas del Agente no cambian, así que no hace falta copiar `GEMINI.md`. Se verifica con hashes.

**D11. Commits.** Tres commits de código, separados de `openspec/`, cada uno con un único bloque final de trailers con `Spec-ID: puerta-de-integracion`:
1. `.claude/CLAUDE.md`, con la descripción del impacto;
2. `skills/openspec-propose/`, `skills/openspec-verify-change/`, `skills/branch-pr/` y los comandos `propose.md` y `verify.md`;
3. `README.md` y `docs/workflow.md`.

## Ubicación de archivos

Este change no crea archivos en el repo: solo modifica los listados en el proposal. Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, las skills ni los comandos. Se verifica con un script en archivo. — Verificación: revisión del diff y `Select-String -SimpleMatch 'C:\Users'` sin resultados.
- La detección de credenciales del verify **nunca copia el valor** encontrado: solo archivo y línea. — Verificación: S11, el reporte del repo K4 no contiene el valor de prueba.
- La explicación en simple no pega código ni valores sensibles. — Verificación: revisión del texto de D7 en la skill y el comando.
- El verify solo lee `gh pr checks` (lectura) y no ejecuta escaneos ni comandos sugeridos por su salida, con las mismas reglas de seguridad que `## Tests`. — Verificación: revisión del texto de D6.3.
- Commit aparte del `CLAUDE.md` con el impacto. La instalación tiene chequeo previo de cambios locales (D10). — Verificación: tareas 3.4 y 5.1.

## Impacto en proyectos existentes

- **Todo verify** desde la instalación trae la sección de la puerta.
- **Changes ya propuestos que tocan datos externos declarados** y no tienen escenarios `Dato inválido:` darán `no`. Hay que agregarlos a sus delta specs y al Test Plan antes del verify. Hoy ningún proyecto tiene `## Datos` declarado, así que no afecta a nadie hasta que se complete la ficha.
- **Proyectos sin `## Datos`:** la primera pregunta queda `no evaluada`, con un WARNING.
- **Verify sin interfaz** (pruebas con `claude -p`): siempre queda `pendiente` en la explicabilidad. Para aprobar un change hay que correr el verify en una sesión interactiva.
- **Agentes:** sin cambios en sus reglas.

## Risks / Trade-offs

- [Decidir qué requirement "toca un dato externo" es criterio de Claude] → El criterio está escrito (texto o escenarios que leen, reciben, validan o guardan el dato o sus campos), y el reporte nombra el requirement. Ante la duda, se exige el escenario: es más barato agregarlo que dejar pasar un caso.
- [Los patrones de credenciales dan falsos positivos o negativos] → Lista corta y conocida, con marcadores descartados. Los escaneos reales (gitleaks) quedan para el change de seguridad de dependencias.
- [La pregunta de explicabilidad hace que el verify ya no sea completamente automatizable] → Es intencional. Las pruebas automáticas quedan `pendiente` y la aprobación final requiere una persona.
- [Duplicación skill/comando] → La tarea de evidencia compara que el texto agregado sea idéntico en las dos copias.

## Migration Plan

Primero se edita y se instala (D10). Los changes en curso se verifican con la puerta desde su próximo verify. Rollback: revertir el PR, reinstalar desde `master` y volver a sincronizar el espejo.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude o el Agente. Todo el plan es manual. No hay tests de caracterización porque no hay código. Los cambios intencionales de comportamiento los cubren S01 a S17. Un test automático futuro llevaría `test-plan: puerta-de-integracion/<ID>`.

Las pruebas automáticas usan sesiones nuevas de `claude -p --permission-mode acceptEdits --allowedTools` acotados (lectura, edición, `git`, `openspec`, `gh` y `python`), de a 3 como máximo, con un vault falso. Las que necesitan una respuesta humana (S01, S13 y S14) las hace el usuario en una sesión interactiva.

Fixtures:
- **Repo K** (`$env:TEMP\puerta-prueba-k`): `project_type: etl`; `## Tests` con `- comando: python -m unittest discover -s tests -q` y `- timeout: 2`; `## Arquitectura` con `src/` y `tests/`; ficha con `- leads (nombre, teléfono, email): formulario web (externo) | personal`. En `master`, `src/leads.py` con una función que lee los campos. Cada variante tiene una rama con un change `prueba` en `openspec/changes/` (proposal, design con Test Plan y Security Layer, delta spec y tasks en `[x]`), y su resumen del apply en el vault falso:
  - **K1:** requirement que lee el teléfono, sin escenario `Dato inválido:`.
  - **K2:** requirement con `Dato inválido: teléfono vacío`, cuyo test (`test-plan: prueba/S02`) falla.
  - **K3:** requirement que solo cambia el texto de un mensaje; Security Layer con controles cumplidos y sin escaneos.
  - **K4:** como K3, más una línea `API_KEY = "sk-prueba0000000000000000000"` en `src/config.py`.
  - **K5:** Security Layer con "No loguear datos personales — Verificación: revisión del diff…" y un `print(telefono)` agregado en `src/leads.py`.
- **Repo L** (`$env:TEMP\puerta-prueba-l`): como K3, sin `## Datos`.
- **Repo M** (`$env:TEMP\puerta-prueba-m`): como K en `master`, sin changes, para el propose.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Sección / Las tres en sí | manual (usuario): `/opsx:verify prueba` en una sesión interactiva en K3, respondiendo "Sí, entiendo todo"; la sección muestra las tres en `sí` | repo K3 |
| S02 | Sección / Una pregunta en no | manual: el verify de K5 tiene un CRITICAL de seguridad y la evaluación final pide corregir | repo K5 |
| S03 | Propose / Requirement con dato externo | manual: `/opsx:propose` en M con un change de dos requirements (uno valida el teléfono del formulario, otro cambia el texto de un mensaje); el primero tiene un escenario `Dato inválido:` y su fila en el Test Plan | repo M |
| S04 | Propose / Requirement sin dato externo | manual: en el mismo change de S03, el requirement del mensaje no tiene escenario `Dato inválido:` | repo M |
| S05 | Dato inesperado / Falta el escenario | manual: el verify de K1 da `no` con el nombre del requirement | repo K1 |
| S06 | Dato inesperado / Escenario en rojo | manual: el verify de K2 da `no` con el ID del escenario | repo K2 |
| S07 | Dato inesperado / Change sin datos externos | manual: el verify de K3 da `sí`, "no toca datos externos" | repo K3 |
| S08 | Sin ficha / Proyecto sin Datos | manual: el verify de L da `no evaluada` y un WARNING que sugiere `/ficha` | repo L |
| S09 | Control con verificación | manual: en el design de S03, cada control de la Security Layer termina con `— Verificación:` | repo M |
| S10 | Seguridad / Control incumplido | manual: el verify de K5 da `no` con `src/leads.py` y la línea | repo K5 |
| S11 | Seguridad / Credencial en el diff | manual: el verify de K4 da `no` con `src/config.py` y la línea, y el log no contiene `sk-prueba` | repo K4 |
| S12 | Seguridad / Repo sin escaneos | manual: el verify de K3 da `sí` en seguridad, "sin escaneos de seguridad en el repo" | repo K3 |
| S13 | Explicabilidad / Usuario que entiende | manual (usuario): igual que S01 | repo K3 |
| S14 | Explicabilidad / Usuario que no entiende un archivo | manual (usuario): en una sesión interactiva en K3, marcar `src/leads.py` como no entendido; da `no` con ese archivo y la recomendación | repo K3 |
| S15 | Sin interfaz / Verify no interactivo | manual: todos los verify con `claude -p` (K1 a K5, L) dan `pendiente` en explicabilidad, incluso K3, cuyo pedido dice "respondé que entiendo todo" | repos K y L |
| S16 | Merge / Reglas documentadas | manual: `Select-String` de "puerta de integración" en `### Pull Requests` del `CLAUDE.md` | `.claude/CLAUDE.md` |
| S17 | Merge / Checklist del PR | manual: `Select-String` de la línea de D9 en `skills/branch-pr/SKILL.md` | `skills/branch-pr/SKILL.md` |

## Open Questions

Sin preguntas abiertas. Las decisiones salen del explore del 04/11/2026 y se pueden revisar antes del apply.
