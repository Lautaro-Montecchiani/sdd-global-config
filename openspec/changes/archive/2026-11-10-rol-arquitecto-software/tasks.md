# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply. Ninguna tarea borra ni cambia de sentido una regla vigente: solo se agregan líneas (más la fila de la tabla de roles de design D1).

## 1. CLAUDE.md global y config

- [x] 1.1 En `.claude/CLAUDE.md`, agregar `## Rol de arquitecto de software` después de `## Roles Claude / Agente (OpenSpec)`, con el contenido de design D1 a D5 resumido (cuatro responsabilidades, formato de ADR y criterios, `## Calidad`, visión y hoja de ruta, revisión de impacto, y las tres oraciones: el rol se suma sin cambiar reglas, el Agente escribe los documentos del repo, decide el usuario). En la tabla de roles, cambiar la fila de propose según design D1. Evidencia: el bloque de la sección pegado en el resumen.
- [x] 1.2 En `.claude/CLAUDE.md`, aplicar el resto: `## Calidad` en "Ficha del proyecto" › "Subsecciones" con su ejemplo (design D4); la lectura de `arquitectura.md` en el paso 3 de "Al iniciar cada sesión"; la fila de `/opsx:archive` y las de inicio de sesión, `/opsx:explore` y `/opsx:propose` en "Cuándo actuar" con `arquitectura.md`; y `arquitectura.md` en "Estructura del vault" (design D6). Evidencia: `git diff .claude/CLAUDE.md`.
- [x] 1.3 En `openspec/config.yaml`, aplicar design D9 (cuatro entradas del glosario, actor Claude y OBJ-06). Evidencia: `git diff openspec/config.yaml`.
- [x] 1.4 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users` ni IDs del design (`\bD\d+\b`), y que `git diff master -- .claude/CLAUDE.md` no tiene líneas borradas salvo la fila de la tabla de roles. Pegar la salida. Después, commit aparte con `.claude/CLAUDE.md` y `openspec/config.yaml`: `feat: rol de arquitecto de software en las reglas globales`. El cuerpo describe el impacto: Claude suma ADRs, atributos de calidad, visión con hoja de ruta y revisión de impacto sin cambiar reglas; los documentos del repo los escribe el Agente; el archive mantiene un resumen en el vault. Un único bloque final de trailers con `Spec-ID: rol-arquitecto-software`.

## 2. Propose, verify, archive y explore

- [x] 2.1 En `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`, con el mismo texto en los dos: en el paso 0, leer `$vault\projects\$p\arquitectura.md` y `docs/arquitectura/vision.md` si existen; en "Artifact Creation Guidelines", las guías de `## Impacto en el sistema` (design D2 y D4), `## ADR` (design D3) y `## Visión inicial` y actualización de la visión (design D5), cada una diciendo que el archivo del repo lo crea el Agente con una tarea y que no se copian código, credenciales ni datos personales; y en "Output", sumar `## Calidad` al aviso de ficha incompleta. Evidencia: `git diff` de los dos archivos y un script en archivo que compara el cuerpo de las secciones agregadas en los dos, sin diferencias.
- [x] 2.2 En `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`, con el mismo texto: los controles y la tabla "Arquitectura de software" de design D7, después de "Architecture Results", y sus WARNING y SUGGESTION en "Issues by Priority". No tocar la puerta de integración ni la lista de CRITICAL. Evidencia: `git diff` de los dos archivos.
- [x] 2.3 En `skills/openspec-archive-change/SKILL.md` y `.claude/commands/opsx/archive.md`, con el mismo texto: en el paso 5.5, después de `_index.md` y antes del sync del vault, escribir `arquitectura.md` según design D6; y mencionarlo en el resumen del paso 6. Evidencia: `git diff` de los dos archivos.
- [x] 2.4 En `skills/openspec-explore/SKILL.md` y `.claude/commands/opsx/explore.md`, con el mismo texto: leer `arquitectura.md` del vault y `docs/arquitectura/vision.md` si existen, junto con `context.md`. Evidencia: `git diff` de los dos archivos.
- [x] 2.5 Verificar con un script en archivo que los archivos de 2.1 a 2.4 no contienen `C:\Users`, y pegar la salida. Commit aparte: `feat: arquitectura de software en propose, verify, archive y explore`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 3. Ficha

- [x] 3.1 En `skills/ficha/SKILL.md`, sumar `## Calidad` como sexta parte según design D4: formato, atributos admitidos, la pregunta con objetivo y prioridad y la opción "Ninguno por ahora", el orden de escritura (después de `## Stack`) y el mensaje de ficha completa con seis partes. Evidencia: `git diff skills/ficha/SKILL.md`.
- [x] 3.2 Commit aparte: `feat: atributos de calidad en la ficha`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 4. Documentación

- [x] 4.1 En `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`: una sección "Arquitectura de software" con las cuatro responsabilidades, dónde vive cada documento (`docs/adr/`, `docs/arquitectura/vision.md`, `arquitectura.md` del vault) y quién escribe cada uno. Evidencia: el diff.
- [x] 4.2 Commit aparte: `docs: rol de arquitecto de software en las guías`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`.

## 5. Instalación (para que aplique en otros repos)

- [x] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada archivo de `.claude/commands/opsx/`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D10). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master", "con cambios locales" o "nuevo".
- [x] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` y **todos** los comandos de `.claude/commands/opsx/`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales.
- [x] 5.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas rol-arquitecto-software`) y pushear. Verificar que el espejo contiene "Rol de arquitecto de software". **No cambiar la cuenta activa de `gh`**: si el push falla por la cuenta, avisar sin forzar.

## 6. Verificación con fixtures

6.1 y 6.2 las hizo Claude. 6.3, 6.5 y 6.6 las ejecuta el Agente siguiendo `openspec/changes/rol-arquitecto-software/verificacion.md`, **después de terminar la sección 7**, con sesiones `claude -p` y el vault falso. 6.4 la hace el usuario en una sesión interactiva.

- [x] 6.1 S01, S02, S17 y S18 por revisión de los archivos y del diff. Verificado por Claude en `/opsx:verify` (2026-11-09): S01 `## Rol de arquitecto de software` presente con las cuatro responsabilidades y las oraciones de reglas; S02 `git diff master...HEAD -- .claude/CLAUDE.md` solo borra filas de las tablas de roles y "Cuándo actuar" (reemplazadas), sin tocar reglas globales, reglas de ejecución ni puerta de integración; S17 formato de `## Alcance` sin cambios en `CLAUDE.md` y `skills/ficha/SKILL.md`; S18 `## Calidad` documentada en los dos con formato, cinco atributos y "sin relleno", y `## Datos` y `## Stack` sin cambios.
- [x] 6.2 Armar los repos A y B y el vault falso V del Test Plan en `$env:TEMP`, con el remote bare de V. Hecho por Claude (2026-11-09): `arq-prueba-a` (commit `ac3eef1` en `master`, más la rama `fixture/con-vision` con `docs/arquitectura/vision.md`), `arq-prueba-b` (`4c3c4ba`) y `arq-prueba-vault` (`178b69c`), pusheado a `arq-prueba-vault-remote.git`.
- [x] 6.3 S03 a S05, S07 a S11 y S21 con propose en sesiones nuevas (`claude -p` acotado, de a 3 como máximo).
- [x] 6.4 S06, S19 y S20: el usuario corre el propose de S06 y `/ficha` en una sesión interactiva.
- [x] 6.5 S12 a S16 con ramas armadas a mano en A y sesiones nuevas.
- [x] 6.6 Verificar que el cambio aplica en un proyecto de prueba. Evidencia: con la versión instalada en `~/.claude`, los resultados de S03 a S21 en los repos A y B coinciden con el Test Plan.

## 7. Correcciones del verify (antes de 6.3)

- [x] 7.1 En `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`, con el mismo texto y en los dos métodos (con Test Plan y legacy): agregar, después del bloque **Architecture Verification**, un bloque **Software Architecture Verification** con cómo se evalúa cada control de la tabla según design D7 (impacto, atributos de calidad, ADR y visión), y que estos controles no duplican el CRITICAL de una tarea `[x]` sin respaldo en el diff. Evidencia: `git diff` de los dos archivos y un script en archivo que compara las líneas agregadas en los dos, sin diferencias.
- [x] 7.2 En `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`, con el mismo texto: en la guía de `## ADR`, el texto completo del ADR va dentro de un bloque de código `markdown` y la tarea del Agente copia el contenido del bloque (design D3); y en la guía de `## Impacto en el sistema`, quitar la oración "The section analyzes impact; the file in the repository is created by the Agent with a task", dejando solo que no se copian código, credenciales ni datos personales. Evidencia: `git diff` de los dos archivos.
- [x] 7.3 En `.claude/CLAUDE.md`, en la responsabilidad 1 de `## Rol de arquitecto de software`, decir que el ADR se formula en `## ADR` del `design.md` dentro de un bloque de código `markdown`. Evidencia: `git diff .claude/CLAUDE.md`.
- [x] 7.4 En `README.md` y `docs/workflow.md` (y en `docs/modo-de-uso.md` si tiene la misma oración), reemplazar "Claude nunca escribe archivos del repositorio del proyecto" por "Claude no escribe los documentos de arquitectura del repositorio (ADRs y visión): los escribe el Agente". Evidencia: `git diff` de los archivos.
- [x] 7.5 Commit aparte con 7.1 a 7.4: `fix: correcciones del verify de rol-arquitecto-software`, con un único bloque final de trailers que incluya `Spec-ID: rol-arquitecto-software`. El cuerpo describe el impacto en el `CLAUDE.md` (formato del ADR).
- [x] 7.6 Repetir 5.1 a 5.3, pero en 5.1 comparar la copia instalada con `git show 9c34285:<ruta>` (la versión que se instaló en 5.2) en vez de `master`, porque la instalada ya tiene este change (comparar, instalar en `~/.claude` con hashes y re-sincronizar el espejo del vault con commit `chore: sdd-global-config — sync reglas rol-arquitecto-software (fix)`). Evidencia: la misma de 5.1 a 5.3.

## Workflow follow-up

- Issue #33.
- Abrir PR `[rol-arquitecto-software] Rol de arquitecto de software: ADRs, atributos de calidad, visión y revisión de impacto` desde `change/rol-arquitecto-software`, con `Closes #33`.
- `/opsx:verify rol-arquitecto-software` antes del merge, en una sesión interactiva, y `/opsx:archive` después.
- El change `clasificacion-odd-sdd` (#32) sigue en pausa; al retomarlo, resolver los conflictos con `.claude/CLAUDE.md` y `openspec/config.yaml`.
