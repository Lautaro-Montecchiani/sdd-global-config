# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply.

## 1. Skill y comandos ODD

- [ ] 1.1 Crear `skills/odd-change/SKILL.md` con frontmatter (`name: odd-change` y una `description` que diga cuándo usarla) y tres secciones: "Inicio (`/odd`)" con design D5 y el formato del documento de D4; "Verify (`/odd:verify`)" con D7; "Cierre (`/odd:close`)" con D8 y la nota del vault de D9. Más una sección "Escalado" con D10 y el resumen de la clasificación (criterios K1 a K10 y reglas de cambio de D2 y D3) y la relación con el rol de arquitecto de D18 (documento en `docs/odd/`, sin ADR por K10, lectura de la visión al escribir el documento, control de visión en el verify y `arquitectura.md` en el cierre). Sin IDs del design salvo K1 a K10. Evidencia: `Get-Content skills/odd-change/SKILL.md | Select-Object -First 10` y `Select-String -Pattern '\bD\d+\b'` sin resultados.
- [ ] 1.2 Crear `.claude/commands/odd/start.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd/close.md`, cada uno con frontmatter (`name`, `description`, `category: Workflow`) y el texto de la sección correspondiente de la skill (y "Escalado" en `start.md` y `verify.md`). Crear `.claude/commands/odd.md` con el mismo contenido que `start.md` (design D15). Evidencia: `diff` entre cada comando y su sección de la skill, sin diferencias en el cuerpo, y `Compare-Object` entre `odd.md` y `odd/start.md` sin diferencias.
- [ ] 1.3 En `skills/branch-pr/SKILL.md`, aceptar `odd/{nombre}` con los controles de design D14 (documento `docs/odd/{nombre}.md` en vez de los artefactos OpenSpec, trailer `Spec-ID: odd-{nombre}` y "`/odd:verify` pendiente de ejecutar" y la línea de la puerta "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)" en el checklist). El caso `change/` no cambia. Evidencia: `git diff skills/branch-pr/SKILL.md`.
- [ ] 1.4 Verificar con un script en archivo que los archivos de 1.1 a 1.3 no contienen `C:\Users`, y pegar la salida.
- [ ] 1.5 Commit aparte con los archivos de 1.1 a 1.3: `feat: flujo ODD (skill, comandos y branch-pr)`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 2. CLAUDE.md global y config

- [ ] 2.1 En `.claude/CLAUDE.md`, agregar la sección `## Clasificación ODD / SDD` después de `## Reglas globales (obligatorias)`, con el contenido de design D12 (cuándo se clasifica, tabla K1 a K10 con la columna de qué se puede pasar por alto, anuncio y cambio de clasificación, flujo ODD resumido, escalado, y las dos oraciones de D18 sobre ADR y visión). Evidencia: el bloque de la sección pegado en el resumen.
- [ ] 2.2 En `.claude/CLAUDE.md`, aplicar el resto de design D12: reglas 4 y 9, la oración ODD al final de la regla 7 del Agente, `### Branches`, la condición de merge ODD en `### Pull Requests`, el resultado `no aplica (ODD)` en "Resultados y condición de merge" de la puerta de integración, las tres filas de la tabla "Cuándo actuar", el comentario en "Estructura del vault" y el bloque "Escribir nota de ODD (al `/odd:close`)" en "Comandos PowerShell". Evidencia: `git diff .claude/CLAUDE.md`.
- [ ] 2.3 En `openspec/config.yaml`, reemplazar OBJ-01 y agregar las tres entradas del glosario de design D11. Evidencia: `git diff openspec/config.yaml`.
- [ ] 2.4 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users` ni IDs del design (`\bD\d+\b`), y pegar la salida. Después, commit aparte con `.claude/CLAUDE.md` y `openspec/config.yaml`: `feat: clasificación ODD / SDD en las reglas globales`. El cuerpo describe el impacto: Claude clasifica todo pedido que cambia archivos, los cambios que no tocan specs, datos, seguridad ni contratos van por ODD con un único documento, y el ODD cerrado se guarda en el vault. Un único bloque final de trailers con `Spec-ID: clasificacion-odd-sdd`.

## 3. Plantillas del Agente y CI

- [ ] 3.1 En `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`, agregar la sección `## Handoff ODD` después de `## Reglas de ejecución (obligatorias)`, con el contenido de design D6 y texto idéntico en las cuatro, y sumar al final de la regla 7 de cada una la oración ODD de design D13. Evidencia: `Select-String -SimpleMatch "## Handoff ODD"` con un resultado por archivo, `Select-String -SimpleMatch "En un handoff ODD, pegá la evidencia"` con un resultado por archivo, y un script en archivo que extrae la sección de cada plantilla y muestra que las cuatro son iguales.
- [ ] 3.2 En `.github/workflows/pr-check.yml`, paso "Check branch name": aceptar `change/` u `odd/` y listar las dos convenciones en el mensaje de error (design D14). No tocar los demás pasos. Evidencia: `git diff .github/workflows/pr-check.yml`.
- [ ] 3.3 Commit aparte con los archivos de 3.1 y 3.2: `feat: handoff ODD en las plantillas y branches odd en CI`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 4. Documentación

- [ ] 4.1 En `README.md`: una fila nueva en la tabla "Qué contiene" para `skills/odd-change/` y `.claude/commands/odd/`, y en "Flujo resumido" un segundo bloque con el flujo ODD (`/odd`, Agente, PR, `/odd:verify`, merge, `/odd:close`) y una línea con cuándo se usa cada uno. Evidencia: el diff.
- [ ] 4.2 En `docs/workflow.md` y `docs/modo-de-uso.md`: una sección "Cambios chicos: ODD" con los criterios de clasificación en una tabla corta, los tres comandos, qué se guarda en el vault y el escalado. Evidencia: el diff.
- [ ] 4.3 Crear `docs/arquitectura/vision.md` copiando el contenido del bloque `markdown` de `## Visión inicial` del design, sin cambios. Evidencia: `Select-String -Pattern '^## '` con las cinco secciones (Propósito, Contexto e integraciones, Componentes, Decisiones vigentes, Hoja de ruta) y un script en archivo que compara el archivo con el bloque del design, sin diferencias.
- [ ] 4.4 Commit aparte con los archivos de 4.1 a 4.3: `docs: flujo ODD en las guías y visión del repo`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 5. Instalación (para que aplique en otros repos)

- [ ] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada archivo de `.claude/commands/`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D16). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master", "con cambios locales" o "nuevo".
- [ ] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` y **todos** los comandos de `.claude/commands/` (`opsx/`, `odd/` y `odd.md`). Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales.
- [ ] 5.3 Si la máquina usa Antigravity, copiar `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md` (fusionar si tiene contenido propio). Evidencia: `Select-String -SimpleMatch "## Handoff ODD"` en el instalado.
- [ ] 5.4 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas clasificacion-odd-sdd`) y pushear. Verificar que el espejo contiene "Clasificación ODD / SDD". **No cambiar la cuenta activa de `gh`**: si el push falla por la cuenta, avisar sin forzar.

## 6. Verificación con fixtures

6.1 y 6.2 las hace Claude. 6.3, 6.5 y 6.6 las ejecuta el Agente con sesiones `claude -p` y el vault falso, siguiendo un instructivo `verificacion.md` que Claude agrega al change al armar los fixtures. 6.4 la hace el usuario en una sesión interactiva.


- [ ] 6.1 S16 a S20 y S24 por revisión de los archivos con los `Select-String` del Test Plan.
- [ ] 6.2 Armar el repo P y el vault falso V del Test Plan en `$env:TEMP`, con el remote bare de V.
- [ ] 6.3 S01 a S05 y S21 con pedidos en sesiones nuevas en P (`claude -p` acotado). En S04 y S21, el segundo pedido pide ODD explícitamente.
- [ ] 6.4 S06, S09, S12 a S14 y S23: el usuario corre `/odd typo-bienvenida`, aprueba el documento, hace que el Agente implemente (S08), corre `/odd:verify` en una sesión interactiva, mergea en P, corre `/odd:close` y abre una sesión nueva. S07 se controla en V después de S06.
- [ ] 6.5 S10, S11, S15 y S22 con ramas `odd/*` armadas a mano en P y sesiones nuevas.
- [ ] 6.6 Verificar que el cambio aplica en un proyecto de prueba. Evidencia: con la versión instalada en `~/.claude` y las plantillas copiadas en P, los resultados de S01 a S15 y S21 a S23 coinciden con el Test Plan.

## Workflow follow-up

- Issue #32 creado y registrado en el proposal.
- Abrir PR `[clasificacion-odd-sdd] Clasificación ODD / SDD y flujo ODD con cierre en Obsidian` desde `change/clasificacion-odd-sdd`, con `Closes #32`.
- `/opsx:verify clasificacion-odd-sdd` antes del merge, en una sesión interactiva, y `/opsx:archive` después.
- En cada proyecto que quiera usar ODD: volver a copiar las plantillas del Agente y el `pr-check.yml`.
