Issue: #52

## Why

Lo pendiente de cada proyecto está repartido en cinco lugares con formatos distintos: la hoja de ruta de `docs/arquitectura/vision.md`, los `- no incluye:` de `## Alcance`, los changes activos, los issues de GitHub y los "Pendientes" del `context.md` del vault. La regla de `issue-creation` ("no hay `/opsx:propose` sin issue aprobado") existe pero no se cumple: los últimos changes salieron sin issue, las etiquetas `status:*` que usa la skill no existen en el repo y los issues #9 y #6 siguen abiertos aunque están resueltos. Hoy no hay una lista única y priorizada de lo que falta hacer, y el SRS (lo que el sistema ya hace) no tiene contraparte.

## What Changes

Modelo B del explore del 13/11/2026: los issues de GitHub son la fuente única de lo pendiente de cada proyecto, y `docs/backlog.md` es una vista generada que convive con el SRS.

- **`issue-creation`:** pide prioridad (`prioridad:alta`, `media`, `baja`) y tipo (`tipo:feature`, `deuda`, `bug`), crea las etiquetas que falten en el repo y crea el issue con `status:needs-review` más esas dos etiquetas.
- **`openspec-propose` y `/opsx:propose`:** antes de crear el change, piden el issue, lo controlan con `gh` y escriben `Issue: #NN` como primera línea del `proposal.md`. Frenan si el issue no existe o está cerrado. Si no tiene `status:approved`, le preguntan al usuario y, si confirma, agregan la etiqueta. Sin `gh`, sin red o sin permiso, avisan, escriben `Issue: pendiente` y siguen.
- **`branch-pr`:** si el proposal (o el documento ODD) tiene `Issue: #NN`, agrega `Closes #NN` al cuerpo del PR, así el merge cierra el issue.
- **Script nuevo `scripts/generar-backlog.ps1`:** genera `docs/backlog.md` desde los issues abiertos (por prioridad y número, con tipo y estado `bloqueado`), sin copiar el cuerpo de los issues. Si no puede leerlos, avisa, no toca el archivo y termina con 1.
- **`openspec-archive-change` y `/opsx:archive`:** en la fase de la rama, después del SRS, regeneran `docs/backlog.md` si existe, o preguntan si generarlo. Si el script falla, avisan y siguen.
- **`srs-generate`:** cada requirement nuevo anota el issue del change que lo agregó (atributo "Issue" en el SRS y mapa `issues:` en `docs/srs.meta.yaml`).
- **Hoja de ruta:** el formato de cada línea suma un final opcional `— issue: #NN` (en el rol de arquitecto de `.claude/CLAUDE.md` y en la guía de visión del propose).
- **ODD (`odd-change` y `/odd`):** el documento puede llevar `Issue: #NN` si el issue existe; no es obligatorio.
- **Migración de este repo:** crear las etiquetas, cerrar #9 y #6 citando la spec que los resolvió, crear un issue por cada línea de la hoja de ruta (7) y sumarles el número en `vision.md`, y generar el primer `docs/backlog.md`.
- **Ficha del proyecto:** `## Datos` suma los issues de GitHub como dato externo y `## Stack` suma GitHub Issues como integración (ya hecho en este propose).

Archivos globales que se modifican y por qué:
- `.claude/CLAUDE.md` (rol de arquitecto, formato de la hoja de ruta): es la fuente de las reglas globales.
- `skills/issue-creation`, `skills/openspec-propose`, `skills/branch-pr`, `skills/openspec-archive-change`, `skills/srs-generate` y `skills/odd-change`: son las fuentes del comportamiento de Claude. Los comandos `.claude/commands/opsx/propose.md`, `archive.md`, `odd.md` y `odd/start.md` se regeneran desde ellas.

## Capabilities

### New Capabilities
- `product-backlog`: los issues de GitHub como fuente única de lo pendiente de un proyecto (etiquetas, issue en el proposal y en el PR, generación de `docs/backlog.md` y su oferta en el archive, issue de origen en el SRS, hoja de ruta con número de issue e issue opcional en el ODD).

### Modified Capabilities
- (ninguna)

## Non-goals

- Lo operativo entre proyectos (máquinas, poner al día proyectos, `claude auth login`): sigue en el `context.md` del vault, porque no es producto.
- Migrar a issues los "no incluye" de `## Alcance` o los pendientes del vault de otros proyectos: cada proyecto lo hace cuando lo necesite con `/issue-creation`.
- GitHub Projects, tableros o estimaciones: el backlog es la lista de issues abiertos con prioridad y tipo.
- Proyectos sin repositorio en GitHub (hoy, analisis-LO-Saleforce): quedan afuera hasta que se suban. El propose les escribe `Issue: pendiente`.
- Validar `Issue:` en el CI de los PR (`pr-check.yml`): queda para el change de la huella en el CI.

## Impact

- Todos los proyectos: el propose empieza a pedir un issue y el PR lo cierra. Los proyectos reciben las skills nuevas con `instalar.ps1`. Los changes en curso no cambian.
- GitHub: en este repo se crean 9 etiquetas y 7 issues y se cierran #9 y #6. En los otros repos, las etiquetas se crean la primera vez que se usa `/issue-creation`.
- Hay tres dueños de repos (Toyota-Yacopini, lmontecchiani-dev y Lautaro-Montecchiani): la cuenta activa de `gh` tiene que tener permiso en el repo. Si no lo tiene, el propose y el archive avisan y siguen, e `issue-creation` frena y dice qué cuenta activar.
- Documentación: el `docs/srs.md` suma el atributo "Issue" en los requirements nuevos. Aparece `docs/backlog.md` en los proyectos que lo generen.
