---
tipo: odd
nombre: reglas-agente-evidencia-commits
creado: 2026-11-12
estado: verificado
branch: odd/reglas-agente-evidencia-commits
---

## Objetivo
Las reglas 1 y 5 de ejecución del Agente impiden tres cosas que pasaron el 12/11/2026: simular una tarea manual que tenía que correr el usuario, commitear con un tipo no permitido (`style:`) y cambiar la cuenta activa de `gh`.

## Problema
- En `srs-en-rama-del-change` y `sugerir-arquitectura`, el Agente marcó `[x]` la tarea M01 simulándola, aunque la tarea decía que la corría el usuario.
- En `desindentar-nivel-tamano`, commiteó con `style:`, que no está entre los tipos permitidos del `CLAUDE.md` global.
- En varios applies dejó activa la cuenta `Lautaro-Montecchiani`, y eso rompió el pull y el push del vault de trabajo.

Las reglas de ejecución no dicen nada de estos casos.

## Alcance
- Incluye: agregar texto al final de las reglas 1 y 5 en `templates/fuente/fragmentos/reglas-ejecucion.md` y regenerar con `pwsh scripts/generar-plantillas.ps1`.
- No incluye: reglas nuevas (siguen siendo 8 con los mismos títulos), cambios a las demás reglas ni a otros fragmentos.
- Cambio de spec: ninguno. Las specs controlan los títulos y la cantidad de reglas, que no cambian.
- Archivos permitidos:
  - `templates/fuente/fragmentos/reglas-ejecucion.md`
  - `templates/antigravity/GEMINI.md`
  - `templates/comun/AGENTS.md`
  - `templates/copilot/copilot-instructions.md`
  - `templates/cursor/sdd-workflow.mdc`
  - `.claude/CLAUDE.md` (solo el bloque generado entre `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`)
  - `docs/odd/reglas-agente-evidencia-commits.md`
  - `tests/generar-plantillas.Tests.ps1` (solo para retirar el test de migración C01, ver tarea 3b)
  - `tests/datos/plantillas-antes/` (se borra)

## Clasificación
SDD por K7 (6 archivos sin contar documentación). K7 se pasó por alto a pedido del usuario el 2026-11-12, porque se edita un solo archivo a mano y los otros 5 se regeneran desde él. No se cumple ningún otro criterio:
- K1: no se agrega ni se quita comportamiento de ninguna spec.
- K2, K3: no toca datos ni seguridad.
- K4, K5, K6: no toca dependencias, contratos ni arquitectura.
- K8: el texto está definido abajo.
- K10: no cumple ningún criterio de ADR.

## Checklist
- [x] 1. En `templates/fuente/fragmentos/reglas-ejecucion.md`, al final de la regla 1 (después de "Sin evidencia, la tarea queda `[ ]` y avisás."), agregar con un espacio delante, exacto: `Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda [ ] y en el resumen le pedís al usuario que la corra.` Escribir `[ ]` entre comillas invertidas, igual que en el resto de la regla.
- [x] 2. En el mismo archivo, al final de la regla 5 (después de "los artefactos de spec van en un commit aparte."), agregar con un espacio delante, exacto: `Usá solo los tipos feat, fix, chore, refactor, docs y test. No cambies la cuenta activa de gh (gh auth switch): si un push o un PR falla por permisos, frená y avisá.` Escribir cada tipo, `gh` y `gh auth switch` entre comillas invertidas.
- [x] 3. Regenerar con `pwsh scripts/generar-plantillas.ps1` y comprobar con `pwsh scripts/generar-plantillas.ps1 -Comprobar`.
- [x] 3b. En `tests/generar-plantillas.Tests.ps1`:
  - Quitar el test "C01 plantillas sin cambios de texto", con sus dos marcadores (`sincronizar-reglas/C01` y `clasificacion-odd-sdd/C01`).
  - Quitar la función `Limpiar-PlantillaParaC01` y la variable `$antesDir`, que solo usa ese test.
  - Borrar la carpeta `tests/datos/plantillas-antes/`.
  - No tocar los demás tests del archivo.

  Es un test de migración del change `sincronizar-reglas`: comparaba las plantillas generadas contra las copias escritas a mano antes de esa migración. Esa migración ya está cerrada, y se rompe con cada cambio intencional a las reglas (ya tenía dos excepciones agregadas a mano). Que cada plantilla coincida con su fuente lo siguen controlando `generar-plantillas.ps1 -Comprobar` en el CI y los tests `sincronizar-reglas/S03` y `S05`. Es el mismo criterio que se usó para retirar los C01 y C02 de `generar-comandos` en `srs-en-rama-del-change`. Evidencia: la salida en rojo de C01 que ya obtuviste, y la suite en verde después.
- [x] 4. Correr la suite: `pwsh -NoProfile -File tests/ejecutar.ps1`.
- [x] 5. Commitear con un tipo permitido (`docs:`) y `Spec-ID: odd-reglas-agente-evidencia-commits`, sin cambiar la cuenta de `gh`.

## Criterios de aceptación
- CA1: las dos oraciones nuevas aparecen, idénticas, en el fragmento, en las 4 plantillas y en el bloque generado de `.claude/CLAUDE.md`. — Evidencia esperada: salida de `Select-String -SimpleMatch` de cada oración, con 6 coincidencias por oración.
- CA2: siguen siendo 8 reglas, con los mismos títulos. — Evidencia esperada: salida de `Select-String` de `^\d\. \*\*` sobre el fragmento (8 líneas).
- CA3: el diff solo toca los archivos permitidos. — Evidencia esperada: salida de `git diff --stat master`.
- CA4: la generación y los tests siguen en verde. — Evidencia esperada: `-Comprobar` con código 0 y suite con código 0.

## Evidencia

### Tareas 1 y 2
Texto incorporado en `templates/fuente/fragmentos/reglas-ejecucion.md`:
- Regla 1: `Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.`
- Regla 5: `Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.`

### Tarea 3
```
> pwsh -NoProfile -Command ".\scripts\generar-plantillas.ps1"
Generado: templates/comun/AGENTS.md
Generado: templates/copilot/copilot-instructions.md
Generado: templates/cursor/sdd-workflow.mdc
Generado: templates/antigravity/GEMINI.md
Generado: .claude/commands/opsx/apply.md
Generado: .claude/commands/opsx/archive.md
Generado: .claude/commands/opsx/explore.md
Generado: .claude/commands/opsx/propose.md
Generado: .claude/commands/opsx/verify.md
Generado: .claude/commands/odd/start.md
Generado: .claude/commands/odd.md
Generado: .claude/commands/odd/verify.md
Generado: .claude/commands/odd/close.md
Generado: .claude/CLAUDE.md

> pwsh -NoProfile -Command ".\scripts\generar-plantillas.ps1 -Comprobar"
OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados.
```

### Tarea 3b
1. Salida en rojo previa de C01:
```
FALLA C01 plantillas sin cambios de texto: El texto de templates/comun/AGENTS.md difiere de tests/datos/plantillas-antes/AGENTS.md
```
2. Retiro de C01, `Limpiar-PlantillaParaC01` y `$antesDir` de `tests/generar-plantillas.Tests.ps1`.
3. Eliminación de `tests/datos/plantillas-antes/`:
```
rm 'tests/datos/plantillas-antes/AGENTS.md'
rm 'tests/datos/plantillas-antes/GEMINI.md'
rm 'tests/datos/plantillas-antes/copilot-instructions.md'
rm 'tests/datos/plantillas-antes/sdd-workflow.mdc'
```

### Tarea 4
Salida de la suite completa en verde:
```
> pwsh -NoProfile -File tests/ejecutar.ps1
OK S01 texto de K2 en CLAUDE.md, skill y comandos
OK S04 guías tienen versión corta de K2 y visión no contiene la deuda
OK C02 pr-check sin cambios fuera del paso de branch
OK S16 plantillas incluyen handoff ODD desde la fuente
OK S17 CI acepta branch odd
OK S18 reglas documentadas en CLAUDE.md y config.yaml
OK S19 puerta y merge en ODD
OK S20 regla 7 con excepción ODD
OK S25 comandos ODD iguales a la skill
OK S31 reglas de D21 para ODD con cambio mínimo de spec
OK S01 comando con la skill completa
OK S02 comando con secciones de una skill
OK S03 título dentro de un bloque de código
OK S04 mismo texto para /odd y /odd:start
OK S05 dato inválido: skill inexistente
OK S06 dato inválido: sección inexistente
OK S07 comando editado a mano falla en -Comprobar
OK S08 skill editada sin regenerar falla en -Comprobar
OK S09 todo sincronizado pasa en el repositorio real
OK S10 security layer: el script no ejecuta texto leído
OK S01 generar plantillas desde la fuente
OK S02 generar falla con fragmento inexistente
OK S03 comprobar falla si una plantilla se editó a mano
OK S04 comprobar falla si reglas de CLAUDE.md tienen otro título
OK S05 comprobar pasa si todo está sincronizado
OK S21 plantillas con aviso y sección propia
OK reglas-fuente-unica/S01 bloque generado desde el fragmento
OK reglas-fuente-unica/S02 el resto del CLAUDE.md no cambia
OK reglas-fuente-unica/S03 marcas faltantes
OK reglas-fuente-unica/S21 bloque de reglas del CLAUDE.md editado a mano
OK S06 destino vacío instala archivos y crea manifiesto
OK S07 cambio local bloquea la instalación sin tocar archivos
OK S08 forzar respalda y sobreescribe cambios locales
OK S09 simular muestra tabla sin modificar destino ni manifiesto
OK S10 GEMINI.md instalado conserva contenido propio
OK S11 espejo del vault sincronizado con remote bare
OK S12 aviso cuando el vault no existe y continúa
OK reglas-fuente-unica/S04 archivo de carga con vault
OK reglas-fuente-unica/S05 copia completa sin vault
OK reglas-fuente-unica/S06 ruta del vault con espacios
OK reglas-fuente-unica/S07 copia completa anterior pasa a archivo de carga
OK reglas-fuente-unica/S08 espejo ya igual
OK reglas-fuente-unica/S09 espejo editado a mano
OK reglas-fuente-unica/S10 forzar con respaldo del espejo
OK reglas-fuente-unica/S11 espejo atrasado
OK reglas-fuente-unica/S12 repo atrasado
OK reglas-fuente-unica/S13 comprobar con instalación al día
OK reglas-fuente-unica/S14 comprobar con espejo distinto
OK reglas-fuente-unica/S15 comprobar con destino vacío
OK reglas-fuente-unica/S16 texto de las reglas globales
OK reglas-fuente-unica/S17 texto de las guías
OK S13 proyecto nuevo crea agentes especificados
OK S14 conserva contenido propio debajo del título
OK S15 copia vieja reconocida en la historia se actualiza
OK S16 contenido propio sin marcar bloquea la sincronización
OK S17 comprobar falla si está atrasado y pasa cuando está al día
OK S18 no crea commits en el proyecto y deja cambios en el árbol de trabajo
OK S01 Archive en la rama antes del merge / Archive en la rama del change
OK S02 Archive en la rama antes del merge / Fuera de la rama del change
OK S03 Archive en la rama antes del merge / Verify sin aprobar
OK S04 Change mergeado sin archivar / Change del flujo anterior
OK S05 Cierre en el vault después del merge / Cierre después del merge
OK S06 Cierre en el vault después del merge / PR sin mergear
OK S07 Cierre en el vault después del merge / Dato inválido: config sin calidad ni nivel
OK S08 Orden documentado en reglas y guías / Reglas de Git
OK S09 Orden documentado en reglas y guías / Guías, verify y checklist del PR
OK S10 Enganche opcional en el archive / Archive en un proyecto que ya usa SRS
OK S11 Enganche opcional en el archive / Archive en un proyecto sin SRS
OK S12 Enganche opcional en el archive / Usuario que posterga la generación
OK S13 Enganche opcional en el archive / El cierre en el vault no ofrece el SRS
OK S14 Verify liviano / ODD con cambio de spec y SRS
OK S15 Cierre en el vault de Obsidian / Cierre de un ODD con cambio de spec
OK S17 Archive en la rama antes del merge / Carpeta de archive ya existente
OK S18 Estado del archive del ODD en el vault y en el PR / ODD con cambio de spec archivado y ODD sin cambio de spec
OK S19 Estado del archive del ODD en el vault y en el PR / PR de un ODD
OK S01 Claude sugiere la skill arquitectura / Inicio de sesión sin nivel
OK S02 Claude sugiere la skill arquitectura / Propose sin nivel
OK S03 Claude sugiere la skill arquitectura / Verify con un archivo sobre la advertencia
OK S04 Claude sugiere la skill arquitectura / Archive con nivel sin evaluar
OK S05 Claude sugiere la skill arquitectura / Proyecto con nivel declarado
OK S06 Claude sugiere la skill arquitectura / Dato inválido: nivel desconocido
OK S07 ADR y visión
```
Código de salida: 0.

### Tarea 5
Commit realizado con tipo `docs:` y trailer `Spec-ID: odd-reglas-agente-evidencia-commits` sin tocar la configuración ni credenciales de `gh`.

### CA1: 6 coincidencias por oración
Oración 1:
```
templates\fuente\fragmentos\reglas-ejecucion.md:1:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
templates\comun\AGENTS.md:23:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
templates\copilot\copilot-instructions.md:21:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
templates\cursor\sdd-workflow.mdc:33:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
templates\antigravity\GEMINI.md:15:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
.claude\CLAUDE.md:128:1. **Evidencia antes de `[x]`:** marcá una tarea con test solo si pegás en el resumen del apply la salida del test en rojo (antes del cambio) y en verde (después). Una tarea manual se marca solo con evidencia (salida de consola o captura). Sin evidencia, la tarea queda `[ ]` y avisás. Una tarea manual que dice que la corre el usuario, o que necesita una sesión real (por ejemplo, abrir Claude Code o probar en otro proyecto), no se simula ni se marca: queda `[ ]` y en el resumen le pedís al usuario que la corra.
```

Oración 2:
```
templates\fuente\fragmentos\reglas-ejecucion.md:5:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
templates\comun\AGENTS.md:27:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
templates\copilot\copilot-instructions.md:25:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
templates\cursor\sdd-workflow.mdc:37:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
templates\antigravity\GEMINI.md:19:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
.claude\CLAUDE.md:132:5. **Commits separados:** el commit de código no incluye archivos de `openspec/`; los artefactos de spec van en un commit aparte. Usá solo los tipos `feat`, `fix`, `chore`, `refactor`, `docs` y `test`. No cambies la cuenta activa de `gh` (`gh auth switch`): si un push o un PR falla por permisos, frená y avisá.
```

### CA2: 8 reglas con los mismos títulos
```
templates\fuente\fragmentos\reglas-ejecucion.md:1:1. **Evidencia antes de `[x]`:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:2:2. **Test primero = falla primero:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:3:3. **No debilitar tests:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:4:4. **No inventar:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:5:5. **Commits separados:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:6:6. **Sin comentarios de razonamiento:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:7:7. **Resumen final con evidencia:** ...
templates\fuente\fragmentos\reglas-ejecucion.md:8:8. **Respetar la arquitectura:** ...
```

### CA3: Diff solo en archivos permitidos
```
> git diff --stat master
 .claude/CLAUDE.md                                  |   4 +-
 docs/odd/reglas-agente-evidencia-commits.md        | 170 +++++++++++++++++++++
 templates/antigravity/GEMINI.md                    |   4 +-
 templates/comun/AGENTS.md                          |   4 +-
 templates/copilot/copilot-instructions.md          |   4 +-
 templates/cursor/sdd-workflow.mdc                  |   4 +-
 templates/fuente/fragmentos/reglas-ejecucion.md    |   4 +-
 tests/datos/plantillas-antes/AGENTS.md             |  39 -----
 tests/datos/plantillas-antes/GEMINI.md             |  31 ----
 .../datos/plantillas-antes/copilot-instructions.md |  37 -----
 tests/datos/plantillas-antes/sdd-workflow.mdc      |  49 -------
 tests/generar-plantillas.Tests.ps1                 |  61 +-------
 12 files changed, 170 insertions(+), 228 deletions(-)
```

### CA4: Generación y tests
- `pwsh scripts/generar-plantillas.ps1 -Comprobar`: OK (código 0).
- `pwsh -NoProfile -File tests/ejecutar.ps1`: OK (código 0).

## Progreso
2026-11-12: documento redactado — Claude.
2026-11-12: Agente implementó tareas 1, 2 y 3. Al ejecutar la tarea 4 (`tests/ejecutar.ps1`), falló `C01 plantillas sin cambios de texto` porque compara las plantillas contra los fixtures históricos `tests/datos/plantillas-antes/`. Para que la suite pase se requiere modificar `tests/generar-plantillas.Tests.ps1` (o los fixtures), lo cual excede los archivos permitidos en Alcance. Se frena y se avisa escalar a SDD según el protocolo.
2026-11-12: no se escala. Tocar tests no cumple ningún criterio de K1 a K10 (K7 no cuenta tests). Era un hueco del alcance: se suman `tests/generar-plantillas.Tests.ps1` y `tests/datos/plantillas-antes/` a los archivos permitidos y se agrega la tarea 3b para retirar el test de migración C01 — Claude.
2026-11-12: Agente implementó tareas 3b, 4 y 5. Suite en verde, sin cambiar cuenta de gh.
2026-11-12: /odd:verify sin CRITICAL; puerta: dato inesperado no aplica (ODD), seguridad sí (se reemplazaron 2 rutas absolutas con el usuario local en la evidencia), explicabilidad sí — Claude.

## Próximo paso
Merge del PR y después `/odd:close reglas-agente-evidencia-commits`.
