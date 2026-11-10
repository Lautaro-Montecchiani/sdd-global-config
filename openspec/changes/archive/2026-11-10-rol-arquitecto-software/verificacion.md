# Verificación con fixtures: instructivo para el Agente

Instructivo de las tareas 6.3, 6.5 y 6.6 de `tasks.md`. Lo que se prueba es el comportamiento de Claude (propose, verify y archive), así que cada prueba corre en una **sesión nueva de Claude Code en modo no interactivo** (`claude -p`). El Agente no implementa nada acá: ejecuta, compara con lo esperado y pega la evidencia.

Las pruebas de 6.4 (S06, S19 y S20) las hace el usuario en una sesión interactiva: no son del Agente.

## Antes de empezar

- Las tareas de la sección 7 de `tasks.md` tienen que estar hechas e instaladas: las pruebas corren sobre la versión instalada en `~/.claude`.
- Fixtures ya armados por Claude (tarea 6.2):
  - **Repo A:** `$env:TEMP\arq-prueba-a`. Rama `master` sin visión y rama `fixture/con-vision` con `docs/arquitectura/vision.md`.
  - **Repo B:** `$env:TEMP\arq-prueba-b`.
  - **Vault falso V:** `$env:TEMP\arq-prueba-vault`, con remote bare `$env:TEMP\arq-prueba-vault-remote.git`.
- **Nunca usar el vault real.** En la misma sesión de PowerShell de cada prueba, antes de `claude -p`, redefinir `$env:OBSIDIAN_VAULT = "$env:TEMP\arq-prueba-vault"`. Si una prueba escribe en `D:\Proyectos\sdd-vault` o en otro vault que no sea V, frenar y avisar.
- Comando base de cada prueba (en PowerShell, parado en el repo del fixture):
  - `claude -p "<pedido>" --permission-mode acceptEdits --add-dir "$env:TEMP\arq-prueba-vault" --allowedTools "Read,Edit,Write,Glob,Grep,PowerShell,Bash(git:*),Bash(openspec:*)"`
  - `PowerShell` hace falta para leer `$env:OBSIDIAN_VAULT` y `--add-dir` para escribir en V, que está fuera del repo del fixture. Sin los dos, `claude -p` no puede pedir aprobación y saltea el vault: eso no es un resultado válido de la prueba sino un error del entorno, y la prueba se repite.
- **Una prueba por vez en cada repo.** El propose crea ramas, así que entre pruebas del mismo repo hay que volver a `master` (`git checkout master`) y borrar la rama creada (`git branch -D change/<nombre>`) y la carpeta `openspec/changes/<nombre>/` si quedó. Para correr en paralelo (de a 3 como máximo), clonar el fixture (`git clone $env:TEMP\arq-prueba-a $env:TEMP\arq-prueba-a2`).
- No editar archivos de `sdd-global-config` salvo marcar las tareas 6.3, 6.5 y 6.6 de `tasks.md` y agregar la evidencia al resumen del apply del vault real (`projects/sdd-global-config/apply/2026-11-09-rol-arquitecto-software.md`, sección nueva al final).
- Evidencia de cada ID: el pedido, el resultado (`coincide` / `no coincide`) y las líneas del `design.md`, `tasks.md` o reporte que lo prueban (no el archivo entero). Si no coincide, no se arregla nada: se anota y se avisa.

## 6.3: propose (S03, S04, S05, S07, S08, S09, S10, S11, S21)

| ID | Repo y rama | Pedido para `claude -p` | Qué tiene que pasar |
|---|---|---|---|
| S03, S08, S10 | A, `master` | `/opsx:propose cache-clima: agregar una caché en memoria de 10 minutos a src/services/clima.py` | `## Impacto en el sistema` existe antes de `## Ubicación de archivos`. **Componentes afectados** nombra `src/api/pronostico.py` y `src/api/alertas.py` (S03). **Atributos de calidad** tiene una línea de rendimiento con `— Verificación:` (S08). Hay `## Visión inicial` y `tasks.md` tiene una tarea para que el Agente cree `docs/arquitectura/vision.md` (S10). Claude no creó `docs/arquitectura/vision.md`. |
| S05 | A, `master` | `/opsx:propose postgresql: reemplazar SQLite por PostgreSQL en src/db/` | `design.md` tiene `## ADR` con `0003`, `Estado: aceptada` y las secciones Contexto, Alternativas, Decisión y Consecuencias; que reemplaza a `0001`. `tasks.md` tiene la tarea de crear `docs/adr/0003-<slug>.md` y la de cambiar el estado de `0001` a `reemplazada por 0003`. Claude no creó el archivo del ADR. |
| S11 | A, `fixture/con-vision` | `/opsx:propose timeout-clima: agregar un timeout de 2 segundos a obtener_pronostico en src/services/clima.py` | **Deuda técnica** dice que paga "sin timeout en clima". `tasks.md` tiene una tarea para quitar esa línea de `## Hoja de ruta` de `docs/arquitectura/vision.md`. No hay `## Visión inicial` (la visión ya existe). |
| S04, S07, S09, S21 | B, `master` | `/opsx:propose typo-ayuda: corregir el typo "Exporat" del texto de ayuda en scripts/exportar.py` | Las cuatro partes de `## Impacto en el sistema` dicen "ninguno", "ninguna" o "sin `## Calidad` declarada" (S04, S09). No hay `## ADR` (S07). El resumen final dice que falta `## Calidad` y sugiere `/ficha` (S09, S21). |
| S21 (regresión) | copia de B sin `## Datos` ni `## Stack` | `/opsx:propose typo-ayuda2: corregir el typo "Exporat" del texto de ayuda en scripts/exportar.py` | El resumen final dice que faltan `## Datos`, `## Stack` y `## Calidad` y sugiere `/ficha`, sin haber preguntado. Para la copia: clonar B, borrar esas dos subsecciones del `openspec/config.yaml` de la copia y commitear en la copia. |
| S21 (sensibles) | — | — | En todos los `design.md` generados arriba, los textos de ADR, visión e impacto no copian bloques de código, credenciales ni datos personales. |

## 6.5: verify y archive (S12, S13, S14, S15, S16)

Para estas pruebas hace falta una rama de A con un change ya "implementado". El Agente la arma a mano (es un fixture, no código del proyecto) partiendo del `design.md` que generó S05 o S03.

| ID | Preparación en A | Pedido para `claude -p` | Qué tiene que pasar |
|---|---|---|---|
| S14 | Rama `change/postgresql` con el change de S05 y un commit que toca `src/db/conexion.py` **sin** agregar nada en `docs/adr/`. Marcar `[x]` en sus tareas y escribir el resumen del apply en V (`projects/arq-prueba-a/apply/AAAA-MM-DD-postgresql.md`). | `/opsx:verify postgresql` | El reporte tiene la tabla "Arquitectura de software" con un WARNING de ADR ("falta en docs/adr/"). Ese control no agrega un CRITICAL propio (puede haber otros CRITICAL, por ejemplo la explicabilidad `pendiente` por correr con `-p`, o una tarea `[x]` sin respaldo). |
| S15 | Rama `change/cache-clima` con el change de S03 y un commit que agrega en `src/services/clima.py` algo que contradice la `— Verificación:` de rendimiento del design (por ejemplo, una espera fija de 1 segundo antes de llamar a la API). | `/opsx:verify cache-clima` | WARNING de rendimiento con el motivo en una línea. |
| S16 | Rama `change/sin-impacto` con un change cuyo `design.md` se editó a mano para quitar `## Impacto en el sistema`. | `/opsx:verify sin-impacto` | Una SUGGESTION por la falta de `## Impacto en el sistema` y ningún WARNING por eso. |
| S12 | Rama `change/postgresql` completa: agregar `docs/adr/0003-<slug>.md` con el texto del design, mergear a `master` de A (merge local, sin PR). | `/opsx:archive postgresql` | En V existe `projects/arq-prueba-a/arquitectura.md` con `## Nivel`, `## Atributos de calidad` (rendimiento y mantenibilidad), `## Decisiones vigentes` con `0003` y `## Deuda prioritaria`. El commit `chore: arq-prueba-a — archive postgresql` de V lo incluye y llegó al remote bare (`git -C $env:TEMP\arq-prueba-vault-remote.git log --oneline -1`). Si el archive ofrece el SRS, responder "Más tarde" (con `-p` no puede preguntar: anotar qué hizo). **Repetición:** si una corrida anterior archivó sin tocar V, antes de repetir dejar A como estaba después del merge (`git -C $env:TEMP\arq-prueba-a checkout -- .` y `git -C $env:TEMP\arq-prueba-a clean -fd openspec/`) y verificar que `openspec/changes/postgresql/` volvió. |
| S13 | Después de S12. | `claude -p "Resumí el estado de arquitectura de este proyecto según tu contexto de inicio de sesión." --add-dir "$env:TEMP\arq-prueba-vault" --allowedTools "Read,Glob,Grep,PowerShell"` en A | La respuesta menciona datos de `arquitectura.md` de V (por ejemplo, el ADR `0003`). |

## 6.6: cierre

Marcar 6.6 solo si S03 a S05, S07 a S16 y S21 coinciden y el usuario ya marcó 6.4 (S06, S19 y S20). Si alguno no coincide, dejar 6.6 en `[ ]` con la lista de IDs y el motivo.

Al terminar, borrar los clones extra (`arq-prueba-a2`, etc.). Los fixtures originales quedan para el re-verify de Claude.
