## 1. Caracterización

- [ ] 1.1 C01: correr `pwsh -NoProfile -File tests/ejecutar.ps1` sin tocar nada, antes de modificar `.claude/CLAUDE.md` y `README.md`. Verificación: salida en verde pegada.

## 2. Tests primero

- [ ] 2.1 Test primero, S01 a S07 en `tests/claude-md-liviano.Tests.ps1` (archivo nuevo, UTF-8 sin BOM), como dice el Test Plan de `design.md`: `. "$PSScriptRoot/apoyo.ps1"`, `# test-plan: claude-md-liviano/<ID>` arriba de cada `Probar`, saltos de línea normalizados a `\n`. Comando: `pwsh -NoProfile -File tests/claude-md-liviano.Tests.ps1`. Verificación: S01 a S03 y S05 a S07 fallan con el código actual (salida en rojo pegada). S04 también tiene que fallar, porque hoy `### Escalera de niveles` tiene una tabla.

## 3. Implementación

- [ ] 3.1 D7: antes de borrar nada, confirmar que el texto de `### Flujo ODD resumido` y `### Escalado a SDD` está en `skills/odd-change/SKILL.md`, la tabla de `### Escalera de niveles` en `skills/arquitectura/references/recetas.md` y los cuatro ejemplos YAML de `### Subsecciones` en `skills/ficha/SKILL.md`. Si falta una oración, copiarla tal cual al destino y, si se tocó una skill, correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1`. Verificación: lista pegada de cada oración con la línea del destino donde está, o lo que se copió.
- [ ] 3.2 En `README.md`: agregar `## Espejo del vault` antes de `## Plantillas del Agente` (D5) y `## Comandos del vault` al final (D6), con los textos copiados tal cual del `.claude/CLAUDE.md` actual. Commit: `docs: espejo y comandos del vault en el README`, con `Spec-ID: claude-md-liviano`. Verificación: S02 y S06 (parte del README) pegados.
- [ ] 3.3 En `.claude/CLAUDE.md`: aplicar D1 a D6 de `design.md` con los textos exactos (sin la sangría de 4 espacios del design), sin tocar el bloque entre `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->` ni el resto de las secciones. Commit que solo toque ese archivo: `docs: sacar el detalle operativo del CLAUDE.md global`, con una línea "Impacto: Claude carga unas 900 palabras menos por sesión; el detalle queda en las skills y en el README, sin cambiar reglas" y `Spec-ID: claude-md-liviano`. Verificación: S01 a S07 en verde, y las palabras del archivo antes y después (`(Get-Content .claude/CLAUDE.md -Raw -split '\s+' | Where-Object { $_ }).Count`) pegadas.
- [ ] 3.4 Correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1 -Comprobar`. Verificación: código 0 pegado (el bloque de reglas del `CLAUDE.md` sigue igual al fragmento).

## 4. Documentos de arquitectura

- [ ] 4.1 En `docs/arquitectura/vision.md`, `## Hoja de ruta`: quitar la línea `- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software, clasificacion-odd-sdd, tablero-scrumban y cadencias-scrumban — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas — issue: #55`. Commit: `docs: pagar la deuda del CLAUDE.md global en la visión`, con `Spec-ID: claude-md-liviano`. Verificación: diff pegado.

## 5. Cierre

- [ ] 5.1 Suite completa: `pwsh -NoProfile -File tests/ejecutar.ps1`. Verificación: salida en verde pegada (S01 a S07 y todos los tests de C01, sin modificarlos).
- [ ] 5.2 Revisión de seguridad del diff: buscar `C:\Users`, el nombre de la carpeta del usuario, tokens e `Invoke-Expression`/`iex` en las líneas agregadas fuera de `openspec/`, y confirmar que ningún archivo nuevo o modificado empieza con `EF BB BF`. Verificación: salida sin coincidencias y los primeros 3 bytes de cada archivo tocado, pegados.
- [ ] 5.3 M01 (lo corre el usuario): verificar que el cambio aplica en un proyecto de prueba, como dice M01 del Test Plan: en la rama del change, `pwsh scripts/instalar.ps1`; abrir una sesión nueva de Claude Code en otro proyecto con OpenSpec, comprobar que el inicio de sesión corre igual que antes y preguntar "¿qué pasos sigue un ODD si aparece un criterio SDD?". Al terminar, `git checkout master` y `pwsh scripts/instalar.ps1`. Queda `[ ]` hasta que el usuario lo confirme en el verify.
