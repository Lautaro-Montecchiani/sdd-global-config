# Tasks

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 minutos). Cada tarea con test pega la salida literal en rojo (antes) y en verde (después). Escribir los archivos con el editor o Python, nunca con strings de PowerShell entre comillas dobles (design D5).

## 1. Test primero

- [ ] 1.1 Crear `tests/aclarar-k2.Tests.ps1` (mismo estilo que `tests/clasificacion-odd.Tests.ps1`) con S01 y S04 del Test Plan, cada uno con su marcador `# test-plan: aclarar-k2/<ID>`. Correr el comando de tests: S01 y S04 en rojo, el resto en verde. Evidencia: la salida literal.
- [ ] 1.2 Commit: `test: test de K2 aclarado` con `Spec-ID: aclarar-k2`.

## 2. Reglas, skill y comandos

- [ ] 2.1 Reemplazar la fila K2 por la de design D1 en `.claude/CLAUDE.md`, `skills/odd-change/SKILL.md`, `.claude/commands/odd.md`, `.claude/commands/odd/start.md` y `.claude/commands/odd/verify.md`. Correr el comando de tests: S01 en verde, S25 de `clasificacion-odd-sdd` en verde. Evidencia: `git diff --stat` y la salida.
- [ ] 2.2 Commit: `feat: aclarar el criterio K2`, cuerpo con el impacto (la clasificación de todos los proyectos cambia desde la instalación) y `Spec-ID: aclarar-k2`.

## 3. Guías y visión

- [ ] 3.1 En `docs/workflow.md` y `docs/modo-de-uso.md` (y `README.md` si tiene la fila K2), la fila de design D2. Evidencia: el diff.
- [ ] 3.2 En `docs/arquitectura/vision.md`, quitar la deuda de K2 (design D4). Correr el comando de tests: todo en verde. Evidencia: el diff y la salida.
- [ ] 3.3 Buscar `C:\Users`, el nombre de la carpeta del usuario, `Invoke-Expression` e `iex` en los archivos del diff, sin resultados. Commit: `docs: K2 aclarado en las guías y la visión` con `Spec-ID: aclarar-k2`. Evidencia: la búsqueda y el commit.

## 4. Instalación y prueba

- [ ] 4.1 `pwsh -NoProfile -File scripts/instalar.ps1 -Simular` y, sin cambios locales, `pwsh -NoProfile -File scripts/instalar.ps1`. Evidencia: la tabla con los archivos en `igual` después de instalar.
- [ ] 4.2 Verificar que el cambio aplica en un proyecto de prueba: S02 y S03 en el repo de prueba P con `claude -p` y el vault de prueba. Evidencia: las respuestas literales.

## Workflow follow-up

- Issue #39. PR `[aclarar-k2] Aclarar el criterio K2 de la clasificación ODD/SDD` desde `change/aclarar-k2`, con `Closes #39` y `Spec-ID: aclarar-k2`.
- `/opsx:verify aclarar-k2` antes del merge y `/opsx:archive` después.
