# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply. Ninguna tarea borra ni cambia de sentido una regla vigente: solo se agregan líneas (más la fila de la tabla de roles de design D1).

## 1. CLAUDE.md global y config

- [ ] 1.1 En `.claude/CLAUDE.md`, agregar `## Rol de arquitecto de software` después de `## Roles Claude / Agente (OpenSpec)`, con el contenido de design D1 a D5 resumido (cuatro responsabilidades, formato de ADR y criterios, `## Calidad`, visión y hoja de ruta, revisión de impacto, y las tres oraciones: el rol se suma sin cambiar reglas, el Agente escribe los documentos del repo, decide el usuario). En la tabla de roles, cambiar la fila de propose según design D1. Evidencia: el bloque de la sección pegado en el resumen.
- [ ] 1.2 En `.claude/CLAUDE.md`, aplicar el resto: `## Calidad` en "Ficha del proyecto" › "Subsecciones" con su ejemplo (design D4); la lectura de `arquitectura.md` en el paso 3 de "Al iniciar cada sesión"; la fila de `/opsx:archive` y las de inicio de sesión, `/opsx:explore` y `/opsx:propose` en "Cuándo actuar" con `arquitectura.md`; y `arquitectura.md` en "Estructura del vault" (design D6). Evidencia: `git diff .claude/CLAUDE.md`.
- [ ] 1.3 En `openspec/config.yaml`, aplicar design D9 (cuatro entradas del glosario, actor Claude y OBJ-06). Evidencia: `git diff openspec/config.yaml`.
- [ ] 1.4 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users` ni IDs del design (`\bD\d+\b`), y que `git diff master -- .claude/CLAUDE.md` no tiene líneas borradas salvo la fila de la tabla de roles. Pegar la salida. Después, commit aparte con `.claude/CLAUDE.md` y `openspec/config.yaml`: `feat: rol de arquitecto de software en las reglas globales`. El cuerpo describe el impacto: Claude suma ADRs, atributos de calidad, visión con hoja de ruta y revisión de impacto sin cambiar reglas; los documentos del repo los escribe el Agente; el archive mantiene un resumen en el vault. Un único bloque final de trailers con `Spec-ID: rol-arquitecto-software`.

## 2. Propose, verify, archive y explore

- [ ] 2.1 En `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`, con el mismo texto en los dos: en el paso 0, leer `$vault\projects\$p\arquitectura.md` y `docs/arquitectura/vision.md` si existen; en "Artifact Creation Guidelines", las guías de `## Impacto en el sistema` (design D2 y D4), `## ADR` (design D3) y `## Visión inicial` y actualización de la visión (design D5), cada una diciendo que el archivo del repo lo crea el Agente con una tarea y que no se copian código, credenciales ni datos personales; y en "Output", sumar `## Calidad` al aviso de ficha incompleta. Evidencia: `git diff` de los dos archivos y un script en archivo que compara el cuerpo de las secciones agregadas en los dos, sin diferencias.
- [ ] 2.2 En `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`, con el mismo texto: los controles y la tabla "Arquitectura de software" de design D7, después de "Architecture Results", y sus WARNING y SUGGESTION en "Issues by Priority". No tocar la puerta de integración ni la lista de CRITICAL. Evidencia: `git diff` de los dos archivos.
- [ ] 2.3 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`, con el mismo texto: en el paso 5.5, después de `_index.md` y antes del sync del vault, escribir `arquitectura.md` según design D6; y mencionarlo en el resumen del paso 6. Evidencia: `git diff` de los dos archivos.
- [ ] 2.4 En `skills/openspec-explore/SKILL.md` y `.claude/commands/opsx/explore.md`, con el mismo texto: leer `arquitectura.md` del vault y `docs/arquitectura/vision.md` si existen, junto con `context.md`. Evidencia: `git diff` de los dos archivos.
- [ ] 2.5 Verificar con un script en archivo que los archivos de 2.1 a 2.4 no contienen `C:\Users`, y pegar la salida. Commit aparte: `feat: arquitectura de software en propose, verify, archive y explore`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 3. Ficha

- [ ] 3.1 En `skills/ficha/SKILL.md`, sumar `## Calidad` como sexta parte según design D4: formato, atributos admitidos, la pregunta con objetivo y prioridad y la opción "Ninguno por ahora", el orden de escritura (después de `## Stack`) y el mensaje de ficha completa con seis partes. Evidencia: `git diff skills/ficha/SKILL.md`.
- [ ] 3.2 Commit aparte: `feat: atributos de calidad en la ficha`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 4. Documentación

- [ ] 4.1 En `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`: una sección "Arquitectura de software" con las cuatro responsabilidades, dónde vive cada documento (`docs/adr/`, `docs/arquitectura/vision.md`, `arquitectura.md` del vault) y quién escribe cada uno. Evidencia: el diff.
- [ ] 4.2 Commit aparte: `docs: rol de arquitecto de software en las guías`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 5. Instalación (para que aplique en otros repos)

- [ ] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada archivo de `.claude/commands/opsx/`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D10). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master", "con cambios locales" o "nuevo".
- [ ] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` y **todos** los comandos de `.claude/commands/opsx/`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales.
- [ ] 5.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas rol-arquitecto-software`) y pushear. Verificar que el espejo contiene "Rol de arquitecto de software". **No cambiar la cuenta activa de `gh`**: si el push falla por la cuenta, avisar sin forzar.

## 6. Verificación con Claude y el usuario (no la ejecuta el Agente)

- [ ] 6.1 S01, S02, S17 y S18 por revisión de los archivos y del diff.
- [ ] 6.2 Armar los repos A y B y el vault falso V del Test Plan en `$env:TEMP`, con el remote bare de V.
- [ ] 6.3 S03 a S05, S07 a S11 y S21 con propose en sesiones nuevas (`claude -p` acotado, de a 3 como máximo).
- [ ] 6.4 S06, S19 y S20: el usuario corre el propose de S06 y `/ficha` en una sesión interactiva.
- [ ] 6.5 S12 a S16 con ramas armadas a mano en A y sesiones nuevas.
- [ ] 6.6 Verificar que el cambio aplica en un proyecto de prueba. Evidencia: con la versión instalada en `~/.claude`, los resultados de S03 a S21 en los repos A y B coinciden con el Test Plan.

## Workflow follow-up

- Issue #33.
- Abrir PR `[rol-arquitecto-software] Rol de arquitecto de software: ADRs, atributos de calidad, visión y revisión de impacto` desde `change/rol-arquitecto-software`, con `Closes #33`.
- `/opsx:verify rol-arquitecto-software` antes del merge, en una sesión interactiva, y `/opsx:archive` después.
- El change `clasificacion-odd-sdd` (#32) sigue en pausa; al retomarlo, resolver los conflictos con `.claude/CLAUDE.md` y `openspec/config.yaml`.
