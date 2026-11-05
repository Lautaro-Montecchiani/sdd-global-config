# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply.

## 1. Propose (skill y comando)

- [x] 1.1 En `skills/openspec-propose/SKILL.md` **y** `.claude/commands/opsx/propose.md`, en "Artifact Creation Guidelines":
  - para las delta specs, los escenarios `Dato inválido:` de design D2 (criterio de "toca un dato externo", casos posibles, qué dice el THEN y su fila en el Test Plan; sin `## Datos` no se aplica);
  - para `design.md`, que cada control de la `## Security Layer` termine con `— Verificación: <Sxx | revisión del diff: … | manual: …>` (D5).

  Texto agregado idéntico en los dos archivos y sin IDs del design. Evidencia: `diff` de las líneas agregadas entre los dos archivos, sin diferencias, y `Select-String -Pattern '\bD\d+\b'` sin resultados en ambos.

## 2. Verify (skill y comando) y branch-pr

- [x] 2.1 En `skills/openspec-verify-change/SKILL.md` **y** `.claude/commands/opsx/verify.md`, en los dos flujos (con Test Plan y legacy):
  - la evaluación de la puerta: dato inesperado (D3 y D4), seguridad (D6, con los patrones de credenciales, los marcadores descartados y la lectura de `gh pr checks`) y explicabilidad (D7, con la "Explicación en simple", las dos preguntas y la regla de `pendiente` sin interfaz);
  - la tabla "Puerta de integración" después de "Architecture Results" (D1);
  - en "Issues by Priority": `no` y `pendiente` como CRITICAL; `no evaluada` y "control sin verificación declarada" como WARNING.

  Texto idéntico en los dos archivos y sin IDs del design. Evidencia: igual que 1.1.
- [x] 2.2 En `skills/branch-pr/SKILL.md`, agregar al checklist la línea de design D9, antes de "`/opsx:verify` pendiente de ejecutar". Evidencia: `Select-String -Path skills/branch-pr/SKILL.md -SimpleMatch -Pattern "Puerta de integración en sí"`.
- [x] 2.3 Verificar con un script en archivo que los cinco archivos de 1.1, 2.1 y 2.2 no contienen `C:\Users`, y pegar la salida.
- [x] 2.4 Commit aparte con los archivos de 1.1, 2.1 y 2.2: `feat: puerta de integración en propose, verify y PR`, con un único bloque final de trailers que incluya `Spec-ID: puerta-de-integracion`.

## 3. CLAUDE.md global

- [x] 3.1 En `.claude/CLAUDE.md`, agregar la sección `## Puerta de integración` después de `## Ficha del proyecto`, con el contenido de design D8. Evidencia: el bloque de la sección pegado en el resumen.
- [x] 3.2 En `.claude/CLAUDE.md`, en `### Pull Requests`, reemplazar la línea de la condición de merge por la de design D8. Evidencia: `Select-String -Path .claude/CLAUDE.md -Pattern "puerta de integración" -Context 0,0`.
- [x] 3.3 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users` ni IDs del design (`\bD\d+\b`), y pegar la salida.
- [x] 3.4 Commit aparte, solo con `.claude/CLAUDE.md`: `feat: puerta de integración en CLAUDE.md`. El cuerpo describe el impacto: todo verify trae la puerta, un "no" o "pendiente" bloquea el merge, sin `## Datos` el dato inesperado queda "no evaluada" y sin interfaz la explicabilidad queda "pendiente". Un único bloque final de trailers con `Spec-ID: puerta-de-integracion`.

## 4. Documentación

- [x] 4.1 En `README.md` y `docs/workflow.md`, agregar una línea que explique la puerta de integración y sus tres preguntas. Evidencia: el diff.
- [x] 4.2 Commit aparte: `docs: puerta de integración en las guías`, con un único bloque final de trailers que incluya `Spec-ID: puerta-de-integracion`.

## 5. Instalación (para que aplique en otros repos)

- [x] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada `.claude/commands/opsx/*.md`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D10). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master" o "con cambios locales".
- [x] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` y **todos** los comandos de `.claude/commands/opsx/`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales.
- [x] 5.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas puerta-de-integracion`) y pushear. Verificar que el espejo contiene "Puerta de integración". **No cambiar la cuenta activa de `gh`**: si el push falla por la cuenta, avisar sin forzar.

## 6. Verificación con Claude y el usuario (no la ejecuta el Agente)

- [x] 6.1 S16 y S17 por revisión de los archivos con los `Select-String` del Test Plan.
- [ ] 6.2 S03, S04 y S09 con `/opsx:propose` en una sesión nueva en el repo descartable M.
- [x] 6.3 S02, S05 a S08, S10 a S12 y S15 con `/opsx:verify prueba` en sesiones nuevas en los repos descartables K1 a K5 y L.
- [ ] 6.4 S01, S13 y S14: el usuario corre `/opsx:verify prueba` en una sesión interactiva en el repo K3 y responde las preguntas de explicabilidad.
- [ ] 6.5 Verificar que el cambio aplica en un proyecto de prueba

## 7. Corrección del desvío del verify

- [ ] 7.1 En `skills/openspec-verify-change/SKILL.md` **y** `.claude/commands/opsx/verify.md`, mover la evaluación de la puerta al flujo que corresponde:
  - en el paso 8 del flujo con Test Plan ("Verify Coherence & Generate Report") hay dos bloques `**Integration Gate Verification (Puerta de integración)**` seguidos. Borrar el **primero** (el que tiene la línea "In legacy flow (changes without Test Plan), only check…") y dejar el segundo sin cambios;
  - en el paso 8 del "Legacy method (changes without Test Plan)" ("Generate Verification Report"), agregar un bloque `**Integration Gate Verification (Puerta de integración)**` justo después de "Apply Summary Verification (Vault)" y antes de "Summary Scorecard", con la sangría de ese paso. Su texto es el del bloque que queda en el flujo con Test Plan, salvo la viñeta "If all have it, check each corresponding Test Plan ID…", que se reemplaza por: "If all have it, the result is `sí` (in this flow there is no Test Plan: only check that the scenario starting with `Dato inválido:` exists in the delta specs, without checking Test Plan IDs)."
  - no tocar ninguna otra línea (las diferencias previas de sangría en "Architecture Verification" del flujo legacy quedan como están).

  Texto agregado idéntico en los dos archivos y sin IDs del design. Evidencia, para cada archivo: `Select-String -SimpleMatch -Pattern "Integration Gate Verification"` con dos resultados, uno antes y otro después de la línea `**Legacy method`; `Select-String -SimpleMatch -Pattern "In legacy flow"` sin resultados; `Select-String -SimpleMatch -Pattern "in this flow there is no Test Plan"` con un resultado, después de `**Legacy method`; y `git diff` de los dos archivos.
- [ ] 7.2 Commit aparte con los dos archivos de 7.1: `fix: puerta de integración en el flujo legacy del verify`, con un único bloque final de trailers que incluya `Spec-ID: puerta-de-integracion`. **No cambiar la cuenta activa de `gh` ni hacer push.**

La reinstalación en `~/.claude` y la verificación del desvío las hace Claude después del apply.

## Workflow follow-up

- Abrir PR `[puerta-de-integracion] Puerta de integración: dato inesperado, seguridad y explicabilidad` desde `change/puerta-de-integracion`, con `Closes #29`.
- `/opsx:verify puerta-de-integracion` antes del merge, **en una sesión interactiva** (este mismo change ya se verifica con la puerta), y `/opsx:archive` después.
- Pendiente aparte: sumar a las plantillas del Agente la regla de no cambiar la cuenta activa de `gh`.
