# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 minutos). Cada tarea con tests pega en el resumen del apply la salida en rojo (antes) y en verde (después). Las tareas de la sección 7 son manuales (instructivo `verificacion.md`). Las plantillas de `templates/comun/`, `copilot/`, `cursor/` y `antigravity/` no se editan a mano: se edita `templates/fuente/` y se regenera (design D13).

## 1. Tests primero

- [x] 1.1 C02, en verde antes de tocar `pr-check.yml`: copiar `.github/workflows/pr-check.yml` sin cambios a `tests/datos/pr-check-antes.yml` y crear `tests/clasificacion-odd.Tests.ps1` (mismo estilo que `tests/generar-plantillas.Tests.ps1`: carga `apoyo.ps1`, `Probar`, `Afirmar`) con el test `C02 pr-check sin cambios fuera del paso de branch` (marcador `# test-plan: clasificacion-odd-sdd/C02`) según design D19. Correr el comando de tests: todo en verde. Evidencia: la salida.
- [x] 1.2 En `tests/generar-plantillas.Tests.ps1`, ajustar `Limpiar-PlantillaParaC01` con las dos quitas exactas de design D19 y sumar el marcador `# test-plan: clasificacion-odd-sdd/C01` debajo del existente. No tocar `tests/datos/plantillas-antes/` ni ninguna otra aserción. Correr el comando de tests: C01 en verde. Evidencia: `git diff tests/generar-plantillas.Tests.ps1` y la salida.
- [x] 1.3 Test primero: en `tests/clasificacion-odd.Tests.ps1`, los tests S16, S17, S18, S19, S20 y S25 del Test Plan del design, cada uno con su marcador `# test-plan: clasificacion-odd-sdd/<ID>` y las aserciones de su fila (sin escribir archivos). Correr el comando de tests: los seis en rojo, C01, C02 y los tests de `sincronizar-reglas` en verde. Evidencia: la salida.
- [x] 1.4 Commit aparte con los archivos de 1.1 a 1.3: `test: tests del flujo ODD`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 2. Skill y comandos ODD

- [x] 2.1 Crear `skills/odd-change/SKILL.md` con frontmatter (`name: odd-change` y una `description` que diga cuándo usarla) y tres secciones: "Inicio (`/odd`)" con design D5 y el formato del documento de D4; "Verify (`/odd:verify`)" con D7; "Cierre (`/odd:close`)" con D8 y la nota del vault de D9. Más una sección "Escalado" con D10 y el resumen de la clasificación (criterios K1 a K10 y reglas de cambio de D2 y D3) y la relación con el rol de arquitecto de D18 (documento en `docs/odd/`, sin ADR por K10, lectura de la visión al escribir el documento, control de visión en el verify y `arquitectura.md` en el cierre). Sin IDs del design salvo K1 a K10. Evidencia: `Get-Content skills/odd-change/SKILL.md | Select-Object -First 10` y `Select-String -Pattern '\bD\d+\b'` sin resultados.
- [x] 2.2 Crear `.claude/commands/odd/start.md`, `.claude/commands/odd/verify.md` y `.claude/commands/odd/close.md`, cada uno con frontmatter (`name`, `description`, `category: Workflow`) y el texto de la sección correspondiente de la skill (y "Escalado" en `start.md` y `verify.md`). Crear `.claude/commands/odd.md` igual a `start.md` (design D15). Correr el comando de tests: S25 en verde. Evidencia: la salida.
- [x] 2.3 En `skills/branch-pr/SKILL.md`, aceptar `odd/{nombre}` con los controles de design D14 (documento `docs/odd/{nombre}.md` en vez de los artefactos OpenSpec, trailer `Spec-ID: odd-{nombre}`, "`/odd:verify` pendiente de ejecutar" y la línea de la puerta "Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)" en el checklist). El caso `change/` no cambia. Evidencia: `git diff skills/branch-pr/SKILL.md`.
- [x] 2.4 Commit aparte con los archivos de 2.1 a 2.3: `feat: flujo ODD (skill, comandos y branch-pr)`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 3. CLAUDE.md global y config

- [x] 3.1 En `.claude/CLAUDE.md`, agregar la sección `## Clasificación ODD / SDD` después de `## Reglas globales (obligatorias)`, con el contenido de design D12 (cuándo se clasifica, tabla K1 a K10 con la columna de qué se puede pasar por alto, anuncio y cambio de clasificación, flujo ODD resumido, escalado, y las dos oraciones de D18 sobre ADR y visión). Evidencia: el bloque de la sección pegado en el resumen.
- [x] 3.2 En `.claude/CLAUDE.md`, aplicar el resto de design D12: reglas 4 y 9, la oración ODD al final de la regla 7 del Agente, `### Branches`, la condición de merge ODD en `### Pull Requests`, el resultado `no aplica (ODD)` en "Resultados y condición de merge" de la puerta de integración, las tres filas de la tabla "Cuándo actuar", el comentario en "Estructura del vault" y el bloque "Escribir nota de ODD (al `/odd:close`)" en "Comandos PowerShell". No cambiar los títulos de las 8 reglas de ejecución. Evidencia: `git diff .claude/CLAUDE.md`.
- [x] 3.3 En `openspec/config.yaml`, aplicar design D11: OBJ-01, las tres entradas del glosario y las líneas "Setup de máquina" y "Onboarding de proyecto" de `### Procesos`. Correr el comando de tests: S18 y S19 en verde. Evidencia: `git diff openspec/config.yaml` y la salida.
- [x] 3.4 Correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1 -Comprobar` (los títulos del `CLAUDE.md` siguen coincidiendo) y un script en archivo que busca IDs del design (`\bD\d+\b`) en `.claude/CLAUDE.md`, sin resultados. Evidencia: las dos salidas. Después, commit aparte con `.claude/CLAUDE.md` y `openspec/config.yaml`: `feat: clasificación ODD / SDD en las reglas globales`. El cuerpo describe el impacto: Claude clasifica todo pedido que cambia archivos, los cambios que no tocan specs, datos, seguridad ni contratos van por ODD con un único documento, y el ODD cerrado se guarda en el vault. Un único bloque final de trailers con `Spec-ID: clasificacion-odd-sdd`.

## 4. Plantillas del Agente y CI

- [x] 4.1 Crear `templates/fuente/fragmentos/handoff-odd.md` con el contenido de design D6 en segunda persona, y agregar en los cuatro esqueletos de `templates/fuente/esqueletos/` el título `## Handoff ODD` con la marca `<!-- incluir: handoff-odd -->` después de la marca de `reglas-ejecucion`, según design D13. Evidencia: `git diff templates/fuente/esqueletos/` y el fragmento.
- [x] 4.2 En `templates/fuente/fragmentos/reglas-ejecucion.md`, sumar al final de la regla 7 la oración de design D13. Evidencia: `git diff templates/fuente/fragmentos/reglas-ejecucion.md`.
- [x] 4.3 Correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1` y después `-Comprobar` (código 0). Evidencia: las dos salidas y `git diff --stat templates/`, donde cada plantilla suma solo la sección `## Handoff ODD` y la oración de la regla 7.
- [x] 4.4 En `.github/workflows/pr-check.yml`, paso "Check branch name": aceptar `change/` u `odd/` y listar las dos convenciones con un ejemplo de cada una en el mensaje de error (design D14). No tocar los demás pasos. Evidencia: `git diff .github/workflows/pr-check.yml`.
- [x] 4.5 Sincronizar la copia del repo: `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot` (debe dar `.github/copilot-instructions.md` `actualizado` y `pr-check.yml` `igual`, sin `-Forzar`; si da `bloqueado`, frenar y avisar) y después `-Comprobar` con código 0 (design D19). Evidencia: las dos salidas.
- [x] 4.6 Correr el comando de tests completo: todos en verde (S16, S17 y S20 pasan a verde acá; C01 y C02 siguen en verde). Correr el script en archivo de la Security Layer del design (busca `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en `scripts/`, `tests/`, `templates/`, `skills/odd-change/`, `.claude/commands/odd*` y `.claude/CLAUDE.md`), sin resultados. Evidencia: las dos salidas.
- [x] 4.7 Commit aparte con `templates/fuente/`, las cuatro plantillas, `.github/workflows/pr-check.yml` y `.github/copilot-instructions.md`: `feat: handoff ODD en las plantillas y branches odd en CI`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 5. Documentación y visión

- [x] 5.1 En `README.md`: una fila nueva en la tabla "Qué contiene" para `skills/odd-change/` y `.claude/commands/odd/`, y en "Flujo resumido" un segundo bloque con el flujo ODD (`/odd`, Agente, PR, `/odd:verify`, merge, `/odd:close`) y una línea con cuándo se usa cada uno. En el párrafo de actualización de proyectos, aclarar que para usar ODD hay que correr `sincronizar-proyecto.ps1`. Evidencia: el diff.
- [x] 5.2 En `docs/workflow.md` y `docs/modo-de-uso.md`: una sección "Cambios chicos: ODD" con los criterios de clasificación en una tabla corta, los tres comandos, qué se guarda en el vault, el escalado y que el proyecto necesita `sincronizar-proyecto.ps1` para usarlo. Evidencia: el diff.
- [x] 5.3 En `docs/arquitectura/vision.md`, aplicar exactamente los cambios de design D20. Evidencia: `git diff docs/arquitectura/vision.md` (S24).
- [x] 5.4 Commit aparte con los archivos de 5.1 a 5.3: `docs: flujo ODD en las guías y visión del repo`, con un único bloque final de trailers que incluya `Spec-ID: clasificacion-odd-sdd`.

## 6. Instalación (para que aplique en otros repos)

- [x] 6.1 `pwsh -NoProfile -File scripts/instalar.ps1 -Simular`. Si algún archivo figura `con cambios locales`, **frenar y preguntar** (no usar `-Forzar` sin confirmación del usuario). Si no, `pwsh -NoProfile -File scripts/instalar.ps1`. Verificar que `~/.claude/skills/odd-change/SKILL.md`, `~/.claude/commands/odd/` y `~/.claude/commands/odd.md` figuran en la tabla, y que el espejo del vault contiene "Clasificación ODD / SDD". **No cambiar la cuenta activa de `gh`**: si el push del vault falla por la cuenta, avisar. Evidencia: las dos tablas, `Select-String -SimpleMatch "Clasificación ODD / SDD"` en el espejo y `git -C $env:OBSIDIAN_VAULT log --oneline -1`.

## 7. Verificación con fixtures

7.1 y 7.2 las hace Claude. 7.3, 7.5 y 7.6 las ejecuta el Agente con sesiones `claude -p` y el vault falso, siguiendo un instructivo `verificacion.md` que Claude agrega al change al armar los fixtures. 7.4 la hace el usuario en una sesión interactiva.

- [x] 7.1 S24 por revisión del diff de la visión. Hecho por Claude: `git diff master...HEAD -- docs/arquitectura/vision.md` muestra solo los cinco cambios de D20 (tres líneas de `## Componentes` y el origen de dos deudas).
- [x] 7.2 Armar el repo P (con las reglas del Agente y el `pr-check.yml` puestos con `sincronizar-proyecto.ps1`) y el vault falso V del Test Plan en `$env:TEMP`, con el remote bare de V. Hecho por Claude: P con remote bare `odd-prueba-p-remote.git` y `AGENTS.md` y `pr-check.yml` puestos con `sincronizar-proyecto.ps1 -PrCheck`; V con remote bare `odd-prueba-vault-remote.git`; instructivo en `verificacion.md`.
- [x] 7.3 S01 a S05 y S21 con pedidos en sesiones nuevas en P (`claude -p` acotado). En S04 y S21, el segundo pedido pide ODD explícitamente. Evidencia: los 6 casos coinciden con el Test Plan (S01 ODD frena pidiendo aprobación sin branch; S02 SDD K1 ofrece propose; S03 SDD K8; S04 SDD K2 rechaza ODD; S05 ODD K7 pasado por alto frena pidiendo aprobación; S21 SDD K10 rechaza ODD).
- [ ] 7.4 S06, S09, S12 a S14 y S23: el usuario corre `/odd typo-bienvenida`, aprueba el documento, hace que el Agente implemente (S08), corre `/odd:verify` en una sesión interactiva, mergea en P, corre `/odd:close` y abre una sesión nueva. S07 se controla en V después de S06.
- [x] 7.5 S10, S11, S15 y S22 con ramas `odd/*` armadas a mano en P y sesiones nuevas. Evidencia: los 4 casos coinciden con el Test Plan (S10 CRITICAL re-clasificación K2 estado: escalado; S11 CRITICAL alcance nombra NOTAS.md; S15 escalado a SDD confirmado en progreso y context.md; S22 (a) checklist incluye vision.md, (b) WARNING vision.md en verify, (c) cierre en archive, _index.md, arquitectura.md y context.md en V sin commits nuevos en clon).
- [x] 7.6 Verificar que el cambio aplica en un proyecto de prueba. Evidencia: con la versión instalada en `~/.claude` y las reglas sincronizadas en P, los resultados de S01 a S05, S10, S11, S15, S21 y S22 coinciden con el Test Plan.

## Workflow follow-up

- Issue #32 creado y registrado en el proposal.
- Abrir PR `[clasificacion-odd-sdd] Clasificación ODD / SDD y flujo ODD con cierre en Obsidian` desde `change/clasificacion-odd-sdd`, con `Closes #32` y `Spec-ID: clasificacion-odd-sdd` en el body. Los checks "Validate PR conventions" y "Tests y control de plantillas" tienen que pasar.
- `/opsx:verify clasificacion-odd-sdd` antes del merge, en una sesión interactiva, y `/opsx:archive` después.
- En cada proyecto que quiera usar ODD: correr `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .`.
