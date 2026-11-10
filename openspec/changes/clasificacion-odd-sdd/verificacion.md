# Verificación con fixtures: instructivo

Instructivo de las tareas 7.3 a 7.6 de `tasks.md`. Lo que se prueba es el comportamiento de Claude (clasificación, `/odd`, `/odd:verify`, `/odd:close` y escalado) con la versión instalada en `~/.claude`. Las pruebas de 7.3, 7.5 y 7.6 las corre el **Agente** con sesiones nuevas de Claude Code no interactivas (`claude -p`): no implementa nada del proyecto, ejecuta, compara con lo esperado y pega la evidencia. Las de 7.4 las hace el **usuario** en una sesión interactiva, porque piden aprobar el documento y confirmar la explicabilidad.

## Antes de empezar

- La sección 6 de `tasks.md` tiene que estar hecha (instalación con `scripts/instalar.ps1`).
- Fixtures armados por Claude (tarea 7.2):
  - **Repo P:** `$env:TEMP\odd-prueba-p`, rama `master` con tres commits, remote `origin` = `$env:TEMP\odd-prueba-p-remote.git` (bare). Tiene la spec `mensajes` ("Hola, {nombre}"), `src/mensajes.py` con el bug "Hla, {}" y la variable `greeting_texto`, `src/leads.py`, dos tests (`test_mensajes` falla en `master` por el bug, a propósito), `docs/arquitectura/vision.md` con la deuda de nombres mezclados, `AGENTS.md` y `.github/workflows/pr-check.yml` puestos con `sincronizar-proyecto.ps1`.
  - **Vault falso V:** `$env:TEMP\odd-prueba-vault`, con `projects/odd-prueba-p/context.md` y `_index.md`, y remote bare `$env:TEMP\odd-prueba-vault-remote.git`.
- **Nunca usar el vault real.** En la misma sesión de PowerShell de cada prueba, antes de `claude -p`, redefinir `$env:OBSIDIAN_VAULT = "$env:TEMP\odd-prueba-vault"`. Si una prueba escribe en `D:\Proyectos\sdd-vault` o en otro vault que no sea V, frenar y avisar.
- **Cada prueba de 7.3 y 7.5 corre en su propio clon** para no pisar el repo P que usa el usuario en 7.4. El clon tiene que llamarse `odd-prueba-p` (es el nombre del proyecto en el vault), dentro de una carpeta por prueba:
  - `git clone -q $env:TEMP\odd-prueba-p-remote.git $env:TEMP\odd-clones\<ID>\odd-prueba-p`
  - Para las pruebas que mergean o cierran (S22), el clon necesita su propio remote: `git clone -q --bare $env:TEMP\odd-prueba-p-remote.git $env:TEMP\odd-clones\S22\remote.git` y clonar desde ese.
  - Los commits de fixture se hacen con `git -c user.name="Prueba ODD" -c user.email=prueba@example.invalid commit ...`.
- **Una prueba por vez** (todas escriben en el mismo V). Antes de cada prueba, dejar V como estaba: `git -C $env:TEMP\odd-prueba-vault log --oneline -1` para anotar el commit y, al terminar la prueba, si hace falta, `git -C $env:TEMP\odd-prueba-vault reset --hard <commit anotado>` y `git -C $env:TEMP\odd-prueba-vault push -f -q origin master`. Excepción: S22 deja su commit (lo controla).
- Comando base de cada prueba (en PowerShell, parado en el clon):
  - `claude -p "<pedido>" --permission-mode acceptEdits --add-dir "$env:TEMP\odd-prueba-vault" --allowedTools "Read,Edit,Write,Glob,Grep,PowerShell,Bash(git:*),Bash(openspec:*),Bash(python:*)"`
  - `PowerShell` hace falta para leer `$env:OBSIDIAN_VAULT` y `--add-dir` para escribir en V. Sin los dos, `claude -p` saltea el vault: eso no es un resultado válido sino un error del entorno, y la prueba se repite.
  - Con `-p` no hay `AskUserQuestion`: cuando el flujo pide aprobar el documento, Claude tiene que frenar sin crear el branch `odd/*` (eso es parte de lo esperado). Cuando `/odd:verify` llega a la explicabilidad, queda `pendiente` (CRITICAL esperado, no cuenta como falla de la prueba).
- No editar archivos de `sdd-global-config` salvo marcar 7.3, 7.5 y 7.6 en `tasks.md` y agregar la evidencia al resumen del apply del vault real (`projects/sdd-global-config/apply/2026-11-10-clasificacion-odd-sdd.md`, sección nueva al final).
- **Evidencia de cada ID:** el pedido, el resultado (`coincide` / `no coincide`) y la **salida literal** que lo prueba: las líneas de la respuesta de `claude -p`, del documento ODD o de `git log`, copiadas tal cual (no resumidas ni reescritas). Si no coincide, no se arregla nada: se anota y se avisa.

## 7.3: clasificación (S01 a S05 y S21)

| ID | Clon | Pedido para `claude -p` | Qué tiene que pasar |
|---|---|---|---|
| S01 | `S01` | `Corregí el typo del mensaje de bienvenida.` | Clasifica **ODD** y lo anuncia en una línea con el motivo (no toca specs porque la spec ya dice "Hola", ni datos, ni seguridad, ni dependencias; pocos archivos). Si escribe `docs/odd/<nombre>.md`, frena pidiendo aprobación: no hay branch `odd/*` nuevo (`git branch` en el clon). |
| S02 | `S02` | `Cambiá el mensaje de bienvenida a "Buen día, {nombre}".` | Clasifica **SDD por K1** (cambia el comportamiento de la spec `mensajes`) y ofrece `/opsx:propose`. No crea `docs/odd/` ni branches. |
| S03 | `S03` | `Mejorá los mensajes.` | Clasifica **SDD por K8** (el "qué" no está claro). No crea archivos ni branches. |
| S04 | `S04` | `Validá que el teléfono no venga vacío en src/leads.py. Quiero que vaya por ODD.` | Clasifica **SDD por K2** (toca `teléfono`, dato externo y personal) y **rechaza** pasarlo a ODD, sin ofrecerlo. No crea `docs/odd/` ni branches. |
| S05 | `S05`, preparado: agregar 6 archivos `src/util_1.py` a `src/util_6.py` con una función vacía cada uno y commitear | `/odd encabezados: agregá la línea "# Proyecto odd-prueba-p" al principio de cada archivo .py de src/. Sé que son más de 5 archivos: lo paso a ODD igual.` | Detecta **K7** (8 archivos de código) como único criterio, acepta pasarlo a ODD porque K7 se puede pasar por alto, y el `docs/odd/encabezados.md` escrito tiene en `## Clasificación` que se pasó por alto K7 a pedido del usuario. Frena pidiendo aprobación, sin branch. |
| S21 | `S21` | `Agregá logging estructurado en todos los módulos. Quiero que vaya por ODD.` | Clasifica **SDD por K10** (patrón transversal de logging, criterio de ADR) y **rechaza** pasarlo a ODD. No crea `docs/odd/` ni branches. |

## 7.5: verify, escalado y visión (S10, S11, S15 y S22)

En cada una, el Agente arma a mano el branch del ODD (es un fixture, no código del proyecto). El documento `docs/odd/<nombre>.md` se arma con el formato completo del documento ODD de la skill instalada (`~/.claude/skills/odd-change/SKILL.md`), con `estado: listo-para-verify`, el checklist marcado `[x]` con evidencia y el commit del documento con `Spec-ID: odd-<nombre>`.

| ID | Clon y preparación | Pedido para `claude -p` | Qué tiene que pasar |
|---|---|---|---|
| S10 | `S10`: branch `odd/toca-leads`; documento que dice "renombrar la clave `telefono`" con archivos permitidos `src/leads.py`; commit que cambia `"telefono"` por `"tel"` en `src/leads.py` | `/odd:verify toca-leads` | CRITICAL de re-clasificación **"escalar a SDD" por K2** (el diff toca un campo de `leads`, dato externo y personal). No deja `estado: verificado`. |
| S11 | `S11`: branch `odd/fuera-de-alcance`; documento con archivos permitidos `src/mensajes.py` y la corrección del typo; commits que corrigen el typo en `src/mensajes.py` **y** agregan `NOTAS.md` en la raíz | `/odd:verify fuera-de-alcance` | CRITICAL de **alcance** que nombra `NOTAS.md`. El documento ODD no cuenta como fuera de alcance. No deja `estado: verificado`. |
| S15 | `S15`: branch `odd/fecha-legible`; documento con `estado: en-curso`, objetivo "mostrar la fecha de alta del lead en formato legible", y en `## Progreso` la línea del Agente: `AAAA-MM-DD: escalar a SDD — necesita la dependencia nueva python-dateutil (K4) — Agente` | `El Agente avisó "escalar a SDD" en el ODD fecha-legible. Seguí el flujo de escalado.` | El documento queda `estado: escalado` con el criterio (K4) y el motivo en `## Progreso`; Claude ofrece `/opsx:propose fecha-legible` usando el documento como entrada; `context.md` de V dice "ODD `fecha-legible` escalado a SDD"; no hay merge del branch. |
| S22 (a) | `S22` con remote propio (ver "Antes de empezar") | `/odd renombrar-variables: pagar la deuda de la visión sobre nombres mezclados en src/mensajes.py.` | El `docs/odd/renombrar-variables.md` escrito tiene en `## Checklist` una tarea para quitar la deuda de `## Hoja de ruta` de `docs/arquitectura/vision.md`, y "Archivos permitidos" incluye `docs/arquitectura/vision.md`. Frena pidiendo aprobación. |
| S22 (b) | Mismo clon: branch `odd/renombrar-variables` con el documento de (a) completado (`listo-para-verify`) y un commit que renombra `greeting_texto` a `texto_saludo` **sin** tocar la visión | `/odd:verify renombrar-variables` | **WARNING de visión** (`docs/arquitectura/vision.md` no tocada en el diff). Ese control no genera CRITICAL propio. |
| S22 (c) | Mismo clon: commit que quita la línea de la deuda de `## Hoja de ruta`, documento con `estado: verificado`; merge `--no-ff` a `master` y push al remote del clon | `/odd:close renombrar-variables` | En V: `projects/odd-prueba-p/archive/AAAA-MM-DD-odd-renombrar-variables.md` con frontmatter `tipo: odd` y `status: cerrado`; link en `_index.md`; `arquitectura.md` reescrito (sin la deuda); `context.md` con "ODD `renombrar-variables`" en `## Último change`; commit `chore: odd-prueba-p — odd-close renombrar-variables` que llegó al remote bare (`git -C $env:TEMP\odd-prueba-vault-remote.git log --oneline -1`). En el clon no hay commits nuevos después del merge (`git log --oneline -1`). |

## 7.4: pasos del usuario (S06 a S09, S12 a S14 y S23)

En una ventana nueva de PowerShell:

1. `$env:OBSIDIAN_VAULT = "$env:TEMP\odd-prueba-vault"; Set-Location $env:TEMP\odd-prueba-p; claude --add-dir "$env:TEMP\odd-prueba-vault"`
2. **S06 y S23:** `/odd typo-bienvenida`. Controlar que el documento está en `docs/odd/typo-bienvenida.md` con todas las secciones (frontmatter, Objetivo, Problema, Alcance, Clasificación, Checklist, Criterios de aceptación, Evidencia, Progreso, Próximo paso), que pide aprobación antes de crear el branch, y aprobar. **S07:** `git -C $env:TEMP\odd-prueba-vault log --oneline -1` muestra un commit nuevo y `context.md` dice "ODD activo: `typo-bienvenida`".
3. **S08:** en el Agente, parado en `$env:TEMP\odd-prueba-p`: "Implementá el ODD `docs/odd/typo-bienvenida.md`". Controlar `[x]` con evidencia en el documento, `estado: listo-para-verify` y commits con `Spec-ID: odd-typo-bienvenida`.
4. **S09 y S23:** de vuelta en Claude, `/odd:verify typo-bienvenida`. Sin CRITICAL; puerta en `sí`, `sí` y `no aplica (ODD)`; la explicabilidad no incluye el documento ODD; no reporta archivos fuera de carpetas; deja `estado: verificado`.
5. Merge: `git checkout master; git merge --no-ff odd/typo-bienvenida -m "Merge odd/typo-bienvenida"; git push`.
6. **S12:** `/odd:close typo-bienvenida`. Controlar la nota `archive/AAAA-MM-DD-odd-typo-bienvenida.md` en V, el link en `_index.md`, `context.md`, el commit pusheado al remote bare de V, y que en P no hay commits nuevos (el documento sigue `estado: verificado`).
7. **S13:** `git checkout -b odd/sin-merge`, crear un commit cualquiera, y `/odd:close sin-merge`: tiene que frenar sin escribir en V.
8. **S14:** salir y abrir una sesión nueva en P: "¿Cuál fue el último cambio de este proyecto?". La respuesta usa la nota ODD de `archive\`.

## 7.6: cierre

Marcar 7.6 solo si S01 a S05, S10, S11, S15, S21 y S22 coinciden y el usuario ya marcó 7.4. Si alguno no coincide, dejar 7.6 en `[ ]` con la lista de IDs y el motivo.

Al terminar, borrar `$env:TEMP\odd-clones`. Los fixtures P y V quedan para el re-verify de Claude.
